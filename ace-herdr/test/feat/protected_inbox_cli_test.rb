# frozen_string_literal: true
require "test_helper"
require "ace/herdr/cli"
require "ace/assign/cli"
require "ace/assign/cli/commands/authority/inbox_context_principal"
require "ace/assign/cli/commands/authority/inbox_context_selection"
require "ace/assign/authority/protected_assignment_context"
require "socket"
require_relative "../support/inbox_context_owner_fixture"
require_relative "../support/codex_inbox_observation_fixture"

class ProtectedInboxCliTest < Minitest::Test
  include InboxContextOwnerFixture
  Entry = Ace::Runtime::Molecules::ProtectedTaskContextEntry
  Status = Struct.new(:ok) { def success? = ok }

  class PeerKernel < Kernel
    def initialize(peer) = @peer = peer
    def peer(_socket) = @peer
    def capture(_pid) = @peer
  end

  class CountingNative < CodexInboxObservationFixture::Native
    attr_reader :calls
    def initialize
      super
      @calls = []
    end
    def submit(**arguments)
      @calls << arguments
      super
    end
  end

  class Protection
    def root_path!(_path) = true
    def verify!(_path, handle, directory:)
      raise "fixture artifact kind differs" unless directory ? handle.stat.directory? : handle.stat.file?
    end
  end

  def artifact(name, bytes, mode = 0o644)
    path = File.join(@root, name)
    File.binwrite(path, bytes); File.chmod(mode, path)
    {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
  end

  def selected_entry
    wrapper = artifact("wrapper.py", "# fixed held fixture wrapper\n")
    interpreter = artifact("interpreter", "never executed controlled interpreter", 0o755)
    bootstrap = %w[original_source owner preparation].to_h { |key| [key, artifact("#{key}.json", "immutable #{key}")] }
    bootstrap["startup_entries"] = {"ace-assign" => artifact("assign.rb", "immutable source entry")}
    manifest = {"schema" => Entry::MANIFEST_SCHEMA, "role" => Entry::ROLE,
      "wrapper" => wrapper, "interpreter" => interpreter, "bootstrap" => bootstrap}
    @pin = {"manifest" => artifact("manifest.json", JSON.generate(manifest)), "wrapper" => wrapper}
    projection = artifact("projection.json", JSON.generate("schema" => Entry::SCHEMA, "task_context_entry" => @pin)).fetch("path")
    protection = Protection.new
    factory = Class.new do
      define_method(:initialize) { @held = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: protection) }
      define_method(:with) { |&block| @held.with { block.call(self) } }
      define_method(:read_path!) { |path, **opts| raise "unexpected discovery" unless path == Entry::PATH; @held.read_path!(projection, **opts) }
      define_method(:read!) { |ref| @held.read!(ref) }
      define_method(:verify_unchanged!) { @held.verify_unchanged! }
      define_method(:with_readonly_handle!) { |ref, &block| @held.with_readonly_handle!(ref, &block) }
    end
    Entry.new(artifacts_factory: -> { factory.new }, stat: ->(path) { raise "unexpected discovery path" unless path == Entry::PATH; File.lstat(projection) })
  end

  def child_context(endpoint, owner_peer)
    # Static installed selection is controlled; actual context classifier,
    # fixed command, held reference reads and effect owner remain production.
    descriptor = artifact("descriptor.json", "controlled installed descriptor bytes")
    history_ref = artifact("history.json", "controlled installed history bytes")
    roles = %w[launcher_uids reviewer_uids worker_uids service_executor_uids supervisor_uids].to_h { |key| [key, [Process.uid]] }
    context = {"control_socket_path" => endpoint, "owner_credentials" => owner_peer.slice("uid", "gid", "groups"), "native_mapping_id" => "mapping"}
    roles["service_receivers"] = {}; roles["inbox_contexts"] = {"ctx" => context}
    deployment = Object.new
    deployment.define_singleton_method(:artifact_reference) { descriptor }
    deployment.define_singleton_method(:data) { {"projects" => {"project" => roles}, "authorities" => {"authority" => {"uid" => Process.uid}}, "launch_mappings" => {"mapping" => {"launcher_uid" => Process.uid, "worker_uid" => Process.uid}}} }
    deployment.define_singleton_method(:mapping) { |id| raise KeyError unless id == "mapping"; {"project_id" => "project", "authority_id" => "authority"} }
    deployment.define_singleton_method(:inbox_context) { |mapping, id| raise KeyError unless mapping == "mapping" && id == "ctx"; context }
    deployment.define_singleton_method(:authority) { |id| raise KeyError unless id == "authority"; owner_peer.slice("uid", "gid", "groups").merge("socket_path" => endpoint) }
    history = Object.new
    history.define_singleton_method(:artifact_reference) { history_ref }
    history.define_singleton_method(:selects?) { |candidate| candidate.equal?(deployment) }
    history.define_singleton_method(:descriptors) { [deployment] }
    Ace::Assign::Authority::ProtectedAssignmentContext.new(deployment: deployment, history: history, uid: Process.uid, env: {},
      artifacts_factory: -> { Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: Protection.new) })
  end

  def test_registered_enqueue_uses_selected_child_actual_socket_and_durable_store
    native = CountingNative.new
    @source_inbox = Ace::Herdr::Organisms::Inbox.new(executor: PaneFixture.new, native: native,
      deliveries_dir: @events)
    restart
    endpoint = File.join(@root, "context.sock")
    listener = UNIXServer.new(endpoint)
    owner_peer = peer(505)
    entry_owner = selected_entry
    context = child_context(endpoint, owner_peer)
    invocations = []
    test = self
    runner = Object.new
    runner.define_singleton_method(:call) do |argv, **opts|
      invocations << argv.drop(5)
      test.assert_equal({}, opts.fetch(:environment))
      test.assert_equal "/", opts.fetch(:chdir)
      test.assert_equal [4, 5], opts.fetch(:descriptor_mapping).keys.sort
      test.assert_equal test.instance_variable_get(:@pin).fetch("manifest"), JSON.parse(opts.fetch(:descriptor_mapping).fetch(5).read)
      pin = test.instance_variable_get(:@pin)
      immutable = lambda { |value| value.each { |key, item| immutable.call(key); immutable.call(item) } if value.is_a?(Hash); value.freeze }
      immutable.call(pin)
      Object.const_set(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, pin)
      command = if argv[6] == "inbox-context-principal"
        Ace::Assign::CLI::Commands::Authority::InboxContextPrincipal.new
      else
        Ace::Assign::CLI::Commands::Authority::InboxContextSelection.new
      end
      command.instance_variable_set(:@protected_assignment_context, context)
      options = argv[6] == "inbox-context-principal" ? {} : {project: argv[8], mapping: argv[10], inbox_context: argv[12]}
      out, err = test.capture_io { test.assert_equal 0, command.call(**options) }
      test.assert_empty err
      Ace::Herdr::Molecules::BoundedProcess::Result.new(out, "", Status.new(true), false)
    ensure
      Object.send(:remove_const, :ACE_PROTECTED_TASK_CONTEXT_ENTRY) if Object.const_defined?(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, false)
    end
    selection = Ace::Herdr::Molecules::ProtectedInboxSelection.new(entry_owner: entry_owner, runner: runner, env: {})
    wire = Object.new
    wire.define_singleton_method(:root_path!) { |path, **_| raise "unexpected endpoint root" unless path == File.dirname(endpoint) }
    wire.define_singleton_method(:socket_identity) { |path| stat = File.lstat(path); raise "not socket" unless stat.socket?; [stat.dev, stat.ino, owner_peer.fetch("uid")] }
    wire.define_singleton_method(:connect) { |path, deadline:, &block| Ace::Runtime::Molecules::ProtectedSocket.connect(path, deadline: deadline, &block) }
    client_factory = ->(**opts) { Ace::Herdr::Molecules::InboxContextClient.selected(**opts, kernel: PeerKernel.new(owner_peer), wire: wire) }
    stop, workers = false, []
    acceptor = Thread.new do
      until stop
        socket = listener.accept
        workers << Thread.new(socket) do |connection|
          Ace::Herdr::Organisms::InboxContextServer.new(owner: @owner, context_id: "ctx", kernel: PeerKernel.new(@cli_peer || @normal)).handle(connection)
        ensure
          connection.close
        end
      end
    rescue IOError, Errno::EBADF
      raise unless stop
    end
    command = Ace::Herdr::CLI.resolve(["inbox"]).first
    variables = %i[@selection @context_client_factory @kernel]
    previous = variables.to_h { |key| [key, command.instance_variable_get(key)] }
    command.instance_variable_set(:@selection, selection)
    command.instance_variable_set(:@context_client_factory, client_factory)
    command.instance_variable_set(:@kernel, PeerKernel.new(@normal))
    command.define_singleton_method(:config) { raise "local config must never be read" }
    ref = File.join(@root, "ref.json"); payload = File.join(@root, "payload.txt")
    File.write(ref, JSON.generate("schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => "ws1", "pane" => "p1"))
    File.write(payload, "actual registered payload")
    args = %w[inbox enqueue --project project --mapping mapping --inbox-context ctx --assignment assignment --event event1 --attempt attempt1] + ["--ref", ref, "--file", payload]
    out, err = capture_io { assert_equal 0, Ace::Herdr::CLI.start(args) }
    assert_empty err
    queued = JSON.parse(out)
    assert_equal "queued", queued.fetch("state")
    assert_equal Digest::SHA256.hexdigest(File.binread(payload)), queued.fetch("payload_sha256")
    assert_equal @keys.snapshot.fetch("fingerprint"), queued.fetch("receipt_key_sha256")
    assert_equal 0, @owner.status(peer: @normal).fetch("active_operations")
    out, = capture_io { assert_equal 0, Ace::Herdr::CLI.start(args) }
    assert_equal queued, JSON.parse(out)
    assert_equal 0, @owner.status(peer: @normal).fetch("active_operations")
    deliver_args = %w[inbox deliver --project project --mapping mapping --inbox-context ctx --assignment assignment --event event1 --attempt attempt1 --claim-generation 0]
    out, err = capture_io { assert_equal 0, Ace::Herdr::CLI.start(deliver_args) }
    assert_empty err
    delivered = JSON.parse(out)
    assert_equal "delivered", delivered.fetch("state")
    assert_equal "idle", delivered.fetch("admission_state")
    assert_equal 1, native.calls.size
    assert_equal 0, @owner.status(peer: @normal).fetch("active_operations")
    out, = capture_io { assert_equal 0, Ace::Herdr::CLI.start(deliver_args) }
    assert_equal delivered, JSON.parse(out)
    assert_equal 1, native.calls.size, "exact original generation replay must not resubmit or wake"
    observe_args = %w[inbox observe --project project --mapping mapping --inbox-context ctx --assignment assignment --event event1 --attempt attempt1 --claim-generation 1]
    out, = capture_io { assert_raises(Ace::Support::Cli::Error) { Ace::Herdr::CLI.start(observe_args) } }
    assert_empty out, "ordinary peer cannot acquire observe_to_sign admission"
    @cli_peer = @signer
    command.instance_variable_set(:@kernel, PeerKernel.new(@signer))
    out, = capture_io { assert_raises(Ace::Support::Cli::Error) { Ace::Herdr::CLI.start(observe_args + ["--file", payload]) } }
    assert_empty out
    stale_args = observe_args.dup; stale_args[-1] = "2"
    out, = capture_io { assert_raises(Ace::Support::Cli::Error) { Ace::Herdr::CLI.start(stale_args) } }
    assert_empty out
    ledger = File.join(@events, "event1.json")
    before_observe = File.binread(ledger)
    mutations = [{"event_id" => "foreign"}, {"attempt_id" => "foreign"}, {"claim_generation" => 2},
      {"operation_id" => "f" * 32}, {"key_generation" => 2}, {"context_id" => "foreign"},
      {"payload_sha256" => "f" * 64}, {"binding" => {}}, {"observation" => {"outcome" => "uncertain", "evidence_id" => "forged"}}]
    mutations.each do |mutation|
      command.instance_variable_set(:@context_client_factory, ->(**opts) do
        actual = client_factory.call(**opts)
        wrapper = Object.new
        wrapper.define_singleton_method(:request) do |operation, params|
          result = actual.request(operation, params)
          operation == "observe_context" ? result.merge(mutation) : result
        end
        wrapper
      end)
      out, = capture_io { assert_raises(Ace::Support::Cli::Error) { Ace::Herdr::CLI.start(observe_args) } }
      assert_empty out
      assert_equal 1, @owner.status(peer: @signer).fetch("active_operations"), "unvalidated response retains admission"
      assert_equal before_observe, File.binread(ledger)
    end
    command.instance_variable_set(:@context_client_factory, client_factory)
    native.result = {"outcome" => "uncertain"}
    out, err = capture_io { assert_equal 0, Ace::Herdr::CLI.start(observe_args) }
    assert_empty err
    candidate = JSON.parse(out)
    assert_equal true, candidate.fetch("candidate")
    assert_equal({"outcome" => "uncertain"}, candidate.fetch("observation"))
    refute candidate.key?("evidence_id")
    assert_equal before_observe, File.binread(ledger)
    assert_equal 1, native.calls.size
    assert_equal 0, @owner.status(peer: @signer).fetch("active_operations")
    native.result = nil
    out, err = capture_io { assert_equal 0, Ace::Herdr::CLI.start(observe_args) }
    assert_empty err
    completed_candidate = JSON.parse(out)
    assert_equal true, completed_candidate.fetch("candidate")
    assert_equal "consumed", completed_candidate.dig("observation", "outcome")
    refute completed_candidate.key?("signature")
    assert_equal before_observe, File.binread(ledger)
    assert_equal 1, native.calls.size
    assert_equal 0, @owner.status(peer: @signer).fetch("active_operations")
    @cli_peer = @normal
    command.instance_variable_set(:@kernel, PeerKernel.new(@normal))
    ledger = File.join(@events, "event1.json")
    before_conflict = File.binread(ledger)
    File.write(payload, "conflicting payload")
    out, = capture_io { assert_raises(Ace::Support::Cli::Error) { Ace::Herdr::CLI.start(args) } }
    assert_empty out
    assert_equal before_conflict, File.binread(ledger)
    assert_equal 1, @owner.status(peer: @normal).fetch("active_operations"), "failed effect retains unknown admission"
    assert_equal 38, invocations.size
  ensure
    stop = true
    listener&.close
    acceptor&.value
    workers&.each(&:value)
    previous&.each { |key, value| command.instance_variable_set(key, value) }
    command&.singleton_class&.send(:remove_method, :config) if command&.singleton_class&.instance_methods(false)&.include?(:config)
  end

  def test_actual_selector_runner_deadline_is_typed_before_downstream
    runner = Object.new
    runner.define_singleton_method(:call) do |*_, **_options|
      Ace::Herdr::Molecules::BoundedProcess.call([RbConfig.ruby, "-e", "sleep 10"],
        timeout_s: 0.02, output_limit: 1024, cleanup_group: true)
    end
    selection = Ace::Herdr::Molecules::ProtectedInboxSelection.new(entry_owner: selected_entry, runner: runner, env: {})
    called = false
    error = assert_raises(Ace::Herdr::ValidationError) { selection.with({}) { called = true } }
    assert_equal "protected inbox selection is unavailable", error.message
    refute called
    assert_empty Dir.children(@events)
  end

  def test_downstream_timeout_keeps_its_original_exception
    owner = Object.new
    owner.define_singleton_method(:with) { |&block| block.call(nil) }
    selection = Ace::Herdr::Molecules::ProtectedInboxSelection.new(entry_owner: owner, env: {})
    original = Timeout::Error.new("downstream effect is uncertain")
    error = assert_raises(Timeout::Error) { selection.with({}) { raise original } }
    assert_same original, error
  end
end

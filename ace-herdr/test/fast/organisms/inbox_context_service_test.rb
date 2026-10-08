# frozen_string_literal: true

require "test_helper"
require "ace/herdr/organisms/inbox_context_service"
require_relative "../../support/inbox_context_service_runtime_fixture"
require_relative "../../../../ace-runtime/test/support/codex_runtime_installation_fixture"

class InboxContextServiceTest < Minitest::Test
  include InboxContextServiceRuntimeFixture
  alias_method :setup_runtime, :setup
  Service = Ace::Herdr::Organisms::InboxContextService
  ERROR = Ace::Herdr::ValidationError

  # Actual constructor/Store/listener composition with controlled full-owner,
  # kernel, cgroup and installed-file observations. No whole Inbox is injected.
  # The real Lab entry/initialization publication remains a separate source join.
  class CodexInstallationHarness
    include CodexRuntimeInstallationFixture
  end

  class Bootstrap
    attr_reader :initial_calls, :normal_calls, :prepared
    attr_accessor :after_prepare
    def initialize(association, native = nil)
      @native = native
      @association, @initial_calls, @normal_calls = association, 0, 0
    end
    def with_initial_inbox_context(configuration:, installation:, codex_runtime:)
      @initial_calls += 1
      select(configuration, installation) { |_selection| yield codex_runtime.static_association.merge(codex_runtime: codex_runtime).freeze }
    end
    def with_inbox_context_service(configuration:, installation:, codex_runtime:)
      @normal_calls += 1
      select(configuration, installation) { |_selection| yield codex_runtime.static_association.merge(codex_runtime: codex_runtime).freeze }
    end
    def with_inbox_context_installation(configuration:, installation:)
      raise "unselected installation" unless installation == {"path" => "/selected/installation", "bytes" => 1, "sha256" => "a" * 64}
      yield @association.merge(configuration: configuration).freeze
    end
    def with_codex_runtime_installation(configuration:, installation:, static:)
      raise "unselected original scope" unless static.fetch(:configuration).equal?(configuration) && @native
      yield @native
    end
    def select(configuration, installation)
      raise "unselected installation" unless installation == {"path" => "/selected/installation", "bytes" => 1, "sha256" => "a" * 64}
      raise "unselected configuration" unless configuration.reference == @association.fetch(:configuration).reference
      @prepared = yield @association
      raise "ingress before bounded startup acknowledgement" if File.exist?(configuration.data.fetch("control_socket_path"))
      after_prepare&.call(@prepared)
      @prepared
    end
  end

  class Paths < InboxContextOwnerFixture::FixturePaths
    def socket_identity(path) = Ace::Runtime::Molecules::ProtectedSocket.socket_identity(path)
  end

  def setup
    setup_runtime
    File.chown(nil, Process.gid, @root)
    File.chmod(0o750, @root)
    data = JSON.parse(JSON.generate(@configuration.data))
    @state, @events, @socket_parent = %w[state events socket].map { |name| File.join(@root, name) }
    [@state, @events].each { |path| Dir.mkdir(path, 0o700) }
    Dir.mkdir(@socket_parent, 0o750)
    File.chown(nil, Process.gid, @socket_parent)
    @socket_path = File.join(@socket_parent, "control.sock")
    data.merge!("state_root" => @state, "deliveries_dir" => @events, "control_socket_path" => @socket_path,
      "owner_credentials" => {"uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort.uniq}, "socket_gid" => Process.gid)
    data["grants"] = [{"uid" => 13000, "gid" => 13000, "groups" => [Process.gid], "role" => "authority", "purposes" => %w[deliver enqueue reconcile]}]
    public_key = File.join(@root, "public.pem")
    key_config = File.join(@root, "key.json")
    File.write(public_key, InboxContextOwnerFixture::KEY.public_to_pem)
    File.write(key_config, JSON.generate("schema" => "ace.herdr.inbox-key/v1", "context_id" => "ctx", "key_generation" => 1,
      "public_key_sha256" => Digest::SHA256.file(public_key).hexdigest))
    [public_key, key_config].each { |path| File.chmod(0o600, path) }
    data["key"] = {"public_key_path" => public_key, "configuration_path" => key_config}
    refs = %w[codex pi herdr].to_h do |role|
      path, bytes = File.join(@root, role), "#!/bin/sh\nexit 0\n"
      File.write(path, bytes)
      File.chmod(0o700, path)
      @files.bytes[path] = bytes
      ref = {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
      @artifacts << {"role" => "runtime_dependency", "host_path" => path, "view_path" => path, "sha256" => ref.fetch("sha256")}
      @profiles.fetch("ace-slot.service").fetch("BindReadOnlyPaths") << [path, path, false, 0]
      [role, ref]
    end
    @codex_socket = File.join(@root, "codex.sock")
    @codex_peer = {"uid" => 16000, "gid" => 16000, "groups" => [], "pid" => 16000, "parent_pid" => 1,
      "host" => "controlled", "started_at" => "linux:#{InboxContextServiceRuntimeFixture::BOOT}:99"}
    intent = {"schema" => "lab.codex-runtime-intent/v1", "project_id" => "project", "inbox_context_id" => "ctx",
      "native_mapping_id" => "map", "codex" => refs.fetch("codex"), "dependencies" => [], "environment" => {},
      "credentials" => @codex_peer.slice("uid", "gid", "groups"), "home" => @root,
      "socket_path" => @codex_socket, "socket_gid" => Process.gid, "unit_name" => "codex.service",
      "thread_configuration" => {"model" => "gpt-6.1", "approval_policy" => "never", "sandbox" => "danger-full-access"}}
    cwd = File.join(@root, "native")
    Dir.mkdir(cwd, 0o700)
    intent["cwd"] = cwd
    intent_path, intent_bytes = File.join(@root, "intent.json"), JSON.generate(intent)
    File.write(intent_path, intent_bytes)
    File.chmod(0o600, intent_path)
    @files.bytes[intent_path] = intent_bytes
    refs["codex_runtime_intent"] = {"path" => intent_path, "bytes" => intent_bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(intent_bytes)}
    @artifacts << {"role" => "runtime_dependency", "host_path" => intent_path, "view_path" => intent_path, "sha256" => refs.fetch("codex_runtime_intent").fetch("sha256")}
    @profiles.fetch("ace-slot.service").fetch("BindReadOnlyPaths") << [intent_path, intent_path, false, 0]
    data["native_clients"] = refs.merge("dependencies" => [], "environment" => {}, "cwd" => cwd,
      "resources" => [{"path" => cwd, "kind" => "directory", "access" => "read", "uid" => Process.uid, "gid" => File.stat(cwd).gid, "mode" => 0o700}])
    @profiles.fetch("ace-slot.service").fetch("BindReadOnlyPaths") << [cwd, cwd, false, 0]
    boundary_ref = @context_selection.fetch("boundary_manifest")
    boundary = JSON.parse(@files.bytes.fetch(boundary_ref.fetch("path")))
    boundary.fetch("resources") << {"host_path" => cwd, "view_path" => cwd, "stage" => "parent", "worker_visible" => true, "read_only" => true}
    @files.bytes[boundary_ref.fetch("path")] = JSON.generate(boundary)
    boundary_ref["bytes"], boundary_ref["sha256"] = @files.bytes.fetch(boundary_ref.fetch("path")).bytesize, Digest::SHA256.hexdigest(@files.bytes.fetch(boundary_ref.fetch("path")))
    @scope["boundary_manifest_sha256"] = boundary_ref.fetch("sha256")
    @artifacts.find { |artifact| artifact["role"] == "boundary_manifest" }["sha256"] = boundary_ref.fetch("sha256")
    @codex_harness = CodexInstallationHarness.new
    @codex_harness.setup
    native_installation = @codex_harness.selected_installation(intent_override: intent,
      authority: data.fetch("authority"), metadata_root: @root)
    @codex_association = {installation: native_installation, manager: @codex_harness.manager}.freeze
    data.fetch("native_clients")["codex_runtime_service"] = @codex_harness.selection
    @codex_harness.selection.values_at("unit_manifest", "boundary_manifest").each do |selected|
      @files.bytes[selected.fetch("path")] = File.binread(selected.fetch("path"))
      @artifacts << {"role" => "runtime_dependency", "host_path" => selected.fetch("path"), "view_path" => selected.fetch("path"), "sha256" => selected.fetch("sha256")}
      @profiles.fetch("ace-slot.service").fetch("BindReadOnlyPaths") << [selected.fetch("path"), selected.fetch("path"), false, 0]
    end
    config_ref = @configuration.reference
    bytes = JSON.generate(data)
    File.write(config_ref.fetch("path"), bytes)
    @files.bytes[config_ref.fetch("path")] = bytes
    config_ref = {"path" => config_ref.fetch("path"), "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
    @artifacts.find { |artifact| artifact["role"] == "context_configuration" }["sha256"] = config_ref.fetch("sha256")
    @stage = {"schema" => "ace.herdr.inbox-context-stage/v1", "codex_runtime" => {"path" => "/opt/context/runtime.json", "bytes" => 1, "sha256" => "a" * 64}, "project_id" => "project", "inbox_context_id" => "ctx", "configuration" => config_ref}
    @artifact_factory = -> { Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: InboxContextOwnerFixture::FixtureArtifacts.new(@root)) }
    @document = {"path" => "/selected/installation", "bytes" => 1, "sha256" => "a" * 64}
    runtime = {"schema" => "ace.herdr.codex-runtime/v1", "project_id" => "project", "inbox_context_id" => "ctx",
      "native_mapping_id" => "map", "provider" => "codex", "provider_version" => "0.159.3", "socket_path" => @codex_socket,
      "socket_gid" => Process.gid, "server_process_binding" => @codex_peer,
      "thread_id" => "0123abcd-0000-4000-8000-000000000001", "runtime_generation" => 1,
      "previous_runtime_reference" => nil, "intent" => refs.fetch("codex_runtime_intent"),
      "configuration" => config_ref, "installation" => @document}
    runtime_bytes = JSON.generate(runtime)
    @runtime_path = File.join(@root, "runtime.json")
    File.write(@runtime_path, runtime_bytes)
    File.chmod(0o600, @runtime_path)
    runtime_sha = Digest::SHA256.hexdigest(runtime_bytes)
    @stage["codex_runtime"] = {"path" => "/var/lib/lab/herdr-native-artifacts/codex/project/ctx/map/generations/1/#{runtime_sha}.json",
      "bytes" => runtime_bytes.bytesize, "sha256" => runtime_sha}
    @configuration = Ace::Herdr::Molecules::InboxContextServiceConfiguration.load(stage: @stage, artifacts: @artifact_factory.call)
    profile = @profiles.fetch("ace-slot.service")
    profile.merge!("User" => Process.uid.to_s, "Group" => Process.gid.to_s, "SupplementaryGroups" => Process.groups.sort.uniq.map(&:to_s))
    %w[User Group SupplementaryGroups BindReadOnlyPaths].each { |field| @manifest.fetch("properties").fetch("service")[field] = profile.fetch(field) }
    save_manifest
    @context_selection["unit_manifest"]["bytes"] = @files.bytes.fetch(@context_selection.fetch("unit_manifest").fetch("path")).bytesize
    @context_selection["unit_manifest"]["sha256"] = @scope.fetch("unit_manifest_sha256")
    @installation = Installation.for_inbox_context(service: @context_selection, configuration: config_ref, load_paths: ["/usr/lib/ruby"],
      authority: data.fetch("authority"), owner_credentials: data.fetch("owner_credentials"), files: @files)
    credentials = data.fetch("owner_credentials")
    @kernel.define_singleton_method(:capture) do |pid|
      credentials.merge("pid" => pid, "parent_pid" => 1, "host" => "controlled", "started_at" => "linux:#{InboxContextServiceRuntimeFixture::BOOT}:42")
    end
    codex_path, codex_peer = @codex_socket, @codex_peer
    @kernel.define_singleton_method(:pin) { |_peer| File.open(File::NULL) }
    @kernel.define_singleton_method(:exited?) { |_pin| false }
    @kernel.define_singleton_method(:peer) do |socket|
      next codex_peer if socket.remote_address.unix_path == codex_path
      {"uid" => 13000, "gid" => 13000, "groups" => [Process.gid], "pid" => 13000, "parent_pid" => 1,
        "host" => "controlled", "started_at" => "linux:#{InboxContextServiceRuntimeFixture::BOOT}:43"}
    end
    @bootstrap = Bootstrap.new({configuration: @configuration, installation: @installation, manager: @manager, kernel: @kernel, cgroups: @cgroups}.freeze, @codex_association)
    @codex_listener = UNIXServer.new(@codex_socket)
    @codex_thread = Thread.new do
      loop do
        socket = @codex_listener.accept
        driver = WebSocket::Driver.server(CodexWriter.new(socket))
        driver.on(:connect) { driver.start }
        driver.on(:message) do |event|
          message = JSON.parse(event.data)
          if message["method"] == "initialize"
            driver.text(JSON.generate("id" => message.fetch("id"), "result" => {}))
          elsif message["method"] == "thread/read"
            @native_reads ||= []
            @native_reads << message
            @before_native_read&.call(message)
            driver.text(JSON.generate("id" => message.fetch("id"), "result" => @native_read_result))
          elsif message["method"] == "thread/queue/add"
            @native_adds ||= []
            @native_adds << message
            @before_native_add&.call(message)
            if @native_reply_lost
              socket.close
            else
              params = message.fetch("params")
              driver.text(JSON.generate("id" => message.fetch("id"), "result" => {"queuedSubmission" => {
                "id" => "00000000-0000-0000-0000-000000000002", "clientUserMessageId" => params.fetch("clientUserMessageId"),
                "input" => params.fetch("input")}}))
            end
          end
        end
        begin
          driver.parse(socket.readpartial(2048)) until socket.closed?
        rescue EOFError
          nil
        ensure
          socket.close unless socket.closed?
        end
      end
    rescue IOError, Errno::EBADF
      nil
    end
  end

  def teardown
    @codex_listener&.close
    raise "controlled Codex socket handler remained live" unless @codex_thread&.join(2)
    @codex_thread.value
    super
  end

  class CodexWriter
    def initialize(socket) = @socket = socket
    def write(bytes) = @socket.write(bytes)
  end

  class RuntimeArtifacts
    attr_reader :open_scopes, :close_count
    def initialize(factory, logical, physical)
      @factory, @logical, @physical = factory, logical, physical
      @open_scopes = @close_count = 0
    end
    def with
      @open_scopes += 1
      @factory.call.with do |held|
        logical, physical = @logical, @physical
        mapped = Object.new
        mapped.define_singleton_method(:read!) { |reference| held.read!(reference.fetch("path") == logical ? reference.merge("path" => physical) : reference) }
        mapped.define_singleton_method(:verify_unchanged!) { held.verify_unchanged! }
        yield mapped
      end
    ensure
      @open_scopes -= 1
      @close_count += 1
    end
  end

  class RuntimeEndpoint
    def with(path, uid:, gid:)
      original = Ace::Runtime::Molecules::ProtectedSocket.socket_identity(path)
      selection = [path, original]
      yield selection
      verify!(selection)
    end
    def verify!(selection)
      raise ERROR, "controlled endpoint replaced" unless Ace::Runtime::Molecules::ProtectedSocket.socket_identity(selection.first) == selection.last
      true
    end
  end

  def with_source_observation_seams(&block)
    runtime_class = Ace::Herdr::Molecules::CodexRuntimeSelection
    runtime_with = @actual_runtime_factory = runtime_class.method(:with)
    runtime_artifacts = @runtime_artifacts = RuntimeArtifacts.new(@artifact_factory, @stage.fetch("codex_runtime").fetch("path"), @runtime_path)
    runtime_class.stub(:with, ->(**args, &callback) { runtime_with.call(**args, artifacts: runtime_artifacts, protection: RuntimeEndpoint.new, &callback) }) do
    configuration = Ace::Herdr::Molecules::InboxContextServiceConfiguration
    key_class = Ace::Herdr::Molecules::InboxContextKey
    store_class = Ace::Herdr::Molecules::InboxContextStore
    process_class = Ace::Herdr::Molecules::InboxContextNativeProcess
    listener_class = Ace::Herdr::Organisms::InboxContextListener
    load, key_new, store_new, process_new, listener_new = configuration.method(:load), key_class.method(:new), store_class.method(:new), process_class.method(:new), listener_class.method(:new)
    configuration.stub(:load, ->(**args) { load.call(**args, artifacts: @artifact_factory.call) }) do
      key_class.stub(:new, ->(**args) { key_new.call(**args, artifacts: @artifact_factory.call) }) do
        store_class.stub(:new, ->(**args) { store_new.call(**args, protection: Paths.new) }) do
          process_class.stub(:new, ->(**args) { process_new.call(**args, artifacts_factory: @artifact_factory) }) do
            listener_class.stub(:new, ->(**args) { server = args.fetch(:server)
              original_handle = server.method(:handle)
              before_handler = @before_handler
              server.define_singleton_method(:handle) do |connection|
                before_handler&.call
                original_handle.call(connection)
              end
              @listener = listener_new.call(**args, protection: Paths.new) }) do
              Lifetime::KernelFiles.stub(:new, @boot_files, &block)
            end
          end
        end
      end
    end
  end

    end

  def launch(method)
    @failure = nil
    @thread = Thread.new { Service.public_send(method, stage: @stage, installation: @document, bootstrap: @bootstrap) rescue @failure = $! }
    Timeout.timeout(2) do
      loop do
        raise @failure if @failure
        break if File.socket?(@socket_path) && (File.stat(@socket_path).mode & 0o777) == 0o660
        Thread.pass
      end
    end
  end

  def finish
    @listener&.stop
    assert @thread.join(2)
    assert_nil @failure
  end

  def test_root_protected_output_schema_and_original_peer_are_rechecked_before_native_bytes
    original = JSON.parse(File.read(@runtime_path))
    changes = [->(doc) { doc["extra"] = true }, ->(doc) { doc["project_id"] = "other" },
      ->(doc) { doc["server_process_binding"]["pid"] = 16000.0 },
      ->(doc) { doc["server_process_binding"]["uid"] = 0 },
      ->(doc) { doc["server_process_binding"]["uid"] = @configuration.data.fetch("owner_credentials").fetch("uid") },
      ->(doc) { doc["thread_id"] = "named-thread" }, ->(doc) { doc["runtime_generation"] = 0 },
      ->(doc) { doc["previous_runtime_reference"] = @stage.fetch("codex_runtime") }]
    with_source_observation_seams do
      changes.each do |change|
        document = Marshal.load(Marshal.dump(original))
        change.call(document)
        bytes = JSON.generate(document)
        File.write(@runtime_path, bytes)
        sha = Digest::SHA256.hexdigest(bytes)
        stage = @stage.merge("codex_runtime" => {"path" => "/var/lib/lab/herdr-native-artifacts/codex/project/ctx/map/generations/#{document.fetch('runtime_generation')}/#{sha}.json",
          "bytes" => bytes.bytesize, "sha256" => sha})
        selected = Ace::Herdr::Molecules::InboxContextServiceConfiguration.load(stage: stage)
        held = RuntimeArtifacts.new(@artifact_factory, stage.fetch("codex_runtime").fetch("path"), @runtime_path)
        # Call the actual factory directly through its original method to select
        # this independently held output, not the outer fixture's original REF.
        actual = @actual_runtime_factory
        assert_raises(ERROR) { actual.call(stage_reference: selected.codex_runtime_reference,
          configuration: selected, installation: @document, bootstrap: @bootstrap, artifacts: held,
          protection: RuntimeEndpoint.new) { flunk "invalid runtime admitted" } }
      end
      File.write(@runtime_path, JSON.generate(original))
      original_peer = @kernel.method(:peer)
      @kernel.define_singleton_method(:peer) { |socket| original_peer.call(socket).merge("pid" => 16001) }
      assert_raises(ERROR) { Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: @stage.fetch("codex_runtime"),
        configuration: @configuration, installation: @document, bootstrap: @bootstrap) { flunk "replacement peer admitted" } }
      assert_nil @native_adds
    end
  end

  def test_actual_inbox_persists_correlation_before_native_add_and_never_replays_lost_reply
    with_source_observation_seams do
      Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: @stage.fetch("codex_runtime"),
        configuration: @configuration, installation: @document, bootstrap: @bootstrap) do |runtime|
        native = Ace::Herdr::Molecules::NativeQueueExecutor.new(codex_runtime: runtime)
        inbox = Ace::Herdr::Organisms::Inbox.new(executor: InboxContextOwnerFixture::PaneFixture.new,
          native: native, deliveries_dir: @events, receipt_public_key: InboxContextOwnerFixture::KEY.public_key)
        dispatcher = runtime.handler_dispatcher(limit: 8)
        inbox.enqueue(event: "success", attempt: "attempt1", ref: {"session" => "ws1", "pane" => "p1"}, payload: "same text")
        positive = Thread.new do
          dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2) { inbox.deliver(event: "success") }
        end
        assert positive.join(3)
        delivered = positive.value
        assert_equal "delivered", delivered.fetch("state")
        assert_equal "none", delivered.fetch("wake").fetch("status")
        accepted = Ace::Herdr::Molecules::DeliveryRecordStore.load(@events, "success").inbox.fetch("receipt").fetch("codex_submission")
        assert_equal "00000000-0000-0000-0000-000000000002", accepted.fetch("queued_submission_id")
        assert_equal @stage.fetch("codex_runtime").fetch("sha256"), accepted.fetch("endpoint_reference_sha256")
        inbox.enqueue(event: "event1", attempt: "attempt1", ref: {"session" => "ws1", "pane" => "p1"}, payload: "same text")
        observed = Queue.new
        @before_native_add = lambda do |message|
          record = Ace::Herdr::Molecules::DeliveryRecordStore.load(@events, "event1")
          observed << [record.inbox.fetch("submission_intent"), record.inbox.fetch("codex_submission"), message]
        end
        @native_reply_lost = true
        dispatcher = runtime.handler_dispatcher(limit: 8)
        worker = Thread.new do
          dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2) { inbox.deliver(event: "event1") }
        end
        assert worker.join(3)
        first = worker.value
        assert_equal "uncertain", first.fetch("state")
        intent, correlation, message = Timeout.timeout(2) { observed.pop }
        assert intent
        assert_equal correlation.fetch("client_user_message_id"), message.fetch("params").fetch("clientUserMessageId")
        assert_equal Digest::SHA256.hexdigest("same text"), correlation.fetch("payload_sha256")
        assert_equal @stage.fetch("codex_runtime").fetch("sha256"), correlation.fetch("endpoint_reference_sha256")
        assert_equal 2, @native_adds.size
        refute_equal accepted.fetch("client_user_message_id"), correlation.fetch("client_user_message_id"), "identical text in different events retains distinct native IDs"
        restarted = Ace::Herdr::Organisms::Inbox.new(executor: InboxContextOwnerFixture::PaneFixture.new,
          native: native, deliveries_dir: @events, receipt_public_key: InboxContextOwnerFixture::KEY.public_key)
        assert_equal "uncertain", restarted.deliver(event: "event1").fetch("state")
        assert_equal 2, @native_adds.size, "uncertain restart must not repeat native queue add"
      end
    end
  end

  def test_typed_original_runtime_reads_exact_intent_without_resend_and_refuses_changed_binding
    with_source_observation_seams do
      assert_raises(ERROR) do # The mutated held artifact also refuses scope exit.
        Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: @stage.fetch("codex_runtime"),
          configuration: @configuration, installation: @document, bootstrap: @bootstrap) do |runtime|
          native = Ace::Herdr::Molecules::NativeQueueExecutor.new(codex_runtime: runtime)
          thread = runtime.data.fetch("thread_id")
          digest = Digest::SHA256.hexdigest("same text")
          intent = native.prepare_submission(agent: "codex", thread: thread, event_id: "event1",
            attempt_id: "attempt1", claim_generation: 1, digest: digest)
          @native_read_result = {"thread" => {"id" => thread, "cliVersion" => "0.159.3", "turns" => [
            {"id" => "00000000-0000-0000-0000-000000000003", "status" => "completed", "items" => [
              {"id" => "item-1", "type" => "userMessage", "clientId" => intent.fetch("client_user_message_id"),
                "content" => [{"type" => "text", "text" => "same text"}]}]}]}}
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
          args = {agent: "codex", thread: thread, event_id: "event1", digest: digest, submission: intent, deadline: deadline}
          observed = native.observe(**args)
          assert_equal "consumed", observed.fetch("outcome")
          assert_nil observed.fetch("native_reference").fetch("queued_submission_id"), "lost add reply is not invented"
          assert_equal @stage.fetch("codex_runtime").fetch("sha256"), observed.fetch("endpoint_reference_sha256")
          assert_equal runtime.data.fetch("server_process_binding"), observed.fetch("server_process_binding")
          assert_empty @native_adds || [], "observation never resubmits even without a retained add reply"
          assert_equal({"threadId" => thread, "includeTurns" => true}, @native_reads.last.fetch("params"))
          assert_equal "uncertain", native.observe(**args.merge(event_id: "foreign")).fetch("outcome")
          assert_equal 1, @native_reads.size
          assert_equal "uncertain", native.observe(**args.merge(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1)).fetch("outcome")
          assert_equal 1, @native_reads.size
          receipt = intent.slice("provider_version", "endpoint_reference_sha256", "thread_id",
            "client_user_message_id", "payload_sha256", "server_process_binding").merge(
            "queued_submission_id" => "00000000-0000-0000-0000-000000000004")
          assert_equal "uncertain", native.observe(**args.merge(receipt: receipt.merge("client_user_message_id" => "ace-#{"f" * 32}"))).fetch("outcome")
          assert_equal 1, @native_reads.size
          assert_equal receipt.fetch("queued_submission_id"), native.observe(**args.merge(receipt: receipt)).fetch("native_reference").fetch("queued_submission_id")
          transport = Ace::Herdr::Molecules::CodexAppServerTransport.new
          original_observe = transport.method(:observe)
          observed_deadline = nil
          transport.define_singleton_method(:observe) do |**parameters|
            observed_deadline = parameters.fetch(:deadline)
            original_observe.call(**parameters)
          end
          handler_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 1
          dispatcher = runtime.handler_dispatcher(limit: 8)
          Ace::Herdr::Molecules::CodexAppServerTransport.stub(:new, transport) do
            worker = Thread.new do
              dispatcher.call(deadline: handler_deadline) { native.observe(**args) }
            end
            assert worker.join(2), "owned observation did not finish within original budget"
            assert_equal "consumed", worker.value.fetch("outcome")
          end
          assert_equal handler_deadline, observed_deadline, "held handler original deadline caps the native read"
          @before_native_read = ->(*) { File.open(@runtime_path, "a") { |file| file.write(" ") } }
          assert_equal "uncertain", native.observe(**args).fetch("outcome"), "changed held binding discards positive history"
          assert_empty @native_adds || []
        end
      end
    end
  end

  def test_stop_timeout_retains_runtime_artifacts_until_actual_listener_handler_exits
    admitted, release = Queue.new, Queue.new
    @before_handler = -> { admitted << true; release.pop }
    connection = nil
    with_source_observation_seams do
      launch(:provision!)
      connection = UNIXSocket.new(@socket_path)
      wire = Ace::Herdr::Molecules::InboxContextWire
      wire.write(connection, {"version" => 1, "context_id" => "ctx", "operation" => "status", "params" => {}}, deadline: wire.deadline)
      connection.shutdown(Socket::SHUT_WR)
      Timeout.timeout(2) { admitted.pop }
      assert_raises(ERROR) { @listener.stop(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC)) }
      assert_equal 1, @runtime_artifacts.open_scopes
      assert_equal 0, @runtime_artifacts.close_count
      refute @thread.join(0), "service returned before its admitted handler exited"
      release << true
      reply = wire.read(connection, deadline: wire.deadline)
      assert_equal "open", reply.fetch("result").fetch("state")
      assert @thread.join(2)
      assert_instance_of ERROR, @failure, "stop timeout must remain failure after joined cleanup"
      assert_equal 0, @runtime_artifacts.open_scopes
      assert_equal 1, @runtime_artifacts.close_count
    end
  ensure
    release << true
    connection&.close
    @thread&.join(2)
  end

  def test_original_runtime_refuses_unadmitted_cross_thread_and_escaped_scope
    escaped = nil
    with_source_observation_seams do
      Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: @stage.fetch("codex_runtime"),
        configuration: @configuration, installation: @document, bootstrap: @bootstrap) do |runtime|
        escaped = runtime
        dispatcher = runtime.handler_dispatcher(limit: 8)
        worker = Thread.new do
          assert_raises(ERROR) { runtime.verify! }
          true
        end
        assert worker.join(2), "owned controlled handler did not finish within original scope"
        assert worker.value
        admitted = Thread.new do
          dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2) { runtime.verify! }
        end
        assert admitted.join(2)
        assert admitted.value
        assert runtime.verify!
      end
    end
    assert_raises(ERROR) { escaped.verify! }
  end

  def test_handler_bound_exception_unwind_and_original_deadline_refuse
    workers = []
    release, entered = Queue.new, Queue.new
    with_source_observation_seams do
      Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: @stage.fetch("codex_runtime"),
        configuration: @configuration, installation: @document, bootstrap: @bootstrap) do |runtime|
        dispatcher = runtime.handler_dispatcher(limit: 8)
        workers = 8.times.map do
          Thread.new do
            dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3) do
              assert runtime.verify!
              entered << true
              release.pop
            end
          end
        end
        Timeout.timeout(2) { 8.times { entered.pop } }
        refused = Thread.new do
          assert_raises(ERROR) { dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2) { flunk } }
        end
        assert refused.join(2)
        refused.value
        8.times { release << true }
        workers.each { |worker| assert worker.join(2); worker.value }
        assert_raises(ERROR) { dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) - 1) { flunk } }
        exception = RuntimeError.new("controlled handler failure")
        exceptional = Thread.new do
          assert_same exception, assert_raises(RuntimeError) { dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2) { raise exception } }
        end
        assert exceptional.join(2)
        exceptional.value
        again = Thread.new { dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2) { runtime.verify! } }
        assert again.join(2)
        assert again.value
      end
    end
  ensure
    8.times { release << true }
    workers.each { |worker| worker.join(2) }
  end

  def test_scope_close_joins_admitted_handler_and_blocks_late_dispatch
    dispatcher_queue, admitted_queue, release_queue = Queue.new, Queue.new, Queue.new
    escaped = nil
    scope = worker = nil
    with_source_observation_seams do
      scope = Thread.new do
        Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: @stage.fetch("codex_runtime"),
          configuration: @configuration, installation: @document, bootstrap: @bootstrap) do |runtime|
          escaped = runtime
          dispatcher = runtime.handler_dispatcher(limit: 8)
          dispatcher_queue << dispatcher
          admitted_queue.pop
        end
      end
      dispatcher = Timeout.timeout(2) { dispatcher_queue.pop }
      worker = Thread.new do
        dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2) do
          admitted_queue << true
          release_queue.pop
          assert escaped.verify!, "held evidence closed before handler exit"
        end
      end
      # Callback has returned, but close must remain joined to this handler.
      Timeout.timeout(2) { Thread.pass until scope.status == "sleep" }
      refute scope.join(0)
      release_queue << true
      assert worker.join(2)
      worker.value
      assert scope.join(2)
      scope.value
      assert_raises(ERROR) { dispatcher.call(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2) { flunk } }
      assert_raises(ERROR) { escaped.verify! }
    end
  ensure
    release_queue << true if worker&.alive?
    worker&.join(2)
    scope&.join(2)
  end

  def test_actual_constructor_publishes_v3_before_ingress_and_normal_same_epoch_restart_is_read_only
    with_source_observation_seams do
      @bootstrap.after_prepare = ->(prepared) { assert_equal "active", JSON.parse(File.read(File.join(@state, ".context-control.json"))).fetch("owner_epoch_state"); assert prepared.epoch.frozen? }
      launch(:provision!)
      assert_equal 1, @bootstrap.initial_calls
      assert_equal 0, @bootstrap.normal_calls
      UNIXSocket.open(@socket_path) do |socket|
        wire = Ace::Herdr::Molecules::InboxContextWire
        deadline = wire.deadline
        wire.write(socket, {"version" => 1, "context_id" => "ctx", "operation" => "status", "params" => {}}, deadline: deadline)
        socket.shutdown(Socket::SHUT_WR)
        reply = wire.read(socket, deadline: deadline)
        assert_equal "open", reply.fetch("result").fetch("state")
        assert_equal 0, reply.fetch("result").fetch("active_operations")
      end
      before = File.binread(File.join(@state, ".context-control.json"))
      finish
      launch(:start!)
      assert_equal 1, @bootstrap.normal_calls
      assert_equal before, File.binread(File.join(@state, ".context-control.json"))
      finish
    end
  end

  def test_publication_ack_loss_replays_only_same_epoch_and_missing_normal_state_never_initializes
    with_source_observation_seams do
      @bootstrap.after_prepare = ->(_prepared) { raise ERROR, "controlled lost initialization acknowledgement" }
      assert_raises(ERROR) { Service.provision!(stage: @stage, installation: @document, bootstrap: @bootstrap) }
      refute File.exist?(@socket_path)
      before = File.binread(File.join(@state, ".context-control.json"))
      @bootstrap.after_prepare = nil
      launch(:provision!)
      assert_equal before, File.binread(File.join(@state, ".context-control.json"))
      finish
      @profiles.fetch("ace-slot.service")["InvocationID"] = [3] * 16
      assert_raises(ERROR) { Service.provision!(stage: @stage, installation: @document, bootstrap: @bootstrap) }
      assert_equal before, File.binread(File.join(@state, ".context-control.json"))
      refute File.exist?(@socket_path)
      File.unlink(File.join(@state, ".context-control.json"))
      assert_raises(ERROR) { Service.start!(stage: @stage, installation: @document, bootstrap: @bootstrap) }
      refute File.exist?(File.join(@state, ".context-control.json"))
    end
  end
  def test_dedicated_unit_is_verified_inside_original_runtime_scope
    with_source_observation_seams do
      Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: @stage.fetch("codex_runtime"),
        configuration: @configuration, installation: @document, bootstrap: @bootstrap) do |runtime|
        profile = @codex_harness.instance_variable_get(:@profiles).fetch("codex.service")
        original = profile.fetch("ExecStartEx").first[1].dup
        profile.fetch("ExecStartEx").first[1] << "--foreign"
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { runtime.verify! }
        assert_nil @native_adds
        profile.fetch("ExecStartEx").first[1].replace(original)
        assert runtime.verify!
      end
    end
  end

  def test_nested_static_factory_cannot_substitute_context_unit_or_foreign_manager
    original = @codex_association
    [{installation: @installation, manager: @manager}.freeze,
     {installation: original.fetch(:installation), manager: @manager}.freeze].each do |foreign|
      @bootstrap.instance_variable_set(:@native, foreign)
      with_source_observation_seams do
        assert_raises(ERROR) do
          Ace::Herdr::Molecules::CodexRuntimeSelection.with(stage_reference: @stage.fetch("codex_runtime"),
            configuration: @configuration, installation: @document, bootstrap: @bootstrap) { flunk "foreign dedicated factory accepted" }
        end
      end
      assert_nil @native_adds
    end
  ensure
    @bootstrap.instance_variable_set(:@native, original)
  end

end

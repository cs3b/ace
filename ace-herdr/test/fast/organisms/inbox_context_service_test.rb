# frozen_string_literal: true

require "test_helper"
require "ace/herdr/organisms/inbox_context_service"
require_relative "../../support/inbox_context_service_runtime_fixture"

class InboxContextServiceTest < Minitest::Test
  include InboxContextServiceRuntimeFixture
  alias_method :setup_runtime, :setup
  Service = Ace::Herdr::Organisms::InboxContextService
  ERROR = Ace::Herdr::ValidationError

  # Actual constructor/Store/listener composition with controlled full-owner,
  # kernel, cgroup and installed-file observations. No whole Inbox is injected.
  # The real Lab entry/initialization publication remains a separate source join.
  class Bootstrap
    attr_reader :initial_calls, :normal_calls, :prepared
    attr_accessor :after_prepare
    def initialize(association)
      @association, @initial_calls, @normal_calls = association, 0, 0
    end
    def with_initial_inbox_context(configuration:, installation:)
      @initial_calls += 1
      select(configuration, installation) { |selection| yield selection }
    end
    def with_inbox_context_service(configuration:, installation:)
      @normal_calls += 1
      select(configuration, installation) { |selection| yield selection }
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
    cwd = File.join(@root, "native")
    Dir.mkdir(cwd, 0o700)
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
    config_ref = @configuration.reference
    bytes = JSON.generate(data)
    File.write(config_ref.fetch("path"), bytes)
    @files.bytes[config_ref.fetch("path")] = bytes
    config_ref = {"path" => config_ref.fetch("path"), "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
    @artifacts.find { |artifact| artifact["role"] == "context_configuration" }["sha256"] = config_ref.fetch("sha256")
    @stage = {"schema" => "ace.herdr.inbox-context-stage/v1", "project_id" => "project", "inbox_context_id" => "ctx", "configuration" => config_ref}
    @artifact_factory = -> { Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: InboxContextOwnerFixture::FixtureArtifacts.new(@root)) }
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
    @kernel.define_singleton_method(:peer) do |_socket|
      {"uid" => 13000, "gid" => 13000, "groups" => [Process.gid], "pid" => 13000, "parent_pid" => 1,
        "host" => "controlled", "started_at" => "linux:#{InboxContextServiceRuntimeFixture::BOOT}:43"}
    end
    @bootstrap = Bootstrap.new({configuration: @configuration, installation: @installation, manager: @manager, kernel: @kernel, cgroups: @cgroups}.freeze)
    @document = {"path" => "/selected/installation", "bytes" => 1, "sha256" => "a" * 64}
  end

  def with_source_observation_seams(&block)
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
            listener_class.stub(:new, ->(**args) { @listener = listener_new.call(**args, protection: Paths.new) }) do
              Lifetime::KernelFiles.stub(:new, @boot_files, &block)
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
end

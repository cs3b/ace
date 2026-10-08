# frozen_string_literal: true

require "test_helper"
require "rbconfig"
require "ace/herdr/molecules/inbox_context_native_process"
require "ace/herdr/molecules/native_queue_executor"
require "ace/herdr/molecules/herdr_executor"
require_relative "../../support/inbox_context_owner_fixture"

class InboxContextNativeProcessTest < Minitest::Test
  ProcessOwner = Ace::Herdr::Molecules::InboxContextNativeProcess
  Configuration = Ace::Herdr::Molecules::InboxContextServiceConfiguration
  ERROR = Ace::Herdr::ValidationError

  # Only the kernel descriptor namespace differs in this controlled local
  # fixture. It launches the actual selected inode through BoundedProcess;
  # native Codex/Pi backend semantics and Linux installation are excluded.
  class DescriptorNamespace
    def self.call(argv, **options)
      raise "unfixed descriptor executable" unless argv.first == "/proc/self/fd/5"
      Ace::Herdr::Molecules::BoundedProcess.call([RbConfig.ruby, "/dev/fd/5", *argv.drop(1)], **options)
    end
  end

  def setup
    @root = File.realpath(Dir.mktmpdir("ic-native", "/tmp"))
    bytes = "#!#{RbConfig.ruby}\n" + <<~'RUBY'
      require "json"
      if ARGV.first == "--delivery"
        payload = STDIN.read
        puts JSON.generate(ok: true, id: ARGV[1], session_id: ARGV[3], payload_sha256: ARGV[5])
      elsif ARGV.first == "--identity"
        puts JSON.generate(session_id: "original-session")
      else
        puts JSON.generate(argv: ARGV, inherited: ENV["ACE_UNSELECTED_SECRET"], fixed: ENV["LANG"])
      end
    RUBY
    refs = %w[codex pi herdr].to_h do |role|
      path = File.join(@root, role)
      File.write(path, bytes)
      File.chmod(0o700, path)
      [role, {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}]
    end
    @clients = refs.merge("dependencies" => [], "environment" => {"LANG" => "selected"}, "cwd" => @root,
      "resources" => [{"path" => @root, "kind" => "directory", "access" => "read", "uid" => Process.uid, "gid" => File.stat(@root).gid, "mode" => 0o700}])
    data = {"schema" => "ace.herdr.inbox-context-service/v1", "project_id" => "project", "inbox_context_id" => "ctx",
      "native_mapping_id" => "mapping", "native_clients" => @clients, "control_socket_path" => "/run/ctx/control.sock",
      "state_root" => "/var/lib/ctx/state", "deliveries_dir" => "/var/lib/ctx/events", "socket_gid" => 300,
      "owner_credentials" => {"uid" => Process.uid, "gid" => Process.gid, "groups" => [300]},
      "key" => {"public_key_path" => "/etc/ctx/public.pem", "configuration_path" => "/etc/ctx/key.json"},
      "authority" => {"uid" => 100, "gid" => 100, "groups" => [], "socket_path" => "/run/authority/control.sock"},
      "grants" => [{"uid" => 100, "gid" => 100, "groups" => [300], "role" => "authority", "purposes" => %w[deliver enqueue]}]}
    config_bytes = JSON.generate(data)
    config_path = File.join(@root, "config.json")
    File.write(config_path, config_bytes)
    File.chmod(0o600, config_path)
    @artifacts = -> { Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: InboxContextOwnerFixture::FixtureArtifacts.new(@root)) }
    selected = Configuration.load(stage: {"schema" => "ace.herdr.inbox-context-stage/v1", "project_id" => "project", "inbox_context_id" => "ctx",
      "configuration" => {"path" => config_path, "bytes" => config_bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(config_bytes)}}, artifacts: @artifacts.call)
    @process = ProcessOwner.new(configuration: selected, artifacts_factory: @artifacts, process: DescriptorNamespace)
  end

  def teardown = FileUtils.remove_entry(@root)

  def test_actual_selected_child_constructs_queue_and_wake_with_fixed_environment
    ENV["ACE_UNSELECTED_SECRET"] = "must-not-be-inherited"
    native = Ace::Herdr::Molecules::NativeQueueExecutor.new(pi_client: @clients.fetch("pi").fetch("path"), process: @process)
    result = native.submit(agent: "pi", thread: "original-session", event_id: "inb-controlled", digest: "a" * 64, payload: "payload")
    assert_equal true, result.fetch("accepted"), result.inspect
    assert_equal "original-session", native.pi_identity
    executor = Ace::Herdr::Molecules::HerdrExecutor.new(binary: @clients.fetch("herdr").fetch("path"), process: @process)
    wake = executor.agent_prompt_bounded(pane: "original-pane", text: "Check your native queued messages.", timeout_ms: 1000)
    assert_equal ["agent", "prompt", "original-pane", "Check your native queued messages."], wake.parsed_json.fetch("argv")
    assert_nil wake.parsed_json.fetch("inherited")
    assert_equal "selected", wake.parsed_json.fetch("fixed")
  ensure
    ENV.delete("ACE_UNSELECTED_SECRET")
  end

  def test_unselected_or_replaced_executable_refuses_before_spawn
    assert_raises(ERROR) { @process.call(["herdr", "pane", "get", "pane"], stdin_data: "", timeout_s: 1) }
    File.write(@clients.fetch("pi").fetch("path"), "replaced bytes")
    assert_raises(ERROR) { @process.call([@clients.fetch("codex").fetch("path"), "queue"], stdin_data: "", timeout_s: 1) }
  end

  def test_startup_requires_actual_executable_mode_and_exact_private_ipc_placement
    assert @process.verify!
    File.chmod(0o600, @clients.fetch("pi").fetch("path"))
    assert_raises(ERROR) { @process.verify! }
    File.chmod(0o700, @clients.fetch("pi").fetch("path"))
    File.chmod(0o750, @root)
    assert_raises(ERROR) { @process.verify! }
  end
end

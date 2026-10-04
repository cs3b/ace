# frozen_string_literal: true

require "test_helper"
require "ace/hitl/hermes/cli"
require "open3"
require "timeout"
require "rubygems/package"
require "rbconfig"
require "set"

class TransportCliTest < AceHermesTestCase
  L = Ace::Hitl::Lifecycle
  T = Ace::Hitl::Hermes::Transport

  class Binding < L::Binding
    def validate_request(**); end
    def require_active(**); end
  end

  class Policy
    def transport?(peer, project: nil)
      peer.uid == Process.uid && (project.nil? || project == "ace")
    end
    def service_uid; end
  end

  def setup
    super
    @tmp = Dir.mktmpdir("hermes-cli", "/tmp")
    @folder = File.join(@tmp, "inbox")
    FileUtils.mkdir_p(@folder, mode: 0o750)
    @socket = File.join(@tmp, "hitl.sock")
    @service = L::Service.new(root: File.join(@tmp, "store"), binding: Binding.new, policy: Policy.new,
      socket_path: @socket, group: Etc.getgrgid(Process.gid).name)
    @thread = Thread.new { @service.run }
    Timeout.timeout(5) { sleep 0.01 until File.socket?(@socket) || !@thread.alive? }
    @thread.value unless @thread.alive?
    @client = L::Client.new(socket_path: @socket, service_uid: Process.uid)
    @registry_path = File.join(@tmp, "channels.json")
    @config_path = File.join(@tmp, "runtime.json")
    registry = {"schema" => "ace.hitl.hermes.channels/v1", "channels" => [
      {"name" => "inbox", "machine" => "local", "folder" => @folder, "target" => "overseer", "projects" => ["ace"],
       "chat_id" => "-424242", "captain_user_ids" => ["42"]}
    ]}
    @gateway_path = File.join(@tmp, "hermes.yaml")
    File.write(@gateway_path, "platforms:\n  telegram:\n    enabled: false\n")
    @config = {"schema" => "ace.hitl.hermes.runtime/v1", "registry" => @registry_path,
               "state" => File.join(@tmp, "state"), "hitl_socket" => @socket, "hitl_service_uid" => Process.uid,
               "hermes_gateway_config" => @gateway_path, "polling_owner" => "ace-hitl-hermes"}
    File.write(@registry_path, JSON.generate(registry))
    File.write(@config_path, JSON.generate(@config))
    @registry = T::Registry.load(@registry_path)
    @journal = T::Journal.new(@config["state"])
    @relay = T::Relay.new(registry: @registry, journal: @journal, lifecycle: @client,
      sender: ->(channel, _) { {"success" => true, "chat_id" => channel["chat_id"], "message_id" => "100"} })
  end

  def teardown
    @service&.stop
    @thread&.join(5)
    @thread&.kill
    FileUtils.remove_entry(@tmp)
    super
  end

  def create(id: "hitl001", secret: false)
    args = {"id" => id, "assignment" => "8x3test", "attempt" => "a1b2c3", "kind" => secret ? "otp" : "text",
            "project" => "ace", "harness" => "agy", "plan" => "test", "question" => "Proceed?",
            "ace_hitl_id" => "ace-hitl-1"}
    args["otp"] = {"operation" => "gem-push", "result_ref" => "test-result", "input_digest" => "b" * 64,
                    "expires_at" => Time.now.to_i + 600} if secret
    @client.create(**args)
    ch = Ace::Hitl::Hermes::Molecules::HermesChannels::Channel.new(name: "inbox", machine: "local", folder: @folder)
    Ace::Hitl::Hermes::Organisms::HermesBox.new(channel: ch).publish(kind: :question, id: id,
      body: "Proceed?", sender: "agent", timestamp: Time.now.utc.iso8601)
    @relay.submit(channel: "inbox", request: id, revision: "rev1")
  end

  def event(text)
    {"platform" => "telegram", "chat_id" => "-424242", "chat_type" => "supergroup", "user_id" => "42",
     "message_id" => "101", "reply_to_message_id" => "100", "text" => text}
  end

  def cli(*arguments, stdin: "")
    output = StringIO.new
    Ace::Hitl::Hermes::CLI.start([*arguments, "--config", @config_path], input: StringIO.new(stdin), output: output)
    JSON.parse(output.string)
  end

  def test_cli_ordinary_reply_round_trips_real_authenticated_boundary_and_folder
    create
    result = cli("receive", stdin: JSON.generate(event("approved")))
    assert_equal "delivered", result["status"]
    answer = JSON.parse(File.read(File.join(@folder, "hitl001.json")))
    assert_equal "approved", answer["answer"]
    assert_equal "approved", @client.consume("hitl001", timeout: 1)["answer"]
    late = event("late").merge("message_id" => "102")
    assert_equal "closed", cli("receive", stdin: JSON.generate(late))["status"]
    assert_equal "submitted", cli("delivery", "--request", "hitl001")["status"]
  end

  def test_cli_otp_crosses_real_ipc_without_disk_or_projection_value
    create(secret: true)
    surrogate = "918273"
    result = cli("receive", stdin: JSON.generate(event(surrogate)))
    assert_equal "delivered", result["status"]
    assert_empty Dir.children(@folder)
    assert_equal surrogate, @client.consume("hitl001", timeout: 1, operation: "gem-push")["answer"]
    public = cli("ingress", "reconcile", "--request", "hitl001", "--through", Time.now.utc.iso8601)
    refute_includes JSON.generate(public), surrogate
    Dir.glob(File.join(@tmp, "**", "*"), File::FNM_DOTMATCH).select { |p| File.file?(p) }.each do |path|
      refute_includes File.binread(path), surrogate, path
    end
  end

  def test_startup_refuses_competing_gateway_and_requires_explicit_polling_owner
    runtime = Ace::Hitl::Hermes::Runtime.new(@config_path)
    runtime.verify_polling_owner!
    File.write(@gateway_path, "platforms:\n  telegram:\n    enabled: true\n")
    assert_raises(Ace::Hitl::Hermes::ContractError) { runtime.verify_polling_owner! }
    File.write(@gateway_path, "platforms:\n  telegram:\n    enabled: false\n")
    runtime.config["polling_owner"] = "hermes"
    assert_raises(Ace::Hitl::Hermes::ContractError) { runtime.verify_polling_owner! }
  end

  def test_serve_establishes_coverage_before_startup_submission
    @client.create(id: "startup1", assignment: "8x3test", attempt: "a1b2c3", kind: "text",
      project: "ace", harness: "agy", plan: "test", question: "Proceed?", ace_hitl_id: "ace-hitl-1")
    ch = Ace::Hitl::Hermes::Molecules::HermesChannels::Channel.new(name: "inbox", machine: "local", folder: @folder)
    Ace::Hitl::Hermes::Organisms::HermesBox.new(channel: ch).publish(kind: :question, id: "startup1",
      body: "Proceed?", sender: "agent", timestamp: Time.now.utc.iso8601)
    calls = []
    transport = Object.new
    transport.define_singleton_method(:updates) { |offset:| calls << :poll; [] }
    transport.define_singleton_method(:call) do |channel, question|
      calls << :send
      {"success" => true, "chat_id" => channel["chat_id"], "message_id" => "100"}
    end
    runtime = Ace::Hitl::Hermes::Runtime.new(@config_path)
    runtime.define_singleton_method(:telegram) { transport }
    runtime.serve(once: true)
    assert_equal [:poll, :send, :poll], calls
    submitted_at = runtime.relay.delivery("startup1")["submitted_at"]
    assert runtime.relay.reconcile(request: "startup1", through: submitted_at)["healthy"]
  end

  def test_unknown_request_checkpoint_and_malformed_ingress_errors_are_sanitized
    checkpoint = cli("ingress", "reconcile", "--request", "absent1", "--through", Time.now.utc.iso8601)
    refute checkpoint["healthy"]
    refute checkpoint["drained"]
    error = assert_raises(Ace::Support::Cli::Error) { cli("receive", stdin: "{secret918273") }
    refute_includes error.message, "918273"
  end

  def test_built_gem_installed_executable_delivers_otp_through_real_boundary
    create(secret: true)
    package = File.expand_path("../../..", __dir__)
    spec = Gem::Specification.load(File.join(package, "ace-hitl-hermes.gemspec"))
    pool = File.join(@tmp, "packages")
    FileUtils.mkdir_p(pool)
    closure = {}
    collect = lambda do |dependency|
      return if closure.key?(dependency.name)
      resolved = Gem::Specification.find_by_name(dependency.name, dependency.requirement)
      closure[dependency.name] = resolved
      resolved.runtime_dependencies.each { |child| collect.call(child) }
    end
    spec.runtime_dependencies.each { |dep| collect.call(dep) }
    closure[spec.name] = spec
    closure.each_value do |dependency|
      source_directory = File.join(File.dirname(package), dependency.name)
      source = File.join(source_directory, "#{dependency.name}.gemspec")
      if File.file?(source)
        capture_io do
          Dir.chdir(source_directory) do
            fresh = Gem::Specification.load(source)
            Gem::Package.build(fresh, false, false, File.join(pool, "#{fresh.full_name}.gem"))
          end
        end
      else
        assert File.file?(dependency.cache_file), "missing local dependency archive #{dependency.full_name}"
        FileUtils.cp(dependency.cache_file, pool)
      end
    end
    archive = File.join(pool, "#{spec.full_name}.gem")
    home = File.join(@tmp, "installed-home")
    env = {"GEM_HOME" => home, "GEM_PATH" => home,
           "BUNDLE_GEMFILE" => nil, "BUNDLE_BIN_PATH" => nil, "RUBYOPT" => nil, "RUBYLIB" => nil}
    out, status = Open3.capture2e(env, RbConfig.ruby, "-S", "gem", "install", "--local", "--no-document",
      "--install-dir", home, archive, chdir: pool)
    assert status.success?, out
    executable = File.join(home, "bin", "ace-hitl-hermes")
    out, status = Open3.capture2e(env, executable, "receive", "--config", @config_path,
      stdin_data: JSON.generate(event("918273")), chdir: @tmp)
    assert status.success?, out
    assert_equal "delivered", JSON.parse(out)["status"]
    refute_includes out, "918273"
    assert_empty Dir.children(@folder)
    assert_equal "918273", @client.consume("hitl001", timeout: 1, operation: "gem-push")["answer"]
    plugin = File.join(@tmp, "installed-guard")
    out, status = Open3.capture2e(env, executable, "plugin", "install", "--path", plugin, chdir: @tmp)
    assert status.success?, out
    assert File.file?(File.join(plugin, "__init__.py"))
    retention = File.join(File.dirname(package), ".ace-local", "test", "artifacts", "hitl-hermes",
      "installed-#{Time.now.utc.strftime('%Y%m%d%H%M%S')}-#{SecureRandom.hex(4)}")
    FileUtils.mkdir_p(retention)
    FileUtils.cp_r(pool, File.join(retention, "packages"))
    FileUtils.cp_r(home, File.join(retention, "installed-home"))
    File.write(File.join(retention, "proof.json"), JSON.pretty_generate({
      "schema" => "ace.hitl.hermes.local-installed-proof/v1", "package" => spec.full_name,
      "dependencies" => closure.values.map(&:full_name).sort,
      "registered_channel" => "controlled-local-inbox", "authenticated_ipc" => true,
      "otp_folder_absent" => true, "public_value_absent" => true,
      "live_telegram" => false, "lab_gad2" => false
    }))
  end

  def test_installable_plugin_intercepts_unknown_reply_and_failure_without_preview
    destination = File.join(@tmp, "installed-plugin")
    out = StringIO.new
    Ace::Hitl::Hermes::CLI.start(["plugin", "install", "--path", destination], output: out)
    assert File.file?(File.join(destination, "plugin.yaml"))
    script = <<~PY
      import importlib.util, os, types
      spec=importlib.util.spec_from_file_location('ace_plugin', #{File.join(destination, '__init__.py').inspect})
      plugin=importlib.util.module_from_spec(spec); spec.loader.exec_module(plugin)
      os.environ['ACE_HITL_HERMES_CONFIG']=#{@config_path.inspect}
      os.environ['ACE_HITL_HERMES_EXE']='/nonexistent/controlled-command'
      source=types.SimpleNamespace(platform='telegram', chat_id='-424242', chat_type='supergroup', user_id='42')
      event=types.SimpleNamespace(source=source, text='918273', message_id='101', reply_to_message_id='999')
      assert plugin._pre_dispatch(event)=={'action':'skip','reason':'ace_hitl_hermes'}
      event.text='/hitl-reply malformed 918273'; event.reply_to_message_id=''
      assert plugin._pre_dispatch(event)['action']=='skip'
      source.user_id='99'; event.text='918273'; event.reply_to_message_id='100'
      assert plugin._pre_dispatch(event)['action']=='skip'
      print('protected')
    PY
    stdout, stderr, status = Open3.capture3("python3", "-c", script)
    assert status.success?, stderr
    assert_equal "protected\n", stdout
    refute_includes stdout + stderr, "918273"
  end
end

# frozen_string_literal: true

require "test_helper"
require "support/lifecycle_fixtures"
require "etc"
require "timeout"

# Real authenticated boundary; assignment/native authority is an explicit
# fixture here. Its real journal and native-owner contracts have separate tests.
class HitlAskCliTest < AceHitlTestCase
  include LifecycleFixtures

  def setup
    super
    @scratch = Dir.mktmpdir("ace-hitl-ask")
    @root = File.join(@scratch, "store")
    @socket = File.join(@scratch, "hitl.sock")
    @failure = nil
    test = self
    @binding = TestBinding.new(reverse: {"schema" => "ace.hitl.ref/v1", "session" => "workspace1", "pane" => "pane1"},
      on_validate: ->(**) { raise test.failure if test.failure })
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {
      "hitl" => {"service_uid" => Process.uid, "transport_uids" => [Process.uid]}
    })
    @service = Ace::Hitl::Lifecycle::Service.new(root: @root, binding: @binding,
      policy: policy, socket_path: @socket, group: Etc.getgrgid(Process.gid).name)
    @thread = Thread.new { @service.run }
    Timeout.timeout(5) { sleep 0.01 until File.socket?(@socket) || !@thread.alive? }
    @thread.value unless @thread.alive?
    @client = Ace::Hitl::Lifecycle::Client.new(socket_path: @socket, service_uid: Process.uid)
    @original_client = Ace::Hitl::Providers::Lab.method(:boundary_client)
    client = @client
    Ace::Hitl::Providers::Lab.define_singleton_method(:boundary_client) { |**| client }
  end

  attr_reader :failure

  def teardown
    Ace::Hitl::Providers::Lab.define_singleton_method(:boundary_client, @original_client)
    @service&.stop
    @thread&.join(5)
    @thread&.kill
    FileUtils.remove_entry(@scratch)
    super
  end

  def ask(*flags, question: "Proceed with deploy?")
    with_hitl_dir do |root|
      with_cli_root(root) do
        result = run_cli(["ask", "--question", question, "--assignment", "assign685", "--attempt", "attempt685", *flags])
        yield result, root if block_given?
        result
      end
    end
  end

  def test_ask_uses_managed_binding_and_trusted_reverse_without_daemon_or_env
    with_env("ACE_HITL_LABD_SOCKET" => File.join(@scratch, "absent.sock"),
      "HERDR_SESSION" => "forged-workspace", "HERDR_PANE" => "forged-pane") do
      ask do |result, local_root|
        assert_equal 0, result[:exit_code], result[:stderr]
        request = result[:stdout][/Lab request: (\S+)/, 1]
        event = result[:stdout][/HITL event: (\S+)/, 1]
        record = JSON.parse(File.read(File.join(@root, "requests", "#{request}.json")))
        assert_equal "assign685", record["assignment"]
        assert_equal "attempt685", record["attempt"]
        assert_equal Etc.getpwuid(Process.uid).name, record["requester"]
        refute record.key?("work")
        assert_equal "pane1", record.dig("envelope", "reverse", "pane")
        assert_match(/ref workspace1\/pane1/, result[:stdout])
        manager = Ace::Hitl::Organisms::HitlManager.new(root_dir: local_root)
        assert_equal request, manager.show(event)[:event].metadata["lab_request_id"]
      end
    end
  end

  def test_missing_assignment_attempt_and_question_and_removed_work_are_rejected
    with_hitl_dir do |root|
      with_cli_root(root) do
        [
          ["ask", "--question", "Continue?", "--attempt", "attempt685"],
          ["ask", "--question", "Continue?", "--assignment", "assign685"],
          ["ask", "--assignment", "assign685", "--attempt", "attempt685"],
          ["ask", "--question", "Continue?", "--work", "W685", "--attempt", "attempt685"]
        ].each do |argv|
          result = run_cli(argv)
          assert_equal 1, result[:exit_code], result[:stdout]
        end
        assert_empty @binding.validations
        assert_empty Dir.children(File.join(@root, "requests"))
      end
    end
  end

  def test_unknown_provider_and_invalid_effect_do_not_create_any_event
    ask("--provider", "missing") do |result, root|
      assert_equal 1, result[:exit_code]
      assert_match(/unknown HITL provider/, result[:stderr])
      assert_empty Ace::Hitl::Organisms::HitlManager.new(root_dir: root).list(in_folder: "all")
    end
    ask("--effect-arg", "/bin/false", "--effect-cwd", "relative") do |result, root|
      assert_equal 1, result[:exit_code]
      assert_match(/absolute path/, result[:stderr])
      assert_empty Ace::Hitl::Organisms::HitlManager.new(root_dir: root).list(in_folder: "all")
    end
    assert_empty @binding.validations
  end

  def test_binding_failure_is_classified_and_orphan_local_event_is_inspectable
    @failure = Ace::Hitl::Lifecycle::BindingError.new("native owner is unavailable")
    ask do |result, root|
      assert_equal 1, result[:exit_code]
      assert_match(/native owner is unavailable/, result[:stderr])
      event = result[:stderr][/HITL event (\S+) was created/, 1]
      refute_nil event
      assert Ace::Hitl::Organisms::HitlManager.new(root_dir: root).show(event)[:event]
      assert_empty Dir.children(File.join(@root, "requests"))
    end
  end

  def test_effect_declaration_is_independent_from_transport_envelope
    ask("--effect-arg", "/bin/false", "--effect-cwd", "/tmp") do |result, _|
      assert_equal 0, result[:exit_code], result[:stderr]
      request = result[:stdout][/Lab request: (\S+)/, 1]
      record = JSON.parse(File.read(File.join(@root, "requests", "#{request}.json")))
      assert_equal ["/bin/false"], record.dig("effect", "argv")
      assert record.dig("envelope", "effect", "authorization_ref")
      refute record["envelope"]["effect"].key?("receipt_ref") # declaration is not an effect receipt
    end
  end
end

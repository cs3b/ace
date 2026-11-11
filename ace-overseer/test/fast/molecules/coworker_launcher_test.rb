# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/coworker_launcher"

class CoworkerLauncherTest < AceOverseerTestCase
  Result = Struct.new(:parsed_json)
  Session = {"agent" => "pi", "kind" => "id", "value" => "12345678-1234-1234-1234-123456789abc"}.freeze

  class Executor
    attr_reader :starts, :prompts, :closes
    attr_accessor :session, :prompt_failure, :cwd, :interactive_ready, :agent_status, :name, :dead, :terminal_id

    def initialize
      @starts, @prompts, @closes = [], [], []
      @session = Session.dup
      @interactive_ready = true
      @agent_status = "idle"
      @name = "coworker-assignment-1"
      @terminal_id = "term_123"
    end

    def pane_current
      Result.new({"workspace_id" => "w1"})
    end

    def tab_create(**_)
      Result.new({"pane_id" => "w1:p1"})
    end

    def agent_start(**values)
      @starts << values
      @dead = false
      raise "environment file missing at launch" unless File.file?(values.fetch(:env_file))
    end

    def pane_get(pane)
      raise Ace::Herdr::PaneNotFoundError, "gone" unless @closes.empty?
      Result.new({"result" => {"pane" => {"pane_id" => pane, "terminal_id" => terminal_id,
        "agent" => "pi", "agent_session" => (dead ? nil : session), "cwd" => cwd}}})
    end

    def agent_get(pane)
      raise Ace::Herdr::AgentNotFoundError, "exited" if dead
      row = pane_get(pane.start_with?("coworker-") ? "w1:p1" : pane).parsed_json.dig("result", "pane")
      Result.new({"result" => {"agent" => row.merge("interactive_ready" => interactive_ready, "name" => name, "agent_status" => agent_status)}})
    end

    def agent_prompt(**values)
      @prompts << values
      raise Ace::Herdr::ExecutorTimeoutError, "uncertain prompt" if prompt_failure
    end

    def pane_close(pane)
      @closes << pane
    end
  end

  class Environment
    attr_accessor :failure, :variables
    attr_reader :directory

    def with_environment(**_)
      raise Ace::Overseer::Error, "credentials missing" if failure
      @directory = Dir.mktmpdir("ace-session-")
      File.write(File.join(@directory, "auth.json"), "{}")
      Tempfile.create(["launch-env", ".json"]) do |file|
        file.write(JSON.generate((variables || {}).merge("PI_CODING_AGENT_DIR" => directory))); file.flush
        yield file.path, directory, []
      end
    end
  end

  # Real ordinary child behind the native API seam, without starting Herdr,
  # Pi or a model provider. The child owns its session and report evidence.
  class ProcessExecutor < Executor
    attr_reader :pid, :record

    def tab_create(**values)
      @worktree = values.fetch(:cwd)
      super
    end

    def agent_start(**values)
      super
      environment = JSON.parse(File.read(values.fetch(:env_file)))
      directory = environment.fetch("PI_CODING_AGENT_DIR")
      ready = File.join(directory, "ready.json")
      input, @writer = IO.pipe
      script = <<~'RUBY'
        require "json"
        require "securerandom"
        directory = ENV.fetch("PI_CODING_AGENT_DIR")
        session = File.join(directory, "session_#{SecureRandom.uuid}.jsonl")
        record = {"pid" => Process.pid, "cwd" => Dir.pwd, "toolchain" => ENV["ACE_TOOLCHAIN"],
          "role_value" => ENV["ACE_TEST_ROLE_VALUE"], "ambient" => ENV["ACE_TEST_AMBIENT_SECRET"],
          "session" => session}
        File.write(session, JSON.generate(record) + "\n")
        File.write(File.join(directory, "ready.json"), JSON.generate(record))
        if STDIN.gets
          File.write(File.join(directory, "report.json"), JSON.generate(
            "assignment" => ENV.fetch("ACE_TEST_ASSIGNMENT"), "pid" => Process.pid, "session" => session))
          STDIN.read
        end
      RUBY
      @pid = Process.spawn(environment, RbConfig.ruby, "-e", script, unsetenv_others: true,
        chdir: @worktree, in: input, out: File::NULL, err: File::NULL)
      input.close
      Timeout.timeout(5) { sleep 0.01 until File.file?(ready) }
      @record = JSON.parse(File.read(ready))
      @session = {"agent" => "pi", "kind" => "path", "value" => @record.fetch("session")}
    end

    def agent_prompt(**values)
      super
      @writer.puts(values.fetch(:text))
      @writer.flush
    end

    def pane_close(pane)
      stop
      super
    end

    def stop
      @writer&.close unless @writer&.closed?
      return unless @pid
      Process.kill("TERM", @pid)
      Timeout.timeout(5) { Process.wait(@pid) }
    rescue Errno::ESRCH, Errno::ECHILD
      nil
    ensure
      @pid = nil
    end
  end

  def setup
    super
    @root = Dir.mktmpdir("coworker-launch")
    @path = File.join(@root, Ace::Coworker::Organisms::StartConfigWriter::PREPARE_DIR, "worker.yml")
    FileUtils.mkdir_p(File.dirname(@path))
    @config = Ace::Coworker::Models::Config.new(role: "worker", task: "8xg.t.abc", assignment: "assignment-1",
      instructions: "wfi://coworker/worker", start_prompt: "Work on the task", overseer: "overseer", source_path: @path)
    File.write(@path, YAML.safe_dump(@config.to_h))
    @state = Struct.new(:state, :progress).new("paused", "0/1")
    @brief = Ace::Coworker::Models::Brief.new(config: @config, instructions_source: "/packaged/worker.md",
      task_path: "/task.s.md", assignment_snapshot: @state, project_root: @root)
    @executor = Executor.new
    @executor.cwd = @root
    @environment = Environment.new
  end

  def teardown
    FileUtils.remove_entry(@root)
    FileUtils.remove_entry(@retained_directory) if @retained_directory && File.directory?(@retained_directory)
    FileUtils.remove_entry(@environment.directory) if @environment.directory && File.directory?(@environment.directory)
    super
  end

  def launcher(**kwargs)
    Ace::Overseer::Molecules::CoworkerLauncher.new(executor: @executor, environment: @environment,
      brief_factory: ->(*) { @brief }, readiness: -> { true }, **kwargs)
  end

  def launch(worker = launcher)
    worker.call(worktree_path: @root, config_path: @path)
  end

  def test_dead_worker_resumes_same_assignment_and_transcript_in_same_terminal
    launch
    original_directory = @environment.directory
    transcript = File.join(original_directory, "sessions", "project", "2026-11-11_#{Session.fetch('value')}.jsonl")
    FileUtils.mkdir_p(File.dirname(transcript))
    File.write(transcript, JSON.generate("type" => "session", "id" => Session.fetch("value"), "cwd" => @root) + "\n")
    @state.state = "running"
    @executor.dead = true
    result = launch
    assert_equal "running", result.fetch("state")
    assert_equal 2, @executor.starts.length
    assert_equal "w1:p1", @executor.starts.last.fetch(:pane)
    assert_includes @executor.starts.last.fetch(:args), transcript
    assert_equal Session, result.fetch("agent_session")
    assert_equal "assignment-1", result.fetch("assignment")
    assert_match(/continu/i, @executor.prompts.last.fetch(:text))
    refute File.exist?(File.join(original_directory, "auth.json"))
    assert File.file?(transcript)
    launch
    assert_equal 2, @executor.starts.length
    assert_equal 2, @executor.prompts.length
  ensure
    FileUtils.remove_entry(original_directory) if original_directory && File.directory?(original_directory)
  end

  def interrupted_worker
    launch
    directory = @environment.directory
    @retained_directory = directory
    transcript = File.join(directory, "sessions", "project", "2026-11-11_#{Session.fetch('value')}.jsonl")
    FileUtils.mkdir_p(File.dirname(transcript))
    File.write(transcript, JSON.generate("type" => "session", "id" => Session.fetch("value"), "cwd" => @root) + "\n")
    @state.state = "running"
    @executor.dead = true
    transcript
  end

  def test_uncertain_resume_start_adopts_same_live_session_without_second_start
    interrupted_worker
    @executor.define_singleton_method(:agent_start) do |**args|
      super(**args)
      raise Ace::Herdr::ExecutorTimeoutError, "reply lost"
    end
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal "resuming", YAML.safe_load_file(@path).dig("execution", "state")
    assert_equal "running", launch.fetch("state")
    assert_equal 2, @executor.starts.length
    assert_equal 2, @executor.prompts.length
  end

  def failed_resume_start
    interrupted_worker
    @executor.define_singleton_method(:agent_start) do |**args|
      super(**args)
      self.dead = true
      raise Ace::Herdr::ExecutorTimeoutError, "child failed before readiness"
    end
    assert_raises(Ace::Overseer::Error) { launch }
    @executor.singleton_class.remove_method(:agent_start)
    info = {"pane_id" => "w1:p1", "shell_pid" => 42, "foreground_process_group_id" => 42,
      "foreground_processes" => [{"pid" => 42}], "guarded_prompt" => true,
      "guarded_input_drain" => true, "guarded_prompt_origin" => {"terminal_id" => "term_123"}}
    @executor.define_singleton_method(:pane_process_info) { |_| Result.new({"result" => {"process_info" => info}}) }
    info
  end

  def test_failed_resume_retries_same_assignment_after_positive_shell_proof
    failed_resume_start
    assert_equal "running", launch.fetch("state")
    assert_equal 3, @executor.starts.size
    assert_equal 2, @executor.prompts.size
    assert_equal Session, YAML.safe_load_file(@path).dig("execution", "agent_session")
    launch
    assert_equal 3, @executor.starts.size
  end

  def test_failed_resume_does_not_retry_without_positive_shell_proof
    info = failed_resume_start
    original = Marshal.load(Marshal.dump(info))
    [
      {"foreground_processes" => []},
      {"foreground_processes" => [{"pid" => 42}, {"pid" => 43}]},
      {"foreground_process_group_id" => 43},
      {"shell_pid" => nil},
      {"guarded_prompt" => false},
      {"guarded_input_drain" => false},
      {"guarded_prompt_origin" => {"terminal_id" => "foreign"}},
      {"pane_id" => "w1:p9"}
    ].each do |change|
      info.replace(original.merge(change))
      assert_raises(Ace::Overseer::Error) { launch }
      assert_equal 2, @executor.starts.size
    end
    @executor.define_singleton_method(:pane_process_info) { |_| raise Ace::Herdr::ExecutorTimeoutError, "unreachable" }
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal 2, @executor.starts.size
  end

  def replaced_resume_terminal
    info = failed_resume_start
    @executor.terminal_id = "handoff-terminal"
    @executor.define_singleton_method(:agent_list) { Result.new({"result" => {"agents" => []}}) }
    @executor.define_singleton_method(:tab_create) do |**_|
      self.terminal_id = "fresh-terminal"
      Result.new({"pane_id" => "w1:p2"})
    end
    info.delete("guarded_prompt_origin")
    info.delete("guarded_prompt")
    info.delete("guarded_input_drain")
  end

  def test_terminal_replacement_resumes_same_session_in_fresh_pane_without_touching_old
    replaced_resume_terminal
    result = launch
    assert_equal "w1:p2", result.fetch("pane")
    assert_equal "fresh-terminal", result.fetch("terminal_id")
    assert_equal({"pane" => "w1:p1", "terminal_id" => "term_123"}, result.fetch("previous_terminal"))
    assert_equal Session, result.fetch("agent_session")
    assert_equal "w1:p2", @executor.prompts.last.fetch(:pane)
    assert_empty @executor.closes
    assert_equal 3, @executor.starts.size
  end

  def test_replacement_refuses_live_original_session_or_incomplete_inventory
    replaced_resume_terminal
    [nil, [{"name" => "unclassified", "pane_id" => "w1:p9"}],
      [{"agent" => "unknown", "name" => "unclassified", "pane_id" => "w1:p9"}],
      [{"agent" => "pi", "name" => "different-name", "pane_id" => "w1:p9", "agent_session" => Session}],
      [{"agent" => "pi", "name" => "unknown-session", "pane_id" => "w1:p9"}]].each do |rows|
      @executor.define_singleton_method(:agent_list) { Result.new({"result" => {"agents" => rows}}) }
      assert_raises(Ace::Overseer::Error) { launch }
      assert_equal 2, @executor.starts.size
      assert_empty @executor.closes
    end
  end

  def test_lost_replacement_reply_adopts_exact_session_and_does_not_dispatch_twice
    replaced_resume_terminal
    @executor.define_singleton_method(:agent_start) do |**args|
      super(**args)
      raise Ace::Herdr::ExecutorTimeoutError, "reply lost"
    end
    assert_raises(Ace::Overseer::Error) { launch }
    assert YAML.safe_load_file(@path).dig("execution", "replacement_pending")
    @executor.define_singleton_method(:agent_list) do
      Result.new({"result" => {"agents" => [agent_get("w1:p2").parsed_json.dig("result", "agent")]}})
    end
    assert_equal "running", launch.fetch("state")
    assert_equal 3, @executor.starts.size
    assert_equal 2, @executor.prompts.size
    assert_equal "w1:p2", @executor.prompts.last.fetch(:pane)
  end

  def test_uncertain_resume_prompt_is_not_replayed
    interrupted_worker
    @executor.prompt_failure = true
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal "resume_prompting", YAML.safe_load_file(@path).dig("execution", "state")
    @executor.prompt_failure = false
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal 2, @executor.starts.length
    assert_equal 2, @executor.prompts.length
  end

  def test_missing_transcript_does_not_restart_dead_executor
    transcript = interrupted_worker
    File.unlink(transcript)
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal 1, @executor.starts.length
  end

  def test_native_transport_error_is_not_permission_to_resume
    interrupted_worker
    @executor.define_singleton_method(:agent_get) { |_| raise Ace::Herdr::ExecutorTimeoutError, "unreachable" }
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal 1, @executor.starts.length
  end

  def test_concurrent_retries_bind_one_real_start_and_one_prompt
    workers = 2.times.map { Thread.new { launch } }
    results = workers.map(&:value)
    assert_equal [false, true], results.map { |r| r.fetch("reused") }.sort_by(&:to_s)
    assert_equal 1, @executor.starts.size
    assert_equal 1, @executor.prompts.size
    saved = YAML.safe_load_file(@path).fetch("execution")
    assert_equal "running", saved.fetch("state")
    assert_equal Session, saved.fetch("agent_session")
    assert_equal "assignment-1", saved.fetch("assignment")
    refute results.any? { |r| r.key?("credentials_directory") }
  end

  def test_native_session_can_be_absent_in_first_pane_receipt
    reads = 0
    @executor.define_singleton_method(:session) { reads += 1; (reads == 1) ? nil : Session.dup }
    assert_equal "running", launch.fetch("state")
    assert_equal 1, @executor.starts.size
    assert_equal 1, @executor.prompts.size
  end

  def test_waits_for_asynchronously_published_session_without_restarting
    @executor.session = nil
    sleeps = 0
    worker = launcher(sleeper: ->(_) { sleeps += 1; @executor.session = Session.dup })
    assert_equal "running", launch(worker).fetch("state")
    assert_equal 1, sleeps
    assert_equal 1, @executor.starts.size
    assert_equal 1, @executor.prompts.size
  end

  def test_identity_timeout_preserves_receipt_and_retry_prompts_existing_worker_once
    @executor.session = nil
    assert_raises(Ace::Overseer::Error) { launch(launcher(identity_timeout: 0)) }
    saved = YAML.safe_load_file(@path).fetch("execution")
    assert_equal "started", saved.fetch("state")
    assert_equal "w1:p1", saved.fetch("pane")
    assert_equal "term_123", saved.fetch("terminal_id")
    assert_empty @executor.prompts
    @executor.session = {"agent" => "pi", "kind" => "path",
      "value" => File.join(@environment.directory, "sessions", "session_12345678-1234-1234-1234-123456789abc.jsonl")}
    assert_equal "running", launch.fetch("state")
    assert launch.fetch("reused")
    assert_equal 1, @executor.starts.size
    assert_equal 1, @executor.prompts.size
  end

  def test_saved_terminal_without_session_cannot_adopt_foreign_pi_session
    @executor.session = nil
    assert_raises(Ace::Overseer::Error) { launch(launcher(identity_timeout: 0)) }
    @executor.session = {"agent" => "pi", "kind" => "path",
      "value" => "/tmp/foreign/sessions/session_12345678-1234-1234-1234-123456789abc.jsonl"}
    assert_raises(Ace::Overseer::Error) { launch }
    assert_empty @executor.prompts
    assert_equal 1, @executor.starts.size
  end

  def test_recovery_refuses_worker_that_has_already_started_work
    @executor.session = nil
    assert_raises(Ace::Overseer::Error) { launch(launcher(identity_timeout: 0)) }
    @executor.session = Session.dup
    @executor.agent_status = "working"
    assert_raises(Ace::Overseer::Error) { launch }
    assert_empty @executor.prompts
    assert_equal 1, @executor.starts.size
  end

  def test_missing_receipt_recovery_requires_matching_private_session_provenance
    @executor.session = nil
    assert_raises(Ace::Overseer::Error) { launch(launcher(identity_timeout: 0)) }
    document = YAML.safe_load_file(@path)
    execution = document.fetch("execution")
    execution.delete("pane")
    execution.delete("terminal_id")
    execution["state"] = "launching"
    File.write(@path, YAML.safe_dump(document))
    @executor.session = Session.dup
    assert_raises(Ace::Overseer::Error) { launch }
    assert_empty @executor.prompts
    @executor.session = {"agent" => "pi", "kind" => "path",
      "value" => File.join(@environment.directory, "sessions", "session_12345678-1234-1234-1234-123456789abc.jsonl")}
    @executor.cwd = "/other-project"
    assert_raises(Ace::Overseer::Error) { launch }
    @executor.cwd = @root
    assert_equal "running", launch.fetch("state")
    assert_equal 1, @executor.starts.size
    assert_equal 1, @executor.prompts.size
  end

  def test_missing_credentials_does_not_leave_a_false_uncertain_launch
    @environment.failure = true
    assert_raises(Ace::Overseer::Error) { launch }
    refute YAML.safe_load_file(@path).key?("execution")
    assert_empty @executor.starts
    @environment.failure = false
    assert_equal "running", launch.fetch("state")
  end

  def test_uncertain_prompt_is_not_submitted_twice
    @executor.prompt_failure = true
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal "prompting", YAML.safe_load_file(@path).dig("execution", "state")
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal 1, @executor.starts.size
    assert_equal 1, @executor.prompts.size
    assert File.directory?(@environment.directory), "uncertain live child keeps its credential projection"
  end

  def test_same_terminal_with_replaced_agent_is_neither_reused_nor_closed
    launch
    @executor.session = Session.merge("value" => "87654321-1234-1234-1234-123456789abc")
    assert_raises(Ace::Overseer::Error) { launch }
    assert_raises(Ace::Overseer::Error) { launcher.retire(worktree_path: @root, assignment: "assignment-1") }
    assert_empty @executor.closes
    assert File.directory?(@environment.directory)
  end

  def test_retirement_closes_exact_executor_and_cleans_private_projection_once
    launch
    launcher.retire(worktree_path: @root, assignment: "assignment-1")
    launcher.retire(worktree_path: @root, assignment: "assignment-1")
    assert_equal ["w1:p1"], @executor.closes
    refute File.exist?(File.join(@environment.directory, "auth.json"))
    assert File.directory?(@environment.directory), "session evidence directory is retained"
    assert_equal "retired", YAML.safe_load_file(@path).dig("execution", "state")
    refute YAML.safe_load_file(@path).fetch("execution").key?("credentials_directory")
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal 1, @executor.starts.size
  end

  def test_restored_panel_without_live_agent_is_not_reused
    launch
    @executor.interactive_ready = false
    assert_raises(Ace::Overseer::Error) { launch }
    assert_equal 1, @executor.starts.size
  end

  def test_real_child_receives_worktree_and_environment_and_is_retired_once
    @executor = ProcessExecutor.new
    @environment.variables = {"ACE_TOOLCHAIN" => "installed", "ACE_TEST_ROLE_VALUE" => "scoped-fixture",
      "ACE_TEST_ASSIGNMENT" => "assignment-1"}
    previous = ENV["ACE_TEST_AMBIENT_SECRET"]
    ENV["ACE_TEST_AMBIENT_SECRET"] = "ambient-must-not-cross"
    first = launch
    repeated = launch
    assert_equal false, first.fetch("reused")
    assert_equal true, repeated.fetch("reused")
    assert_equal 1, @executor.starts.size
    record = @executor.record
    assert_equal File.realpath(@root), record.fetch("cwd")
    assert_equal "installed", record.fetch("toolchain")
    assert_equal "scoped-fixture", record.fetch("role_value")
    assert_nil record.fetch("ambient")
    identity = Ace::Herdr::Atoms::NativeAgentSession.normalize(
      {"agent" => "pi", "kind" => "path", "value" => record.fetch("session")}, agent: "pi")
    assert_equal identity, first.fetch("agent_session")
    report_path = File.join(@environment.directory, "report.json")
    Timeout.timeout(5) { sleep 0.01 until File.file?(report_path) }
    assert_equal "assignment-1", JSON.parse(File.read(report_path)).fetch("assignment")
    launcher.retire(worktree_path: @root, assignment: "assignment-1")
    assert_raises(Errno::ESRCH) { Process.kill(0, record.fetch("pid")) }
    refute File.exist?(File.join(@environment.directory, "auth.json"))
    assert File.file?(record.fetch("session")), "real child session evidence survives cleanup"
  ensure
    previous ? ENV["ACE_TEST_AMBIENT_SECRET"] = previous : ENV.delete("ACE_TEST_AMBIENT_SECRET")
    @executor.stop if @executor.respond_to?(:stop)
  end

  def test_unbound_running_assignment_is_never_started_again
    @state.state = "running"
    assert_raises(Ace::Overseer::Error) { launch }
    assert_empty @executor.starts
  end

  def test_predecessor_needs_retirement_even_when_its_assignment_completed
    File.write(File.join(File.dirname(@path), "previous.yml"), YAML.safe_dump({"execution" => {"state" => "running"}}))
    assert_raises(Ace::Overseer::Error) { launch }
    assert_empty @executor.starts
  end

  def test_readiness_and_recipient_use_native_coordinator_root_not_target_cwd
    @executor.cwd = @root
    FileUtils.mkdir_p(File.join(@root, ".ace/overseer"))
    FileUtils.mkdir_p(File.join(@root, ".ace-local/overseer"))
    File.write(File.join(@root, ".ace-local/overseer/eyes.json"), JSON.generate("recipient" => "lab-overseer"))
    observed = []
    eyes = Object.new
    eyes.define_singleton_method(:ready?) { |**values| observed << values; true }
    resolver = Object.new
    resolver.define_singleton_method(:resolve) { |cwd:| cwd }
    worker = Ace::Overseer::Molecules::CoworkerLauncher.new(executor: @executor,
      env: {"HERDR_PANE" => "w1:p9"}, eyes: eyes, root_resolver: resolver)
    assert worker.ready!
    assert_equal @root, observed.first.fetch(:root)
    assert_includes observed.first.fetch(:required_sources), "project_sessions"
    assert_equal "lab-overseer", worker.recipient
    File.write(File.join(@root, ".ace/overseer/config.yml"), YAML.safe_dump("start" => {"scope" => "project"}))
    worker.ready!
    refute_includes observed.last.fetch(:required_sources), "project_sessions"
  end
end

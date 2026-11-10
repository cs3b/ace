# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/overseer/molecules/coworker_launcher"

class CoworkerLauncherTest < AceOverseerTestCase
  Result = Struct.new(:parsed_json)
  Session = {"agent" => "pi", "kind" => "id", "value" => "12345678-1234-1234-1234-123456789abc"}.freeze

  class Executor
    attr_reader :starts, :prompts, :closes
    attr_accessor :session, :prompt_failure, :cwd, :interactive_ready

    def initialize
      @starts, @prompts, @closes = [], [], []
      @session = Session.dup
      @interactive_ready = true
    end

    def pane_current
      Result.new({"workspace_id" => "w1"})
    end

    def tab_create(**_)
      Result.new({"pane_id" => "w1:p1"})
    end

    def agent_start(**values)
      @starts << values
      raise "environment file missing at launch" unless File.file?(values.fetch(:env_file))
    end

    def pane_get(pane)
      raise Ace::Herdr::PaneNotFoundError, "gone" unless @closes.empty?
      Result.new({"result" => {"pane" => {"pane_id" => pane, "terminal_id" => "term_123",
        "agent" => "pi", "agent_session" => session, "cwd" => cwd}}})
    end

    def agent_get(pane)
      row = pane_get(pane).parsed_json.dig("result", "pane")
      Result.new({"result" => {"agent" => row.merge("interactive_ready" => interactive_ready)}})
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
    @environment = Environment.new
  end

  def teardown
    FileUtils.remove_entry(@root)
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

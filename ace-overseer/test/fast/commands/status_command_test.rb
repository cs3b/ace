# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"

class StatusCommandTest < AceOverseerTestCase
  class ProtectedCollector
    attr_reader :calls

    def initialize
      @calls = []
    end

    def collect(project:, agent:)
      @calls << {project: project, agent: agent}
      {"project_id" => project, "provisioned_capacity" => 2, "visible_capacity" => 1, "visibility" => "partial",
        "agents" => [{"agent_id" => "mapping", "status" => "unavailable", "inventory" => nil}]}
    end
  end

  class FakeCollector
    attr_reader :collect_count, :collect_quick_count

    def initialize(snapshot)
      @snapshot = snapshot
      @collect_count = 0
      @collect_quick_count = 0
    end

    def collect
      @collect_count += 1
      @snapshot
    end

    def collect_quick(_previous)
      @collect_quick_count += 1
      @snapshot
    end

    def to_table(_snapshot)
      "fake table output"
    end

    def to_h(_snapshot)
      {worktrees: []}
    end
  end

  def make_assignment(id:, state:)
    {
      "assignment" => {"state" => state, "id" => id, "name" => "work-on-task"},
      "step_summary" => {"total" => 5, "done" => 2, "failed" => 0, "active" => 1, "pending" => 2}
    }
  end

  def test_one_shot_table_output
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignments: [make_assignment(id: "8or5kx", state: "running")],
      git_status: {"clean" => true}
    )
    collector = FakeCollector.new({contexts: [context]})
    command = Ace::Overseer::CLI::Commands::Status.new(collector: collector)

    output = capture_io { command.call(format: "table") }.first

    assert_includes output, "fake table output"
    assert_equal 1, collector.collect_count
  end

  def test_one_shot_json_output
    context = Ace::Overseer::Models::WorkContext.new(
      task_id: "230",
      worktree_path: "/wt/ace-task.230",
      branch: "230-feature",
      assignments: [],
      git_status: {"clean" => true}
    )
    collector = FakeCollector.new({contexts: [context]})
    command = Ace::Overseer::CLI::Commands::Status.new(collector: collector)

    output = capture_io { command.call(format: "json") }.first

    parsed = JSON.parse(output)
    assert_equal [], parsed["worktrees"]
  end

  def test_quiet_suppresses_output
    collector = FakeCollector.new({contexts: []})
    command = Ace::Overseer::CLI::Commands::Status.new(collector: collector)

    output = capture_io { command.call(format: "table", quiet: true) }.first

    assert_empty output
    assert_equal 0, collector.collect_count
  end

  def test_watch_option_with_json_format_runs_once
    collector = FakeCollector.new({contexts: []})
    command = Ace::Overseer::CLI::Commands::Status.new(collector: collector)

    output = capture_io { command.call(format: "json", watch: true) }.first

    parsed = JSON.parse(output)
    assert_equal [], parsed["worktrees"]
    assert_equal 1, collector.collect_count
  end

  def test_requires_git_repo_before_running
    collector = FakeCollector.new({contexts: []})
    command = Ace::Overseer::CLI::Commands::Status.new(collector: collector)

    Dir.mktmpdir("overseer-no-repo") do |dir|
      Dir.chdir(dir) do
        error = assert_raises(Ace::Support::Cli::Error) do
          command.call(format: "table")
        end

        assert_equal Ace::Overseer::Atoms::RepoGuard::MESSAGE, error.message
        assert_equal 0, collector.collect_count
      end
    end
  end

  def test_watch_interrupt_returns_cleanly_without_stack_trace
    collector = FakeCollector.new({contexts: []})
    command = Ace::Overseer::CLI::Commands::Status.new(collector: collector)

    command.define_singleton_method(:run_watch_loop) do |_format, _options|
      raise Interrupt
    end

    stdout, stderr = capture_io do
      command.call(format: "table", watch: true)
    end

    assert_empty stdout
    assert_empty stderr
  end

  def test_project_status_uses_protected_consumer_without_repo_guard
    collector = ProtectedCollector.new
    command = Ace::Overseer::CLI::Commands::Status.new(protected_status: collector)

    Dir.mktmpdir("overseer-lab-status") do |dir|
      Dir.chdir(dir) do
        output = capture_io { command.call(format: "table", project: "nervus") }.first
        assert_includes output, "partial"
        assert_includes output, "mapping\tunavailable"
      end
    end

    assert_equal({project: "nervus", agent: nil}, collector.calls.first)
  end

  def test_protected_status_rejects_duplicate_watch_and_agent_without_project
    command = Ace::Overseer::CLI::Commands::Status.new(protected_status: ProtectedCollector.new)

    error = assert_raises(Ace::Support::Cli::Error) do
      command.call(format: "table", project: "nervus", watch: true)
    end

    assert_equal "Protected status is a bounded snapshot; omit --watch", error.message
    assert_raises(Ace::Support::Cli::Error) { command.call(format: "json", agent: "mapping") }
    assert_raises(Ace::Support::Cli::Error) { command.call(format: "json", runtime: "lab") }
  end

  def test_protected_inventory_is_runtime_independent_including_local_tmux_default
    collector = ProtectedCollector.new
    tick = Object.new
    tick.define_singleton_method(:call) { raise "protected read must not tick proposals" }
    command = Ace::Overseer::CLI::Commands::Status.new(protected_status: collector, config: {"runtime" => "tmux"}, proposal_tick: tick)
    [nil, "auto", "tmux", "herdr"].each do |runtime|
      out = capture_io { command.call(format: "json", project: "project", runtime: runtime) }.first
      assert_equal "project", JSON.parse(out).fetch("project_id")
    end
    assert_equal 4, collector.calls.size
  end
end

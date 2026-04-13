# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"

class StatusCommandTest < AceOverseerTestCase
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
      "step_summary" => {"total" => 5, "done" => 2, "failed" => 0, "in_progress" => 1, "pending" => 2}
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
end

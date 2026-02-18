# frozen_string_literal: true

require "tmpdir"
require_relative "../test_helper"

class WorkOnOrchestratorTest < AceOverseerTestCase
  class FakeTaskLoader
    def initialize(task)
      @task = task
    end

    def find_task_by_reference(_ref)
      @task
    end
  end

  class FakeWorktreeProvisioner
    def initialize(result)
      @result = result
    end

    def provision(_task_ref)
      @result
    end
  end

  class FakeWindowOpener
    attr_reader :calls

    def initialize
      @calls = []
    end

    def open(**kwargs)
      @calls << kwargs
      { window_name: kwargs[:window_name] }
    end
  end

  class FakeAssignmentLauncher
    attr_reader :calls

    def initialize
      @calls = []
    end

    def launch(**kwargs)
      @calls << kwargs
      { assignment_id: "8or5kx", first_phase: "010-onboard" }
    end
  end

  def test_resolves_preset_from_task_frontmatter
    Dir.mktmpdir("task.230") do |worktree|
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskLoader.new({ metadata: { "assign" => { "preset" => "fix-bug" } } }),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          { worktree_path: worktree, branch: "230-feature", created: true }
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: FakeAssignmentLauncher.new,
        config: {
          "default_assign_preset" => "work-on-task",
          "window_name_format" => "t{task_id}",
          "tmux_session_name" => "ace",
          "window_preset" => "cc"
        },
        assignment_detector: ->(_path) { nil }
      )

      result = orchestrator.call(task_ref: "230", cli_preset: "quick-implement")

      assert_equal "fix-bug", result[:preset]
      assert_equal "8or5kx", result[:assignment_id]
      assert_equal "t230", result[:window_name]
    end
  end

  def test_falls_back_to_cli_preset
    Dir.mktmpdir("task.231") do |worktree|
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskLoader.new({ metadata: {} }),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          { worktree_path: worktree, branch: "231-feature", created: false }
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: FakeAssignmentLauncher.new,
        config: {
          "default_assign_preset" => "work-on-task",
          "window_name_format" => "t{task_id}",
          "tmux_session_name" => "ace",
          "window_preset" => "cc"
        },
        assignment_detector: ->(_path) { nil }
      )

      result = orchestrator.call(task_ref: "231", cli_preset: "quick-implement")

      assert_equal "quick-implement", result[:preset]
    end
  end
end

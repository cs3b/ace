# frozen_string_literal: true

require "tmpdir"
require_relative "../../test_helper"

class WorkOnOrchestratorTest < AceOverseerTestCase
  class FakeTaskManager
    attr_reader :calls

    def initialize(tasks)
      @tasks = tasks
      @calls = []
    end

    def show(ref)
      @calls << ref
      data = @tasks.is_a?(Hash) ? @tasks[ref] : @tasks
      return nil unless data

      FakeTask.new(data)
    end
  end

  class FakeTask
    attr_reader :metadata, :subtasks, :status

    def initialize(data)
      @metadata = data[:metadata] || {}
      @status = data[:status]
      @subtasks = if data[:subtasks]
        data[:subtasks].map { |s| FakeTask.new(s) }
      elsif data[:is_orchestrator] && data[:subtask_entries]&.any?
        data[:subtask_entries].map { |e| FakeSubtaskRef.new(e[:id], status: e[:status]) }
      elsif data[:is_orchestrator] && data[:subtask_ids]&.any?
        data[:subtask_ids].map { |id| FakeSubtaskRef.new(id) }
      end
    end
  end

  class FakeSubtaskRef
    attr_reader :id, :status

    def initialize(id, status: nil)
      @id = id
      @status = status
    end
  end

  class FakeWorktreeProvisioner
    attr_reader :calls

    def initialize(result)
      @result = result
      @calls = []
    end

    def provision(task_ref)
      @calls << task_ref
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
    end
  end

  class FakeAssignmentLauncher
    attr_reader :calls

    def initialize(supports_taskrefs: true)
      @calls = []
      @supports_taskrefs = supports_taskrefs
    end

    def preset_supports_taskrefs?(preset_name:, worktree_path: nil)
      @supports_taskrefs
    end

    def launch(**kwargs)
      @calls << kwargs
      {assignment_id: "8or5kx", first_step: "010-onboard", job_path: ".ace-local/assign/jobs/work-on-task-230-job.yml"}
    end
  end

  def test_resolves_preset_from_task_frontmatter
    Dir.mktmpdir("task.230") do |worktree|
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("230" => {metadata: {"assign" => {"preset" => "fix-bug"}}}),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "230-feature", created: true}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: FakeAssignmentLauncher.new,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      result = orchestrator.call(task_ref: "230", cli_preset: "quick-implement")

      assert_equal "fix-bug", result[:preset]
      assert_equal "8or5kx", result[:assignment_id]
    end
  end

  def test_on_progress_receives_step_messages
    Dir.mktmpdir("task.232") do |worktree|
      messages = []
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("232" => {metadata: {}}),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "232-feature", created: true}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: FakeAssignmentLauncher.new,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      orchestrator.call(task_ref: "232", on_progress: ->(msg) { messages << msg })

      assert messages.any? { |m| m.include?("Loading task 232") }
      assert messages.any? { |m| m.include?("Provisioning worktree") }
      assert messages.any? { |m| m.include?("Worktree created at") }
      assert messages.any? { |m| m.include?("Opening tmux window") }
      assert messages.any? { |m| m.include?("Checking assignment status") }
      assert messages.any? { |m| m.include?("Launching assignment") }
    end
  end

  def test_on_progress_reports_existing_worktree
    Dir.mktmpdir("task.233") do |worktree|
      messages = []
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("233" => {metadata: {}}),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "233-feature", created: false}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: FakeAssignmentLauncher.new,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      orchestrator.call(task_ref: "233", on_progress: ->(msg) { messages << msg })

      assert messages.any? { |m| m.include?("Worktree exists at") }
    end
  end

  def test_on_progress_reports_existing_assignment
    Dir.mktmpdir("task.234") do |worktree|
      messages = []
      existing = {
        "assignment" => {"id" => "existing-id"},
        "current_step" => {"number" => "020-implement"}
      }
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("234" => {metadata: {}}),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "234-feature", created: true}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: FakeAssignmentLauncher.new,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) { existing }
      )

      orchestrator.call(task_ref: "234", on_progress: ->(msg) { messages << msg })

      assert messages.any? { |m| m.include?("Assignment already active: existing-id") }
    end
  end

  def test_passes_subtask_refs_for_orchestrator_task
    Dir.mktmpdir("task.272") do |worktree|
      task = {
        metadata: {"assign" => {"preset" => "work-on-task"}},
        is_orchestrator: true,
        subtask_ids: [
          "8pp.t.q7w.a",
          "8pp.t.q7w.b",
          "8pp.t.q7w.c"
        ]
      }
      launcher = FakeAssignmentLauncher.new
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("272" => task),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "272-orchestrator", created: true}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: launcher,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      orchestrator.call(task_ref: "272")

      assert_equal 1, launcher.calls.length
      call = launcher.calls.first
      assert_equal %w[8pp.t.q7w.a 8pp.t.q7w.b 8pp.t.q7w.c], call[:subtask_refs]
    end
  end

  def test_does_not_pass_subtask_refs_for_non_orchestrator_task
    Dir.mktmpdir("task.150") do |worktree|
      task = {metadata: {}, is_orchestrator: false}
      launcher = FakeAssignmentLauncher.new
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("150" => task),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "150-feature", created: true}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: launcher,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      orchestrator.call(task_ref: "150")

      assert_equal 1, launcher.calls.length
      assert_nil launcher.calls.first[:subtask_refs]
    end
  end

  def test_falls_back_to_cli_preset
    Dir.mktmpdir("task.231") do |worktree|
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("231" => {metadata: {}}),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "231-feature", created: false}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: FakeAssignmentLauncher.new,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      result = orchestrator.call(task_ref: "231", cli_preset: "quick-implement")

      assert_equal "quick-implement", result[:preset]
    end

    def test_passes_tmux_preset_from_overseer_config
      Dir.mktmpdir("task.235") do |worktree|
        tmux = FakeWindowOpener.new
        orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
          task_loader: FakeTaskManager.new("235" => {metadata: {}}),
          worktree_provisioner: FakeWorktreeProvisioner.new(
            {worktree_path: worktree, branch: "235-feature", created: true}
          ),
          tmux_window_opener: tmux,
          assignment_launcher: FakeAssignmentLauncher.new,
          config: {
            "default_assign_preset" => "work-on-task",
            "tmux_window_presets" => {
              "work-on-task" => "work-on-task"
            }
          },
          assignment_detector: ->(_path) {}
        )

        orchestrator.call(task_ref: "235", cli_preset: "work-on-task")

        assert_equal 1, tmux.calls.length
        assert_equal(
          {worktree_path: worktree, preset: "work-on-task"},
          tmux.calls.first
        )
      end
    end

    def test_passes_no_tmux_preset_when_mapping_missing
      Dir.mktmpdir("task.236") do |worktree|
        tmux = FakeWindowOpener.new
        orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
          task_loader: FakeTaskManager.new("236" => {metadata: {}}),
          worktree_provisioner: FakeWorktreeProvisioner.new(
            {worktree_path: worktree, branch: "236-feature", created: true}
          ),
          tmux_window_opener: tmux,
          assignment_launcher: FakeAssignmentLauncher.new,
          config: {
            "default_assign_preset" => "work-on-task",
            "tmux_window_presets" => {
              "other-preset" => "work-on-task"
            }
          },
          assignment_detector: ->(_path) {}
        )

        orchestrator.call(task_ref: "236")

        assert_equal 1, tmux.calls.length
        assert_equal({worktree_path: worktree, preset: nil}, tmux.calls.first)
      end
    end
  end

  def test_multi_input_preserves_order_and_expands_orchestrators_in_place
    Dir.mktmpdir("task.288") do |worktree|
      launcher = FakeAssignmentLauncher.new
      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new(
          "288" => {
            metadata: {},
            is_orchestrator: true,
            subtask_ids: ["8pp.t.q7w.a", "8pp.t.q7w.b"]
          },
          "287.01" => {metadata: {}, is_orchestrator: false},
          "300" => {metadata: {}, is_orchestrator: false}
        ),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "288-orchestrator", created: true}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: launcher,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      orchestrator.call(task_ref: "288", task_refs: ["288", "287.01", "300"], cli_preset: "work-on-task")

      assert_equal 1, launcher.calls.length
      call = launcher.calls.first
      assert_equal %w[8pp.t.q7w.a 8pp.t.q7w.b 287.01 300], call[:task_refs]
      assert_equal "288", call[:task_ref]
    end
  end

  def test_multi_input_requires_taskrefs_preset_before_side_effects
    Dir.mktmpdir("task.288") do |worktree|
      worktree_provisioner = FakeWorktreeProvisioner.new(
        {worktree_path: worktree, branch: "288-orchestrator", created: true}
      )
      tmux = FakeWindowOpener.new
      launcher = FakeAssignmentLauncher.new(supports_taskrefs: false)

      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new(
          "288" => {metadata: {}, is_orchestrator: false},
          "287" => {metadata: {}, is_orchestrator: false}
        ),
        worktree_provisioner: worktree_provisioner,
        tmux_window_opener: tmux,
        assignment_launcher: launcher,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      error = assert_raises(Ace::Overseer::Error) do
        orchestrator.call(task_ref: "288", task_refs: %w[288 287], cli_preset: "work-on-task")
      end

      assert_includes error.message, "accepts only single taskref"
      assert_empty worktree_provisioner.calls
      assert_empty tmux.calls
      assert_empty launcher.calls
    end
  end

  def test_multi_input_validation_happens_before_side_effects
    Dir.mktmpdir("task.288") do |worktree|
      worktree_provisioner = FakeWorktreeProvisioner.new(
        {worktree_path: worktree, branch: "288-orchestrator", created: true}
      )
      tmux = FakeWindowOpener.new
      launcher = FakeAssignmentLauncher.new

      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new(
          "288" => {metadata: {}, is_orchestrator: false},
          "999" => nil
        ),
        worktree_provisioner: worktree_provisioner,
        tmux_window_opener: tmux,
        assignment_launcher: launcher,
        config: {
          "default_assign_preset" => "work-on-task"
        },
        assignment_detector: ->(_path) {}
      )

      error = assert_raises(Ace::Overseer::Error) do
        orchestrator.call(task_ref: "288", task_refs: %w[288 999], cli_preset: "work-on-task")
      end

      assert_equal "Task not found: 999", error.message
      assert_empty worktree_provisioner.calls
      assert_empty tmux.calls
      assert_empty launcher.calls
    end
  end

  def test_rejects_draft_task_before_side_effects
    Dir.mktmpdir("task.draft") do |worktree|
      worktree_provisioner = FakeWorktreeProvisioner.new(
        {worktree_path: worktree, branch: "draft-feature", created: true}
      )
      tmux = FakeWindowOpener.new
      launcher = FakeAssignmentLauncher.new

      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("400" => {metadata: {}, status: "draft"}),
        worktree_provisioner: worktree_provisioner,
        tmux_window_opener: tmux,
        assignment_launcher: launcher,
        config: {"default_assign_preset" => "work-on-task"},
        assignment_detector: ->(_path) {}
      )

      error = assert_raises(Ace::Overseer::Error) do
        orchestrator.call(task_ref: "400")
      end

      assert_includes error.message, "status 'draft'"
      assert_includes error.message, "/as-task-review 400"
      assert_empty worktree_provisioner.calls
      assert_empty tmux.calls
      assert_empty launcher.calls
    end
  end

  def test_raises_error_when_no_valid_task_refs_provided
    Dir.mktmpdir("task.empty") do |worktree|
      worktree_provisioner = FakeWorktreeProvisioner.new(
        {worktree_path: worktree, branch: "empty-test", created: true}
      )
      tmux = FakeWindowOpener.new
      launcher = FakeAssignmentLauncher.new

      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new({}),
        worktree_provisioner: worktree_provisioner,
        tmux_window_opener: tmux,
        assignment_launcher: launcher,
        config: {"default_assign_preset" => "work-on-task"},
        assignment_detector: ->(_path) {}
      )

      error = assert_raises(Ace::Overseer::Error) do
        orchestrator.call(task_ref: "", task_refs: [])
      end

      assert_equal "No valid task references provided", error.message
      assert_empty worktree_provisioner.calls
      assert_empty tmux.calls
      assert_empty launcher.calls
    end
  end

  def test_rejects_single_terminal_task_before_side_effects
    Dir.mktmpdir("task.done") do |worktree|
      worktree_provisioner = FakeWorktreeProvisioner.new(
        {worktree_path: worktree, branch: "done-feature", created: true}
      )
      tmux = FakeWindowOpener.new
      launcher = FakeAssignmentLauncher.new

      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("401" => {metadata: {}, status: "done"}),
        worktree_provisioner: worktree_provisioner,
        tmux_window_opener: tmux,
        assignment_launcher: launcher,
        config: {"default_assign_preset" => "work-on-task"},
        assignment_detector: ->(_path) {}
      )

      error = assert_raises(Ace::Overseer::Error) do
        orchestrator.call(task_ref: "401")
      end

      assert_includes error.message, "already terminal"
      assert_includes error.message, "401"
      assert_empty worktree_provisioner.calls
      assert_empty tmux.calls
      assert_empty launcher.calls
    end
  end

  def test_rejects_all_terminal_requested_refs_before_side_effects
    Dir.mktmpdir("task.all-done") do |worktree|
      worktree_provisioner = FakeWorktreeProvisioner.new(
        {worktree_path: worktree, branch: "all-done", created: true}
      )
      tmux = FakeWindowOpener.new
      launcher = FakeAssignmentLauncher.new

      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new(
          "402" => {metadata: {}, status: "done"},
          "403" => {metadata: {}, status: "skipped"}
        ),
        worktree_provisioner: worktree_provisioner,
        tmux_window_opener: tmux,
        assignment_launcher: launcher,
        config: {"default_assign_preset" => "work-on-task"},
        assignment_detector: ->(_path) {}
      )

      error = assert_raises(Ace::Overseer::Error) do
        orchestrator.call(task_ref: "402", task_refs: %w[402 403], cli_preset: "work-on-task")
      end

      assert_includes error.message, "already terminal"
      assert_includes error.message, "402"
      assert_includes error.message, "403"
      assert_empty worktree_provisioner.calls
      assert_empty tmux.calls
      assert_empty launcher.calls
    end
  end

  def test_skips_terminal_requested_ref_in_mixed_set
    Dir.mktmpdir("task.mixed") do |worktree|
      messages = []
      launcher = FakeAssignmentLauncher.new

      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new(
          "404" => {metadata: {}, status: "done"},
          "405" => {metadata: {}, status: nil}
        ),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "mixed-set", created: true}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: launcher,
        config: {"default_assign_preset" => "work-on-task"},
        assignment_detector: ->(_path) {}
      )

      result = orchestrator.call(
        task_ref: "404",
        task_refs: %w[404 405],
        cli_preset: "work-on-task",
        on_progress: ->(msg) { messages << msg }
      )

      assert_equal 1, launcher.calls.length
      assert_equal %w[405], launcher.calls.first[:task_refs]
      assert messages.any? { |m| m.include?("Skipped terminal tasks") && m.include?("404") }
    end
  end

  def test_filters_terminal_subtasks_during_expansion
    Dir.mktmpdir("task.subtask-filter") do |worktree|
      launcher = FakeAssignmentLauncher.new
      task = {
        metadata: {},
        is_orchestrator: true,
        subtask_entries: [
          {id: "8pp.t.q7w.a", status: nil},
          {id: "8pp.t.q7w.b", status: "done"},
          {id: "8pp.t.q7w.c", status: "pending"}
        ]
      }

      orchestrator = Ace::Overseer::Organisms::WorkOnOrchestrator.new(
        task_loader: FakeTaskManager.new("500" => task),
        worktree_provisioner: FakeWorktreeProvisioner.new(
          {worktree_path: worktree, branch: "500-orchestrator", created: true}
        ),
        tmux_window_opener: FakeWindowOpener.new,
        assignment_launcher: launcher,
        config: {"default_assign_preset" => "work-on-task"},
        assignment_detector: ->(_path) {}
      )

      orchestrator.call(task_ref: "500")

      call = launcher.calls.first
      assert_equal %w[8pp.t.q7w.a 8pp.t.q7w.c], call[:task_refs]
      assert_equal %w[8pp.t.q7w.a 8pp.t.q7w.c], call[:subtask_refs]
    end
  end
end

# frozen_string_literal: true

require "tmpdir"
require_relative "../../test_helper"

class AssignmentLauncherTest < AceOverseerTestCase
  FakeAssignment = Struct.new(:id)
  FakeStep = Struct.new(:number, :name)
  FakeSubtask = Struct.new(:id, :status)

  class FakeTask
    attr_reader :status, :subtasks

    def initialize(status: nil, subtasks: [])
      @status = status
      @subtasks = subtasks
    end
  end

  class FakeTaskManager
    def initialize(tasks)
      @tasks = tasks
    end

    def show(ref)
      @tasks[ref]
    end
  end

  def init_git_repo!(path)
    Dir.chdir(path) do
      system("git", "init", "--quiet")
      system("git", "config", "user.name", "ACE Test")
      system("git", "config", "user.email", "ace@example.com")
      File.write(".gitkeep", "")
      system("git", "add", ".gitkeep")
      system("git", "commit", "-m", "init", "--quiet")
    end
  end

  class FakeExecutor
    attr_reader :start_calls

    def initialize
      @start_calls = []
    end

    def start(job_path)
      @start_calls << job_path
      {
        assignment: FakeAssignment.new("abc123"),
        current: FakeStep.new("010", "onboard")
      }
    end
  end

  def test_launch_builds_job_and_starts_assignment
    Dir.mktmpdir("overseer-worktree") do |worktree|
      init_git_repo!(worktree)
      preset_dir = File.join(worktree, ".ace", "assign", "presets")
      FileUtils.mkdir_p(preset_dir)
      File.write(
        File.join(preset_dir, "work-on-task.yml"),
        {
          "name" => "work-on-task",
          "description" => "Test preset",
          "parameters" => {"taskref" => {"required" => true}},
          "steps" => [
            {
              "name" => "work-on-task",
              "instructions" => ["Work on task {{taskref}}."],
              "sub_steps" => ["work-on-task", "pre-commit-review", "release-minor", "create-retro"]
            }
          ]
        }.to_yaml
      )

      fake_executor = FakeExecutor.new
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(
        assignment_executor: fake_executor,
        task_manager: FakeTaskManager.new(
          "235.03" => FakeTask.new(status: "pending")
        )
      )
      result = launcher.launch(worktree_path: worktree, preset_name: "work-on-task", task_ref: "235.03")

      assert_equal "abc123", result[:assignment_id]
      assert_equal "010-onboard", result[:first_step]
      assert File.exist?(result[:job_path])
      assert_equal 1, fake_executor.start_calls.length
      assert_includes File.read(result[:job_path]), "Work on task 235.03"
      assert_includes File.read(result[:job_path]), "pre-commit-review"
      assert_includes File.read(result[:job_path]), "release-minor"
      assert_includes File.read(result[:job_path]), "create-retro"
    end
  end

  def test_launch_expands_subtask_refs_into_taskrefs_parameter
    Dir.mktmpdir("overseer-worktree") do |worktree|
      init_git_repo!(worktree)
      preset_dir = File.join(worktree, ".ace", "assign", "presets")
      FileUtils.mkdir_p(preset_dir)
      File.write(
        File.join(preset_dir, "work-on-task.yml"),
        {
          "name" => "work-on-task",
          "description" => "Multi-task preset",
          "parameters" => {"taskrefs" => {"required" => true, "type" => "array"}},
          "expansion" => {
            "batch-parent" => {
              "name" => "batch-tasks",
              "number" => "010",
              "instructions" => "Batch container"
            },
            "foreach" => "taskrefs",
            "child-template" => {
              "name" => "work-on-{{item}}",
              "parent" => "010",
              "context" => "fork",
              "instructions" => "Work on task {{item}}."
            }
          }
        }.to_yaml
      )

      fake_executor = FakeExecutor.new
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(
        assignment_executor: fake_executor,
        task_manager: FakeTaskManager.new(
          "272" => FakeTask.new(status: "pending", subtasks: [
            FakeSubtask.new("272.01", "pending"),
            FakeSubtask.new("272.02", "pending"),
            FakeSubtask.new("272.03", "pending")
          ]),
          "272.01" => FakeTask.new(status: "pending"),
          "272.02" => FakeTask.new(status: "pending"),
          "272.03" => FakeTask.new(status: "pending")
        )
      )
      result = launcher.launch(
        worktree_path: worktree,
        preset_name: "work-on-task",
        task_ref: "272",
        subtask_refs: %w[272.01 272.02 272.03]
      )

      assert_equal "abc123", result[:assignment_id]
      job_content = File.read(result[:job_path])
      assert_includes job_content, "work-on-272.01"
      assert_includes job_content, "work-on-272.02"
      assert_includes job_content, "work-on-272.03"
    end
  end

  def test_launch_falls_back_to_task_ref_when_no_subtask_refs
    Dir.mktmpdir("overseer-worktree") do |worktree|
      init_git_repo!(worktree)
      preset_dir = File.join(worktree, ".ace", "assign", "presets")
      FileUtils.mkdir_p(preset_dir)
      File.write(
        File.join(preset_dir, "work-on-task.yml"),
        {
          "name" => "work-on-task",
          "description" => "Multi-task preset",
          "parameters" => {"taskrefs" => {"required" => true, "type" => "array"}},
          "expansion" => {
            "batch-parent" => {
              "name" => "batch-tasks",
              "number" => "010",
              "instructions" => "Batch container"
            },
            "foreach" => "taskrefs",
            "child-template" => {
              "name" => "work-on-{{item}}",
              "parent" => "010",
              "context" => "fork",
              "instructions" => "Work on task {{item}}."
            }
          }
        }.to_yaml
      )

      fake_executor = FakeExecutor.new
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(
        assignment_executor: fake_executor,
        task_manager: FakeTaskManager.new(
          "150" => FakeTask.new(status: "pending")
        )
      )
      result = launcher.launch(
        worktree_path: worktree,
        preset_name: "work-on-task",
        task_ref: "150"
      )

      assert_equal "abc123", result[:assignment_id]
      job_content = File.read(result[:job_path])
      assert_includes job_content, "work-on-150"
    end
  end

  def test_launch_uses_explicit_taskrefs_when_provided
    Dir.mktmpdir("overseer-worktree") do |worktree|
      init_git_repo!(worktree)
      preset_dir = File.join(worktree, ".ace", "assign", "presets")
      FileUtils.mkdir_p(preset_dir)
      File.write(
        File.join(preset_dir, "work-on-task.yml"),
        {
          "name" => "work-on-task",
          "description" => "Multi-task preset",
          "parameters" => {"taskrefs" => {"required" => true, "type" => "array"}},
          "expansion" => {
            "batch-parent" => {
              "name" => "batch-tasks",
              "number" => "010",
              "instructions" => "Batch container"
            },
            "foreach" => "taskrefs",
            "child-template" => {
              "name" => "work-on-{{item}}",
              "parent" => "010",
              "context" => "fork",
              "instructions" => "Work on task {{item}}."
            }
          }
        }.to_yaml
      )

      fake_executor = FakeExecutor.new
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(
        assignment_executor: fake_executor,
        task_manager: FakeTaskManager.new(
          "288" => FakeTask.new(status: "pending"),
          "288.01" => FakeTask.new(status: "pending"),
          "288.02" => FakeTask.new(status: "pending"),
          "287.01" => FakeTask.new(status: "pending"),
          "300" => FakeTask.new(status: "pending")
        )
      )
      result = launcher.launch(
        worktree_path: worktree,
        preset_name: "work-on-task",
        task_ref: "288",
        subtask_refs: %w[288.01 288.02],
        task_refs: %w[288.01 288.02 287.01 300]
      )

      assert_equal "abc123", result[:assignment_id]
      job_content = File.read(result[:job_path])
      assert_includes job_content, "work-on-288.01"
      assert_includes job_content, "work-on-288.02"
      assert_includes job_content, "work-on-287.01"
      assert_includes job_content, "work-on-300"
    end
  end

  def test_launch_uses_project_preset_path_when_available
    Dir.mktmpdir("overseer-worktree") do |worktree|
      init_git_repo!(worktree)
      preset_dir = File.join(worktree, ".ace", "assign", "presets")
      FileUtils.mkdir_p(preset_dir)
      File.write(
        File.join(preset_dir, "work-on-task.yml"),
        {
          "name" => "work-on-task",
          "description" => "Project preset",
          "parameters" => {"taskref" => {"required" => true}},
          "steps" => [
            {
              "name" => "work-on-task",
              "instructions" => ["Project preset for {{taskref}}."]
            }
          ]
        }.to_yaml
      )

      fake_executor = FakeExecutor.new
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(
        assignment_executor: fake_executor,
        task_manager: FakeTaskManager.new(
          "235.03" => FakeTask.new(status: "pending")
        )
      )
      result = launcher.launch(worktree_path: worktree, preset_name: "work-on-task", task_ref: "235.03")

      assert_equal "abc123", result[:assignment_id]
      assert_includes File.read(result[:job_path]), "Project preset for 235.03."
    end
  end
end

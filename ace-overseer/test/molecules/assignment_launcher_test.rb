# frozen_string_literal: true

require "tmpdir"
require_relative "../test_helper"

class AssignmentLauncherTest < AceOverseerTestCase
  FakeAssignment = Struct.new(:id)
  FakeStep = Struct.new(:number, :name)

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
      preset_dir = File.join(worktree, "ace-assign", ".ace-defaults", "assign", "presets")
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
              "instructions" => ["Work on task {{taskref}}."]
            }
          ]
        }.to_yaml
      )

      fake_executor = FakeExecutor.new
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(assignment_executor: fake_executor)
      result = launcher.launch(worktree_path: worktree, preset_name: "work-on-task", task_ref: "235.03")

      assert_equal "abc123", result[:assignment_id]
      assert_equal "010-onboard", result[:first_step]
      assert File.exist?(result[:job_path])
      assert_equal 1, fake_executor.start_calls.length
      assert_includes File.read(result[:job_path]), "Work on task 235.03"
    end
  end

  def test_launch_expands_subtask_refs_into_taskrefs_parameter
    Dir.mktmpdir("overseer-worktree") do |worktree|
      preset_dir = File.join(worktree, "ace-assign", ".ace-defaults", "assign", "presets")
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
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(assignment_executor: fake_executor)
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
      preset_dir = File.join(worktree, "ace-assign", ".ace-defaults", "assign", "presets")
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
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(assignment_executor: fake_executor)
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
      preset_dir = File.join(worktree, "ace-assign", ".ace-defaults", "assign", "presets")
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
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(assignment_executor: fake_executor)
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
      launcher = Ace::Overseer::Molecules::AssignmentLauncher.new(assignment_executor: fake_executor)
      result = launcher.launch(worktree_path: worktree, preset_name: "work-on-task", task_ref: "235.03")

      assert_equal "abc123", result[:assignment_id]
      assert_includes File.read(result[:job_path]), "Project preset for 235.03."
    end
  end
end

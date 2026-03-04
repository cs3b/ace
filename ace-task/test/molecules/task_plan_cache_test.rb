# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "ace/task/molecules/task_plan_cache"

class TaskPlanCacheTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-plan-cache-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    @tasks_dir = File.join(@tmpdir, ".ace-tasks")
    create_task_fixture(@tasks_dir, id: "8pp.t.q7w", slug: "plan-cache", status: "pending")
    @task_file = File.join(@tasks_dir, "8pp.t.q7w-plan-cache", "8pp.t.q7w-plan-cache.s.md")
    @context_file = File.join(@tmpdir, "README.md")
    File.write(@context_file, "context")

    @cache = Ace::Task::Molecules::TaskPlanCache.new(task_id: "8pp.t.q7w")
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_write_plan_updates_latest_pointer
    path = @cache.write_plan(
      content: "# Plan\n",
      model: "gemini:flash-latest",
      task_file: @task_file,
      context_files: [@context_file]
    )

    assert File.exist?(path)
    assert_equal File.basename(path), File.read(@cache.latest_pointer_path).strip
  end

  def test_resolve_latest_plan_falls_back_to_newest_when_pointer_missing
    older = @cache.write_plan(
      content: "# Older\n",
      model: "gemini:flash-latest",
      task_file: @task_file,
      context_files: [@context_file]
    )
    newer = @cache.write_plan(
      content: "# Newer\n",
      model: "gemini:flash-latest",
      task_file: @task_file,
      context_files: [@context_file]
    )

    FileUtils.rm_f(@cache.latest_pointer_path)
    resolved = @cache.resolve_latest_plan

    assert_equal newer, resolved
    refute_equal older, resolved
  end

  def test_fresh_returns_false_when_context_file_missing
    path = @cache.write_plan(
      content: "# Plan\n",
      model: "gemini:flash-latest",
      task_file: @task_file,
      context_files: [@context_file]
    )
    FileUtils.rm_f(@context_file)

    refute @cache.fresh?(path, task_file: @task_file)
  end
end

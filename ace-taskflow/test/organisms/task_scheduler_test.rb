# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/task_scheduler"
require_relative "../../lib/ace/taskflow/organisms/task_manager"

class TaskSchedulerTest < AceTaskflowTestCase
  def setup
    @temp_dir = Dir.mktmpdir
    @task_manager = Ace::Taskflow::Organisms::TaskManager.new
    @scheduler = Ace::Taskflow::Organisms::TaskScheduler.new(@task_manager)

    # Stub the root path for task_manager
    @task_manager.instance_variable_set(:@root_path, @temp_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_reschedule_with_add_next_strategy_places_before_pending
    # Create mock tasks
    tasks = [
      { id: "v.0.9.0+task.025", status: "pending", path: File.join(@temp_dir, "025.md"), sort: 100 },
      { id: "v.0.9.0+task.026", status: "pending", path: File.join(@temp_dir, "026.md"), sort: 200 },
      { id: "v.0.9.0+task.027", status: "done", path: File.join(@temp_dir, "027.md") }
    ]

    # Create task files
    tasks.each do |task|
      content = "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n"
      content += "sort: #{task[:sort]}\n" if task[:sort]
      content += "---\n# Task"
      File.write(task[:path], content)
    end

    # Mock list_tasks to accept keyword arguments
    @task_manager.define_singleton_method(:list_tasks) { |context: nil| tasks }

    # Reschedule task 027 to add_next
    @scheduler.reschedule(["027"], strategy: :add_next)

    # Read the updated file to verify sort value
    content = File.read(File.join(@temp_dir, "027.md"))
    assert_match(/sort: \d+/, content)

    # The sort value should be less than 100 (the minimum of pending tasks)
    sort_match = content.match(/sort: (\d+)/)
    refute_nil sort_match
    assert sort_match[1].to_i < 100, "Sort value should be less than 100"
  end

  def test_reschedule_with_add_at_end_strategy_places_after_highest
    tasks = [
      { id: "v.0.9.0+task.025", status: "pending", path: File.join(@temp_dir, "025.md"), sort: 100 },
      { id: "v.0.9.0+task.026", status: "done", path: File.join(@temp_dir, "026.md") }
    ]

    tasks.each do |task|
      content = "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n"
      content += "sort: #{task[:sort]}\n" if task[:sort]
      content += "---\n# Task"
      File.write(task[:path], content)
    end

    @task_manager.define_singleton_method(:list_tasks) { |context: nil| tasks }

    @scheduler.reschedule(["026"], strategy: :add_at_end)

    content = File.read(File.join(@temp_dir, "026.md"))
    sort_match = content.match(/sort: (\d+)/)
    refute_nil sort_match
    assert sort_match[1].to_i > 100, "Sort value should be greater than 100"
  end

  def test_reschedule_with_after_strategy_places_after_reference
    tasks = [
      { id: "v.0.9.0+task.025", status: "pending", path: File.join(@temp_dir, "025.md"), sort: 100 },
      { id: "v.0.9.0+task.026", status: "pending", path: File.join(@temp_dir, "026.md"), sort: 200 },
      { id: "v.0.9.0+task.027", status: "done", path: File.join(@temp_dir, "027.md") }
    ]

    tasks.each do |task|
      content = "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n"
      content += "sort: #{task[:sort]}\n" if task[:sort]
      content += "---\n# Task"
      File.write(task[:path], content)
    end

    @task_manager.define_singleton_method(:list_tasks) { |context: nil| tasks }

    @scheduler.reschedule(["027"], strategy: :after, reference_task: "025")

    content = File.read(File.join(@temp_dir, "027.md"))
    sort_match = content.match(/sort: (\d+)/)
    refute_nil sort_match
    sort_value = sort_match[1].to_i
    assert sort_value > 100, "Sort value should be greater than 100"
    assert sort_value < 200, "Sort value should be less than 200"
  end

  def test_reschedule_with_before_strategy_places_before_reference
    tasks = [
      { id: "v.0.9.0+task.025", status: "pending", path: File.join(@temp_dir, "025.md"), sort: 100 },
      { id: "v.0.9.0+task.026", status: "pending", path: File.join(@temp_dir, "026.md"), sort: 200 },
      { id: "v.0.9.0+task.027", status: "done", path: File.join(@temp_dir, "027.md") }
    ]

    tasks.each do |task|
      content = "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n"
      content += "sort: #{task[:sort]}\n" if task[:sort]
      content += "---\n# Task"
      File.write(task[:path], content)
    end

    @task_manager.define_singleton_method(:list_tasks) { |context: nil| tasks }

    @scheduler.reschedule(["027"], strategy: :before, reference_task: "026")

    content = File.read(File.join(@temp_dir, "027.md"))
    sort_match = content.match(/sort: (\d+)/)
    refute_nil sort_match
    sort_value = sort_match[1].to_i
    assert sort_value > 100, "Sort value should be greater than 100"
    assert sort_value < 200, "Sort value should be less than 200"
  end

  def test_resolve_task_by_number_only
    tasks = [
      { id: "v.0.9.0+task.025", status: "pending", path: File.join(@temp_dir, "025.md") }
    ]

    tasks.each do |task|
      File.write(task[:path], "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n---\n# Task")
    end

    @task_manager.define_singleton_method(:list_tasks) { |context: nil| tasks }

    # Should not raise error
    @scheduler.reschedule(["025"], strategy: :add_at_end)

    content = File.read(File.join(@temp_dir, "025.md"))
    assert_match(/sort: \d+/, content)
  end

  def test_resolve_task_by_partial_id
    tasks = [
      { id: "v.0.9.0+task.025", status: "pending", path: File.join(@temp_dir, "025.md") }
    ]

    tasks.each do |task|
      File.write(task[:path], "---\nid: #{task[:id]}\nstatus: #{task[:status]}\n---\n# Task")
    end

    @task_manager.define_singleton_method(:list_tasks) { |context: nil| tasks }

    # Should not raise error
    @scheduler.reschedule(["task.025"], strategy: :add_at_end)

    content = File.read(File.join(@temp_dir, "025.md"))
    assert_match(/sort: \d+/, content)
  end

  def test_raises_error_when_no_valid_tasks_found
    @task_manager.define_singleton_method(:list_tasks) { |context: nil| [] }

    error = assert_raises(RuntimeError) do
      @scheduler.reschedule(["999"], strategy: :add_next)
    end

    assert_match(/No valid tasks found/, error.message)
  end

  def test_raises_error_when_reference_task_not_found
    tasks = [
      { id: "v.0.9.0+task.025", status: "pending", path: File.join(@temp_dir, "025.md") }
    ]

    File.write(tasks[0][:path], "---\nid: #{tasks[0][:id]}\nstatus: #{tasks[0][:status]}\n---\n# Task")
    @task_manager.define_singleton_method(:list_tasks) { |context: nil| tasks }

    error = assert_raises(RuntimeError) do
      @scheduler.reschedule(["025"], strategy: :after, reference_task: "999")
    end

    assert_match(/Could not find reference task/, error.message)
  end
end

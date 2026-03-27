# frozen_string_literal: true

require_relative "../test_helper"

class CreateCommandTest < AceAssignTestCase
  class FakeTaskManager
    def initialize(tasks)
      @tasks = tasks
    end

    def show(ref)
      data = @tasks[ref]
      return nil unless data

      FakeTask.new(data)
    end
  end

  class FakeTask
    attr_reader :status, :subtasks

    def initialize(data)
      @status = data[:status]
      @subtasks = Array(data[:subtasks]).map { |entry| FakeSubtask.new(entry[:id], entry[:status]) }
    end
  end

  class FakeSubtask
    attr_reader :id, :status

    def initialize(id, status)
      @id = id
      @status = status
    end
  end

  class FakeExecutor
    attr_reader :path

    def start(path)
      @path = path
      assignment = Struct.new(:name, :id, :cache_dir, :source_config).new(
        "work-on-task-230",
        "8qqgyk",
        File.join(Dir.pwd, ".ace-local", "assign", "8qqgyk"),
        path
      )
      current = Struct.new(:number, :name, :status, :instructions).new("010", "onboard", "in_progress", "Load context")
      {assignment: assignment, current: current}
    end
  end

  def test_create_with_valid_yaml
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      # Temporarily override cache dir
      Ace::Assign.config["cache_dir"] = cache_dir

      result = nil
      output = capture_io do
        result = Ace::Assign::CLI::Commands::Create.new.call(yaml: config_path)
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "Assignment: test-session"
      assert_includes output.first, "Step 010: init"

      Ace::Assign.reset_config!
    end
  end

  def test_create_with_missing_yaml
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Create.new.call(yaml: "nonexistent.yaml")
    end

    assert_equal 3, error.exit_code
    assert_includes error.message, "not found"
  end

  def test_create_quiet_mode
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      output = capture_io do
        Ace::Assign::CLI::Commands::Create.new.call(yaml: config_path, quiet: true)
      end

      assert_empty output.first.strip

      Ace::Assign.reset_config!
    end
  end

  def test_create_prints_hidden_spec_path_for_assign_jobs_source
    with_temp_cache do |cache_dir|
      hidden_jobs_dir = File.join(cache_dir, ".ace-local", "assign", "jobs")
      FileUtils.mkdir_p(hidden_jobs_dir)
      config_path = create_test_config(hidden_jobs_dir, name: "hidden-spec")

      Ace::Assign.config["cache_dir"] = cache_dir

      output = capture_io do
        Ace::Assign::CLI::Commands::Create.new.call(yaml: config_path)
      end

      assert_includes output.first, "Created from hidden spec:"
      assert_includes output.first, ".ace-local/assign/jobs/"

      Ace::Assign.reset_config!
    end
  end

  def test_create_prints_created_path_relative_to_pwd_when_possible
    with_temp_cache do |tmp_dir|
      previous_project_root = ENV["PROJECT_ROOT_PATH"]
      begin
        ENV["PROJECT_ROOT_PATH"] = tmp_dir
        Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!

        Dir.chdir(tmp_dir) do
          hidden_jobs_dir = File.join(".ace-local", "assign", "jobs")
          FileUtils.mkdir_p(hidden_jobs_dir)
          config_path = create_test_config(hidden_jobs_dir, name: "hidden-spec-relative")

          Ace::Assign.config["cache_dir"] = File.join(".ace-local", "assign")

          output = capture_io do
            Ace::Assign::CLI::Commands::Create.new.call(yaml: config_path)
          end

          created_line = output.first.lines.find { |line| line.start_with?("Created: ") }
          refute_nil created_line
          refute_match(%r{\ACreated: /}, created_line)
          assert_includes created_line, ".ace-local/assign/"
        end
      ensure
        if previous_project_root.nil?
          ENV.delete("PROJECT_ROOT_PATH")
        else
          ENV["PROJECT_ROOT_PATH"] = previous_project_root
        end
        Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
        Ace::Assign.reset_config!
      end
    end
  end

  def test_create_requires_exactly_one_mode
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Create.new.call
    end

    assert_equal "Exactly one of --yaml or --task is required", error.message
  end

  def test_create_rejects_both_yaml_and_task
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Create.new.call(yaml: "job.yml", task: ["230"])
    end

    assert_equal "--yaml and --task are mutually exclusive", error.message
  end

  def test_create_rejects_preset_without_task
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Create.new.call(yaml: "job.yml", preset: "work-on-task")
    end

    assert_equal "--preset requires --task", error.message
  end

  def test_task_assignment_creator_rejects_draft_tasks
    creator = Ace::Assign::Organisms::TaskAssignmentCreator.new(
      task_manager: FakeTaskManager.new("400" => {status: "draft"}),
      executor: FakeExecutor.new
    )

    error = assert_raises(Ace::Support::Cli::Error) do
      creator.call(task_refs: ["400"])
    end

    assert_includes error.message, "status 'draft'"
    assert_includes error.message, "/as-task-review 400"
  end

  def test_task_assignment_creator_skips_terminal_refs_and_continues
    executor = FakeExecutor.new
    creator = Ace::Assign::Organisms::TaskAssignmentCreator.new(
      task_manager: FakeTaskManager.new(
        "404" => {status: "done"},
        "405" => {status: "pending"}
      ),
      executor: executor
    )

    result = creator.call(task_refs: ["404", "405"])

    assert_equal ["404"], result[:skipped_terminal]
    assert_equal ["405"], result[:task_refs]
    assert_match(%r{\.ace-local/assign/jobs/work-on-task-405-[0-9a-f]{8}-job\.yml$}, executor.path)
  end

  def test_task_assignment_creator_rejects_all_terminal_refs
    creator = Ace::Assign::Organisms::TaskAssignmentCreator.new(
      task_manager: FakeTaskManager.new(
        "402" => {status: "done"},
        "403" => {status: "skipped"}
      ),
      executor: FakeExecutor.new
    )

    error = assert_raises(Ace::Support::Cli::Error) do
      creator.call(task_refs: ["402", "403"])
    end

    assert_includes error.message, "All requested tasks are already terminal"
    assert_includes error.message, "402"
    assert_includes error.message, "403"
  end

  def test_create_task_mode_creates_assignment_and_step_files_end_to_end
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir
      fake_manager = FakeTaskManager.new("405" => {status: "pending"})

      output = nil
      Ace::Task::Organisms::TaskManager.stub(:new, fake_manager) do
        output = capture_io do
          Ace::Assign::CLI::Commands::Create.new.call(task: ["405"], preset: "work-on-task")
        end
      end

      assignment_id = output.first[/Assignment: .* \(([0-9a-z]+)\)/, 1]
      refute_nil assignment_id

      assignment_dir = File.join(cache_dir, assignment_id)
      assert Dir.exist?(assignment_dir)
      assert Dir.exist?(File.join(assignment_dir, "steps"))

      step_files = Dir.glob(File.join(assignment_dir, "steps", "*.st.md"))
      refute_empty step_files
      assert step_files.any? { |path| File.read(path).include?("work-on-405") }

      Ace::Assign.reset_config!
    end
  end
end

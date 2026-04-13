# frozen_string_literal: true

require_relative "../../test_helper"

class AddCommandTest < AceAssignTestCase
  class FakeTaskManager
    def initialize(existing_refs)
      @existing_refs = existing_refs
    end

    def show(ref)
      return Object.new if @existing_refs.include?(ref)

      nil
    end
  end

  TEST_ITER_COLLISION_PRESET = {
    "name" => "test-iter-collision",
    "steps" => [
      {
        "name" => "review-fit-1",
        "instructions" => "First review",
        "sub_steps" => [
          {"name" => "review-fit-2", "instructions" => "Expanded child"}
        ]
      },
      {"name" => "review-fit-1", "instructions" => "Second review"}
    ]
  }.freeze

  TEST_TASK_TOKENS_PRESET = {
    "name" => "test-task-tokens",
    "expansion" => {
      "child-template" => {
        "name" => "work-on-{{item}}",
        "instructions" => "Implement {{item}} from {{task_id}}"
      }
    }
  }.freeze

  def with_preset_loader_stubs(presets = {})
    original = Ace::Assign::Atoms::PresetLoader.method(:load)
    Ace::Assign::Atoms::PresetLoader.stub(:load, ->(preset_name) do
      presets.fetch(preset_name.to_s) { original.call(preset_name) }
    end) do
      yield
    end
  end

  def test_add_with_yaml_inserts_steps
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      steps_path = File.join(cache_dir, "batch-steps.yml")
      File.write(steps_path, {
        "steps" => [
          {"name" => "review-security", "instructions" => "Review auth changes"},
          {"name" => "review-performance", "instructions" => "Profile endpoints"}
        ]
      }.to_yaml)

      Ace::Assign.config["cache_dir"] = cache_dir
      build_fast_executor(cache_base: cache_dir).start(config_path)

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Add.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(yaml: steps_path, after: "010")
        end
      end

      assert_includes output.first, "Added 2 step(s) from batch-steps.yml"
      assert_includes output.first, "011: review-security"
      assert_includes output.first, "012: review-performance"

      Ace::Assign.reset_config!
    end
  end

  def test_add_requires_exactly_one_mode
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Add.new.call
    end

    assert_includes error.message, "Exactly one of --yaml, --step, or --task is required"
  end

  def test_add_rejects_multiple_modes
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Add.new.call(step: "review-fit", task: "t.123")
    end

    assert_includes error.message, "mutually exclusive"
  end

  def test_add_rejects_preset_without_step_or_task
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Add.new.call(yaml: "steps.yml", preset: "work-on-task")
    end

    assert_includes error.message, "--preset requires --step or --task"
  end

  def test_add_step_mode_uses_base_name_matching_and_auto_iteration
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [
        {"name" => "seed", "instructions" => "Seed"},
        {"name" => "review-fit-1", "instructions" => "Existing cycle"}
      ])

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Add.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(step: "review-fit", preset: "work-on-task", after: "010")
        end
      end

      assert_includes output.first, "Added review-fit-2"
      state = executor.status[:state]
      assert state.steps.any? { |step| step.name == "review-fit-2" }

      Ace::Assign.reset_config!
    end
  end

  def test_add_task_mode_auto_detects_batch_parent
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [
        {"name" => "batch-tasks", "instructions" => "Batch container"},
        {"name" => "finalize", "instructions" => "Finalize"}
      ])

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Add.new
        command.stub(:task_manager, FakeTaskManager.new(["t.456"])) do
          with_fast_command_executor(command, cache_base: cache_dir) do
            command.call(task: "t.456", preset: "work-on-task")
          end
        end
      end

      assert_includes output.first, "Added task t.456 under 010"
      state = executor.status[:state]
      assert state.steps.any? { |step| step.name == "work-on-t.456" }

      Ace::Assign.reset_config!
    end
  end

  def test_add_task_mode_errors_when_batch_parent_not_found
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir
      build_fast_executor(cache_base: cache_dir).start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        command = Ace::Assign::CLI::Commands::Add.new
        command.stub(:task_manager, FakeTaskManager.new(["t.456"])) do
          with_fast_command_executor(command, cache_base: cache_dir) do
            command.call(task: "t.456", preset: "work-on-task")
          end
        end
      end

      assert_includes error.message, "No batch parent found"
      Ace::Assign.reset_config!
    end
  end

  def test_add_task_mode_validates_task_reference_exists
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [
        {"name" => "batch-tasks", "instructions" => "Batch container"}
      ])

      Ace::Assign.config["cache_dir"] = cache_dir
      build_fast_executor(cache_base: cache_dir).start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        command = Ace::Assign::CLI::Commands::Add.new
        command.stub(:task_manager, FakeTaskManager.new([])) do
          with_fast_command_executor(command, cache_base: cache_dir) do
            command.call(task: "t.missing", preset: "work-on-task")
          end
        end
      end

      assert_equal "Task not found: t.missing", error.message
      Ace::Assign.reset_config!
    end
  end

  def test_add_task_mode_respects_after_without_child_as_sibling_insertion
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [
        {"name" => "seed", "instructions" => "Seed"},
        {"name" => "batch-tasks", "instructions" => "Batch container"},
        {"name" => "finalize", "instructions" => "Finalize"}
      ])

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Add.new
        command.stub(:task_manager, FakeTaskManager.new(["t.900"])) do
          with_fast_command_executor(command, cache_base: cache_dir) do
            command.call(task: "t.900", preset: "work-on-task", after: "010")
          end
        end
      end

      assert_includes output.first, "Added task t.900 after 010"

      state = executor.status[:state]
      inserted = state.top_level.find { |step| step.name == "work-on-t.900" }
      assert inserted
      assert_equal "011", inserted.number

      Ace::Assign.reset_config!
    end
  end

  def test_add_step_mode_refreshes_existing_names_between_preset_insertions
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "seed", "instructions" => "Seed"}])

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      capture_io do
        command = Ace::Assign::CLI::Commands::Add.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          with_preset_loader_stubs("test-iter-collision" => TEST_ITER_COLLISION_PRESET) do
            command.call(step: "review-fit,review-fit", preset: "test-iter-collision", after: "010")
          end
        end
      end

      state = executor.status[:state]
      top_level_names = state.top_level.map(&:name)
      assert_includes top_level_names, "review-fit-1"
      assert_includes top_level_names, "review-fit-3"
      assert state.steps.any? { |step| step.name == "review-fit-2" && step.number.start_with?("011.") }

      Ace::Assign.reset_config!
    end
  end

  def test_add_task_mode_warns_for_unexpanded_tokens_in_debug_mode
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [
        {"name" => "batch-tasks", "instructions" => "Batch container"},
        {"name" => "finalize", "instructions" => "Finalize"}
      ])

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Add.new
        command.stub(:task_manager, FakeTaskManager.new(["t.789"])) do
          with_fast_command_executor(command, cache_base: cache_dir) do
            with_preset_loader_stubs("test-task-tokens" => TEST_TASK_TOKENS_PRESET) do
              command.call(task: "t.789", preset: "test-task-tokens", debug: true)
            end
          end
        end
      end

      assert_includes output.last, "Unexpanded preset template token(s): {{task_id}}"
      inserted = executor.status[:state].steps.find { |step| step.name == "work-on-t.789" }
      assert inserted
      assert_includes inserted.instructions, "{{task_id}}"

      Ace::Assign.reset_config!
    end
  end

  def test_add_rejects_invalid_after_reference_with_available_steps
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir
      build_fast_executor(cache_base: cache_dir).start(config_path)

      error = assert_raises(Ace::Assign::StepErrors::NotFound) do
        command = Ace::Assign::CLI::Commands::Add.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(step: "review-fit", preset: "work-on-task", after: "999")
        end
      end

      assert_equal "Step 999 not found. Available steps: 010, 020, 030", error.message
    ensure
      Ace::Assign.reset_config!
    end
  end
end

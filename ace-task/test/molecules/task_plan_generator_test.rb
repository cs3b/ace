# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "ace/task/molecules/task_plan_generator"

class TaskPlanGeneratorTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-plan-generator-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
    create_minimal_project_preset!

    @task_file = File.join(@tmpdir, "task.s.md")
    File.write(@task_file, <<~TASK)
      ---
      id: 8pp.t.q7w
      status: pending
      ---

      # Task
    TASK

    @task = Struct.new(:id, :file_path).new("8pp.t.q7w", @task_file)
    @client = Class.new do
      class << self
        attr_accessor :next_response, :last_args, :last_kwargs
      end

      def self.query(*args, **kwargs)
        @last_args = args
        @last_kwargs = kwargs
        next_response
      end
    end
    @generator = Ace::Task::Molecules::TaskPlanGenerator.new(
      model: "gemini:flash-latest",
      client: @client
    )
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_generate_returns_text_from_backend
    @client.next_response = {text: "# Generated Plan\n"}
    result = @generator.generate(task: @task, context_files: [])
    assert_equal "# Generated Plan", result
  end

  def test_generate_raises_when_backend_returns_empty
    @client.next_response = {text: "  "}
    error = assert_raises(Ace::Support::Cli::Error) do
      @generator.generate(task: @task, context_files: [])
    end

    assert_includes error.message, "empty output"
  end

  def test_generate_with_cache_dir_uses_file_based_prompts
    @client.next_response = {text: "# Plan from files\n"}
    cache_dir = File.join(@tmpdir, ".cache", "ace-task", "8pp.t.q7w")

    result = @generator.generate(task: @task, context_files: [], cache_dir: cache_dir)

    assert_equal "# Plan from files", result
    assert_equal "gemini:flash-latest", @client.last_args[0]
    refute_nil @client.last_args[1], "Prompt content should be read from file"
    refute_nil @client.last_kwargs[:system], "System content should be read from file"
  end

  def test_generate_threads_cli_args_to_file_based_query
    @client.next_response = {text: "# Plan from files\n"}
    generator = Ace::Task::Molecules::TaskPlanGenerator.new(
      model: "gemini:flash-latest",
      client: @client,
      cli_args: "--approval-mode plan"
    )
    cache_dir = File.join(@tmpdir, ".cache", "ace-task", "8pp.t.q7w")

    generator.generate(task: @task, context_files: [], cache_dir: cache_dir)

    assert_equal "--approval-mode plan", @client.last_kwargs[:cli_args]
  end

  def test_generate_with_cache_dir_stores_prompt_paths
    @client.next_response = {text: "# Plan\n"}
    cache_dir = File.join(@tmpdir, ".cache", "ace-task", "8pp.t.q7w")

    @generator.generate(task: @task, context_files: [], cache_dir: cache_dir)

    assert @generator.prompt_paths, "prompt_paths should be set after file-based generate"
    assert @generator.prompt_paths[:system_file]
    assert @generator.prompt_paths[:prompt_file]
  end

  def test_generate_without_cache_dir_uses_inline_prompt
    @client.next_response = {text: "# Inline plan\n"}

    result = @generator.generate(task: @task, context_files: [])

    assert_equal "# Inline plan", result
    assert_nil @generator.prompt_paths, "prompt_paths should be nil for inline mode"
    assert_nil @client.last_kwargs[:system_file]
    assert_nil @client.last_kwargs[:prompt_file]
    refute_nil @client.last_args[1], "Inline prompt string should be passed"
  end

  def test_generate_threads_cli_args_to_inline_query
    @client.next_response = {text: "# Inline plan\n"}
    generator = Ace::Task::Molecules::TaskPlanGenerator.new(
      model: "gemini:flash-latest",
      client: @client,
      cli_args: "--approval-mode plan"
    )

    generator.generate(task: @task, context_files: [])

    assert_equal "--approval-mode plan", @client.last_kwargs[:cli_args]
  end

  def test_prompt_files_written_to_prompts_subdirectory
    @client.next_response = {text: "# Plan\n"}
    cache_dir = File.join(@tmpdir, ".cache", "ace-task", "8pp.t.q7w")

    @generator.generate(task: @task, context_files: [], cache_dir: cache_dir)

    prompts_dir = File.join(cache_dir, "prompts")
    assert Dir.exist?(prompts_dir)
    system_files = Dir.glob(File.join(prompts_dir, "*-system.md"))
    user_files = Dir.glob(File.join(prompts_dir, "*-user.md"))
    assert_equal 1, system_files.length
    assert_equal 1, user_files.length
  end

  private

  def create_minimal_project_preset!
    preset_dir = File.join(@tmpdir, ".ace", "bundle", "presets")
    FileUtils.mkdir_p(preset_dir)
    File.write(File.join(preset_dir, "project.md"), <<~PRESET)
      ---
      description: Test project context
      bundle:
        files: []
      ---
    PRESET
  end
end

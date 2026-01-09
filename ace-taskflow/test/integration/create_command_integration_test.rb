# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core"
require "ace/taskflow/commands/task/create"
require "ace/taskflow/commands/task_command"

# Integration tests for the Create command (nested dry-cli subcommand)
# Tests actual file creation, dry-run behavior, and end-to-end command execution.
class CreateCommandIntegrationTest < AceTaskflowTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    super
    @command = Ace::Taskflow::Commands::Task::Create.new
  end

  # Test: Dry-run mode shows preview without creating files
  def test_dry_run_mode_shows_preview_without_creating_files
    with_real_test_project do |dir|
      output = capture_stdout do
        @command.call(title: "Dry run test task", :"dry-run" => true)
      end

      # Should show dry-run preview
      assert_match(/\[DRY-RUN\] Would create task/, output)
      assert_match(/Dry run test task/, output)

      # Should NOT create any new task files
      new_tasks = Dir.glob(File.join(dir, ".ace-taskflow/v.0.9.0/t/**/dry-run-*.s.md"))
      assert_empty new_tasks, "Dry-run should not create task files"
    end
  end

  # Test: Actual task creation produces file
  def test_create_task_produces_file
    with_real_test_project do |dir|
      # Mock LLM for slug generation
      stub_llm_slug_generation("integration-test", "integration-test")

      output = capture_stdout do
        @command.call(title: "Integration test task")
      end

      # Should show success message
      assert_match(/Created task/, output)
      assert_match(/Path:/, output)

      # Should create a task file (pattern: NNN-*.s.md)
      task_files = Dir.glob(File.join(dir, ".ace-taskflow/v.0.9.0/t/**/*.s.md"))
      new_task = task_files.find { |f| f.include?("integration-test") }
      assert new_task, "Should create task file"
      assert File.exist?(new_task), "Task file should exist on filesystem"
    end
  end

  # Test: Create with all metadata options
  def test_create_with_metadata_options
    with_real_test_project do |_dir|
      stub_llm_slug_generation("full-options", "full-options")

      output = capture_stdout do
        @command.call(
          title: "Full options task",
          status: "draft",
          estimate: "4h",
          release: "v.0.9.0"
        )
      end

      assert_match(/Created task/, output)
      assert_match(/Path:/, output)
    end
  end

  # Test: Missing title returns error
  def test_missing_title_returns_error
    with_real_test_project do |_dir|
      output = capture_stdout do
        exit_code = @command.call(title: nil)
        assert_equal 1, exit_code
      end

      assert_match(/Error: Task title is required/, output)
    end
  end

  # Test: Title precedence (--title option wins over positional title argument)
  # In dry-cli, positional argument is passed as keyword: title: "positional"
  # while --title flag is also title: but takes precedence in build_args_for_create
  def test_title_flag_takes_precedence_over_positional
    with_real_test_project do |_dir|
      stub_llm_slug_generation("flag-title", "flag-title")

      # Simulate: ace-taskflow task create "Positional" --title "Flag title"
      # dry-cli would call: call(title: "Positional", title: "Flag title")
      # but Ruby only allows one key, so we test the args building directly
      args = @command.send(:build_args_for_create, "Positional title", title: "Flag title")

      # The --title flag should take precedence
      assert_equal ["Flag title"], args
    end
  end

  private

  # Capture stdout during block execution
  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  # Stub LLM slug generation for predictable test output
  def stub_llm_slug_generation(folder_slug, file_slug)
    Ace::Taskflow::Molecules::LlmSlugGenerator.define_method(:generate_task_slugs) do |_title, _metadata|
      { folder_slug: folder_slug, file_slug: file_slug, source: :stub }
    end
  end
end

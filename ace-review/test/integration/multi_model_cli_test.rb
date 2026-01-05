# frozen_string_literal: true

require "test_helper"
require "ace/review/cli"
require "ace/review/commands/review_command"

# Tests for ReviewCommand option processing (migrated from OptionParser to Thor)
# These tests verify that Thor CLI options are processed correctly by ReviewCommand
class ReviewCommandOptionsTest < Minitest::Test
  # Test model parsing - comma-separated models in single flag
  def test_command_parses_comma_separated_models
    # Thor's repeatable option would give us an array with one element
    command = Ace::Review::Commands::ReviewCommand.new([], {
      model: ["gemini,gpt-4,claude"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Verify models were parsed and split correctly
    assert_equal ["gemini", "gpt-4", "claude"], options[:model]
  end

  # Test model parsing - multiple --model flags
  def test_command_parses_repeated_model_flags
    # Thor's repeatable option gives us array of values
    command = Ace::Review::Commands::ReviewCommand.new([], {
      model: ["gemini", "gpt-4"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Verify models were collected
    assert_equal ["gemini", "gpt-4"], options[:model]
  end

  # Test model deduplication
  def test_command_deduplicates_models
    command = Ace::Review::Commands::ReviewCommand.new([], {
      model: ["gemini,gemini,gpt-4"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Verify duplicates were removed
    assert_equal ["gemini", "gpt-4"], options[:model]
  end

  # Test single subject parsing
  def test_command_parses_single_subject_flag
    command = Ace::Review::Commands::ReviewCommand.new([], {
      subject: ["diff:HEAD~3"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Single subject should be passed as string (backward compatible)
    assert_equal "diff:HEAD~3", options[:subject]
  end

  # Test multiple subjects parsing
  def test_command_parses_multiple_subject_flags_as_array
    command = Ace::Review::Commands::ReviewCommand.new([], {
      subject: ["diff:HEAD~3", "files:*.md"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Multiple subjects should be passed as array
    assert_equal ["diff:HEAD~3", "files:*.md"], options[:subject]
  end

  # Test three or more subjects
  def test_command_normalizes_three_or_more_subjects
    command = Ace::Review::Commands::ReviewCommand.new([], {
      subject: ["pr:77", "files:README.md", "diff:HEAD~1"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Three or more subjects should all be in the array
    assert_equal ["pr:77", "files:README.md", "diff:HEAD~1"], options[:subject]
  end

  # Test subject deduplication
  def test_command_deduplicates_subjects
    command = Ace::Review::Commands::ReviewCommand.new([], {
      subject: ["diff:HEAD~3", "diff:HEAD~3", "files:*.md"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Duplicate subjects should be removed
    assert_equal ["diff:HEAD~3", "files:*.md"], options[:subject]
  end

  # Test empty subject filtering
  def test_command_rejects_empty_subject_strings
    command = Ace::Review::Commands::ReviewCommand.new([], {
      subject: ["", "diff:HEAD~3"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Empty subjects should be filtered out, single remaining subject as string
    assert_equal "diff:HEAD~3", options[:subject]
  end

  # Test whitespace-only subject filtering
  def test_command_rejects_whitespace_only_subjects
    command = Ace::Review::Commands::ReviewCommand.new([], {
      subject: ["   ", "diff:HEAD~3"],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # Whitespace-only subjects should be filtered out
    assert_equal "diff:HEAD~3", options[:subject]
  end

  # Test all empty subjects results in nil
  def test_command_no_subject_when_all_empty
    command = Ace::Review::Commands::ReviewCommand.new([], {
      subject: ["", "   "],
      preset: "pr"
    })

    options = command.instance_variable_get(:@options)

    # When all subjects are empty, subject should be nil
    assert_nil options[:subject]
  end

  # Test PR comments flag enabled
  def test_command_preserves_pr_comments_flag_enabled
    command = Ace::Review::Commands::ReviewCommand.new([], {
      pr: "123",
      pr_comments: true
    })

    options = command.instance_variable_get(:@options)

    assert_equal true, options[:pr_comments]
  end

  # Test PR comments flag disabled (--no-pr-comments)
  def test_command_preserves_no_pr_comments_flag
    command = Ace::Review::Commands::ReviewCommand.new([], {
      pr: "123",
      pr_comments: false
    })

    options = command.instance_variable_get(:@options)

    assert_equal false, options[:pr_comments]
  end

  # Test PR comments default (not specified)
  def test_command_pr_comments_default_when_not_specified
    command = Ace::Review::Commands::ReviewCommand.new([], {
      pr: "123"
    })

    options = command.instance_variable_get(:@options)

    # When not specified, pr_comments should be nil (defaults handled by ReviewOptions)
    assert_nil options[:pr_comments]
  end
end

# Tests for ReviewOptions model (unchanged from original)
class ReviewOptionsModelTest < Minitest::Test
  def test_review_options_effective_models_with_array
    options = Ace::Review::Models::ReviewOptions.new(
      models: ["gemini", "gpt-4", "claude"]
    )

    effective = options.effective_models

    assert_equal ["gemini", "gpt-4", "claude"], effective
  end

  def test_review_options_effective_models_with_single_model
    options = Ace::Review::Models::ReviewOptions.new(
      model: "gemini"
    )

    effective = options.effective_models

    assert_equal ["gemini"], effective
  end

  def test_review_options_effective_models_with_config_array
    options = Ace::Review::Models::ReviewOptions.new

    effective = options.effective_models(["gemini", "gpt-4"])

    assert_equal ["gemini", "gpt-4"], effective
  end

  def test_review_options_models_array_overrides_model_scalar
    options = Ace::Review::Models::ReviewOptions.new(
      model: "gemini",
      models: ["gpt-4", "claude"]
    )

    effective = options.effective_models

    # models array should take precedence
    assert_equal ["gpt-4", "claude"], effective
  end

  def test_effective_model_uses_models_array_first_element
    options = Ace::Review::Models::ReviewOptions.new(
      models: ["gpt-4", "claude"]
    )

    # effective_model should return the first model from the array
    assert_equal "gpt-4", options.effective_model
  end

  def test_effective_model_prefers_scalar_over_array
    options = Ace::Review::Models::ReviewOptions.new(
      model: "gemini",
      models: ["gpt-4", "claude"]
    )

    # scalar model should take precedence
    assert_equal "gemini", options.effective_model
  end

  def test_effective_model_falls_back_to_config
    options = Ace::Review::Models::ReviewOptions.new

    # should use config model when no CLI models
    assert_equal "custom-model", options.effective_model("custom-model")
  end

  def test_effective_model_uses_default_when_nothing_set
    options = Ace::Review::Models::ReviewOptions.new

    # should use default when nothing is set
    assert_equal "google:gemini-2.5-flash", options.effective_model
  end
end

# Tests for MultiModelExecutor (unchanged from original)
class MultiModelExecutorTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_executor_passes_output_file_to_llm_executor
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 1)

    # Track what arguments are passed to LlmExecutor
    captured_calls = []

    # Stub the LlmExecutor#execute method
    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      captured_calls << args
      {
        success: true,
        response: "test response",
        output_file: args[:output_file],
        metadata: {}
      }
    } do
      result = executor.execute(
        models: ["test-model"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )

      assert result[:success]
      assert_equal 1, captured_calls.size

      # Verify output_file was passed
      call = captured_calls.first
      assert call.key?(:output_file), "output_file should be passed to LlmExecutor"
      assert_match %r{review-test-model\.md$}, call[:output_file]
    end
  end

  def test_executor_returns_correct_output_files
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 2)

    # Stub to return success with the provided output_file
    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      # Actually create the file to simulate real behavior
      File.write(args[:output_file], "test content for #{args[:model]}")
      {
        success: true,
        response: "test response",
        output_file: args[:output_file],
        metadata: {}
      }
    } do
      result = executor.execute(
        models: ["google:gemini-2.5-flash", "openai:gpt-4"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )

      assert result[:success]
      assert_equal 2, result[:results].size

      # Verify each model has correct output file that exists
      result[:results].each do |model, model_result|
        assert model_result[:success], "Model #{model} should succeed"
        assert model_result[:output_file], "Model #{model} should have output_file"
        assert File.exist?(model_result[:output_file]), "Output file should exist: #{model_result[:output_file]}"
      end
    end
  end

  def test_executor_handles_partial_failures
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 2)

    call_count = 0
    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      call_count += 1
      if args[:model] == "failing-model"
        { success: false, error: "API error", response: nil }
      else
        File.write(args[:output_file], "success")
        { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
      end
    } do
      result = executor.execute(
        models: ["good-model", "failing-model"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )

      # Should still be considered success if at least one model succeeds
      assert result[:success]
      assert_equal 2, result[:summary][:total_models]
      assert_equal 1, result[:summary][:success_count]
      assert_equal 1, result[:summary][:failure_count]

      # Verify individual results
      assert result[:results]["good-model"][:success]
      refute result[:results]["failing-model"][:success]
    end
  end

  def test_executor_generates_correct_model_slugs
    executor = Ace::Review::Molecules::MultiModelExecutor.new(max_concurrent: 1)

    executor.instance_variable_get(:@llm_executor).stub :execute, ->(args) {
      File.write(args[:output_file], "test")
      { success: true, response: "ok", output_file: args[:output_file], metadata: {} }
    } do
      result = executor.execute(
        models: ["google:gemini-2.5-flash"],
        system_prompt: "system",
        user_prompt: "user",
        session_dir: @tmpdir
      )

      model_result = result[:results]["google:gemini-2.5-flash"]
      assert_equal "google-gemini-2-5-flash", model_result[:model_slug]
      assert_match %r{review-google-gemini-2-5-flash\.md$}, model_result[:output_file]
    end
  end
end

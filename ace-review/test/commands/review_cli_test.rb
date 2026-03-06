# frozen_string_literal: true

require "test_helper"
require "ace/review/cli"
require "dry/cli"

class ReviewCliTest < AceReviewTest
  def setup
    super
    @original_home = ENV["HOME"]
    ENV["HOME"] = @test_dir
    Ace::Review.reset_config!
    create_test_preset("code-valid", <<~YAML)
      description: "Test code-valid preset"
      reviewers:
        - name: correctness
          providers:
            - llm:google:google:gemini-2.5-flash
          prompt:
            base: "prompt://base/system"
      subject:
        content: "def test; end"
    YAML
  end

  def teardown
    ENV["HOME"] = @original_home
    Ace::Review.reset_config!
    super
  end

  def invoke_cli(args)
    stdout, stderr = capture_io do
      begin
        @_cli_result = Dry::CLI.new(Ace::Review::CLI::Commands::Review).call(arguments: args)
      rescue SystemExit => e
        @_cli_result = e.status
      rescue StandardError => e
        $stderr.puts e.message
        @_cli_result = 1
      end
    end

    { stdout: stdout, stderr: stderr, result: @_cli_result }
  end

  def test_help_does_not_list_removed_prompt_override_flags
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    refute_match(/--prompt-base/, output)
    refute_match(/--prompt-format/, output)
    refute_match(/--prompt-focus/, output)
    refute_match(/--add-focus/, output)
    refute_match(/--prompt-guidelines/, output)
  end

  def test_removed_prompt_override_flag_is_rejected
    result = invoke_cli(["--prompt-focus", "prompt://focus/phase/correctness"])
    output = result[:stdout] + result[:stderr]

    assert_match(/prompt-focus/, output)
    refute_equal 0, result[:result]
  end

  def test_invalid_model_name_fails_with_clear_error
    result = invoke_cli(["--preset", "code-valid", "--model", "invalid/model", "--dry-run"])
    output = result[:stdout] + result[:stderr]

    assert_equal 1, result[:result]
    assert_match(/Invalid model name 'invalid\/model'/, output)
    refute_match(/in `/, output)
  end

  def test_model_name_with_preset_suffix_is_allowed
    result = invoke_cli(["--preset", "code-valid", "--model", "codex:codex-review-deep@review-deep", "--dry-run"])
    output = result[:stdout] + result[:stderr]

    assert_includes [0, nil], result[:result]
    refute_match(/Invalid model name/, output)
  end

  def test_help_lists_provider_override_flag
    result = invoke_cli(["--help"])
    output = result[:stdout] + result[:stderr]

    assert_match(/--provider/, output)
    assert_match(/repeatable/i, output)
  end

  def test_invalid_provider_ref_fails_with_clear_error
    result = invoke_cli(["--preset", "code-valid", "--provider", "fast", "--dry-run"])
    output = result[:stdout] + result[:stderr]

    assert_equal 1, result[:result]
    assert_match(/Invalid provider reference 'fast'/, output)
    assert_match(/target is required|llm:<target>:<model>/, output)
  end

  def test_provider_override_conflicts_with_cli_models
    result = invoke_cli(["--preset", "code-valid", "--provider", "llm:codex:codex@review-deep", "--model", "codex:codex", "--dry-run"])
    output = result[:stdout] + result[:stderr]

    assert_equal 1, result[:result]
    assert_match(/cannot be combined with --model\/--models/i, output)
  end

  def test_provider_override_supports_repeated_flags
    result = invoke_cli([
      "--preset", "code-valid",
      "--provider", "llm:codex:codex@review-deep",
      "--provider", "llm:claude:anthropic:claude-3-7-sonnet",
      "--dry-run"
    ])

    output = result[:stdout] + result[:stderr]
    assert_includes [0, nil], result[:result], output
  end
end

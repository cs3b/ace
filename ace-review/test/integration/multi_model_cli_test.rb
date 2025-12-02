# frozen_string_literal: true

require "test_helper"
require "ace/review/cli"
require "tmpdir"

class MultiModelCliTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)

    # Create minimal git repo
    system("git init -q")
    system("git config user.email 'test@example.com'")
    system("git config user.name 'Test User'")

    # Create a test file and commit
    File.write("test.rb", "# test file")
    system("git add test.rb")
    system("git commit -q -m 'initial'")
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_cli_parses_comma_separated_models
    cli = Ace::Review::CLI.new

    # Simulate parsing --model "gemini,gpt-4,claude"
    argv = ["--preset", "pr", "--model", "gemini,gpt-4,claude", "--dry-run"]

    # Parse options (private method, but we can test indirectly via run)
    cli.instance_variable_set(:@options, { preset: "pr", save_session: true })
    cli.send(:parse_options, argv)

    options = cli.instance_variable_get(:@options)

    # Verify models were parsed correctly
    assert_equal ["gemini", "gpt-4", "claude"], options[:models]
  end

  def test_cli_parses_repeated_model_flags
    cli = Ace::Review::CLI.new

    # Simulate parsing multiple --model flags
    argv = ["--preset", "pr", "--model", "gemini", "--model", "gpt-4", "--dry-run"]

    cli.instance_variable_set(:@options, { preset: "pr", save_session: true })
    cli.send(:parse_options, argv)

    options = cli.instance_variable_get(:@options)

    # Verify models were collected
    assert_equal ["gemini", "gpt-4"], options[:models]
  end

  def test_cli_deduplicates_models
    cli = Ace::Review::CLI.new

    # Simulate parsing duplicate models
    argv = ["--preset", "pr", "--model", "gemini,gemini,gpt-4", "--dry-run"]

    cli.instance_variable_set(:@options, { preset: "pr", save_session: true })
    cli.send(:parse_options, argv)

    options = cli.instance_variable_get(:@options)

    # Verify duplicates were removed
    assert_equal ["gemini", "gpt-4"], options[:models]
  end

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
end

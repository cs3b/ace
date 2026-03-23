# frozen_string_literal: true

require_relative "../test_helper"
require "ace/core/atoms/config_summary"
require "stringio"

class ConfigSummaryTest < Minitest::Test
  def setup
    @original_stderr = $stderr
    $stderr = StringIO.new
  end

  def teardown
    $stderr = @original_stderr
  end

  def test_display_outputs_to_stderr
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {verbose: true}
    )

    output = $stderr.string
    assert_match(/Config:/, output)
    assert_match(/model=gflash/, output)
  end

  def test_display_with_nested_config
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {llm: {provider: "google", model: "gemini"}},
      defaults: {},
      options: {verbose: true}
    )

    output = $stderr.string
    assert_match(/llm.provider=google/, output)
    assert_match(/llm.model=gemini/, output)
  end

  def test_quiet_suppresses_output
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {},
      quiet: true
    )

    assert_empty $stderr.string
  end

  def test_only_non_default_values_shown
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {model: "gflash", format: "markdown", timeout: 30},
      defaults: {"model" => "glite", "format" => "markdown", "timeout" => 30},
      options: {verbose: true}
    )

    output = $stderr.string
    # Only model should show (differs from default)
    assert_match(/model=gflash/, output)
    refute_match(/format=markdown/, output)
    refute_match(/timeout=30/, output)
  end

  def test_allowlist_filtering
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {model: "gflash", format: "markdown", verbose: true},
      defaults: {},
      options: {verbose: true},
      summary_keys: %w[model format]
    )

    output = $stderr.string
    assert_match(/model=gflash/, output)
    assert_match(/format=markdown/, output)
    refute_match(/verbose=true/, output)
  end

  def test_sensitive_key_filtering
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {
        api_key: "secret123",
        max_tokens: 1000,
        keyboard_layout: "us",
        auth_token: "token123"
      },
      defaults: {},
      options: {verbose: true}
    )

    output = $stderr.string
    # api_key should be filtered (ends with key)
    refute_match(/api_key/, output)
    # auth_token should be filtered (ends with token)
    refute_match(/auth_token/, output)
    # max_tokens should show (contains "token" but doesn't end with it)
    assert_match(/max_tokens=1000/, output)
    # keyboard_layout should show (contains "key" but doesn't end with it)
    assert_match(/keyboard_layout=us/, output)
  end

  def test_sensitive_key_with_underscore_prefix
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {_secret: "hidden", public_key: "visible"},
      defaults: {},
      options: {verbose: true}
    )

    output = $stderr.string
    # _secret should be filtered (ends with secret)
    refute_match(/_secret/, output)
    # public_key should be filtered (ends with key)
    refute_match(/public_key/, output)
  end

  def test_cli_options_shown
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {},
      defaults: {},
      options: {verbose: true, dry_run: true}
    )

    output = $stderr.string
    assert_match(/verbose=true/, output)
    assert_match(/dry_run=true/, output)
  end

  def test_array_values_joined
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {files: ["file1.rb", "file2.rb", "file3.rb"]},
      defaults: {},
      options: {verbose: true}
    )

    output = $stderr.string
    assert_match(/files=file1.rb,file2.rb,file3.rb/, output)
  end

  def test_keys_are_sorted
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {zebra: 1, apple: 2, model: "gflash"},
      defaults: {},
      options: {verbose: true}
    )

    output = $stderr.string
    # Check order: apple comes before model comes before zebra
    apple_pos = output.index("apple=")
    model_pos = output.index("model=")
    zebra_pos = output.index("zebra=")
    assert apple_pos < model_pos, "apple should come before model"
    assert model_pos < zebra_pos, "model should come before zebra"
  end

  def test_empty_summary_produces_no_output
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {value: 1},
      defaults: {"value" => 1},
      options: {}
    )

    # No "Config:" output when empty
    refute_match(/Config:/, $stderr.string)
  end

  def test_cli_options_take_precedence_over_config
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {model: "glite"},
      defaults: {"model" => "glite"},
      options: {model: "gflash", verbose: true}
    )

    output = $stderr.string
    # CLI option should be shown (not config, since it's same as default)
    assert_match(/model=gflash/, output)
  end

  def test_false_and_nil_options_not_shown
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {},
      defaults: {},
      options: {verbose: false, debug: nil, quiet: false}
    )

    output = $stderr.string
    # false and nil options should not be shown
    refute_match(/verbose/, output)
    refute_match(/debug/, output)
    refute_match(/quiet/, output)
  end

  def test_true_boolean_shown_as_true
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {},
      defaults: {},
      options: {verbose: true}
    )

    output = $stderr.string
    assert_match(/verbose=true/, output)
  end

  def test_config_and_options_combined
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {model: "gflash", preset: "code-review"},
      defaults: {"model" => "glite"},
      options: {verbose: true}
    )

    output = $stderr.string
    assert_match(/model=gflash/, output)
    assert_match(/preset=code-review/, output)
    assert_match(/verbose=true/, output)
  end

  def test_nested_keys_flattened_with_dots
    result = Ace::Core::Atoms::ConfigSummary.new(
      "test",
      {llm: {provider: "google", settings: {temperature: 0.7}}},
      {},
      {},
      nil
    ).build

    assert_equal "llm.provider=google llm.settings.temperature=0.7", result
  end

  def test_empty_config_and_options
    Ace::Core::Atoms::ConfigSummary.display(
      command: "test",
      config: {},
      defaults: {},
      options: {}
    )

    # No output when everything is empty
    refute_match(/Config:/, $stderr.string)
  end

  # Tests for display_if_needed method
  def test_display_if_needed_shows_when_verbose_and_no_help
    Ace::Core::Atoms::ConfigSummary.display_if_needed(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {verbose: true},
      args: []
    )

    output = $stderr.string
    assert_match(/Config:/, output)
    assert_match(/model=gflash/, output)
  end

  def test_display_if_needed_skips_when_verbose_false
    Ace::Core::Atoms::ConfigSummary.display_if_needed(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {verbose: false},
      args: []
    )

    refute_match(/Config:/, $stderr.string)
  end

  def test_display_if_needed_skips_when_help_requested_via_options
    Ace::Core::Atoms::ConfigSummary.display_if_needed(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {help: true, verbose: true},
      args: []
    )

    # Should not display when help is requested
    refute_match(/Config:/, $stderr.string)
  end

  def test_display_if_needed_skips_when_help_requested_via_args
    Ace::Core::Atoms::ConfigSummary.display_if_needed(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {verbose: true},
      args: ["--help"]
    )

    # Should not display when help is requested via args
    refute_match(/Config:/, $stderr.string)
  end

  def test_display_if_needed_skips_when_short_help_in_args
    Ace::Core::Atoms::ConfigSummary.display_if_needed(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {verbose: true},
      args: ["-h"]
    )

    # Should not display when -h is in args
    refute_match(/Config:/, $stderr.string)
  end

  def test_display_if_needed_skips_when_h_option_true
    Ace::Core::Atoms::ConfigSummary.display_if_needed(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {h: true, verbose: true},
      args: []
    )

    # Should not display when h option is true
    refute_match(/Config:/, $stderr.string)
  end

  def test_display_if_needed_respects_quiet_flag
    Ace::Core::Atoms::ConfigSummary.display_if_needed(
      command: "test",
      config: {model: "gflash"},
      defaults: {},
      options: {verbose: true},
      args: [],
      quiet: true
    )

    # Quiet flag should suppress output
    refute_match(/Config:/, $stderr.string)
  end

  # Tests for help_requested? method
  def test_help_requested_with_help_option
    assert Ace::Core::Atoms::ConfigSummary.help_requested?({help: true}, [])
  end

  def test_help_requested_with_h_option
    assert Ace::Core::Atoms::ConfigSummary.help_requested?({h: true}, [])
  end

  def test_help_requested_with_long_help_arg
    assert Ace::Core::Atoms::ConfigSummary.help_requested?({}, ["--help"])
  end

  def test_help_requested_with_short_help_arg
    assert Ace::Core::Atoms::ConfigSummary.help_requested?({}, ["-h"])
  end

  def test_help_requested_with_mixed_args
    assert Ace::Core::Atoms::ConfigSummary.help_requested?({}, ["command", "--help"])
  end

  def test_help_requested_returns_false_when_no_help
    refute Ace::Core::Atoms::ConfigSummary.help_requested?({}, [])
    refute Ace::Core::Atoms::ConfigSummary.help_requested?({verbose: true}, ["command", "arg1"])
  end

  def test_help_requested_defaults_to_argv
    # When args is not provided, should check ARGV
    original_argv = ARGV.dup
    begin
      ARGV.replace(["--help"])
      assert Ace::Core::Atoms::ConfigSummary.help_requested?({})
    ensure
      ARGV.replace(original_argv)
    end
  end
end

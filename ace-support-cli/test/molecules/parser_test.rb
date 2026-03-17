# frozen_string_literal: true

require_relative "../test_helper"

class ParserTest < AceSupportCliTestCase
  class ParseCommand < Ace::Support::Cli::Command
    option :count, type: :integer, required: true
    option :rate, type: :float
    option :verbose, type: :boolean, default: false
    option :tags, type: :array, default: []
    option :headers, type: :hash, default: {}
    option :name, type: :string
    argument :target, type: :string, required: true
    argument :level, type: :integer, required: false
  end

  def setup
    @parser = Ace::Support::Cli::Parser.new(ParseCommand)
  end

  def test_parses_all_supported_types
    parsed = @parser.parse([
      "--count", "3",
      "--rate", "2.5",
      "--verbose",
      "--tags", "a,b",
      "--tags", "c",
      "--headers", "x:1",
      "--name", "demo",
      "dest",
      "9"
    ])

    assert_equal 3, parsed[:count]
    assert_equal 2.5, parsed[:rate]
    assert_equal true, parsed[:verbose]
    assert_equal ["a", "b", "c"], parsed[:tags]
    assert_equal({ "x" => "1" }, parsed[:headers])
    assert_equal "demo", parsed[:name]
    assert_equal "dest", parsed[:target]
    assert_equal 9, parsed[:level]
  end

  def test_parses_boolean_false_form
    parsed = @parser.parse(["--count", "1", "--no-verbose", "dest"])

    assert_equal false, parsed[:verbose]
  end

  def test_honors_double_dash
    parsed = @parser.parse(["--count", "1", "--", "dest"])

    assert_equal "dest", parsed[:target]
  end

  def test_reports_missing_required_options
    error = assert_raises(Ace::Support::Cli::ParseError) { @parser.parse(["dest"]) }

    assert_includes error.message, "Missing required options"
  end

  def test_reports_invalid_integer
    error = assert_raises(Ace::Support::Cli::ParseError) { @parser.parse(["--count", "x", "dest"]) }

    assert_includes error.message, "invalid argument"
  end

  def test_reports_unknown_flags_with_suggestion
    error = assert_raises(Ace::Support::Cli::ParseError) { @parser.parse(["--cout", "1", "dest"]) }

    assert_includes error.message, "Did you mean"
  end

  # --- Rich help interception ---

  class RichHelpCommand < Ace::Support::Cli::Command
    desc "Show task details"
    option :format, type: :string, default: "text", desc: "Output format"
    argument :id, type: :integer, required: true, desc: "Task ID"
    example ["42", "42 --format json"]

    def call(**_params) = nil
  end

  class BareCommand < Ace::Support::Cli::Command
    option :verbose, type: :boolean, default: false

    def call(**_params) = nil
  end

  def test_help_flag_on_rich_command_renders_banner
    parser = Ace::Support::Cli::Parser.new(RichHelpCommand, command_name: "ace-task show")
    output = capture_io { assert_raises(SystemExit) { parser.parse(["--help"]) } }.first

    assert_includes output, "NAME"
    assert_includes output, "USAGE"
    assert_includes output, "EXAMPLES"
    assert_includes output, "ace-task show"
  end

  def test_h_flag_on_rich_command_renders_concise
    parser = Ace::Support::Cli::Parser.new(RichHelpCommand, command_name: "ace-task show")
    output = capture_io { assert_raises(SystemExit) { parser.parse(["-h"]) } }.first

    assert_includes output, "ace-task show"
    assert_includes output, "Run 'ace-task show --help' for full details."
  end

  def test_help_flag_on_bare_command_falls_through
    parser = Ace::Support::Cli::Parser.new(BareCommand)

    # Bare command has no desc/examples, so OptionParser handles --help
    # OptionParser's default --help also exits
    assert_raises(SystemExit) { parser.parse(["--help"]) }
  end

  def test_help_flag_mixed_with_other_flags_still_triggers
    parser = Ace::Support::Cli::Parser.new(RichHelpCommand, command_name: "ace-task show")
    output = capture_io { assert_raises(SystemExit) { parser.parse(["--format", "json", "--help"]) } }.first

    assert_includes output, "NAME"
    assert_includes output, "ace-task show"
  end
end

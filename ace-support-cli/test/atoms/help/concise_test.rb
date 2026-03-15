# frozen_string_literal: true

require_relative "../../test_helper"

class HelpConciseTest < AceSupportCliTestCase
  class ConciseCommand < Ace::Support::Cli::Command
    desc "Run linter on files"
    option :format, type: :string, aliases: ["-f"], desc: "Output format"
    option :verbose, type: :boolean, default: false
    example ["ace-tool lint .", "ace-tool lint src/", "ace-tool lint lib/", "ace-tool lint test/"]
  end

  def test_renders_compact_help_output
    output = Ace::Support::Cli::HelpConcise.call(ConciseCommand, "ace-tool lint")

    assert_includes output, "ace-tool lint - Run linter on files"
    assert_includes output, "Usage: ace-tool lint [OPTIONS]"
    assert_includes output, "Options:\n  --format VALUE, -f"
    assert_includes output, "--[no-]verbose"
    assert_includes output, "Examples:\n  $ ace-tool lint ."
    assert_includes output, "Run 'ace-tool lint --help' for full details."
    refute_includes output, "$ ace-tool lint test/"
  end
end

# frozen_string_literal: true

require_relative "../../../test_helper"

class HelpBannerTest < AceSupportCliTestCase
  class BannerCommand < Ace::Support::Cli::Command
    desc <<~DESC
      Run linter on files

      Runs the linter on the specified path with configurable rules.
    DESC

    option :timeout, type: :integer, default: 30, aliases: ["-t"], desc: "Timeout in seconds"
    option :format, type: :string, values: %w[json text], desc: "Output format"
    option :verbose, type: :boolean, default: false, desc: "Enable verbose output"
    argument :path, required: false, desc: "Path to lint"
    example ["ace-tool lint .", "ace-tool lint src/ --format text --timeout 60"]
  end

  def test_renders_all_expected_sections
    output = Ace::Support::Cli::Banner.call(BannerCommand, "ace-tool lint")

    assert_includes output, "NAME\n  ace-tool lint - Run linter on files"
    assert_includes output, "USAGE\n  ace-tool lint [PATH] [OPTIONS]"
    assert_includes output, "DESCRIPTION\n  Runs the linter on the specified path with configurable rules."
    assert_includes output, "ARGUMENTS\n  [PATH]"
    assert_includes output, "OPTIONS\n"
    assert_includes output, "--timeout=VALUE, -t"
    assert_includes output, "(default: 30)"
    assert_includes output, "(values: json, text)"
    assert_includes output, "--[no-]verbose"
    assert_includes output, "--help, -h"
    assert_includes output, "EXAMPLES\n  $ ace-tool lint ."
  end

  class NoDescriptionCommand < Ace::Support::Cli::Command
    desc "Single line only"
  end

  def test_omits_description_for_single_line_desc
    output = Ace::Support::Cli::Banner.call(NoDescriptionCommand, "ace-tool noop")

    refute_includes output, "DESCRIPTION"
  end
end

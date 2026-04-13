# frozen_string_literal: true

require_relative "../../test_helper"

class TwoTierHelpTest < AceSupportCliTestCase
  class HelpCommand < Ace::Support::Cli::Command
    desc "Run something"
    option :verbose, type: :boolean, default: false
  end

  def test_detects_concise_only_for_short_flag_without_long_flag
    assert Ace::Support::Cli::TwoTierHelp.concise?(["-h"])
    refute Ace::Support::Cli::TwoTierHelp.concise?(["--help"])
    refute Ace::Support::Cli::TwoTierHelp.concise?(["-h", "--help"])
    refute Ace::Support::Cli::TwoTierHelp.concise?([])
  end

  def test_dispatches_to_concise_and_full_renderers
    concise = Ace::Support::Cli::TwoTierHelp.render(HelpCommand, "ace-tool run", args: ["-h"])
    full = Ace::Support::Cli::TwoTierHelp.render(HelpCommand, "ace-tool run", args: ["--help"])

    assert_includes concise, "Usage: ace-tool run [OPTIONS]"
    assert_includes full, "NAME\n  ace-tool run - Run something"
  end
end

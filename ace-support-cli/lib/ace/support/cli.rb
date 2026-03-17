# frozen_string_literal: true

require_relative "cli/version"
require_relative "cli/errors"
require_relative "cli/models/option"
require_relative "cli/models/argument"
require_relative "cli/command"
require_relative "cli/parser"
require_relative "cli/argv_coalescer"
require_relative "cli/registry"
require_relative "cli/runner"
require_relative "cli/help/banner"
require_relative "cli/help/usage"
require_relative "cli/help/concise"
require_relative "cli/help/help_command"
require_relative "cli/help/version_command"
require_relative "cli/help/two_tier_help"

module Ace
  module Support
    module Cli
      Banner = Help::Banner
      HelpConcise = Help::Concise
      HelpCommand = Help::HelpCommand
      VersionCommand = Help::VersionCommand
      TwoTierHelp = Help::TwoTierHelp

      class Usage < Help::Usage
      end
    end
  end
end

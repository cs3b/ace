# frozen_string_literal: true

module Ace
  module Core
    module CLI
      module DryCli
        # Mixin for CLI registries to define command grouping for --help output.
        #
        # When a CLI registry includes this module and defines COMMAND_GROUPS,
        # the usage formatter will render commands under group headings in the
        # full --help output. Without COMMAND_GROUPS, commands are displayed as
        # a flat alphabetical list (safe default).
        #
        # @example Adding groups to a CLI registry
        #   module MyGem
        #     module CLI
        #       extend Dry::CLI::Registry
        #       include Ace::Core::CLI::DryCli::CommandGroups
        #
        #       COMMAND_GROUPS = {
        #         "Task Management" => %w[task tasks],
        #         "Configuration"   => %w[config doctor],
        #       }.freeze
        #
        #       # ... register commands ...
        #     end
        #   end
        #
        # @since 0.12.0
        module CommandGroups
          # No-op mixin. The COMMAND_GROUPS constant is detected by the usage
          # formatter via const_defined?(:COMMAND_GROUPS). This module serves
          # as documentation and a convention marker.
        end
      end
    end
  end
end

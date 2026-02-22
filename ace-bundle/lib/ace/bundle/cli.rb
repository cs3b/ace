# frozen_string_literal: true

require 'dry/cli'
require 'ace/core'
require_relative '../bundle'
require_relative 'cli/commands/load'
require_relative 'cli/commands/list'

module Ace
  module Bundle
    module CLI
      extend Dry::CLI::Registry

      PROGRAM_NAME = 'ace-bundle'

      REGISTERED_COMMANDS = [
        ['load', 'Load context from preset, file, or protocol URL'],
        ['list', 'List available presets']
      ].freeze

      HELP_EXAMPLES = [
        'ace-bundle load project',
        'ace-bundle load wfi://bundle',
        'ace-bundle list',
        'ace-bundle load path/to/file.md'
      ].freeze

      register 'load', Commands::Load.new
      register 'list', Commands::List.new

      version_cmd = Ace::Core::CLI::DryCli::VersionCommand.build(
        gem_name: 'ace-bundle',
        version: Ace::Bundle::VERSION
      )
      register 'version', version_cmd
      register '--version', version_cmd

      help_cmd = Ace::Core::CLI::DryCli::HelpCommand.build(
        program_name: PROGRAM_NAME,
        version: Ace::Bundle::VERSION,
        commands: REGISTERED_COMMANDS,
        examples: HELP_EXAMPLES
      )
      register 'help', help_cmd
      register '--help', help_cmd
      register '-h', help_cmd
    end
  end
end

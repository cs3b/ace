# frozen_string_literal: true

require "dry/cli"
require_relative "../commands/idea_command"

module Ace
  module Taskflow
    module CLI
      class Idea < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Operations on single ideas

          SYNTAX:
            ace-taskflow idea [ACTION] [ARGS]

          EXAMPLES:

            # Show next idea
            $ ace-taskflow idea

            # Create new idea
            $ ace-taskflow idea create 'Add caching'

            # Prioritize ideas
            $ ace-taskflow idea prioritize

          CONFIGURATION:

            Global config:  ~/.ace/taskflow/config.yml
            Project config: .ace/taskflow/config.yml
            Example:        ace-taskflow/.ace-defaults/taskflow/config.yml

          OUTPUT:

            Idea details printed to stdout
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          '                         # Show next idea',
          'create "Add caching"     # Create new idea',
          'prioritize               # Prioritize ideas'
        ]

        option :quiet, type: :boolean, aliases: %w[-q]
        option :verbose, type: :boolean, aliases: %w[-v]
        option :debug, type: :boolean, aliases: %w[-d]

        def call(**options)
          args = options[:args] || []
          Commands::IdeaCommand.new.execute(args)
        end
      end
    end
  end
end

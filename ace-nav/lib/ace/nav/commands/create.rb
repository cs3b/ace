# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "create_command"

module Ace
  module Nav
    module Commands
      # dry-cli Command class for the create command
      #
      # This wraps the existing CreateCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Create < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Create resource from template

          SYNTAX:
            ace-nav create [URI] [TARGET] [OPTIONS]

          EXAMPLES:

            # Create from workflow template
            $ ace-nav create wfi://my-workflow

            # Create from template to specific file
            $ ace-nav create tmpl://custom ./output.md

            # Backward compat: using --create flag
            $ ace-nav --create wfi://my-workflow

          CONFIGURATION:

            Global config:  ~/.ace/nav/config.yml
            Project config: .ace/nav/config.yml
            Example:        ace-nav/.ace-defaults/nav/config.yml

          OUTPUT:

            Creates resource at specified path or default location
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          "wfi://my-workflow           # Create from workflow template",
          "tmpl://custom ./output.md   # Create from template to file",
          "--create wfi://my-workflow  # Backward compatibility"
        ]

        argument :uri, required: true, desc: "Template URI"
        argument :target, required: false, desc: "Target file path"

        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show detailed information"
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(uri:, target: nil, **options)
          # Use the existing CreateCommand logic
          command = CreateCommand.new(uri, target, options)
          command.execute
        end
      end
    end
  end
end

# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "sources_command"

module Ace
  module Nav
    module Commands
      # dry-cli Command class for the sources command
      #
      # This wraps the existing SourcesCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Sources < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Show available sources

          Show all available sources for resources.

          EXAMPLES:

            # Show all sources
            $ ace-nav sources

            # Verbose JSON output
            $ ace-nav sources --verbose

            # Backward compat: using --sources flag
            $ ace-nav --sources

          CONFIGURATION:

            Sources configured in: .ace/nav/config.yml
            Global config:  ~/.ace/nav/config.yml
            Project config: .ace/nav/config.yml

          OUTPUT:

            Table format with source details
            Use --verbose for JSON output
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          "                          # Show all sources",
          "--verbose                 # Show detailed information (JSON)",
          "                          # Backward compat: --sources flag"
        ]

        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show detailed information (JSON)"
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(**options)
          # Use the existing SourcesCommand logic
          command = SourcesCommand.new(options)
          command.execute
        end
      end
    end
  end
end

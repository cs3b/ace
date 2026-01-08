# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "list_command"

module Ace
  module Nav
    module Commands
      # dry-cli Command class for the list command
      #
      # This wraps the existing ListCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class List < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          List matching resources

          SYNTAX:
            ace-nav list [PATTERN] [OPTIONS]

          EXAMPLES:

            # List all workflows
            $ ace-nav list 'wfi://*'

            # List templates with pattern
            $ ace-nav list 'tmpl://@ace-*/*'

            # Tree format
            $ ace-nav list wfi:// --tree

            # Can also use wildcard directly (auto-routed)
            $ ace-nav wfi://*

          CONFIGURATION:

            Global config:  ~/.ace/nav/config.yml
            Project config: .ace/nav/config.yml
            Example:        ace-nav/.ace-defaults/nav/config.yml

          OUTPUT:

            Table format with columns: URI, path, type
            Use --tree for hierarchical format
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          "'wfi://*'                 # List all workflows",
          "'tmpl://@ace-*/*'         # List templates with pattern",
          "wfi:// --tree             # Tree format",
          "wfi://*                   # Auto-routed from resolve"
        ]

        argument :pattern, required: true, desc: "Pattern to match resources"

        option :tree, type: :boolean, desc: "Display resources in tree format"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Show detailed information"
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(pattern:, **options)
          # Use the existing ListCommand logic
          command = ListCommand.new(pattern, options)
          command.execute
        end
      end
    end
  end
end

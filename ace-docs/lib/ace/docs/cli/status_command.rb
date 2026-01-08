# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../commands/status_command"

module Ace
  module Docs
    module CLI
      # dry-cli Command class for the status command
      #
      # This wraps the existing StatusCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class StatusCommand < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Show status of all managed documents

          Display status information for all documents tracked by ace-docs,
          including freshness, update status, and document metadata.

          Configuration:
            Global config:  ~/.ace/docs/config.yml
            Project config: .ace/docs/config.yml
            Example:        ace-docs/.ace-defaults/docs/config.yml

          Output:
            Table format with columns: path, type, status, last-updated
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          "ace-docs status                      # All tracked documents",
          "ace-docs status --type handbook      # Filter by document type",
          "ace-docs status --needs-update       # Show only documents needing update",
          "ace-docs status --freshness stale    # Filter by freshness status",
          "ace-docs status --freshness current  # Filter by freshness status"
        ]

        option :type, type: :string, desc: "Filter by document type"
        option :needs_update, type: :boolean, desc: "Show only documents needing update"
        option :freshness, type: :string, desc: "Filter by freshness status (current/stale/outdated)"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(**options)
          command = Commands::StatusCommand.new(options)
          command.execute
          0
        rescue StandardError => e
          warn "Error showing status: #{e.message}"
          warn e.backtrace.join("\n  ") if debug?(options)
          1
        end
      end
    end
  end
end

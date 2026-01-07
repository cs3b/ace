# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../commands/update_command"

module Ace
  module Docs
    module CLI
      # dry-cli Command class for the update command
      #
      # This wraps the existing UpdateCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class UpdateCommand < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Update document frontmatter

          Update frontmatter fields in a single document or all documents matching a preset.
          Common updates include last-updated timestamps and status changes.

          SYNTAX:
            ace-docs update FILE [OPTIONS]
            ace-docs update --preset PRESET [OPTIONS]

          Configuration:
            Global config:  ~/.ace/docs/config.yml
            Project config: .ace/docs/config.yml

          Output:
            Updated fields written to file frontmatter
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          "ace-docs update README.md --set last-updated=today",
          "ace-docs update docs/guide.md --set status=complete --set last-reviewed=2025-01-04",
          "ace-docs update --set last-updated=today --preset handbook",
          "ace-docs update file.md --set last-updated=2025-01-04"
        ]

        argument :file, required: false, desc: "File to update (or use --preset)"

        option :set, type: :hash, desc: "Fields to update (e.g., --set last-updated=today)"
        option :preset, type: :string, desc: "Update all documents matching preset"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(file: nil, **options)
          # Handle --help/-h passed as file argument
          if file == "--help" || file == "-h"
            # dry-cli will handle help automatically, so we just ignore
            return 0
          end

          command = Commands::UpdateCommand.new(options)
          exit_code = command.execute(file)
          return exit_code if exit_code != 0
          0
        rescue StandardError => e
          warn "Error updating document: #{e.message}"
          warn e.backtrace.join("\n  ") if debug?(options)
          1
        end
      end
    end
  end
end

# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../organisms/document_registry"

module Ace
  module Docs
    module CLI
      # dry-cli Command class for the discover command
      #
      # This wraps the discover logic in a dry-cli compatible interface.
      class DiscoverCommand < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Find and list all managed documents

          Scan the project for all documents managed by ace-docs and display them.
          Useful for verifying which files are being tracked.

          Output:
            Shows count and file paths with types
            Exit codes: 0 (success), 1 (error)
        DESC

        example [
          "ace-docs discover                    # List all managed documents",
          "# Output shows count and file paths with types",
          "# Found 15 managed documents:",
          "#   docs/architecture.md (architecture)",
          "#   ace-handbook/handbook/guides/testing.g.md (guide)"
        ]

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(**options)
          registry = Organisms::DocumentRegistry.new
          documents = registry.all

          if documents.empty?
            puts "No managed documents found."
            return 0
          end

          puts "Found #{documents.size} managed documents:"
          documents.each do |doc|
            puts "  #{doc.relative_path || doc.path} (#{doc.doc_type})"
          end
          0
        rescue StandardError => e
          warn "Error discovering documents: #{e.message}"
          warn e.backtrace.join("\n  ") if debug?(options)
          1
        end
      end
    end
  end
end

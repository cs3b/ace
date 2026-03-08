# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../organisms/document_registry"
require_relative "scope_options"

module Ace
  module Docs
    module CLI
      module Commands
        # dry-cli Command class for the discover command
        #
        # This wraps the discover logic in a dry-cli compatible interface.
        class Discover < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          include ScopeOptions

          # Exit codes
          EXIT_SUCCESS = 0
          EXIT_ERROR = 1

          desc <<~DESC.strip
            Find and list all managed documents

            Scan the project for all documents managed by ace-docs and display them.
            Useful for verifying which files are being tracked.

            Output:
              Shows count and file paths with types
              Exit codes: 0 (success), 1 (error)
          DESC

          example [
            "                             # List all managed documents",
            "--package ace-docs           # List managed docs in one package",
            "--glob 'ace-docs/**/*.md'    # List managed docs by glob"
          ]

          option :package, type: :array, desc: "Scope to package(s), e.g. --package ace-docs"
          option :glob, type: :array, desc: "Scope by glob(s), e.g. --glob 'ace-docs/**/*.md'"

          # Standard options
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            scope_globs = normalized_scope_globs(options, project_root: options[:project_root])
            registry = Ace::Docs::Organisms::DocumentRegistry.new(
              project_root: options[:project_root],
              scope_globs: scope_globs
            )
            documents = registry.all

            if documents.empty?
              puts "No managed documents found."
              return EXIT_SUCCESS
            end

            puts "Found #{documents.size} managed documents:"
            documents.each do |doc|
              puts "  #{doc.relative_path || doc.path} (#{doc.doc_type})"
            end
            EXIT_SUCCESS
          rescue StandardError => e
            warn "Error discovering documents: #{e.message}"
            warn e.backtrace.join("\n  ") if debug?(options)
            EXIT_ERROR
          end
        end
      end
    end
  end
end

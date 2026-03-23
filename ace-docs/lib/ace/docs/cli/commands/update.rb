# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "../../organisms/document_registry"
require_relative "../../molecules/frontmatter_manager"
require_relative "../../atoms/frontmatter_free_matcher"
require_relative "scope_options"

module Ace
  module Docs
    module CLI
      module Commands
        # ace-support-cli Command class for the update command
        #
        # This command handles updating document frontmatter.
        class Update < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include ScopeOptions

          # Exit codes
          EXIT_SUCCESS = 0
          EXIT_ERROR = 1

          # Custom error classes
          class UpdateError < StandardError; end
          class FileNotFoundError < UpdateError; end
          class MissingArgumentError < UpdateError; end

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
            "README.md --set last-updated=today",
            "docs/guide.md --set status=complete --set last-reviewed=2025-01-04",
            "--set last-updated=today --preset handbook",
            "file.md --set last-updated=2025-01-04",
            "--package ace-docs --set last-checked=today",
            "--glob 'ace-docs/docs/**/*.md' --set last-updated=today"
          ]

          argument :file, required: false, desc: "File to update (or use --preset)"

          option :set, type: :hash, desc: "Fields to update (e.g., --set last-updated=today)"
          option :preset, type: :string, desc: "Update all documents matching preset"
          option :package, type: :array, desc: "Scope to package(s), e.g. --package ace-docs"
          option :glob, type: :array, desc: "Scope by glob(s), e.g. --glob 'ace-docs/**/*.md'"

          # Standard options
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(file: nil, **options)
            # Handle --help/-h passed as file argument
            if file == "--help" || file == "-h"
              # ace-support-cli will handle help automatically, so we just ignore
              return EXIT_SUCCESS
            end

            execute_update(file, options)
          end

          private

          def execute_update(file, options)
            documents = select_documents(file, options)

            if documents.empty?
              puts "No documents to update."
              return EXIT_SUCCESS
            end

            updated_count = update_documents(documents, options)
            puts "Updated frontmatter for #{updated_count} document(s)"

            EXIT_SUCCESS
          rescue => e
            warn "Error updating documents: #{e.message}"
            warn e.backtrace.join("\n") if debug?(options)
            EXIT_ERROR
          end

          def select_documents(file, options)
            scope_globs = normalized_scope_globs(options, project_root: options[:project_root])
            registry = Ace::Docs::Organisms::DocumentRegistry.new(
              project_root: options[:project_root],
              scope_globs: scope_globs
            )
            scoped_docs = registry.all

            if options[:preset]
              scoped_docs.select { |d| d.context_preset == options[:preset] }
            elsif file
              # Try to find in registry first (existing doc with frontmatter)
              doc = registry.find_by_path(file)

              # If not in registry, check if file exists without frontmatter
              if !doc && File.exist?(file)
                unless path_in_scope?(file, scope_globs, project_root: options[:project_root] || Dir.pwd)
                  raise FileNotFoundError, "File outside requested scope: #{file}"
                end

                # Create minimal Document object for file without frontmatter
                require_relative "../../models/document"
                doc = Ace::Docs::Models::Document.new(
                  path: File.expand_path(file),
                  frontmatter: {},  # Empty frontmatter - will be initialized
                  content: File.read(file)
                )
              end

              raise FileNotFoundError, "File not found: #{file}" unless doc
              [doc]
            elsif scope_options_present?(options)
              scoped_docs
            else
              raise MissingArgumentError, "Please specify a file, --preset, --package, or --glob"
            end
          end

          def update_documents(documents, options)
            updated_count = 0
            updates = options[:set] || {}
            project_root = options[:project_root] || Dir.pwd

            documents.each do |doc|
              if frontmatter_free_document?(doc.path, project_root: project_root)
                puts "Skipped: #{doc.path} (frontmatter-free document, metadata is inferred)"
                next
              end

              # Initialize required fields if frontmatter is empty
              working_updates = doc.frontmatter.empty? ? initialize_required_fields(doc, updates) : updates

              if Ace::Docs::Molecules::FrontmatterManager.update_document(doc, working_updates)
                updated_count += 1
                puts "Updated: #{doc.display_name}"
              end
            end

            updated_count
          end

          def initialize_required_fields(doc, updates)
            required_updates = updates.dup

            # Infer doc-type from file path/extension if not provided
            required_updates["doc-type"] ||= infer_doc_type(doc.path)

            # Require purpose to be provided
            unless required_updates["purpose"]
              raise MissingArgumentError, "Purpose required for new frontmatter. Use: --set purpose:'Document description'"
            end

            required_updates
          end

          def infer_doc_type(path)
            case path
            when /README\.md$/i then "readme"
            when /\.wf\.md$/ then "workflow"
            when /\.g\.md$/ then "guide"
            when /\.template\.md$/ then "template"
            when /docs\/.*\.md$/ then "context"
            else "reference"
            end
          end

          def frontmatter_free_document?(path, project_root:)
            patterns = Ace::Docs.config["frontmatter_free"] || []
            Ace::Docs::Atoms::FrontmatterFreeMatcher.match?(
              path,
              patterns: patterns,
              project_root: project_root
            )
          end
        end
      end
    end
  end
end

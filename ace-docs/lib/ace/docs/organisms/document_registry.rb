# frozen_string_literal: true

require "yaml"
require_relative "../molecules/document_loader"
require_relative "../models/document"

module Ace
  module Docs
    module Organisms
      # Discovers and indexes all managed documents in the project
      class DocumentRegistry
        attr_reader :documents, :config

        def initialize(config_path: nil)
          @config_path = config_path || find_config_path
          @config = load_configuration
          @documents = []
          discover_documents
        end

        # Refresh the registry by rediscovering documents
        def refresh
          @documents = []
          discover_documents
        end

        # Find all managed documents
        def all
          @documents.dup
        end

        # Find documents by type
        def by_type(doc_type)
          @documents.select { |doc| doc.doc_type == doc_type }
        end

        # Find documents needing update
        def needing_update
          @documents.select(&:needs_update?)
        end

        # Find documents by freshness status
        def by_freshness(status)
          @documents.select { |doc| doc.freshness_status == status }
        end

        # Find document by path
        def find_by_path(path)
          absolute_path = File.absolute_path(path)
          @documents.find { |doc| File.absolute_path(doc.path) == absolute_path }
        end

        # Get document types configuration
        def document_types
          @config["document_types"] || {}
        end

        # Get global validation rules
        def global_rules
          @config["global_rules"] || {}
        end

        # Group documents by type
        def grouped_by_type
          @documents.group_by(&:doc_type)
        end

        # Group documents by directory
        def grouped_by_directory
          @documents.group_by { |doc| File.dirname(doc.path) }
        end

        # Get statistics about the registry
        def stats
          {
            total: @documents.size,
            by_type: @documents.group_by(&:doc_type).transform_values(&:size),
            by_freshness: @documents.group_by(&:freshness_status).transform_values(&:size),
            needing_update: needing_update.size,
            managed: @documents.count(&:managed?)
          }
        end

        private

        def find_config_path
          # Look for config in standard locations
          config_locations = [
            ".ace/docs/config.yml",
            ".ace/docs/config.yaml",
            "ace-docs.yml",
            "ace-docs.yaml"
          ]

          config_locations.each do |location|
            path = File.join(Dir.pwd, location)
            return path if File.exist?(path)
          end

          nil
        end

        def load_configuration
          return default_configuration unless @config_path && File.exist?(@config_path)

          begin
            YAML.safe_load_file(@config_path, permitted_classes: [Symbol]) || default_configuration
          rescue StandardError => e
            warn "Error loading configuration from #{@config_path}: #{e.message}"
            default_configuration
          end
        end

        def default_configuration
          {
            "document_types" => {
              "context" => {
                "paths" => ["docs/*.md"],
                "defaults" => {
                  "update_frequency" => "weekly",
                  "max_lines" => 150
                }
              },
              "guide" => {
                "paths" => ["dev-handbook/guides/**/*.md", "**/*.g.md"],
                "defaults" => {
                  "update_frequency" => "monthly",
                  "max_lines" => 500
                }
              },
              "workflow" => {
                "paths" => ["**/*.wf.md", "dev-handbook/workflow-instructions/**/*.md"],
                "defaults" => {
                  "update_frequency" => "on-change"
                }
              },
              "api" => {
                "paths" => ["*/docs/api/*.md", "*/api-docs/**/*.md"],
                "defaults" => {
                  "update_frequency" => "on-change"
                }
              }
            },
            "global_rules" => {
              "max_lines" => 1000,
              "required_frontmatter" => ["doc-type", "purpose"]
            }
          }
        end

        def discover_documents
          # First, discover documents with explicit frontmatter
          discover_explicit_documents

          # Then, discover documents matching type patterns
          discover_configured_documents
        end

        def discover_explicit_documents
          # Search for all markdown files in the project
          all_md_files = Dir.glob(File.join(Dir.pwd, "**/*.md"))

          # Load those with ace-docs frontmatter
          all_md_files.each do |path|
            next if ignored_path?(path)

            doc = Molecules::DocumentLoader.load_file(path)
            next unless doc&.managed?

            # Avoid duplicates
            unless @documents.any? { |d| d.path == doc.path }
              @documents << doc
            end
          end
        end

        def discover_configured_documents
          return unless document_types.any?

          document_types.each do |type_name, type_config|
            paths = type_config["paths"] || []
            defaults = type_config["defaults"] || {}

            paths.each do |pattern|
              matching_files = Dir.glob(File.join(Dir.pwd, pattern))

              matching_files.each do |path|
                next if ignored_path?(path)
                next if @documents.any? { |d| d.path == path }

                # Load the document
                doc = Molecules::DocumentLoader.load_file(path)

                # If it doesn't have frontmatter, check if we should track it anyway
                if doc.nil? && File.exist?(path) && path.end_with?(".md")
                  # Create a minimal document for tracking
                  content = File.read(path)
                  doc = Models::Document.new(
                    path: path,
                    frontmatter: {
                      "doc-type" => type_name,
                      "purpose" => "Auto-discovered #{type_name} document",
                      "update" => defaults
                    },
                    content: content
                  )
                end

                @documents << doc if doc
              end
            end
          end
        end

        def ignored_path?(path)
          # Ignore certain directories and files
          ignored_patterns = [
            %r{/\.git/},
            %r{/node_modules/},
            %r{/vendor/},
            %r{/tmp/},
            %r{/coverage/},
            %r{/_legacy/},
            %r{/\.ace-taskflow/done/}
          ]

          ignored_patterns.any? { |pattern| path.match?(pattern) }
        end
      end
    end
  end
end
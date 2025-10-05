# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Extracts context (background information) for reviews
      class ContextExtractor
        DEFAULT_PROJECT_DOCS = [
          "README.md",
          "docs/architecture.md",
          "docs/what-do-we-build.md",
          "docs/blueprint.md",
          ".github/CONTRIBUTING.md",
          "ARCHITECTURE.md"
        ].freeze

        def initialize
          @file_reader = Atoms::FileReader
          @preset_manager = nil # Lazy load to avoid circular dependency
        end

        # Extract context from configuration
        # @param context_config [String, Hash, nil] context configuration
        # @return [String] extracted context content
        def extract(context_config)
          case context_config
          when nil, "none", false
            ""
          when "project", "auto", true
            extract_project_context
          when String
            extract_from_string(context_config)
          when Hash
            extract_from_hash(context_config)
          else
            ""
          end
        end

        private

        def extract_from_string(input)
          # Try to parse as YAML first
          parsed = YAML.safe_load(input)
          return extract_from_hash(parsed) if parsed.is_a?(Hash)

          # Check if it's a preset name
          if preset_context = load_preset_context(input)
            return extract(preset_context)
          end

          # Treat as file path
          extract_file(input)
        rescue Psych::SyntaxError
          # If YAML parsing fails, treat as file path
          extract_file(input)
        end

        def extract_from_hash(config)
          parts = []

          # Read specified files
          if config["files"]
            files = config["files"]
            files = [files] unless files.is_a?(Array)

            files.each do |file|
              content = extract_file(file)
              parts << content unless content.empty?
            end
          end

          # Include inline content
          if config["content"]
            parts << config["content"]
          end

          # Execute commands for dynamic context
          if config["commands"]
            config["commands"].each do |command|
              output = execute_command(command)
              parts << format_command_context(command, output) if output
            end
          end

          parts.join("\n\n" + "=" * 80 + "\n\n")
        end

        def extract_project_context
          parts = []

          DEFAULT_PROJECT_DOCS.each do |doc_path|
            content = extract_file(doc_path)
            parts << content unless content.empty?
          end

          if parts.empty?
            # If no standard docs found, try to find any markdown files
            fallback_docs = Dir.glob("{*.md,docs/*.md}").first(3)
            fallback_docs.each do |doc|
              content = extract_file(doc)
              parts << content unless content.empty?
            end
          end

          parts.join("\n\n" + "=" * 80 + "\n\n")
        end

        def extract_file(path)
          result = @file_reader.read(path)
          return "" unless result[:success]

          <<~CONTENT
            File: #{path}
            #{"-" * 40}
            #{result[:content]}
          CONTENT
        end

        def load_preset_context(preset_name)
          # Lazy load preset manager
          @preset_manager ||= PresetManager.new

          preset = @preset_manager.load_preset(preset_name)
          preset&.dig("context")
        end

        def execute_command(command)
          require "open3"
          stdout, stderr, status = Open3.capture3(command)
          return nil unless status.success?

          stdout
        rescue StandardError => e
          warn "Failed to execute context command '#{command}': #{e.message}" if Ace::Review.debug?
          nil
        end

        def format_command_context(command, output)
          <<~CONTEXT
            Command Output: #{command}
            #{"-" * 40}
            #{output}
          CONTEXT
        end
      end
    end
  end
end
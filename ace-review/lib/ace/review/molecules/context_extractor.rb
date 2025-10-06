# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Extracts context (background information) for reviews
      # Delegates to ace-context for unified content aggregation
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
          begin
            parsed = YAML.safe_load(input)
            return extract_from_hash(parsed) if parsed.is_a?(Hash)
          rescue Psych::SyntaxError
            # Continue with string processing
          end

          # Check if it's an ace-review preset name
          if preset_context = load_preset_context(input)
            return extract(preset_context)
          end

          # Check if it's an ace-context preset
          if ace_context_preset_exists?(input)
            return use_ace_context({ "presets" => [input] })
          end

          # Treat as file path
          use_ace_context({ "files" => [input] })
        end

        def extract_from_hash(config)
          # Check for ace-review preset reference
          if config["preset"]
            if preset_context = load_preset_context(config["preset"])
              return extract(preset_context)
            end
          end

          # Check if config has 'presets' key - delegate to ace-context
          if config["presets"]
            return use_ace_context(config)
          end

          # Otherwise use ace-context for unified extraction
          # Include inline content if provided
          if config["content"]
            parts = [config["content"]]

            # Extract other parts via ace-context
            context_config = config.reject { |k, _| k == "content" }
            if context_config.any?
              parts << use_ace_context(context_config)
            end

            return parts.join("\n\n" + "=" * 80 + "\n\n")
          end

          use_ace_context(config)
        end

        def extract_project_context
          # Build list of existing project docs
          existing_docs = DEFAULT_PROJECT_DOCS.select { |path| File.exist?(path) }

          if existing_docs.empty?
            # If no standard docs found, try to find any markdown files
            existing_docs = Dir.glob("{*.md,docs/*.md}").first(3)
          end

          return "" if existing_docs.empty?

          # Use ace-context to load all docs
          use_ace_context({ "files" => existing_docs })
        end

        def load_preset_context(preset_name)
          # Lazy load preset manager for ace-review presets
          @preset_manager ||= PresetManager.new

          preset = @preset_manager.load_preset(preset_name)
          preset&.dig("context")
        end

        def ace_context_preset_exists?(preset_name)
          # Check if this is a valid ace-context preset
          Ace::Context.list_presets.any? { |p| p[:name] == preset_name }
        rescue StandardError
          false
        end

        def use_ace_context(config)
          # Use ace-context for unified content extraction
          result = Ace::Context.load_auto(YAML.dump(config), format: 'markdown')
          result.content
        rescue StandardError => e
          warn "ace-context extraction failed: #{e.message}" if Ace::Review.debug?
          ""
        end
      end
    end
  end
end
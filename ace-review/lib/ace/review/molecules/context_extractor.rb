# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Extracts context (background information) for reviews
      # Delegates to ContextComposer for context.md pattern and ace-bundle integration
      class ContextExtractor
        def initialize
          @preset_manager = nil # Lazy load to avoid circular dependency
        end

        # Extract context from configuration
        # @param context_config [String, Hash, nil] context configuration
        # @param cache_dir [String, nil] Optional cache directory for context.md
        # @return [String] extracted context content
        def extract(context_config, cache_dir = nil)
          case context_config
          when nil, "none", false
            ""
          when "project", "auto", true
            extract_project_context(cache_dir)
          when String
            extract_from_string(context_config, cache_dir)
          when Hash
            extract_from_hash(context_config, cache_dir)
          else
            ""
          end
        end

        private

        def extract_from_string(input, cache_dir = nil)
          # Try to parse as YAML first
          begin
            parsed = YAML.safe_load(input)
            return extract_from_hash(parsed, cache_dir) if parsed.is_a?(Hash)
          rescue Psych::SyntaxError
            # Continue with string processing
          end

          # Check if it's an ace-review preset name
          if preset_context = load_preset_context(input)
            return extract(preset_context, cache_dir)
          end

          # Check if it's an ace-bundle preset
          if ace_bundle_preset_exists?(input)
            return use_context_composer({ "presets" => [input] }, cache_dir)
          end

          # Treat as file path
          use_context_composer({ "files" => [input] }, cache_dir)
        end

        def extract_from_hash(config, cache_dir = nil)
          # Check for ace-review preset reference
          if config["preset"]
            if preset_context = load_preset_context(config["preset"])
              return extract(preset_context, cache_dir)
            end
          end

          # Delegate to ContextComposer for context.md pattern
          use_context_composer(config, cache_dir)
        end

        def extract_project_context(cache_dir = nil)
          # Build list of existing project docs from config (ADR-022 pattern)
          project_docs = Ace::Review.get("project_docs") || default_project_docs
          existing_docs = project_docs.select { |path| File.exist?(path) }

          if existing_docs.empty?
            # If no standard docs found, try to find any markdown files
            existing_docs = Dir.glob("{*.md,docs/*.md}").first(3)
          end

          return "" if existing_docs.empty?

          # Use ContextComposer to load all docs
          use_context_composer({ "files" => existing_docs }, cache_dir)
        end

        # Fallback defaults used only when Ace::Review.get("project_docs") returns nil
        # (e.g., config cascade initialization fails). Primary source is
        # .ace-defaults/review/config.yml project_docs - keep these in sync.
        def default_project_docs
          %w[
            README.md
            docs/architecture.md
            docs/vision.md
            docs/blueprint.md
            .github/CONTRIBUTING.md
            ARCHITECTURE.md
          ]
        end

        def load_preset_context(preset_name)
          # Lazy load preset manager for ace-review presets
          @preset_manager ||= PresetManager.new

          preset = @preset_manager.load_preset(preset_name)
          preset&.dig("bundle")
        end

        def ace_bundle_preset_exists?(preset_name)
          # Check if this is a valid ace-bundle preset
          Ace::Bundle.list_presets.any? { |p| p[:name] == preset_name }
        rescue StandardError => e
          warn "ace-bundle preset check failed: #{e.message}" if Ace::Review.debug?
          raise e if ENV["ACE_TEST_STRICT"]
          false
        end

        def use_context_composer(config, cache_dir = nil)
        require_relative "context_composer"

        base_instructions = "Load context for code review analysis."

        # Create context.md content
        context_md = Ace::Review::Molecules::ContextComposer.create_context_md(
          base_instructions,
          config
        )

        # If cache_dir provided, save context.md and load via ace-bundle
        if cache_dir
          context_file_path = Ace::Review::Molecules::ContextComposer.save_context_md(
            context_md,
            cache_dir
          )

          # Load via ace-bundle for embedded content
          Ace::Review::Molecules::ContextComposer.load_context_via_ace_bundle(context_file_path)
        else
          # Fallback to direct ace-bundle loading without file
          begin
            require "ace/bundle"
            result = Ace::Bundle.load_auto(context_md, format: 'markdown')
            result.content
          rescue StandardError => e
            warn "ace-bundle extraction failed: #{e.message}" if Ace::Review.debug?
            ""
          end
        end
      rescue Ace::Review::Errors::ContextComposerError => e
        # Fail-fast error handling for ace-bundle failures
        raise ContextExtractorError, "Context extraction failed: #{e.message}"
      end

      # Custom error class for ContextExtractor failures
      class ContextExtractorError < StandardError; end
      end
    end
  end
end
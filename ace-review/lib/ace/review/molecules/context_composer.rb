# frozen_string_literal: true

require "yaml"

module Ace
  module Review
    module Molecules
      # Composes context.md files with YAML frontmatter for ace-bundle integration
      # Follows the pattern from ace-docs DocumentAnalysisPrompt
      class ContextComposer
        # Create context.md with YAML frontmatter for review context
        # @param base_instructions [String] Base instructions for the context
        # @param context_config [Hash] Context configuration (presets, files, diffs, commands)
        # @param subject_config [Hash, nil] Optional subject configuration for scope section
        # @return [String] Complete context.md content with YAML frontmatter
        def self.create_context_md(base_instructions, context_config, subject_config = nil)
          # Normalize context configuration following ace-docs pattern
          normalized_config = normalize_context_config(context_config)

          frontmatter = { "bundle" => normalized_config }

          # Build review scope section if subject config provided
          scope_section = build_review_scope_section(subject_config) if subject_config

          # context.md = frontmatter + base instructions + scope section
          # YAML.dump adds opening --- but not closing, we add closing ---
          "#{YAML.dump(frontmatter).strip}\n---\n\n#{base_instructions}\n\n#{scope_section}".strip
        end

        # Save context.md to specified directory
        # @param context_md [String] The context.md content
        # @param cache_dir [String] Directory to save context.md
        # @return [String] Path to saved context.md file
        def self.save_context_md(context_md, cache_dir)
          context_file_path = File.join(cache_dir, "context.md")
          File.write(context_file_path, context_md)
          context_file_path
        end

        # Load context.md via ace-bundle
        # @param context_file_path [String] Path to context.md file
        # @return [String] Content with embedded files and context
        def self.load_context_via_ace_bundle(context_file_path)
          begin
            require "ace/bundle"

            # Use ace-bundle to load context.md - processes presets and files from frontmatter
            result = Ace::Bundle.load_file(context_file_path)
            result.content
          rescue LoadError
            raise Ace::Review::Errors::ContextComposerError, "ace-bundle not available - required for context.md pattern"
          rescue StandardError => e
            raise Ace::Review::Errors::ContextComposerError, "ace-bundle loading failed: #{e.message}"
          end
        end

        private

        # Normalize context configuration to match ace-docs pattern
        # @param config [Hash] Raw context configuration
        # @return [Hash] Normalized configuration
        def self.normalize_context_config(config)
          # Start with base context config following ace-docs pattern
          normalized = {
            "params" => { "format" => "markdown-xml" },
            "embed_document_source" => true
          }

          # Merge with provided config
          config ||= {}
          normalized.merge!(config)

          # Ensure arrays are properly initialized
          normalized["presets"] ||= []
          normalized["files"] ||= []
          normalized["diffs"] ||= []
          normalized["commands"] ||= []

          normalized
        end

        # Build review scope section explaining what will be reviewed
        # @param subject_config [Hash] Subject configuration
        # @return [String] Review scope section
        def self.build_review_scope_section(subject_config)
          return "" unless subject_config

          # Extract subject description
          subject_desc = extract_subject_description(subject_config)

          <<~SECTION
            ## Review Scope

            **Subject of review**:
            #{subject_desc}
          SECTION
        end

        # Extract human-readable description from subject configuration
        # @param subject_config [Hash] Subject configuration
        # @return [String] Description string
        def self.extract_subject_description(subject_config)
          if subject_config["diff"]
            "- Git diff changes"
          elsif subject_config["files"]
            files = subject_config["files"]
            if files.is_a?(Array)
              if files.length == 1
                "- File: `#{files.first}`"
              else
                "- Files: #{files.map { |f| "`#{f}`" }.join(", ")}"
              end
            else
              "- File: `#{files}`"
            end
          elsif subject_config["content"]
            "- Inline content"
          else
            "- Repository changes"
          end
        end

      end
    end
  end
end
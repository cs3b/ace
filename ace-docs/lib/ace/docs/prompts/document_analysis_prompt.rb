# frozen_string_literal: true

require "open3"
require "yaml"

module Ace
  module Docs
    module Prompts
      # Builds prompts for analyzing changes relevant to a specific document
      class DocumentAnalysisPrompt
        # Build prompts for analyzing changes for a specific document
        # @param document [Document] The document to analyze changes for
        # @param diff [String] The filtered git diff (already filtered by subject.diff.filters)
        # @param since [String] Time period for the diff
        # @param cache_dir [String, nil] Optional cache directory for context.yml
        # @return [Hash] Hash with :system, :user prompts, and :context_config
        def self.build(document, diff, since: nil, cache_dir: nil)
          # Create context configuration and load context
          context_config = create_context_config(document)
          context_content = load_context(context_config, cache_dir: cache_dir)

          {
            system: load_system_prompt,
            user: build_user_prompt(document, diff, since, context: context_content),
            context_config: context_config
          }
        end

        # Load system prompt via ace-nav protocol
        # @return [String] System prompt content
        def self.load_system_prompt
          stdout, stderr, status = Open3.capture3("ace-nav", "prompt://document-analysis.system", "--content")

          if status.success?
            stdout.strip
          else
            # Fallback to embedded prompt if ace-nav fails
            fallback_system_prompt
          end
        rescue StandardError
          fallback_system_prompt
        end

        # Build user prompt with document context and diff
        # @param document [Document] The document to analyze
        # @param diff [String] The git diff content
        # @param since [String] Time period
        # @param context [String, nil] Optional embedded context from ace-context
        # @return [String] User prompt
        def self.build_user_prompt(document, diff, since, context: nil)
          # Extract document metadata
          doc_type = document.doc_type || "document"
          purpose = document.purpose || "(not specified)"
          doc_path = document.respond_to?(:relative_path) ? document.relative_path : document.path

          # Extract context information
          context_keywords = document.context_keywords
          context_preset = document.context_preset

          # Extract subject filters (to show what was filtered)
          subject_filters = document.subject_diff_filters

          # Build context description
          context_desc = build_context_description(context_keywords, context_preset)

          # Build filters description
          filters_desc = build_filters_description(subject_filters)

          # Build time description
          time_desc = since ? "since #{since}" : "recent changes"

          # Build context section if provided
          context_section = if context && !context.strip.empty?
                              "\n## Context\n\n#{context}\n"
                            else
                              ""
                            end

          <<~PROMPT
            ## Document Information

            **Path**: #{doc_path}
            **Type**: #{doc_type}
            **Purpose**: #{purpose}

            #{context_desc}
            #{context_section}
            ## Changes to Analyze

            The following git diff shows changes #{time_desc}.

            #{filters_desc}

            ```diff
            #{diff}
            ```
          PROMPT
        end

        # Fallback system prompt if ace-nav unavailable
        # @return [String] Embedded system prompt
        def self.fallback_system_prompt
          <<~PROMPT
            You are analyzing code changes to determine what needs to be updated in documentation.

            Provide a markdown report with:
            - Summary (2-3 sentences)
            - Changes Detected (organized by HIGH/MEDIUM/LOW priority)
            - Recommended Updates (specific sections with reasoning)
            - Additional Notes

            Focus on relevance to the document's purpose and be specific about what needs updating and why.
          PROMPT
        end

        # Create context configuration for ace-context
        # @param document [Document] The document to analyze
        # @return [Hash] Context configuration
        def self.create_context_config(document)
          # Build context configuration to load related files
          config = {
            "files" => [],
            "format" => "markdown-xml",
            "embed_document_source" => false
          }

          # Add the document itself if it exists
          if document.path && File.exist?(document.path)
            config["files"] << document.path
          end

          # Add related files based on context preset or keywords
          # TODO: Future enhancement - intelligently discover related files
          # based on document.context_keywords or document.context_preset

          config
        end

        # Load context using ace-context
        # @param config [Hash] Context configuration
        # @param cache_dir [String, nil] Optional cache directory to write context.yml
        # @return [String, nil] Loaded context content or nil if unavailable
        def self.load_context(config, cache_dir: nil)
          # Write context.yml to cache directory if provided
          if cache_dir && Dir.exist?(cache_dir)
            context_yml_path = File.join(cache_dir, "context.yml")
            File.write(context_yml_path, YAML.dump(config))
          end

          # Skip context loading if no files specified
          return nil if config["files"].nil? || config["files"].empty?

          # Try to load context via ace-context
          begin
            require "ace/context"

            result = Ace::Context.load_auto(YAML.dump(config), format: "markdown-xml")
            result.content
          rescue LoadError
            # ace-context not available
            warn "ace-context not available - context embedding disabled" if Ace::Docs.debug?
            nil
          rescue StandardError => e
            # Context loading failed
            warn "Context loading failed: #{e.message}" if Ace::Docs.debug?
            nil
          end
        end

        private_class_method def self.build_context_description(keywords, preset)
          parts = []

          if keywords && !keywords.empty?
            parts << "**Context Keywords**: #{keywords.join(', ')}"
          end

          if preset && !preset.empty?
            parts << "**Context Preset**: #{preset}"
          end

          return "" if parts.empty?

          "\n## Document Context\n\n#{parts.join("\n")}\n"
        end

        private_class_method def self.build_filters_description(filters)
          return "" if filters.nil? || filters.empty?

          "\n**Note**: This diff has been filtered to show only changes in:\n" +
          filters.map { |f| "- `#{f}`" }.join("\n") + "\n"
        end

        # Make helper methods accessible
        private_class_method :create_context_config
        private_class_method :load_context
      end
    end
  end
end

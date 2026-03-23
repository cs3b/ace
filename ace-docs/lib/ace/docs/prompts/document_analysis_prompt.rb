# frozen_string_literal: true

require "open3"
require "timeout"
require "yaml"

module Ace
  module Docs
    module Prompts
      # Builds prompts for analyzing changes relevant to a specific document
      class DocumentAnalysisPrompt
        NAV_RESOLVE_TIMEOUT_SECONDS = 10

        # Build prompts for analyzing changes for a specific document
        # @param document [Document] The document to analyze changes for
        # @param diff [String, Hash] Either single diff string or hash of {subject_name => diff_string}
        # @param since [String] Time period for the diff
        # @param cache_dir [String, nil] Optional cache directory for context.md
        # @return [Hash] Hash with :system, :user prompts, :context_md, :diff_stats
        def self.build(document, diff, since: nil, cache_dir: nil)
          # Load base instructions
          base_instructions = load_user_prompt_template

          # Handle both single diff and multi-subject diffs
          diff_files = []
          if diff.is_a?(Hash)
            # Multi-subject: save each diff with subject name
            if cache_dir && Dir.exist?(cache_dir)
              diff.each do |subject_name, diff_content|
                next if diff_content.strip.empty?  # Skip empty diffs

                diff_file_path = File.join(cache_dir, "#{subject_name}.diff")
                File.write(diff_file_path, diff_content)
                # Store absolute path for ace-bundle (it resolves relative to context.md location)
                diff_files << diff_file_path
              end
            end
          elsif cache_dir && Dir.exist?(cache_dir)
            # Single diff: backward compatible behavior
            diff_file_path = File.join(cache_dir, "repo-diff.diff")
            File.write(diff_file_path, diff)
            # Store absolute path for ace-bundle
            diff_files << diff_file_path
          end

          # Create context.md = frontmatter + instructions + scope section
          # Use relative paths for diff files
          context_md = create_context_markdown(base_instructions, document, since,
            diff_files: diff_files)

          # Save context.md to cache
          if cache_dir && Dir.exist?(cache_dir)
            File.write(File.join(cache_dir, "context.md"), context_md)
          end

          # Load via ace-bundle (returns instructions + embedded context + diffs)
          embedded_content = load_context_md(context_md, document: document, cache_dir: cache_dir) || base_instructions

          # Calculate diff stats for metadata
          all_diffs = diff.is_a?(Hash) ? diff.values.join("\n") : diff
          diff_stats = calculate_diff_stats(all_diffs)

          {
            system: load_system_prompt,
            user: embedded_content,
            context_md: context_md,
            diff_stats: diff_stats
          }
        end

        # Load user prompt template via ace-nav protocol
        # @return [String] User prompt template content
        def self.load_user_prompt_template
          stdout, _, status = Open3.capture3("ace-nav", "prompt://document-analysis", "--content")

          if status.success?
            stdout.strip
          else
            # Fallback to reading file directly
            template_path = File.join(Ace::Docs.root, "handbook/prompts/document-analysis.md")
            File.exist?(template_path) ? File.read(template_path) : fallback_user_template
          end
        rescue
          fallback_user_template
        end

        # Fallback user template if ace-nav unavailable
        # @return [String] Minimal user template
        def self.fallback_user_template
          <<~TEMPLATE
            # Document Analysis

            ## Document Information
            **Path**: {document_path}
            **Type**: {document_type}
            **Purpose**: {document_purpose}

            ## Changes to Analyze
            {diff_content}
          TEMPLATE
        end

        # Load system prompt via ace-nav protocol
        # @return [String] System prompt content
        def self.load_system_prompt
          stdout, _, status = Open3.capture3("ace-nav", "prompt://document-analysis.system", "--content")

          if status.success?
            stdout.strip
          else
            # Fallback to embedded prompt if ace-nav fails
            fallback_system_prompt
          end
        rescue
          fallback_system_prompt
        end

        # Build user prompt with document context and diff
        # @param document [Document] The document to analyze
        # @param diff [String] The git diff content
        # @param since [String] Time period
        # @param context [String, nil] Optional embedded context from ace-bundle
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

        # Calculate diff statistics
        # @param diff [String] The git diff content
        # @return [Hash] Statistics with hunks_total, files_changed, insertions, deletions
        def self.calculate_diff_stats(diff)
          {
            hunks_total: diff.scan(/^@@ .+ @@/).size,
            files_changed: diff.scan(/^diff --git/).size,
            insertions: diff.scan(/^\+[^+]/).size,
            deletions: diff.scan(/^-[^-]/).size
          }
        end

        # Create context.md with frontmatter, instructions, and scope section
        # @param base_instructions [String] The base prompt instructions
        # @param document [Document] The document configuration
        # @param since [String] Time period for analysis
        # @param diff_files [Array<String>] Array of relative paths to diff files
        # @return [String] Complete context.md content
        def self.create_context_markdown(base_instructions, document, since, diff_files: [])
          # Start with base context config
          context_config = {
            "params" => {"format" => "markdown-xml"},
            "embed_document_source" => true
          }

          # Merge document's context configuration (supports new ace-docs namespace and legacy format)
          doc_context = document.ace_docs_config&.dig("context") || document.context_config || {}
          context_config = context_config.merge(doc_context)

          # Add template/guide files from document type config
          type_ref_files = resolve_type_references(document)
          if type_ref_files && !type_ref_files.empty?
            context_config["files"] ||= []
            context_config["files"].concat(type_ref_files)
          end

          # Add diff files to files array (append to existing files if any)
          if diff_files && !diff_files.empty?
            context_config["files"] ||= []
            context_config["files"].concat(diff_files)
          end

          frontmatter = {"context" => context_config}

          # Build analysis scope section
          scope_section = build_analysis_scope_section(document, since)

          # context.md = frontmatter + base instructions + scope section
          # YAML.dump adds opening --- but not closing, we add closing ---
          "#{YAML.dump(frontmatter).strip}\n---\n\n#{base_instructions}\n\n#{scope_section}"
        end

        # Build analysis scope section explaining context vs subject
        # @param document [Document] The document configuration
        # @param since [String] Time period for analysis
        # @return [String] Analysis scope section
        def self.build_analysis_scope_section(document, since)
          preset = document.context_preset
          keywords = document.context_keywords

          context_desc = if preset && !preset.empty?
            "- Loaded from preset: `#{preset}`"
          elsif keywords && !keywords.empty?
            "- Keywords: #{keywords.map { |k| "`#{k}`" }.join(", ")}"
          else
            "- No context files specified"
          end

          # Handle both multi-subject and single-subject configurations
          if document.multi_subject?
            subject_configs = document.subject_configurations
            filters_desc = if subject_configs.empty?
              "- All repository changes (no filters)"
            else
              subject_configs.map do |subj|
                "- `#{subj[:name]}`: #{subj[:filters].join(", ")}"
              end.join("\n")
            end
          else
            filters = document.subject_diff_filters || []
            filters_desc = if filters.empty?
              "- All repository changes (no filters)"
            else
              filters.map { |f| "- `#{f}`" }.join("\n")
            end
          end

          # Check for template/guide references from document type config
          refs_section = build_type_references_section(document)

          <<~SECTION
            ## Analysis Scope

            **Context files** (for understanding the codebase):
            #{context_desc}

            **Subject of analysis** (git diff filtered to):
            #{filters_desc}

            **Time range**: Changes since #{since || "recent"}
            #{refs_section}
          SECTION
        end

        # Resolve template and guide references from document type config
        # Looks up the document's type in Ace::Docs.config to find template/guide protocol URLs,
        # then resolves them to file paths via ace-nav
        # @param document [Document] The document configuration
        # @return [Array<String>] Array of resolved file paths
        def self.resolve_type_references(document)
          doc_type = document.doc_type
          return [] unless doc_type

          type_config = Ace::Docs.config.dig("document_types", doc_type)
          return [] unless type_config

          files = []
          %w[template guide].each do |ref_key|
            protocol_url = type_config[ref_key]
            next unless protocol_url

            stdout, _stderr, status = with_nav_resolve_timeout do
              Open3.capture3("ace-nav", "resolve", protocol_url)
            end
            if status.success?
              path = stdout.strip
              files << path if path && !path.empty? && File.exist?(path)
            end
          end

          files
        rescue
          []
        end

        def self.with_nav_resolve_timeout
          Timeout.timeout(NAV_RESOLVE_TIMEOUT_SECONDS) { yield }
        rescue Timeout::Error
          ["", "ace-nav resolve timed out after #{NAV_RESOLVE_TIMEOUT_SECONDS}s", Struct.new(:success?).new(false)]
        end

        # Build a reference section describing template/guide for this doc type
        # @param document [Document] The document configuration
        # @return [String] Reference section text or empty string
        def self.build_type_references_section(document)
          doc_type = document.doc_type
          return "" unless doc_type

          type_config = Ace::Docs.config.dig("document_types", doc_type)
          return "" unless type_config

          refs = []
          refs << "- Template: `#{type_config["template"]}`" if type_config["template"]
          refs << "- Guide: `#{type_config["guide"]}`" if type_config["guide"]
          return "" if refs.empty?

          "\n**Reference documents** (template/guide for `#{doc_type}` doc type):\n#{refs.join("\n")}\n"
        rescue
          ""
        end

        # Load context.md via ace-bundle (embeds files as XML)
        # @param context_md [String] The context.md content
        # @param document [Document] The document configuration (unused, kept for compatibility)
        # @param cache_dir [String, nil] Directory containing context.md and referenced files
        # @return [String, nil] Final prompt with embedded files or nil if unavailable
        def self.load_context_md(context_md, document:, cache_dir: nil)
          require "ace/bundle"

          # Load context.md - ace-bundle processes presets and files from frontmatter
          result = if cache_dir
            context_file = File.join(cache_dir, "context.md")
            Ace::Bundle.load_file(context_file)
          else
            Ace::Bundle.load_auto(context_md)
          end

          result.content
        rescue LoadError
          warn "ace-bundle not available - context embedding disabled" if Ace::Docs.debug?
          nil
        rescue => e
          warn "Context loading failed: #{e.message}" if Ace::Docs.debug?
          nil
        end

        # Make helper methods accessible
        private_class_method :load_user_prompt_template
        private_class_method :fallback_user_template
        private_class_method :calculate_diff_stats
        private_class_method :create_context_markdown
        private_class_method :build_analysis_scope_section
        private_class_method :resolve_type_references
        private_class_method :with_nav_resolve_timeout
        private_class_method :build_type_references_section
        private_class_method :load_context_md
      end
    end
  end
end

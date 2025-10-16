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
        # @param cache_dir [String, nil] Optional cache directory for context.md
        # @return [Hash] Hash with :system, :user prompts, and :context_md
        def self.build(document, diff, since: nil, cache_dir: nil)
          # Load user prompt template
          template = load_user_prompt_template

          # Calculate diff statistics
          diff_stats = calculate_diff_stats(diff)

          # Extract anchors from document
          doc_anchors = extract_anchors(document)

          # Find related documents
          related_docs = find_related_docs(document)
          target_docs = [document.path] + related_docs

          # Build anchors map for all target docs
          anchors_map = build_anchors_map([document.path] + related_docs.take(3))

          # Fill template placeholders
          filled_template = fill_template(template, document, diff, since, diff_stats, target_docs, anchors_map)

          # Create context.md with frontmatter
          context_md = create_context_markdown(document, filled_template, related_docs)

          # Save context.md to cache if directory provided
          if cache_dir && Dir.exist?(cache_dir)
            File.write(File.join(cache_dir, "context.md"), context_md)
          end

          # Load context via ace-context (embeds files as XML)
          final_user_prompt = load_context_md(context_md)

          {
            system: load_system_prompt,
            user: final_user_prompt || filled_template, # Fallback to template if ace-context unavailable
            context_md: context_md,
            diff_stats: diff_stats
          }
        end

        # Load user prompt template via ace-nav protocol
        # @return [String] User prompt template content
        def self.load_user_prompt_template
          stdout, stderr, status = Open3.capture3("ace-nav", "prompt://document-analysis", "--content")

          if status.success?
            stdout.strip
          else
            # Fallback to reading file directly
            template_path = File.join(Ace::Docs.root, "handbook/prompts/document-analysis.md")
            File.exist?(template_path) ? File.read(template_path) : fallback_user_template
          end
        rescue StandardError
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

        # Extract section anchors from a document
        # @param document [Document] The document to extract anchors from
        # @return [String] Formatted anchor map
        def self.extract_anchors(document)
          return "" unless document.path && File.exist?(document.path)

          content = File.read(document.path)
          anchors = []
          current_h2 = nil
          current_h3 = nil

          content.each_line do |line|
            if line =~ /^##\s+(.+)$/
              current_h2 = $1.strip
              current_h3 = nil
              anchors << "  - ## #{current_h2}"
            elsif line =~ /^###\s+(.+)$/
              current_h3 = $1.strip
              anchors << "    - ### #{current_h3}"
            elsif line =~ /^####\s+(.+)$/
              h4 = $1.strip
              anchors << "      - #### #{h4}"
            end
          end

          return "(No section structure found)" if anchors.empty?

          anchors.join("\n")
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

        # Find related documents based on document type and path
        # @param document [Document] The document being analyzed
        # @return [Array<String>] List of related document paths
        def self.find_related_docs(document)
          related = []

          # Add CHANGELOG if it exists
          related << "CHANGELOG.md" if File.exist?("CHANGELOG.md")

          # Based on document type, add relevant docs
          case document.doc_type
          when "reference", "readme"
            related << "docs/usage.md" if File.exist?("docs/usage.md")
            related << "docs/api.md" if File.exist?("docs/api.md")
          when "guide", "tutorial"
            related << "README.md" if File.exist?("README.md")
          when "architecture"
            related << "docs/design/*.md" if Dir.glob("docs/design/*.md").any?
          when "workflow"
            # Add other workflow docs
            Dir.glob("handbook/workflow-instructions/*.wf.md").each { |f| related << f }
          end

          # Look for docs that mention this document
          # (Simple implementation - can be enhanced)

          related.uniq.reject { |path| path == document.path }
        end

        # Build anchors map for multiple documents
        # @param doc_paths [Array<String>] List of document paths
        # @return [String] Formatted anchors map
        def self.build_anchors_map(doc_paths)
          map = []

          doc_paths.each do |path|
            next unless File.exist?(path)

            map << "\n### #{path}\n"
            content = File.read(path)

            content.each_line do |line|
              if line =~ /^##\s+(.+)$/
                map << "  - ## #{$1.strip}"
              elsif line =~ /^###\s+(.+)$/
                map << "    - ### #{$1.strip}"
              elsif line =~ /^####\s+(.+)$/
                map << "      - #### #{$1.strip}"
              end
            end
          end

          map.empty? ? "(No section structures found)" : map.join("\n")
        end

        # Fill template placeholders with actual values
        # @param template [String] The template with placeholders
        # @param document [Document] The document being analyzed
        # @param diff [String] The git diff
        # @param since [String] Time period
        # @param diff_stats [Hash] Diff statistics
        # @param target_docs [Array<String>] List of target documents
        # @param anchors_map [String] Formatted anchors map
        # @return [String] Filled template
        def self.fill_template(template, document, diff, since, diff_stats, target_docs, anchors_map)
          # Extract document metadata
          doc_path = document.respond_to?(:relative_path) ? document.relative_path : document.path
          doc_type = document.doc_type || "document"
          purpose = document.purpose || "(not specified)"
          keywords = document.context_keywords
          preset = document.context_preset
          filters = document.subject_diff_filters

          # Build target documents list
          target_list = target_docs.map { |path| "- #{path}" }.join("\n")

          # Build time period description
          time_period = since ? "since #{since}" : "recent"

          # Build filters note
          filters_note = if filters && !filters.empty?
                           "\n**Note**: This diff has been filtered to show only changes in:\n" +
                           filters.map { |f| "- `#{f}`" }.join("\n")
                         else
                           ""
                         end

          # Fill all placeholders
          template
            .gsub("{document_path}", doc_path)
            .gsub("{document_type}", doc_type)
            .gsub("{document_purpose}", purpose)
            .gsub("{context_keywords}", keywords && !keywords.empty? ? keywords.join(", ") : "(none)")
            .gsub("{context_preset}", preset || "(none)")
            .gsub("{target_documents_list}", target_list)
            .gsub("{anchors_map}", anchors_map)
            .gsub("{hunks_total}", diff_stats[:hunks_total].to_s)
            .gsub("{files_changed}", diff_stats[:files_changed].to_s)
            .gsub("{insertions}", diff_stats[:insertions].to_s)
            .gsub("{deletions}", diff_stats[:deletions].to_s)
            .gsub("{time_period}", time_period)
            .gsub("{subject_filters_note}", filters_note)
            .gsub("{diff_content}", diff)
        end

        # Create context.md with frontmatter and filled template
        # @param document [Document] The document being analyzed
        # @param filled_template [String] Template with placeholders filled
        # @param related_docs [Array<String>] List of related document paths
        # @return [String] Complete context.md content
        def self.create_context_markdown(document, filled_template, related_docs)
          # Build frontmatter
          files = [document.path] + related_docs.take(3) # Limit to avoid too large context

          frontmatter = {
            "files" => files.compact,
            "embed_document_source" => true,
            "format" => "markdown-xml"
          }

          # Create context.md
          "---\n#{YAML.dump(frontmatter)}---\n\n#{filled_template}"
        end

        # Load context.md via ace-context (embeds files as XML)
        # @param context_md [String] The context.md content
        # @return [String, nil] Final prompt with embedded files or nil if unavailable
        def self.load_context_md(context_md)
          begin
            require "ace/context"

            result = Ace::Context.load_auto(context_md, format: "markdown-xml")
            result.content
          rescue LoadError
            warn "ace-context not available - context embedding disabled" if Ace::Docs.debug?
            nil
          rescue StandardError => e
            warn "Context loading failed: #{e.message}" if Ace::Docs.debug?
            nil
          end
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
        private_class_method :load_user_prompt_template
        private_class_method :fallback_user_template
        private_class_method :extract_anchors
        private_class_method :calculate_diff_stats
        private_class_method :find_related_docs
        private_class_method :build_anchors_map
        private_class_method :fill_template
        private_class_method :create_context_markdown
        private_class_method :load_context_md
      end
    end
  end
end

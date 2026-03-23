# frozen_string_literal: true

require "yaml"
require "fileutils"

# Try to load ace-bundle for better document embedding
begin
  require "ace/bundle"
rescue LoadError
  # Will work without ace-bundle but with less optimal formatting
end

module Ace
  module Docs
    module Prompts
      # Builds prompts for cross-document consistency analysis
      class ConsistencyPrompt
        # Build the complete prompt for consistency analysis
        # @param documents [Hash] hash of { path => content } for documents to analyze
        # @param options [Hash] analysis options
        # @param session_dir [String, nil] session directory for saving context.md
        # @return [Hash] { system: String, user: String } prompts
        def build(documents, options = {}, session_dir: nil)
          # Use ace-bundle if available for better document separation
          user_content = if defined?(Ace::Bundle) && session_dir
            build_with_context(documents, options, session_dir)
          else
            user_prompt(documents, options)
          end

          {
            system: system_prompt,
            user: user_content
          }
        end

        private

        # Generate the system prompt with analysis instructions
        def system_prompt
          <<~PROMPT
            You are a documentation consistency analyzer. Analyze the provided documents for consistency issues.

            ## Analysis Types

            1. **TERMINOLOGY CONFLICTS**: Inconsistent word usage
               - Different words for the same concept (e.g., "gem" vs "package" in Ruby context)
               - Spelling variations (US vs UK: "analyze" vs "analyse", "color" vs "colour")
               - Case inconsistencies (e.g., "GitHub" vs "github" vs "Github")
               - Technical term variations (e.g., "LLM" vs "large language model")

            2. **DUPLICATE CONTENT**: Similar or identical content blocks
               - Identify content that appears in multiple documents with >70% similarity
               - Flag redundant explanations of the same concept
               - Note which document should be the authoritative source

            3. **VERSION INCONSISTENCIES**: Mismatched version numbers
               - Different version numbers for the same tool/library
               - Outdated references in some documents
               - Inconsistent release information

            4. **CONSOLIDATION OPPORTUNITIES**: Content that could be merged
               - Multiple documents explaining the same workflow
               - Scattered information that belongs together
               - Overlapping guides that could be combined

            ## Response Format

            Return ONLY valid JSON in this exact structure:

            ```json
            {
              "terminology_conflicts": [
                {
                  "terms": ["term1", "term2"],
                  "occurrences": {
                    "term1": [
                      {"file": "path/to/file1.md", "count": 5, "examples": ["line excerpt 1", "line excerpt 2"]},
                      {"file": "path/to/file2.md", "count": 3, "examples": ["line excerpt"]}
                    ],
                    "term2": [
                      {"file": "path/to/file3.md", "count": 8, "examples": ["line excerpt"]}
                    ]
                  },
                  "recommendation": "Standardize to 'term1' (Ruby ecosystem convention)"
                }
              ],
              "duplicate_content": [
                {
                  "description": "Installation instructions",
                  "similarity_percentage": 85,
                  "locations": [
                    {"file": "README.md", "lines": "45-67", "excerpt": "first 50 chars..."},
                    {"file": "docs/getting-started.md", "lines": "12-34", "excerpt": "first 50 chars..."}
                  ],
                  "recommendation": "Keep in getting-started.md, reference from README"
                }
              ],
              "version_inconsistencies": [
                {
                  "item": "ace-docs version",
                  "versions_found": [
                    {"version": "0.4.5", "file": "README.md", "line": 12},
                    {"version": "0.4.6", "file": "CHANGELOG.md", "line": 5},
                    {"version": "0.4.4", "file": "docs/api.md", "line": 23}
                  ],
                  "recommendation": "Update all to 0.4.6 (latest in CHANGELOG)"
                }
              ],
              "consolidation_opportunities": [
                {
                  "topic": "Workflow instructions for updating documents",
                  "documents": [
                    {"file": "docs/update-workflow.md", "coverage": "comprehensive"},
                    {"file": "docs/quick-update.md", "coverage": "basic steps"},
                    {"file": "README.md", "coverage": "brief mention in section 'Updating Documents'"}
                  ],
                  "recommendation": "Consolidate into single workflow document with quick-start section"
                }
              ]
            }
            ```

            ## Analysis Guidelines

            - For terminology: Consider context (Ruby gems vs npm packages)
            - For duplicates: Use the similarity threshold provided (default 70%)
            - For versions: Check semantic versioning and identify the most recent
            - For consolidation: Consider user journey and information architecture
            - Always provide actionable, specific recommendations
            - Include file paths and line numbers when possible
            - Provide brief excerpts to illustrate the issues
          PROMPT
        end

        # Generate the user prompt with document content and parameters
        def user_prompt(documents, options)
          threshold = options[:threshold] || 70
          focus_areas = build_focus_areas(options)

          <<~PROMPT
            Analyze these #{documents.count} documents for consistency issues:

            ## Documents to Analyze

            #{format_documents(documents)}

            ## Analysis Parameters

            - Similarity threshold for duplicates: #{threshold}%
            - Focus areas: #{focus_areas.join(", ")}
            #{"- Pattern filter: #{options[:pattern]}" if options[:pattern]}

            ## Instructions

            1. Scan all documents for the four types of consistency issues
            2. Apply the similarity threshold of #{threshold}% for duplicate detection
            3. Provide specific, actionable recommendations for each issue
            4. Include file paths and line references where applicable
            5. Return results in the exact JSON format specified

            Analyze the documents now and return the JSON results.
          PROMPT
        end

        # Format documents for inclusion in the prompt
        def format_documents(documents)
          documents.map do |path, content|
            # Extract frontmatter if present
            frontmatter = extract_frontmatter(content)

            # Truncate very long documents
            truncated_content = truncate_content(content)

            <<~DOC
              ### File: #{path}
              #{"Frontmatter: #{frontmatter.to_json}\n" if frontmatter}
              ```
              #{truncated_content}
              ```
            DOC
          end.join("\n")
        end

        # Extract YAML frontmatter from content
        def extract_frontmatter(content)
          return nil unless content.start_with?("---\n")

          parts = content.split(/^---\s*$/, 3)
          return nil unless parts.size >= 2

          begin
            require "yaml"
            YAML.safe_load(parts[1])
          rescue
            nil
          end
        end

        # Truncate content if it's too long
        def truncate_content(content, max_lines = 500)
          lines = content.lines
          return content if lines.size <= max_lines

          truncated = lines.first(max_lines).join
          truncated + "\n... (truncated, #{lines.size - max_lines} lines omitted) ..."
        end

        # Build focus areas based on options
        def build_focus_areas(options)
          areas = []

          if options[:all] || (!options[:terminology] && !options[:duplicates] && !options[:versions])
            areas = ["terminology conflicts", "duplicate content", "version inconsistencies", "consolidation opportunities"]
          else
            areas << "terminology conflicts" if options[:terminology]
            areas << "duplicate content" if options[:duplicates]
            areas << "version inconsistencies" if options[:versions]
          end

          areas.empty? ? ["all issue types"] : areas
        end

        # Build user prompt with ace-bundle for better document separation
        def build_with_context(documents, options, session_dir)
          # Use the actual document paths directly (no copying needed)
          doc_files = documents.keys.map { |path| File.expand_path(path) }

          # Create context.md with frontmatter and instructions
          threshold = options[:threshold] || 70
          focus_areas = build_focus_areas(options)

          # Build context configuration
          context_config = {
            "params" => {"format" => "markdown-xml"},
            "embed_document_source" => true,
            "files" => doc_files
          }

          # Create frontmatter
          frontmatter = {"context" => context_config}

          # Build instructions
          instructions = <<~INSTRUCTIONS
            # Cross-Document Consistency Analysis

            Analyze these #{documents.count} documents for consistency issues.

            ## Analysis Parameters

            - Similarity threshold for duplicates: #{threshold}%
            - Focus areas: #{focus_areas.join(", ")}
            #{"- Pattern filter: #{options[:pattern]}" if options[:pattern]}

            ## Instructions

            1. Scan all documents for the four types of consistency issues
            2. Apply the similarity threshold of #{threshold}% for duplicate detection
            3. Provide specific, actionable recommendations for each issue
            4. Include file paths and line references where applicable
            5. Return results in the exact JSON format specified

            ## Documents

            The following documents are embedded below using XML tags:
          INSTRUCTIONS

          # Create context.md
          context_md_content = "#{YAML.dump(frontmatter).strip}\n---\n\n#{instructions}"
          context_md_path = File.join(session_dir, "context.md")
          File.write(context_md_path, context_md_content)

          # Load via ace-bundle to get XML-embedded documents
          begin
            result = Ace::Bundle.load_file(context_md_path)
            result.content
          rescue => e
            warn "ace-bundle embedding failed: #{e.message}, falling back to direct format" if Ace::Docs.debug?
            # Fallback to regular prompt if ace-bundle fails
            user_prompt(documents, options)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "ace/support/fs"
require_relative "../molecules/document_loader"
require_relative "../models/document"
require_relative "../atoms/type_inferrer"

module Ace
  module Docs
    module Organisms
      # Discovers and indexes all managed documents in the project
      class DocumentRegistry
        attr_reader :documents, :config

        # Initialize the document registry
        # @param project_root [String, nil] Project root directory
        # @param config [Hash, nil] Optional config override (for testing)
        def initialize(project_root: nil, config: nil, scope_globs: nil)
          @project_root = project_root || determine_project_root
          @config = config || Ace::Docs.config
          @scope_globs = Array(scope_globs).compact
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
          return nil unless File.exist?(path)

          real_path = File.realpath(path)
          @documents.find { |doc| File.exist?(doc.path) && File.realpath(doc.path) == real_path }
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

        def determine_project_root
          Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
        end

        def discover_documents
          # First, discover documents with explicit frontmatter
          discover_explicit_documents

          # Then, discover documents matching type patterns
          discover_configured_documents
        end

        def discover_explicit_documents
          # Search for all markdown files in the project
          all_md_files = if @scope_globs.empty?
                           Dir.glob(File.join(@project_root, "**/*.md"))
                         else
                           @scope_globs.flat_map do |pattern|
                             Dir.glob(File.join(@project_root, pattern))
                           end.uniq
                         end

          # Load those with ace-docs frontmatter
          all_md_files.each do |path|
            next if ignored_path?(path)
            next unless in_scope?(path)

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

            # Separate inclusion and exclusion patterns
            include_patterns = []
            exclude_patterns = []

            paths.each do |pattern|
              if pattern.start_with?("!")
                # Exclusion pattern (remove the !)
                exclude_patterns << pattern[1..]
              else
                # Inclusion pattern
                include_patterns << pattern
              end
            end

            # First collect all matching files from inclusion patterns
            all_matching_files = []
            include_patterns.each do |pattern|
              matching_files = Dir.glob(File.join(@project_root, pattern))
              all_matching_files.concat(matching_files)
            end

            # Then filter out excluded files
            exclude_patterns.each do |pattern|
              excluded_files = Dir.glob(File.join(@project_root, pattern))
              all_matching_files -= excluded_files
            end

            # Process the final list of files
            all_matching_files.uniq.each do |path|
              next if ignored_path?(path)
              next unless in_scope?(path)
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
              elsif doc && !doc.managed?
                # Document has partial frontmatter but missing doc-type or purpose
                # Augment it with inferred values
                augmented_frontmatter = doc.frontmatter.dup

                # Infer doc-type using priority hierarchy
                inferred_type = Atoms::TypeInferrer.resolve(
                  path,
                  pattern_type: type_name,
                  frontmatter_type: augmented_frontmatter["doc-type"]
                )
                augmented_frontmatter["doc-type"] ||= inferred_type if inferred_type

                # Infer purpose if missing
                augmented_frontmatter["purpose"] ||= infer_purpose_from_content(doc)

                # Merge defaults for update config if needed
                if augmented_frontmatter["update"]
                  augmented_frontmatter["update"] = defaults.merge(augmented_frontmatter["update"])
                else
                  augmented_frontmatter["update"] = defaults
                end

                # Create new document with augmented frontmatter
                doc = Models::Document.new(
                  path: doc.path,
                  frontmatter: augmented_frontmatter,
                  content: doc.content
                )
              end

              @documents << doc if doc
            end
          end
        end

        def ignored_path?(path)
          # Start with default ignored patterns
          # For tmp/, build a specific pattern matching <project_root>/tmp/
          tmp_dir = File.join(@project_root, "tmp")
          ignored_patterns = [
            %r{/\.git/},
            %r{/node_modules/},
            %r{/vendor/},
            %r{^#{Regexp.escape(tmp_dir)}/},  # Only ignore <project_root>/tmp/
            %r{/coverage/},
            %r{/_legacy/},
            %r{/\.ace-taskflow/done/}
          ]

          # Add patterns from config if available
          if @config && @config["ignore"]
            config_patterns = @config["ignore"].map do |pattern|
              # Convert glob patterns to regex
              # Remove leading ! for negation patterns (handle separately)
              if pattern.start_with?("!")
                nil  # Skip negation patterns here
              else
                glob_to_regex(pattern)
              end
            end.compact
            ignored_patterns.concat(config_patterns)
          end

          ignored_patterns.any? { |pattern| path.match?(pattern) }
        end

        def in_scope?(path)
          return true if @scope_globs.empty?

          rel = path.sub(/^#{Regexp.escape(@project_root)}\/?/, "")
          @scope_globs.any? do |pattern|
            File.fnmatch?(pattern, rel, File::FNM_PATHNAME | File::FNM_EXTGLOB | File::FNM_DOTMATCH)
          end
        end

        def glob_to_regex(glob_pattern)
          # Convert glob pattern to regex, anchored to project root
          # This ensures patterns like "tmp/**" match <project_root>/tmp/**, not system /tmp/

          # First replace the glob wildcards with placeholders
          regex_str = glob_pattern
            .gsub("**", "\x00DOUBLESTAR\x00")
            .gsub("*", "\x00STAR\x00")

          # Escape special regex characters
          regex_str = regex_str.gsub(/([.+?^${}()\[\]\\|])/) { |m| "\\#{m}" }

          # Now replace the placeholders with regex equivalents
          regex_str = regex_str
            .gsub("\x00DOUBLESTAR\x00", ".*")     # ** matches any characters including /
            .gsub("\x00STAR\x00", "[^/]*")        # * matches within a single directory

          # Anchor to project root unless pattern starts with ** (which means "anywhere under project")
          if glob_pattern.start_with?("**/")
            # Pattern like "**/tmp/**" means "anywhere under project root"
            regex_str = "#{Regexp.escape(@project_root)}/#{regex_str}"
          else
            # Pattern like "tmp/**" means "at project root"
            regex_str = "^#{Regexp.escape(@project_root)}/#{regex_str}"
          end

          Regexp.new(regex_str)
        end

        def infer_purpose_from_content(document)
          # Try to extract purpose from document content or metadata

          # 1. Check if frontmatter has 'name' field (common in workflow files)
          if document.frontmatter["name"]
            name = document.frontmatter["name"]
            return "#{name} workflow instruction"
          end

          # 2. Check if frontmatter has 'description' field
          if document.frontmatter["description"]
            return document.frontmatter["description"]
          end

          # 3. Try to extract from first H1 heading
          if document.content && document.content =~ /^#\s+(.+)$/
            heading = $1.strip
            return heading unless heading.empty?
          end

          # 4. Fallback to filename-based description
          filename = File.basename(document.path, ".*")
          "#{filename.gsub(/[-_]/, ' ').capitalize} documentation"
        end
      end
    end
  end
end

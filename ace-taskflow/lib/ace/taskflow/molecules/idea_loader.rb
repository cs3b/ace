# frozen_string_literal: true

require "pathname"
require "set"
require "ace/support/timestamp"
require_relative "../models/idea"
require_relative "release_resolver"
require_relative "config_loader"
require_relative "../configuration"
require_relative "../atoms/yaml_parser"
require_relative "../atoms/id_title_extractor"
require_relative "idea_structure_validator"

module Ace
  module Taskflow
    module Molecules
      class IdeaLoader
        # Filename extension for idea files (only .idea.s.md format supported)
        IDEA_EXT = ".idea.s.md".freeze

        # Scope-specific subdirectories for organizing ideas (GTD-inspired)
        # Scopes organize ideas by priority/certainty (folder location):
        #   - next (top-level): Immediately actionable ideas
        #   - maybe/: Uncertain if we should do it
        #   - anyday/: Good idea but not urgent
        #   - _archive/: Completed or skipped (configurable via done_dir)
        #   - _maybe/: Good idea but not now (configurable via parked_dir)
        # Note: Scope is independent from status (draft/pending/in-progress/done/obsolete)
        # These values are used as fallback; configuration takes precedence
        # Case-insensitive comparison for robustness against filesystem naming variations
        SCOPE_SUBDIRECTORIES = %w[_archive _maybe maybe anyday].freeze

        def self.excluded_directory?(dir_name)
          SCOPE_SUBDIRECTORIES.any? { |excluded| excludedcasecmp?(dir_name, excluded) }
        end

        def excluded_directory?(dir_name)
          self.class.excluded_directory?(dir_name)
        end

        # Helper for case-insensitive comparison (handles filesystem naming variations)
        def self.excludedcasecmp?(a, b)
          a.downcase == b.downcase
        end

        def initialize(root_path = nil)
          @root_path = root_path || ConfigLoader.find_root
          @config = ConfigLoader.load
          @release_resolver = ReleaseResolver.new(@root_path)
        end

        # Load all ideas matching the glob patterns
        # @param release [String] The release to load from (default: "current")
        #   - "current" or "active": Load from active release
        #   - "backlog": Load from backlog directory
        #   - "v.X.Y.Z": Load from specific release
        # @param include_content [Boolean] Whether to include file content (default: false)
        # @param glob [Array<String>, nil] Glob patterns to match (default: ["ideas/**/*.idea.s.md"])
        #   - Default `["ideas/**/*.idea.s.md"]` matches ALL ideas including subdirectories (maybe/, anyday/, done/)
        #   - Use `["ideas/*.idea.s.md"]` for top-level ideas only (excludes subdirectories)
        #   - Use `["ideas/maybe/**/*.idea.s.md"]` for ideas in maybe/ subdirectory only
        #   - Patterns are relative to the release root (release/backlog path)
        # @return [Array<Hash>] Array of idea hashes with keys: :id, :filename, :title, :path, :created_at, :release
        # @example Load all ideas from current release
        #   loader.load_all(release: "current")
        # @example Load top-level ideas only (no subdirectories)
        #   loader.load_all(release: "current", glob: ["ideas/*#{IDEA_EXT}"])
        # @example Load maybe ideas only
        #   loader.load_all(release: "current", glob: ["ideas/maybe/**/*#{IDEA_EXT}"])
        def load_all(release: "current", include_content: false, glob: nil)
          # Use glob-based loading (glob defaults to all ideas if not provided)
          # Use the default pattern from configuration if no glob provided
          glob ||= Taskflow.configuration.default_glob_pattern
          load_all_with_glob(release: release, include_content: include_content, glob: glob)
        end

        def find_next(release: "current")
          # Top-level ideas only (excludes subdirectories like maybe/, anyday/, done/)
          # Use IDEA_EXT constant for consistency (DRY principle)
          ideas = load_all(release: release, include_content: false, glob: ["*/*#{IDEA_EXT}"])
          ideas.first
        end

        def find_by_partial_name(partial, release: "current")
          # All ideas (including subdirectories)
          ideas = load_all(release: release, include_content: false)

          # Find first idea where filename contains the partial string
          ideas.find do |idea|
            idea[:filename].downcase.include?(partial.downcase)
          end
        end

        def find_by_reference(reference)
          # Parse reference format - supports:
          # - Compact Base36 format: "abc123"
          # - Partial name search for anything else
          format = Ace::Support::Timestamp.detect_format(reference)

          if format == :compact
            # Full ID reference (compact Base36)
            ideas = load_all(release: "current", include_content: true)
            ideas.find { |idea| idea[:id] == reference }
          else
            # Partial name search
            find_by_partial_name(reference)
          end
        end

        def load_idea(path, include_content: true)
          return nil unless File.exist?(path) || Dir.exist?(path)

          # Check if it's a directory (new format with attachments)
          if Dir.exist?(path)
            load_idea_from_directory(path, include_content)
          else
            load_idea_file(path, include_content)
          end
        end

        def count_by_release
          counts = {}
          ideas_dirname = @config.dig("taskflow", "directories", "ideas") || "ideas"

          # Count in active releases
          @release_resolver.find_active.each do |release|
            idea_dir = File.join(release[:path], ideas_dirname)
            counts[release[:name]] = count_ideas_in_directory(idea_dir)
          end

          # Count in backlog
          backlog_release_root = determine_release_root("backlog")
          backlog_idea_dir = File.join(backlog_release_root, ideas_dirname)
          counts["backlog"] = count_ideas_in_directory(backlog_idea_dir)

          counts
        end

        # Detect misplaced ideas outside the proper ideas/ subdirectory structure
        # @return [Hash] validation result with :valid, :misplaced, :total keys
        def detect_misplaced_ideas
          validator = IdeaStructureValidator.new(@root_path)
          validator.validate_all
        end

        private

        # Load ideas using glob patterns
        def load_all_with_glob(release:, include_content:, glob:)
          # Use release root (release path) not idea directory, since glob patterns include ideas/ prefix
          release_root = determine_release_root(release)
          return [] unless release_root && Dir.exist?(release_root)

          ideas = []
          matched_paths = Set.new
          loaded_directories = Set.new  # Track directories we've already loaded

          # Apply each glob pattern - prepend ideas directory
          ideas_dir = Taskflow.configuration.ideas_dir
          Array(glob).each do |pattern|
            # Prepend ideas directory to pattern if not already there
            full_pattern = if pattern.start_with?("#{ideas_dir}/")
              pattern
            else
              File.join(ideas_dir, pattern)
            end
            Dir.glob(File.join(release_root, full_pattern)).each do |path|
              # Avoid duplicates
              next if matched_paths.include?(path)
              matched_paths.add(path)

              # Load idea from file or directory
              if File.file?(path) && path.end_with?(IDEA_EXT)
                # Directory-based idea: {slug}.idea.s.md file inside a directory
                parent_dir = File.dirname(path)
                ideas_dirname = Taskflow.configuration.ideas_dir

                # Check if it's in a subdirectory (not directly in ideas root)
                # Explicit equality check handles edge case where parent_dir is exactly ideas_dirname
                if parent_dir != ideas_dirname && !parent_dir.end_with?("/#{ideas_dirname}")
                  # Skip if we've already loaded from this directory
                  next if loaded_directories.include?(parent_dir)
                  loaded_directories.add(parent_dir)

                  # Load from directory
                  idea = load_idea_from_directory(parent_dir, include_content)
                  ideas << idea if idea
                end
              elsif Dir.exist?(path)
                # Skip if we've already loaded from this directory
                next if loaded_directories.include?(path)
                loaded_directories.add(path)

                # Check if it's a directory-based idea (contains .idea.s.md)
                idea_files = Dir.glob(File.join(path, "*#{IDEA_EXT}"))
                if idea_files.any?
                  idea = load_idea_from_directory(path, include_content)
                  ideas << idea if idea
                end
              end
            end
          end

          ideas
        end

        def load_ideas_from_directory(dir, include_content)
          ideas = []

          # Load directory-based ideas (directories containing .idea.s.md)
          Dir.glob(File.join(dir, "*")).sort.each do |path|
            next unless Dir.exist?(path)
            # Skip scope subdirectories
            basename = File.basename(path)
            next if excluded_directory?(basename)

            idea_files = Dir.glob(File.join(path, "*#{IDEA_EXT}"))
            idea_files.each do |idea_file|
              parent_dir = File.dirname(idea_file)
              idea = load_idea_from_directory(parent_dir, include_content)
              ideas << idea if idea
            end
          end

          ideas
        end

        def load_idea_from_directory(dir_path, include_content)
          dirname = File.basename(dir_path)

          # Load the .idea.s.md file from the directory (only supported format)
          idea_file = Dir.glob(File.join(dir_path, "*#{IDEA_EXT}")).first
          return nil unless idea_file

          # Extract ID from dirname (Base36 format: "abc123-my-idea" -> "abc123")
          id, title = Ace::Taskflow::Atoms::IdTitleExtractor.extract_from_dirname(dirname)

          # Find attachment files (exclude all .s.md files)
          attachments = Dir.glob(File.join(dir_path, "*"))
            .reject { |f| f.end_with?(".s.md") }
            .select { |f| File.file?(f) }
            .map { |f| File.basename(f) }
            .sort

          # Read content to parse frontmatter
          content = File.read(idea_file)
          parsed = Atoms::YamlParser.parse(content)
          frontmatter = parsed[:frontmatter] || {}
          body_content = parsed[:content]

          # Try to extract title from content header (always do this, not just when include_content is true)
          title = extract_title_from_content(body_content) || title

          idea_data = {
            id: id,
            filename: dirname,
            title: title,
            path: dir_path,
            file_path: idea_file,
            created_at: extract_timestamp_from_filename(dirname),
            release: extract_release_from_path(dir_path),
            attachments: attachments,
            is_directory: true,
            status: frontmatter["status"] || "pending",
            priority: frontmatter["priority"]
          }

          if include_content
            idea_data[:content] = body_content
          end

          idea_data
        end

        # Determine the release root directory (backlog or release)
        # This is used for glob-based loading where patterns start from release root
        def determine_release_root(release_name)
          backlog_dir = Ace::Taskflow.configuration.backlog_dir

          case release_name
          when "current", "active", nil
            # Find active release
            active_release = @release_resolver.find_primary_active
            if active_release
              active_release[:path]
            else
              # Fall back to backlog if no active release
              File.join(@root_path, backlog_dir)
            end
          when "backlog"
            File.join(@root_path, backlog_dir)
          when /^v\.\d+\.\d+\.\d+/
            # Specific release
            found_release = @release_resolver.find_release(release_name)
            found_release ? found_release[:path] : nil
          else
            # Try to find as release name
            found_release = @release_resolver.find_release(release_name)
            found_release ? found_release[:path] : nil
          end
        end

        # Determine the ideas directory within a release
        # This is used for scope-based loading (backward compatibility)
        def determine_idea_directory(release)
          release_root = determine_release_root(release)
          return nil unless release_root

          ideas_dirname = @config.dig("taskflow", "directories", "ideas") || "ideas"
          File.join(release_root, ideas_dirname)
        end

        def load_idea_file(path, include_content)
          return nil unless File.exist?(path)

          filename = File.basename(path)

          # Extract ID and title from filename (Base36 format: "abc123-my-idea.s.md")
          basename = filename.sub(/\.s\.md$/, "").sub(/\.md$/, "")
          id, title = Ace::Taskflow::Atoms::IdTitleExtractor.extract_from_dirname(basename)

          # Read content to parse frontmatter
          content = File.read(path)
          parsed = Atoms::YamlParser.parse(content)
          frontmatter = parsed[:frontmatter]
          body_content = parsed[:content]

          idea_data = {
            id: id,
            filename: filename,
            title: title,
            path: path,
            file_path: path,
            created_at: extract_timestamp_from_filename(filename),
            release: extract_release_from_path(path),
            attachments: [],
            is_directory: false,
            status: frontmatter["status"] || "pending",
            priority: frontmatter["priority"]
          }

          if include_content
            idea_data[:content] = body_content

            # Try to extract title from content header
            content_title = extract_title_from_content(body_content)
            idea_data[:title] = content_title if content_title
          end

          idea_data
        end

        # Extract title from content header (# Title)
        # @param content [String] The content to search for title
        # @return [String, nil] The extracted title or nil if not found
        def extract_title_from_content(content)
          return nil unless content
          return nil unless content =~ /^#\s+(.+)$/
          Regexp.last_match(1).strip
        end

        def extract_timestamp_from_filename(filename)
          # Extract the ID using Base36 format detection
          id, _title = Ace::Taskflow::Atoms::IdTitleExtractor.extract_from_dirname(filename)

          return Time.now unless id

          format = Ace::Support::Timestamp.detect_format(id)
          if format == :compact
            # Compact Base36 format - decode to Time
            Ace::Support::Timestamp.decode(id)
          else
            # Fallback for unrecognized format
            Time.now
          end
        rescue StandardError
          # Fallback if decoding fails
          Time.now
        end

        def extract_release_from_path(path)
          relative = Pathname.new(path).relative_path_from(Pathname.new(@root_path)).to_s
          backlog_dir = @config.dig("taskflow", "directories", "backlog") || "backlog"

          if relative.start_with?("#{backlog_dir}/")
            "backlog"
          elsif relative =~ /^v\.\d+\.\d+\.\d+/
            relative.split("/").first
          else
            "current"
          end
        end

        def count_ideas_in_directory(dir)
          return 0 unless Dir.exist?(dir)

          # Count directory-based ideas (directories containing .idea.s.md)
          dir_count = Dir.glob(File.join(dir, "*"))
            .select { |path| Dir.exist?(path) && !excluded_directory?(File.basename(path)) }
            .count { |path| Dir.glob(File.join(path, "*#{IDEA_EXT}")).any? }

          main_count = dir_count

          # Count ideas in scope subdirectories
          subdirs_count = 0
          SCOPE_SUBDIRECTORIES.each do |subdir_name|
            subdir = File.join(dir, subdir_name)
            next unless Dir.exist?(subdir)

            subdir_dirs = Dir.glob(File.join(subdir, "*"))
              .select { |path| Dir.exist?(path) }
              .count { |path| Dir.glob(File.join(path, "*#{IDEA_EXT}")).any? }
            subdirs_count += subdir_dirs
          end

          main_count + subdirs_count
        end
      end
    end
  end
end
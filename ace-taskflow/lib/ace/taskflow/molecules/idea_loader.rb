# frozen_string_literal: true

require "pathname"
require "set"
require_relative "../models/idea"
require_relative "release_resolver"
require_relative "config_loader"
require_relative "../configuration"
require_relative "../atoms/yaml_parser"

module Ace
  module Taskflow
    module Molecules
      class IdeaLoader
        # Scope-specific subdirectories for organizing ideas (GTD-inspired)
        # Scopes organize ideas by priority/certainty (folder location):
        #   - next (top-level): Immediately actionable ideas
        #   - maybe/: Uncertain if we should do it
        #   - anyday/: Good idea but not urgent
        #   - done/: Completed or skipped
        # Note: Scope is independent from status (draft/pending/in-progress/done/obsolete)
        SCOPE_SUBDIRECTORIES = %w[done maybe anyday].freeze

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
        # @param glob [Array<String>, nil] Glob patterns to match (default: ["ideas/**/*.s.md"])
        #   - Default `["ideas/**/*.s.md"]` matches ALL ideas including subdirectories (maybe/, anyday/, done/)
        #   - Use `["ideas/*.s.md"]` for top-level ideas only (excludes subdirectories)
        #   - Use `["ideas/maybe/**/*.s.md"]` for ideas in maybe/ subdirectory only
        #   - Patterns are relative to the release root (release/backlog path)
        # @return [Array<Hash>] Array of idea hashes with keys: :id, :filename, :title, :path, :created_at, :release
        # @example Load all ideas from current release
        #   loader.load_all(release: "current")
        # @example Load top-level ideas only (no subdirectories)
        #   loader.load_all(release: "current", glob: ["ideas/*.s.md"])
        # @example Load maybe ideas only
        #   loader.load_all(release: "current", glob: ["ideas/maybe/**/*.s.md"])
        def load_all(release: "current", include_content: false, glob: nil)
          # Use glob-based loading (glob defaults to all ideas if not provided)
          # Use the default pattern from configuration if no glob provided
          glob ||= Taskflow.configuration.default_glob_pattern
          load_all_with_glob(release: release, include_content: include_content, glob: glob)
        end

        def find_next(release: "current")
          # Top-level ideas only (excludes subdirectories like maybe/, anyday/, done/)
          ideas = load_all(release: release, include_content: false, glob: ["*.s.md"])
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
          # Parse reference format (e.g., "20250924-165837" or just partial name)
          if reference =~ /^\d{8}-\d{6}/
            # Full timestamp reference
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

        private

        # Load ideas using glob patterns
        def load_all_with_glob(release:, include_content:, glob:)
          # Use release root (release path) not idea directory, since glob patterns include ideas/ prefix
          release_root = determine_release_root(release)
          return [] unless release_root && Dir.exist?(release_root)

          ideas = []
          matched_paths = Set.new

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
              if File.file?(path) && path.end_with?('.s.md')
                # Check if this is a directory-based idea (idea.s.md inside a directory)
                if File.basename(path) == "idea.s.md"
                  parent_dir = File.dirname(path)
                  # All idea.s.md files are part of directory-based ideas (standardized format)
                  idea = load_idea_from_directory(parent_dir, include_content)
                  ideas << idea if idea
                  next
                end

                # Otherwise load as flat file (legacy format)
                idea = load_idea_file(path, include_content)
                ideas << idea if idea
              elsif Dir.exist?(path)
                # Check if it's a directory-based idea (contains idea.s.md)
                idea_file = File.join(path, "idea.s.md")
                if File.exist?(idea_file)
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

          # Load flat file ideas (*.s.md)
          flat_files = Dir.glob(File.join(dir, "*.s.md")).sort
          flat_files.each do |path|
            idea = load_idea_file(path, include_content)
            ideas << idea if idea
          end

          # Load directory-based ideas (directories containing idea.s.md)
          Dir.glob(File.join(dir, "*")).sort.each do |path|
            next unless Dir.exist?(path)
            # Skip scope subdirectories
            basename = File.basename(path)
            next if SCOPE_SUBDIRECTORIES.include?(basename)

            idea_file = File.join(path, "idea.s.md")
            if File.exist?(idea_file)
              idea = load_idea_from_directory(path, include_content)
              ideas << idea if idea
            end
          end

          ideas
        end

        def load_idea_from_directory(dir_path, include_content)
          idea_file = File.join(dir_path, "idea.s.md")
          return nil unless File.exist?(idea_file)

          dirname = File.basename(dir_path)

          # Extract ID from dirname (timestamp part)
          id = dirname[/^(\d{8}-\d{6})/, 1]

          # Extract title from dirname (after timestamp)
          title = dirname.sub(/^\d{8}-\d{6}-/, "")
          title = title.tr("-", " ").strip

          # Find attachment files (exclude idea.s.md)
          attachments = Dir.glob(File.join(dir_path, "*"))
            .reject { |f| File.basename(f) == "idea.s.md" }
            .select { |f| File.file?(f) }
            .map { |f| File.basename(f) }
            .sort

          # Read content to parse frontmatter
          content = File.read(idea_file)
          parsed = Atoms::YamlParser.parse(content)
          frontmatter = parsed[:frontmatter]
          body_content = parsed[:content]

          idea_data = {
            id: id,
            filename: dirname,
            title: title,
            path: dir_path,
            created_at: extract_timestamp_from_filename(dirname),
            release: extract_release_from_path(dir_path),
            attachments: attachments,
            is_directory: true,
            status: frontmatter["status"] || "pending",
            priority: frontmatter["priority"]
          }

          if include_content
            idea_data[:content] = body_content

            # Try to extract title from content header
            if body_content =~ /^#\s+(.+)$/
              idea_data[:title] = ::Regexp.last_match(1).strip
            end
          end

          idea_data
        end

        # Determine the release root directory (backlog or release)
        # This is used for glob-based loading where patterns start from release root
        def determine_release_root(release_name)
          backlog_dir = @config.dig("taskflow", "directories", "backlog") || "backlog"

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

          # Extract ID from filename (timestamp part)
          id = filename[/^(\d{8}-\d{6})/, 1]

          # Extract title from filename (after timestamp and before .md)
          title = filename.sub(/^\d{8}-\d{6}-/, "").sub(/\.md$/, "")
          title = title.tr("-", " ").strip

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
            if body_content =~ /^#\s+(.+)$/
              idea_data[:title] = ::Regexp.last_match(1).strip
            end
          end

          idea_data
        end

        def extract_timestamp_from_filename(filename)
          # Extract timestamp from filename format: YYYYMMDD-HHMMSS
          if filename =~ /^(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})/
            year, month, day, hour, min, sec = ::Regexp.last_match.captures
            Time.new(year.to_i, month.to_i, day.to_i, hour.to_i, min.to_i, sec.to_i)
          else
            # Return current time as fallback
            Time.now
          end
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

          # Count flat file ideas (*.s.md)
          flat_count = Dir.glob(File.join(dir, "*.s.md")).count

          # Count directory-based ideas (directories with idea.s.md)
          dir_count = Dir.glob(File.join(dir, "*"))
            .select { |path| Dir.exist?(path) && !SCOPE_SUBDIRECTORIES.include?(File.basename(path)) }
            .count { |path| File.exist?(File.join(path, "idea.s.md")) }

          main_count = flat_count + dir_count

          # Count ideas in scope subdirectories
          subdirs_count = 0
          SCOPE_SUBDIRECTORIES.each do |subdir_name|
            subdir = File.join(dir, subdir_name)
            next unless Dir.exist?(subdir)

            subdir_flat = Dir.glob(File.join(subdir, "*.s.md")).count
            subdir_dirs = Dir.glob(File.join(subdir, "*"))
              .select { |path| Dir.exist?(path) }
              .count { |path| File.exist?(File.join(path, "idea.s.md")) }
            subdirs_count += subdir_flat + subdir_dirs
          end

          main_count + subdirs_count
        end
      end
    end
  end
end
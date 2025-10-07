# frozen_string_literal: true

require "pathname"
require_relative "../models/idea"
require_relative "release_resolver"
require_relative "config_loader"

module Ace
  module Taskflow
    module Molecules
      class IdeaLoader
        def initialize(root_path = nil)
          @root_path = root_path || ConfigLoader.find_root
          @config = ConfigLoader.load
          @release_resolver = ReleaseResolver.new(@root_path)
        end

        def load_all(context: "current", include_content: false, scope: :next)
          idea_dir = determine_idea_directory(context)
          return [] unless idea_dir && Dir.exist?(idea_dir)

          ideas = []

          # Load pending ideas from main ideas/ directory (for :next and :all scopes)
          if [:next, :all, :recent].include?(scope)
            pending_ideas = load_ideas_from_directory(idea_dir, include_content)
            ideas.concat(pending_ideas)
          end

          # Load done ideas from done/ subdirectory (for :done and :all scopes)
          if [:done, :all].include?(scope)
            done_dir = File.join(idea_dir, "done")
            if Dir.exist?(done_dir)
              done_ideas = load_ideas_from_directory(done_dir, include_content)
              ideas.concat(done_ideas)
            end
          end

          ideas
        end

        def find_next(context: "current")
          ideas = load_all(context: context, include_content: false, scope: :next)
          ideas.first
        end

        def find_by_partial_name(partial, context: "current")
          ideas = load_all(context: context, include_content: false, scope: :all)

          # Find first idea where filename contains the partial string
          ideas.find do |idea|
            idea[:filename].downcase.include?(partial.downcase)
          end
        end

        def find_by_reference(reference)
          # Parse reference format (e.g., "20250924-165837" or just partial name)
          if reference =~ /^\d{8}-\d{6}/
            # Full timestamp reference
            ideas = load_all(context: "current", include_content: true)
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

        def count_by_context
          counts = {}

          # Count in active releases
          @release_resolver.find_active.each do |release|
            idea_dir = File.join(release[:path], "ideas")
            counts[release[:name]] = count_ideas_in_directory(idea_dir)
          end

          # Count in backlog
          backlog_dir = File.join(@root_path, "backlog", "ideas")
          counts["backlog"] = count_ideas_in_directory(backlog_dir)

          counts
        end

        private

        def load_ideas_from_directory(dir, include_content)
          ideas = []

          # Load flat file ideas (*.md)
          flat_files = Dir.glob(File.join(dir, "*.md")).sort
          flat_files.each do |path|
            idea = load_idea_file(path, include_content)
            ideas << idea if idea
          end

          # Load directory-based ideas (directories containing idea.md)
          Dir.glob(File.join(dir, "*")).sort.each do |path|
            next unless Dir.exist?(path)
            next if File.basename(path) == "done" # Skip done/ subdirectory

            idea_file = File.join(path, "idea.md")
            if File.exist?(idea_file)
              idea = load_idea_from_directory(path, include_content)
              ideas << idea if idea
            end
          end

          ideas
        end

        def load_idea_from_directory(dir_path, include_content)
          idea_file = File.join(dir_path, "idea.md")
          return nil unless File.exist?(idea_file)

          dirname = File.basename(dir_path)

          # Extract ID from dirname (timestamp part)
          id = dirname[/^(\d{8}-\d{6})/, 1]

          # Extract title from dirname (after timestamp)
          title = dirname.sub(/^\d{8}-\d{6}-/, "")
          title = title.tr("-", " ").strip

          # Find attachment files (exclude idea.md)
          attachments = Dir.glob(File.join(dir_path, "*"))
            .reject { |f| File.basename(f) == "idea.md" }
            .select { |f| File.file?(f) }
            .map { |f| File.basename(f) }
            .sort

          idea_data = {
            id: id,
            filename: dirname,
            title: title,
            path: dir_path,
            created_at: extract_timestamp_from_filename(dirname),
            context: extract_context_from_path(dir_path),
            attachments: attachments,
            is_directory: true
          }

          if include_content
            content = File.read(idea_file)
            idea_data[:content] = content

            # Try to extract metadata from content
            if content =~ /^#\s+(.+)$/
              idea_data[:title] = ::Regexp.last_match(1).strip
            end
          end

          idea_data
        end

        def determine_idea_directory(context)
          case context
          when "current", "active", nil
            # Find active release
            release = @release_resolver.find_primary_active
            if release
              File.join(release[:path], "ideas")
            else
              # Fall back to backlog if no active release
              File.join(@root_path, "backlog", "ideas")
            end
          when "backlog"
            File.join(@root_path, "backlog", "ideas")
          when /^v\.\d+\.\d+\.\d+/
            # Specific release
            release = @release_resolver.find_release(context)
            if release
              File.join(release[:path], "ideas")
            else
              nil
            end
          else
            # Try to find as release name
            release = @release_resolver.find_release(context)
            if release
              File.join(release[:path], "ideas")
            else
              nil
            end
          end
        end

        def load_idea_file(path, include_content)
          return nil unless File.exist?(path)

          filename = File.basename(path)

          # Extract ID from filename (timestamp part)
          id = filename[/^(\d{8}-\d{6})/, 1]

          # Extract title from filename (after timestamp and before .md)
          title = filename.sub(/^\d{8}-\d{6}-/, "").sub(/\.md$/, "")
          title = title.tr("-", " ").strip

          idea_data = {
            id: id,
            filename: filename,
            title: title,
            path: path,
            created_at: extract_timestamp_from_filename(filename),
            context: extract_context_from_path(path),
            attachments: [],
            is_directory: false
          }

          if include_content
            content = File.read(path)
            idea_data[:content] = content

            # Try to extract metadata from content
            if content =~ /^#\s+(.+)$/
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

        def extract_context_from_path(path)
          relative = Pathname.new(path).relative_path_from(Pathname.new(@root_path)).to_s

          if relative.start_with?("backlog/")
            "backlog"
          elsif relative =~ /^v\.\d+\.\d+\.\d+/
            relative.split("/").first
          else
            "current"
          end
        end

        def count_ideas_in_directory(dir)
          return 0 unless Dir.exist?(dir)

          # Count flat file ideas (*.md)
          flat_count = Dir.glob(File.join(dir, "*.md")).count

          # Count directory-based ideas (directories with idea.md)
          dir_count = Dir.glob(File.join(dir, "*"))
            .select { |path| Dir.exist?(path) && File.basename(path) != "done" }
            .count { |path| File.exist?(File.join(path, "idea.md")) }

          main_count = flat_count + dir_count

          # Also count ideas in done/ subdirectory
          done_dir = File.join(dir, "done")
          done_count = 0
          if Dir.exist?(done_dir)
            done_flat = Dir.glob(File.join(done_dir, "*.md")).count
            done_dirs = Dir.glob(File.join(done_dir, "*"))
              .select { |path| Dir.exist?(path) }
              .count { |path| File.exist?(File.join(path, "idea.md")) }
            done_count = done_flat + done_dirs
          end

          main_count + done_count
        end
      end
    end
  end
end
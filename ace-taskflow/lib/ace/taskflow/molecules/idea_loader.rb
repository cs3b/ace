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

        def load_all(context: "current", include_content: false)
          idea_dir = determine_idea_directory(context)
          return [] unless idea_dir && Dir.exist?(idea_dir)

          Dir.glob(File.join(idea_dir, "*.md"))
            .sort
            .map { |path| load_idea_file(path, include_content) }
            .compact
        end

        def find_next(context: "current")
          ideas = load_all(context: context, include_content: false)
          ideas.first
        end

        def find_by_partial_name(partial, context: "current")
          ideas = load_all(context: context, include_content: false)

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
          return nil unless File.exist?(path)
          load_idea_file(path, include_content)
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
            context: extract_context_from_path(path)
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
          Dir.glob(File.join(dir, "*.md")).count
        end
      end
    end
  end
end
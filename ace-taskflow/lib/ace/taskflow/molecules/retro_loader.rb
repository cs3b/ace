# frozen_string_literal: true

require "pathname"
require_relative "release_resolver"
require_relative "config_loader"

module Ace
  module Taskflow
    module Molecules
      # Load and discover retro (reflection note) files
      class RetroLoader
        def initialize(root_path = nil)
          @root_path = root_path || ConfigLoader.find_root
          @config = ConfigLoader.load
          @release_resolver = ReleaseResolver.new(@root_path)
        end

        # Find retro by reference (filename or partial match)
        # Searches both retro/ and retro/done/ directories
        def find_retro_by_reference(reference, context: "current")
          retro_dir = resolve_retro_directory(context)
          return nil unless retro_dir && Dir.exist?(retro_dir)

          # Search in both active (retro/) and done (retro/done/) directories
          search_dirs = [
            retro_dir,
            File.join(retro_dir, "done")
          ].select { |dir| Dir.exist?(dir) }

          # Find matching retro file
          search_dirs.each do |dir|
            retros = Dir.glob(File.join(dir, "*.md")).sort

            # Try exact match first
            exact_match = retros.find { |path| File.basename(path, ".md") == reference }
            return load_retro_file(exact_match) if exact_match

            # Try partial match
            partial_match = retros.find do |path|
              File.basename(path, ".md").downcase.include?(reference.downcase)
            end
            return load_retro_file(partial_match) if partial_match
          end

          nil
        end

        # List retros from retro/ directory only (excludes done/)
        def list_active_retros(context: "current")
          retro_dir = resolve_retro_directory(context)
          return [] unless retro_dir && Dir.exist?(retro_dir)

          Dir.glob(File.join(retro_dir, "*.md"))
            .sort
            .reverse
            .map { |path| load_retro_file(path, include_content: false) }
            .compact
        end

        # List retros from retro/done/ directory only
        def list_done_retros(context: "current")
          retro_dir = resolve_retro_directory(context)
          return [] unless retro_dir

          done_dir = File.join(retro_dir, "done")
          return [] unless Dir.exist?(done_dir)

          Dir.glob(File.join(done_dir, "*.md"))
            .sort
            .reverse
            .map { |path| load_retro_file(path, include_content: false) }
            .compact
        end

        # List all retros (both retro/ and retro/done/)
        def list_all_retros(context: "current")
          list_active_retros(context: context) + list_done_retros(context: context)
        end

        # Parse retro metadata and content
        def parse_retro_metadata(file_path)
          return nil unless File.exist?(file_path)

          content = File.read(file_path)

          # Extract frontmatter if present
          if content.match(/^---\n(.+?)\n---\n/m)
            frontmatter = $1
            body = content.sub(/^---\n.+?\n---\n/m, "")

            # Parse YAML frontmatter
            require "yaml"
            metadata = YAML.safe_load(frontmatter) rescue {}
          else
            metadata = {}
            body = content
          end

          # Extract title from first heading
          title = nil
          if body =~ /^#\s+(.+)$/
            title = $1.strip
          end

          {
            path: file_path,
            filename: File.basename(file_path),
            title: title || extract_title_from_filename(file_path),
            date: extract_date_from_filename(file_path),
            metadata: metadata,
            content: body,
            is_done: file_path.include?("/done/")
          }
        end

        # Resolve retro directory for given context
        def resolve_retro_directory(context)
          case context
          when "current", "active", nil
            # Find active release
            primary = @release_resolver.find_primary_active
            primary ? File.join(primary[:path], "retro") : nil
          when "backlog"
            File.join(@root_path, "backlog", "retro")
          when "all"
            # For "all", return root; caller will need to iterate releases
            @root_path
          else
            # Try to resolve as release
            release = @release_resolver.find_release(context)
            release ? File.join(release[:path], "retro") : nil
          end
        end

        private

        def load_retro_file(path, include_content: true)
          return nil unless path && File.exist?(path)

          if include_content
            parse_retro_metadata(path)
          else
            # Lightweight load without full content parsing
            {
              path: path,
              filename: File.basename(path),
              title: extract_title_from_filename(path),
              date: extract_date_from_filename(path),
              is_done: path.include?("/done/")
            }
          end
        end

        def extract_title_from_filename(path)
          filename = File.basename(path, ".md")

          # Remove date prefix (YYYY-MM-DD-)
          title = filename.sub(/^\d{4}-\d{2}-\d{2}-/, "")

          # Remove timestamp prefix if present (YYYYMMDD-HHMMSS-)
          title = title.sub(/^\d{8}-\d{6}-/, "")

          # Convert slug to readable title
          title.gsub("-", " ").capitalize
        end

        def extract_date_from_filename(path)
          filename = File.basename(path, ".md")

          # Try YYYY-MM-DD format first
          if filename =~ /^(\d{4}-\d{2}-\d{2})/
            return $1
          end

          # Try YYYYMMDD format
          if filename =~ /^(\d{8})/
            date_str = $1
            return "#{date_str[0..3]}-#{date_str[4..5]}-#{date_str[6..7]}"
          end

          nil
        end
      end
    end
  end
end

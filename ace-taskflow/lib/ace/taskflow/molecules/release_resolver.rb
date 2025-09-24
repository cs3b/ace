# frozen_string_literal: true

require "fileutils"

module Ace
  module Taskflow
    module Molecules
      # Resolve release paths and contexts
      class ReleaseResolver
        attr_reader :root_path

        def initialize(root_path = nil)
          @root_path = root_path || default_root_path
        end

        # Find all releases across backlog, active, and done
        # @return [Array<Hash>] Array of release info hashes
        def find_all
          releases = []

          # Find active releases (in root)
          Dir.glob(File.join(root_path, "v.*")).each do |path|
            next unless File.directory?(path)
            releases << build_release_info(path, "active")
          end

          # Find backlog releases
          backlog_path = File.join(root_path, "backlog")
          if File.directory?(backlog_path)
            Dir.glob(File.join(backlog_path, "v.*")).each do |path|
              next unless File.directory?(path)
              releases << build_release_info(path, "backlog")
            end
          end

          # Find done releases
          done_path = File.join(root_path, "done")
          if File.directory?(done_path)
            Dir.glob(File.join(done_path, "v.*")).each do |path|
              next unless File.directory?(path)
              releases << build_release_info(path, "done")
            end
          end

          releases
        end

        # Find active release(s)
        # @return [Array<Hash>] Array of active release info
        def find_active
          find_all.select { |r| r[:status] == "active" }
        end

        # Find primary active release (lowest version)
        # @return [Hash, nil] Primary active release info or nil
        def find_primary_active
          active = find_active
          return nil if active.empty?

          # Sort by version and return the lowest
          active.min_by { |r| parse_version(r[:name]) }
        end

        # Find release by name or path
        # @param identifier [String] Release name, version, or path
        # @return [Hash, nil] Release info or nil if not found
        def find_release(identifier)
          return nil if identifier.nil? || identifier.empty?

          # Try to find by exact name match first
          all_releases = find_all
          release = all_releases.find { |r| r[:name] == identifier }
          return release if release

          # Try to find by version only (e.g., "0.9.0" matches "v.0.9.0-description")
          release = all_releases.find { |r| r[:name].start_with?("v.#{identifier}") }
          return release if release

          # Try to find by path
          all_releases.find { |r| r[:path] == identifier }
        end

        # Resolve a context string to a release path
        # @param context [String] Context string (current, backlog, v.X.Y.Z)
        # @return [String, nil] Resolved path or nil
        def resolve_context(context)
          case context
          when "current", "active"
            primary = find_primary_active
            primary ? primary[:path] : nil
          when "backlog"
            File.join(root_path, "backlog")
          else
            # Try to find as a release
            release = find_release(context)
            release ? release[:path] : nil
          end
        end

        # Check if a release exists
        # @param name [String] Release name
        # @return [Boolean] True if exists
        def exists?(name)
          !find_release(name).nil?
        end

        # Get release statistics
        # @param release_path [String] Path to the release
        # @return [Hash] Statistics about the release
        def get_statistics(release_path)
          require_relative "../atoms/yaml_parser"
          task_path = File.join(release_path, "t")
          return default_statistics unless File.directory?(task_path)

          stats = default_statistics

          # Find all task directories
          Dir.glob(File.join(task_path, "*")).select { |d| File.directory?(d) }.each do |task_folder|
            # Find .md files in the task folder (not in subfolders)
            md_files = Dir.glob(File.join(task_folder, "*.md"))

            # Process each .md file that has task frontmatter
            md_files.each do |file|
              begin
                content = File.read(file, encoding: "utf-8")
                parsed = Atoms::YamlParser.parse(content)
                frontmatter = parsed[:frontmatter]

                # Only count files with proper task frontmatter
                if frontmatter && frontmatter["id"] && frontmatter["status"]
                  status = frontmatter["status"].downcase
                  stats[:statuses][status] = (stats[:statuses][status] || 0) + 1
                  stats[:total] += 1
                end
              rescue StandardError
                # Skip files that can't be parsed
                next
              end
            end
          end

          stats
        end

        private

        def default_root_path
          # Check for configured path or use default
          File.join(Dir.pwd, ".ace-taskflow")
        end

        def build_release_info(path, status)
          name = File.basename(path)
          stats = get_statistics(path)

          {
            name: name,
            path: path,
            status: status,
            version: extract_version(name),
            statistics: stats,
            created_at: File.birthtime(path).to_s,
            modified_at: File.mtime(path).to_s
          }
        end

        def extract_version(name)
          # Extract version from release name (e.g., v.0.9.0 from v.0.9.0-description)
          match = name.match(/^v\.(\d+\.\d+\.\d+)/)
          match ? match[1] : nil
        end

        def parse_version(name)
          version = extract_version(name)
          return [999, 999, 999] unless version

          version.split('.').map(&:to_i)
        end

        def default_statistics
          {
            total: 0,
            statuses: {},
            created_at: nil,
            modified_at: nil
          }
        end
      end
    end
  end
end
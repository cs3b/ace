# frozen_string_literal: true

require_relative "../../atoms/taskflow_management/directory_navigator"
require_relative "release_path_resolver"

module CodingAgentTools
  module Molecules
    module TaskflowManagement
      # ReleaseResolver provides unified release identification and resolution
      # Supports multiple identification formats: version, codename, fullname, path
      class ReleaseResolver
        # Release resolution result
        ResolutionResult = Struct.new(:release_info, :success, :error_message) do
          def success?
            success
          end
        end

        # Resolve release by various identification formats
        # @param identifier [String] Release identifier (version/codename/fullname/path)
        # @param base_path [String] Base path for resolution
        # @return [ResolutionResult] Resolution result with release info
        def self.resolve_release(identifier, base_path: ".")
          return resolve_current_release(base_path: base_path) if identifier.nil? || identifier.strip.empty?

          # Try different resolution strategies in order
          strategies = [
            :resolve_by_path,
            :resolve_by_fullname,
            :resolve_by_version,
            :resolve_by_codename
          ]

          strategies.each do |strategy|
            result = send(strategy, identifier, base_path)
            return result if result.success?
          end

          ResolutionResult.new(nil, false, "Release '#{identifier}' not found using any supported format")
        rescue => e
          ResolutionResult.new(nil, false, "Error resolving release '#{identifier}': #{e.message}")
        end

        # Get current release (backward compatibility)
        def self.resolve_current_release(base_path: ".")
          ReleasePathResolver.get_current_release(base_path: base_path)
        end

        private

        # Resolve by direct path (e.g., "dev-taskflow/current/v.0.3.0-workflows")
        def self.resolve_by_path(identifier, base_path)
          # Check if identifier looks like a path
          return ResolutionResult.new(nil, false, "Not a path") unless identifier.include?("/")

          # Try as absolute path first
          full_path = File.expand_path(identifier, base_path)
          return resolve_directory_path(full_path) if File.exist?(full_path) && File.directory?(full_path)

          # Try relative to base_path
          relative_path = File.join(base_path, identifier)
          return resolve_directory_path(relative_path) if File.exist?(relative_path) && File.directory?(relative_path)

          ResolutionResult.new(nil, false, "Path not found")
        end

        # Resolve by fullname (e.g., "v.0.3.0-workflows")
        def self.resolve_by_fullname(identifier, base_path)
          return ResolutionResult.new(nil, false, "Not a fullname") if identifier.include?("/")

          search_paths = [
            File.join(base_path, "dev-taskflow/current"),
            File.join(base_path, "dev-taskflow/backlog"),
            File.join(base_path, "dev-taskflow/done")
          ]

          search_paths.each do |search_path|
            next unless File.exist?(search_path) && File.directory?(search_path)

            release_path = File.join(search_path, identifier)
            next unless File.exist?(release_path) && File.directory?(release_path)

            return resolve_directory_path(release_path)
          end

          ResolutionResult.new(nil, false, "Fullname not found")
        end

        # Resolve by version (e.g., "v.0.3.0")
        def self.resolve_by_version(identifier, base_path)
          return ResolutionResult.new(nil, false, "Not a version") unless identifier.match?(/^v\.\d+\.\d+\.\d+$/)

          search_paths = [
            File.join(base_path, "dev-taskflow/current"),
            File.join(base_path, "dev-taskflow/backlog"), 
            File.join(base_path, "dev-taskflow/done")
          ]

          search_paths.each do |search_path|
            next unless File.exist?(search_path) && File.directory?(search_path)

            Dir.glob(File.join(search_path, "#{identifier}-*")).each do |release_path|
              next unless File.directory?(release_path)
              return resolve_directory_path(release_path)
            end
          end

          ResolutionResult.new(nil, false, "Version not found")
        end

        # Resolve by codename (e.g., "workflows")
        def self.resolve_by_codename(identifier, base_path)
          return ResolutionResult.new(nil, false, "Not a codename") if identifier.include?(".") || identifier.include?("/")

          search_paths = [
            File.join(base_path, "dev-taskflow/current"),
            File.join(base_path, "dev-taskflow/backlog"),
            File.join(base_path, "dev-taskflow/done")
          ]

          search_paths.each do |search_path|
            next unless File.exist?(search_path) && File.directory?(search_path)

            Dir.glob(File.join(search_path, "*-#{identifier}")).each do |release_path|
              next unless File.directory?(release_path)
              return resolve_directory_path(release_path)
            end
          end

          ResolutionResult.new(nil, false, "Codename not found")
        end

        # Resolve a specific directory path to release info
        def self.resolve_directory_path(release_path)
          return ResolutionResult.new(nil, false, "Directory does not exist") unless File.exist?(release_path)

          release_name = File.basename(release_path)
          
          # Extract version and codename from directory name
          if release_name.match(/^(v\.\d+\.\d+\.\d+)(?:-(.+))?$/)
            version = $1
            codename = $2
          else
            version = release_name
            codename = nil
          end

          # Find tasks directory
          tasks_dir = Atoms::TaskflowManagement::DirectoryNavigator.find_tasks_directory(release_path)
          
          # Determine release type
          release_type = case release_path
                        when /\/current\//
                          :current
                        when /\/backlog\//
                          :backlog
                        when /\/done\//
                          :done
                        else
                          :unknown
                        end

          release_info = ReleasePathResolver::ReleaseInfo.new(
            release_path,
            version,
            tasks_dir,
            release_name,
            release_type
          )

          ResolutionResult.new(release_info, true, nil)
        rescue => e
          ResolutionResult.new(nil, false, "Error processing directory: #{e.message}")
        end
      end
    end
  end
end
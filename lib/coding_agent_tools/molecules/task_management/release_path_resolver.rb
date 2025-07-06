# frozen_string_literal: true

require_relative "../../atoms/task_management/directory_navigator"

module CodingAgentTools
  module Molecules
    module TaskManagement
      # ReleasePathResolver composes atoms to provide release directory resolution
      class ReleasePathResolver
        # Release information structure
        ReleaseInfo = Struct.new(:path, :version, :tasks_directory, :name, :type)

        # Resolution result
        ResolutionResult = Struct.new(:release_info, :success, :error_message) do
          def success?
            success
          end
        end

        # Get current release information
        def self.get_current_release(base_path: ".")
          result = Atoms::TaskManagement::DirectoryNavigator.get_current_release_directory(base_path: base_path)

          if result.nil?
            return ResolutionResult.new(nil, false, "No current release directory found")
          end

          tasks_dir = Atoms::TaskManagement::DirectoryNavigator.find_tasks_directory(result[:path])
          release_info = ReleaseInfo.new(result[:path], result[:version], tasks_dir, File.basename(result[:path]), :current)

          ResolutionResult.new(release_info, true, nil)
        rescue => e
          ResolutionResult.new(nil, false, "Error resolving current release: #{e.message}")
        end

        # Find release by version
        def self.find_release_by_version(version, base_path: ".", search_current: true, search_backlog: true)
          search_paths = []
          search_paths << File.join(base_path, "dev-taskflow/current") if search_current
          search_paths << File.join(base_path, "dev-taskflow/backlog") if search_backlog

          result = Atoms::TaskManagement::DirectoryNavigator.find_release_directory(
            version, search_paths: search_paths, base_path: base_path
          )

          if result.nil?
            return ResolutionResult.new(nil, false, "Release directory for version '#{version}' not found")
          end

          tasks_dir = Atoms::TaskManagement::DirectoryNavigator.find_tasks_directory(result[:path])
          release_type = result[:path].include?("/current/") ? :current : :backlog
          release_info = ReleaseInfo.new(result[:path], result[:version], tasks_dir, File.basename(result[:path]), release_type)

          ResolutionResult.new(release_info, true, nil)
        rescue => e
          ResolutionResult.new(nil, false, "Error finding release by version: #{e.message}")
        end

        # Get current tasks directory
        def self.get_current_tasks_directory(base_path: ".")
          result = get_current_release(base_path: base_path)
          return nil unless result.success?

          result.release_info.tasks_directory
        end
      end
    end
  end
end

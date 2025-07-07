# frozen_string_literal: true

require "pathname"
require_relative "../project_root_detector"

module CodingAgentTools
  module Atoms
    module Git
      class PathResolutionError < StandardError
        attr_reader :path, :reason

        def initialize(message, path: nil, reason: nil)
          super(message)
          @path = path
          @reason = reason
        end
      end

      class PathResolver
        def self.resolve_path(path, repositories, project_root = nil)
          new(repositories, project_root).resolve_path(path)
        end

        def self.resolve_paths(paths, repositories, project_root = nil)
          new(repositories, project_root).resolve_paths(paths)
        end

        def initialize(repositories, project_root = nil)
          @repositories = repositories
          @project_root = project_root || ProjectRootDetector.find_project_root
        end

        def resolve_path(path)
          validate_path(path)
          
          absolute_path = normalize_path(path)
          repository_info = find_repository_for_path(absolute_path)
          relative_path = calculate_relative_path(absolute_path, repository_info)
          
          {
            original_path: path,
            absolute_path: absolute_path,
            repository: repository_info[:name],
            repository_path: repository_info[:path],
            relative_path: relative_path,
            exists: File.exist?(absolute_path)
          }
        end

        def resolve_paths(paths)
          paths.map { |path| resolve_path(path) }
        end

        def group_paths_by_repository(paths)
          resolved_paths = resolve_paths(paths)
          grouped = {}
          
          resolved_paths.each do |path_info|
            repo_name = path_info[:repository]
            grouped[repo_name] ||= []
            grouped[repo_name] << path_info[:relative_path]
          end
          
          grouped
        end

        private

        attr_reader :repositories, :project_root

        def validate_path(path)
          raise PathResolutionError.new(
            "Path cannot be nil or empty",
            path: path,
            reason: :invalid_input
          ) if path.nil? || path.strip.empty?
        end

        def normalize_path(path)
          if Pathname.new(path).relative?
            # For relative paths, we need to determine the context:
            # 1. If path contains repo prefix (e.g., "dev-tools/file"), expand from project root
            # 2. If path is local (e.g., "file"), expand from current working directory to nearest git repo
            
            if path_contains_repository_prefix?(path)
              # Path like "dev-tools/exe/git-log" - expand from project root
              File.expand_path(path, @project_root)
            else
              # Path like "exe/git-log" - expand from current directory (should be within a repo)
              File.expand_path(path, Dir.pwd)
            end
          else
            File.expand_path(path)
          end
        end

        def path_contains_repository_prefix?(path)
          # Check if the path starts with any known repository name
          repository_names = repositories.map { |repo| repo[:name] }
          
          repository_names.any? do |repo_name|
            path.start_with?("#{repo_name}/")
          end
        end

        def find_repository_for_path(absolute_path)
          # Sort repositories by path length (descending) to match most specific first
          sorted_repos = repositories.sort_by { |repo| -repo[:full_path].length }
          
          matching_repo = sorted_repos.find do |repo|
            path_within_repository?(absolute_path, repo[:full_path])
          end
          
          if matching_repo
            matching_repo
          else
            # Default to main repository if no specific match found
            main_repo = repositories.find { |repo| repo[:name] == "main" }
            
            unless main_repo
              raise PathResolutionError.new(
                "No repository found for path and no main repository available",
                path: absolute_path,
                reason: :no_repository_match
              )
            end
            
            main_repo
          end
        end

        def path_within_repository?(absolute_path, repo_path)
          # Normalize paths for comparison
          normalized_path = File.expand_path(absolute_path)
          normalized_repo_path = File.expand_path(repo_path)
          
          # Check if path is exactly the repository root or within it
          normalized_path == normalized_repo_path || 
            normalized_path.start_with?(normalized_repo_path + File::SEPARATOR)
        end

        def calculate_relative_path(absolute_path, repository_info)
          repo_path = Pathname.new(repository_info[:full_path])
          file_path = Pathname.new(absolute_path)
          
          begin
            relative_path = file_path.relative_path_from(repo_path)
            relative_path.to_s
          rescue ArgumentError => e
            raise PathResolutionError.new(
              "Cannot calculate relative path: #{e.message}",
              path: absolute_path,
              reason: :relative_path_calculation_failed
            )
          end
        end
      end
    end
  end
end
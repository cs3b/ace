# frozen_string_literal: true

require 'pathname'
require_relative '../project_root_detector'

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
          return {} if paths.nil? || paths.empty?

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
          return unless path.nil? || path.strip.empty?

          raise PathResolutionError.new(
            'Path cannot be nil or empty',
            path: path,
            reason: :invalid_input
          )
        end

        def normalize_path(path)
          if Pathname.new(path).relative?
            # For relative paths, we need to determine the context:
            # 1. If path contains repo prefix (e.g., "dev-tools/file"), expand from project root
            # 2. If path is local (e.g., "file"), use intelligent resolution

            if path_contains_repository_prefix?(path)
              # Path like "dev-tools/exe/git-log" - expand from project root
              File.expand_path(path, @project_root)
            else
              # Path like "exe/git-log" - use intelligent resolution
              resolve_relative_path_intelligently(path)
            end
          else
            File.expand_path(path)
          end
        end

        def resolve_relative_path_intelligently(path)
          # Use expand_path initially to avoid premature symlink resolution
          # We'll resolve symlinks only when needed for path comparisons
          current_dir = Dir.pwd
          project_root_base = @project_root

          # Normalize for comparison purposes (resolve symlinks for accurate containment checks)
          current_dir_normalized = File.realpath(current_dir)
          project_root_normalized = File.realpath(project_root_base)

          # Try resolving from current directory first
          current_resolved = File.expand_path(path, current_dir)

          # Try resolving from project root as fallback
          project_resolved = File.expand_path(path, project_root_base)

          # If current directory is the project root, use current resolution
          return current_resolved if current_dir_normalized == project_root_normalized

          # If we're in a submodule directory, we need to be more intelligent
          # Check if the file would make more sense from project root

          # Check if paths are within project (using normalized paths with symlinks resolved)
          # We need to normalize the resolved paths for accurate containment checks
          current_resolved_normalized = File.exist?(current_resolved) ? File.realpath(current_resolved) : File.expand_path(current_resolved)
          project_resolved_normalized = File.exist?(project_resolved) ? File.realpath(project_resolved) : File.expand_path(project_resolved)

          current_in_project = current_resolved_normalized.start_with?(project_root_normalized + File::SEPARATOR) ||
                               current_resolved_normalized == project_root_normalized
          project_in_project = project_resolved_normalized.start_with?(project_root_normalized + File::SEPARATOR) ||
                               project_resolved_normalized == project_root_normalized

          # If both are in project, check which one actually exists or makes more sense
          if current_in_project && project_in_project
            # Both paths are within the project root
            # Prioritize existing files first
            if File.exist?(current_resolved) && !File.exist?(project_resolved)
              current_resolved
            elsif File.exist?(project_resolved) && !File.exist?(current_resolved)
              project_resolved
            elsif File.exist?(current_resolved) && File.exist?(project_resolved)
              # Both files exist - use heuristics to decide
              if path.start_with?('.')
                # Dot-prefixed paths likely belong to main repository
                project_resolved
              else
                # Regular files in submodule directory - prefer local
                current_resolved
              end
            elsif path.start_with?('.')
              # Neither exists, but we need to make a decision based on path characteristics
              # Dot-prefixed paths likely belong to main repo
              project_resolved
            else
              # Regular paths in submodule directory should prefer local
              current_resolved
            end
          elsif project_in_project && !current_in_project
            # Only project root resolution is within project, use it
            project_resolved
          else
            # Fall back to current directory resolution
            current_resolved
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
            main_repo = repositories.find { |repo| repo[:name] == 'main' }

            unless main_repo
              raise PathResolutionError.new(
                'No repository found for path and no main repository available',
                path: absolute_path,
                reason: :no_repository_match
              )
            end

            main_repo
          end
        end

        def path_within_repository?(absolute_path, repo_path)
          # Normalize paths for comparison and resolve symlinks consistently
          # Always use the same normalization approach for both paths to avoid
          # symlink resolution inconsistencies
          begin
            # Try to resolve symlinks for both paths if they exist
            if File.exist?(absolute_path) && File.exist?(repo_path)
              normalized_path = File.realpath(absolute_path)
              normalized_repo_path = File.realpath(repo_path)
            else
              # If either path doesn't exist, use expand_path for both
              # to ensure consistent path format comparison
              normalized_path = File.expand_path(absolute_path)
              normalized_repo_path = File.expand_path(repo_path)
            end
          rescue StandardError
            # If any realpath fails, fall back to expand_path for both
            normalized_path = File.expand_path(absolute_path)
            normalized_repo_path = File.expand_path(repo_path)
          end

          # Check if path is exactly the repository root or within it
          normalized_path == normalized_repo_path ||
            normalized_path.start_with?(normalized_repo_path + File::SEPARATOR)
        end

        def calculate_relative_path(absolute_path, repository_info)
          # Ensure we're working with real paths to handle symlinks consistently
          begin
            repo_real_path = if File.exist?(repository_info[:full_path])
                               File.realpath(repository_info[:full_path])
                             else
                               File.expand_path(repository_info[:full_path])
                             end

            file_real_path = if File.exist?(absolute_path)
                               File.realpath(absolute_path)
                             else
                               File.expand_path(absolute_path)
                             end
          rescue StandardError
            # Fallback if realpath fails
            repo_real_path = File.expand_path(repository_info[:full_path])
            file_real_path = File.expand_path(absolute_path)
          end

          repo_path = Pathname.new(repo_real_path)
          file_path = Pathname.new(file_real_path)

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

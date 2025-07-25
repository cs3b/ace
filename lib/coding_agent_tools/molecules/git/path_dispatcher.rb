# frozen_string_literal: true

require "shellwords"
require_relative "../../atoms/git/path_resolver"
require_relative "../../atoms/git/repository_scanner"
require_relative "../../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    module Git
      class PathDispatchError < StandardError; end

      class PathDispatcher
        def self.dispatch_paths(paths, project_root = nil)
          new(project_root).dispatch_paths(paths)
        end

        def initialize(project_root = nil)
          @project_root = project_root || CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
          @repositories = CodingAgentTools::Atoms::Git::RepositoryScanner.discover_repositories(@project_root)
          @path_resolver = CodingAgentTools::Atoms::Git::PathResolver.new(@repositories, @project_root)
        end

        def dispatch_paths(paths)
          return {} if paths.nil? || paths.empty?

          validate_paths(paths)
          grouped_paths = @path_resolver.group_paths_by_repository(paths)

          build_dispatch_commands(grouped_paths)
        end

        def dispatch_single_path(path)
          dispatch_paths([path])
        end

        private

        attr_reader :project_root, :repositories, :path_resolver

        def validate_paths(paths)
          invalid_paths = paths.select { |path| path.nil? || path.strip.empty? }

          unless invalid_paths.empty?
            raise PathDispatchError, "Invalid paths provided: #{invalid_paths.inspect}"
          end
        end

        def build_dispatch_commands(grouped_paths)
          dispatch_info = {}

          grouped_paths.each do |repo_name, file_paths|
            repository = find_repository_by_name(repo_name)

            dispatch_info[repo_name] = {
              repository: repository,
              paths: file_paths,
              command_context: build_command_context(repository),
              working_directory: repository[:full_path]
            }
          end

          dispatch_info
        end

        def find_repository_by_name(name)
          repository = repositories.find { |repo| repo[:name] == name }

          unless repository
            raise PathDispatchError, "Repository not found: #{name}"
          end

          repository
        end

        def build_command_context(repository)
          escaped_path = Shellwords.escape(repository[:full_path])
          {
            prefix: "-C #{escaped_path}",
            git_command_prefix: "git -C #{escaped_path}",
            description: "#{repository[:name]} repository"
          }
        end
      end
    end
  end
end

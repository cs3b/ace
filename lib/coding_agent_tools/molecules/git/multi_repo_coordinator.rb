# frozen_string_literal: true

require_relative "../../atoms/git/repository_scanner"
require_relative "../../atoms/git/git_command_executor"
require_relative "../../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    module Git
      class MultiRepoCoordinationError < StandardError; end

      class MultiRepoCoordinator
        def self.execute_across_repositories(command, options = {})
          new.execute_across_repositories(command, options)
        end

        def initialize(project_root = nil)
          @project_root = project_root || CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
          @repositories = CodingAgentTools::Atoms::Git::RepositoryScanner.discover_repositories(@project_root)
        end

        def execute_across_repositories(command, options = {})
          repositories_to_process = filter_repositories(options)
          validate_repositories(repositories_to_process)
          
          results = {}
          errors = []
          
          repositories_to_process.each do |repository|
            begin
              result = execute_for_repository(repository, command, options)
              results[repository[:name]] = result
            rescue => e
              error_info = {
                repository: repository[:name],
                error: e,
                message: e.message
              }
              errors << error_info
              results[repository[:name]] = { success: false, error: e.message }
            end
          end
          
          {
            success: errors.empty?,
            results: results,
            errors: errors,
            repositories_processed: repositories_to_process.map { |r| r[:name] }
          }
        end

        def available_repositories
          @repositories.select { |repo| repo[:exists] && repo[:is_git_repo] }
        end

        private

        attr_reader :project_root, :repositories

        def filter_repositories(options)
          if options[:repository]
            # Specific repository requested
            specific_repo = repositories.find { |repo| repo[:name] == options[:repository] }
            unless specific_repo
              raise MultiRepoCoordinationError, "Repository not found: #{options[:repository]}"
            end
            [specific_repo]
          elsif options[:main_only]
            repositories.select { |repo| repo[:name] == "main" }
          elsif options[:submodules_only]
            repositories.select { |repo| repo[:name] != "main" }
          else
            # Default: all repositories
            repositories
          end
        end

        def validate_repositories(repos_to_process)
          invalid_repos = repos_to_process.reject { |repo| repo[:exists] && repo[:is_git_repo] }
          
          unless invalid_repos.empty?
            invalid_names = invalid_repos.map { |repo| repo[:name] }
            raise MultiRepoCoordinationError, 
              "Invalid repositories (not git repos or don't exist): #{invalid_names.join(', ')}"
          end
        end

        def execute_for_repository(repository, command, options)
          repository_path = repository[:name] == "main" ? nil : repository[:path]
          
          # Build the command with any repository-specific modifications
          final_command = build_repository_command(command, repository, options)
          
          # Execute the command
          executor = CodingAgentTools::Atoms::Git::GitCommandExecutor.new(repository_path: repository_path)
          result = executor.execute(final_command, capture_output: options.fetch(:capture_output, true))
          
          # Add repository context to result
          result.merge(
            repository: repository[:name],
            repository_path: repository[:path],
            command_executed: final_command
          )
        end

        def build_repository_command(base_command, repository, options)
          # For most commands, no modification needed
          # Subclasses can override this for command-specific modifications
          base_command
        end
      end
    end
  end
end
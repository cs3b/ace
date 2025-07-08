# frozen_string_literal: true

require "open3"
require "shellwords"
require "pathname"
require_relative "../project_root_detector"
require_relative "git_command_executor"

module CodingAgentTools
  module Atoms
    module Git
      class RepositoryScanError < StandardError; end

      class RepositoryScanner
        def self.discover_repositories(project_root = nil)
          new(project_root).discover_repositories
        end

        def initialize(project_root = nil)
          @project_root = project_root || ProjectRootDetector.find_project_root
        end

        def discover_repositories
          repositories = []

          # Add main repository
          repositories << build_repository_info("main", ".", @project_root)

          # Discover submodules
          submodules = discover_submodules
          repositories.concat(submodules)

          # Fallback: scan for dev-* directories
          if submodules.empty?
            dev_directories = discover_dev_directories
            repositories.concat(dev_directories)
          end

          repositories
        end

        private

        attr_reader :project_root

        def discover_submodules
          return [] unless git_repository_exists?

          submodules = []

          begin
            submodule_output = execute_git_command("submodule status")
            submodule_output.split("\n").each do |line|
              next if line.strip.empty?

              # Parse line format: " commit_hash path (branch_info)"
              parts = line.strip.split
              next if parts.length < 2

              submodule_path = parts[1]
              submodule_name = File.basename(submodule_path)
              full_path = File.join(project_root, submodule_path)

              next unless File.directory?(full_path)

              submodules << build_repository_info(submodule_name, submodule_path, full_path)
            end
          rescue GitCommandError
            # Submodule command failed, continue with fallback
          end

          submodules
        end

        def discover_dev_directories
          dev_dirs = []

          DEV_DIRECTORY_PATTERNS.each do |pattern|
            Dir.glob(File.join(project_root, pattern)).each do |dir_path|
              next unless File.directory?(dir_path)
              next unless git_repository_exists?(dir_path)

              relative_path = Pathname.new(dir_path).relative_path_from(Pathname.new(project_root)).to_s
              dir_name = File.basename(dir_path)

              dev_dirs << build_repository_info(dir_name, relative_path, dir_path)
            end
          end

          dev_dirs
        end

        def build_repository_info(name, relative_path, full_path)
          {
            name: name,
            path: relative_path,
            full_path: full_path,
            exists: File.directory?(full_path),
            is_git_repo: git_repository_exists?(full_path)
          }
        end

        def git_repository_exists?(path = nil)
          check_path = path || project_root
          File.exist?(File.join(check_path, ".git")) || File.directory?(File.join(check_path, ".git"))
        end

        def execute_git_command(command)
          full_command = "git -C #{Shellwords.escape(project_root)} #{command}"
          stdout_str, stderr_str, status = Open3.capture3(full_command)

          unless status.success?
            raise CodingAgentTools::Atoms::Git::GitCommandError.new(
              "Git command failed: #{full_command}",
              stderr_output: stderr_str.strip
            )
          end

          stdout_str
        end

        DEV_DIRECTORY_PATTERNS = ["dev-*"].freeze

        private_constant :DEV_DIRECTORY_PATTERNS
      end
    end
  end
end

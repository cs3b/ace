# frozen_string_literal: true

require 'open3'
require 'shellwords'
require_relative '../project_root_detector'
require_relative 'git_command_executor'

module CodingAgentTools
  module Atoms
    module Git
      class SubmoduleDetector
        def self.detect_submodules(project_root = nil)
          new(project_root).detect_submodules
        end

        def self.is_submodule?(path, project_root = nil)
          new(project_root).is_submodule?(path)
        end

        def initialize(project_root = nil)
          @project_root = project_root || ProjectRootDetector.find_project_root
        end

        def detect_submodules
          return [] unless git_repository_exists?

          submodules = []

          begin
            # Try git submodule status first
            submodule_output = execute_git_command('submodule status')
            submodules = parse_submodule_status(submodule_output)
          rescue GitCommandError
            # Fallback to .gitmodules file if available
            submodules = parse_gitmodules_file
          end

          # Validate that submodules actually exist and are git repositories
          submodules.select { |sm| validate_submodule(sm) }
        end

        def is_submodule?(path)
          absolute_path = File.expand_path(path)
          submodules = detect_submodules

          submodules.any? { |sm| absolute_path.start_with?(sm[:full_path]) }
        end

        private

        attr_reader :project_root

        def parse_submodule_status(output)
          submodules = []

          output.split("\n").each do |line|
            next if line.strip.empty?

            # Parse line format: " commit_hash path (branch_info)"
            # Status characters: ' ' (initialized), '-' (not initialized), '+' (checked out)
            status_char = line[0]
            parts = line[1..].strip.split
            next if parts.length < 2

            commit_hash = parts[0]
            submodule_path = parts[1]
            branch_info = parts[2..].join(' ') if parts.length > 2

            submodules << build_submodule_info(
              submodule_path,
              commit_hash,
              status_char,
              branch_info
            )
          end

          submodules
        end

        def parse_gitmodules_file
          gitmodules_path = File.join(project_root, '.gitmodules')
          return [] unless File.exist?(gitmodules_path)

          submodules = []
          current_submodule = {}

          File.readlines(gitmodules_path).each do |line|
            line = line.strip
            next if line.empty? || line.start_with?('#')

            if line =~ /^\[submodule "(.+)"\]$/
              # Save previous submodule if complete
              submodules << build_submodule_info(current_submodule[:path]) if current_submodule[:path]

              # Start new submodule
              current_submodule = { name: ::Regexp.last_match(1) }
            elsif line =~ /^\s*path\s*=\s*(.+)$/
              current_submodule[:path] = ::Regexp.last_match(1).strip
            elsif line =~ /^\s*url\s*=\s*(.+)$/
              current_submodule[:url] = ::Regexp.last_match(1).strip
            end
          end

          # Don't forget the last submodule
          submodules << build_submodule_info(current_submodule[:path]) if current_submodule[:path]

          submodules
        end

        def build_submodule_info(path, commit_hash = nil, status_char = nil, branch_info = nil)
          full_path = File.join(project_root, path)

          {
            name: File.basename(path),
            path: path,
            full_path: full_path,
            commit_hash: commit_hash,
            status: parse_status_character(status_char),
            branch_info: branch_info,
            exists: File.directory?(full_path),
            is_git_repo: git_repository_exists?(full_path)
          }
        end

        def parse_status_character(char)
          case char
          when ' ', nil
            :initialized
          when '-'
            :not_initialized
          when '+'
            :checked_out_different_commit
          when 'U'
            :merge_conflict
          else
            :unknown
          end
        end

        def validate_submodule(submodule_info)
          return false unless submodule_info[:exists]
          return false unless submodule_info[:is_git_repo]

          # Additional validation: check if it's actually a git repository
          git_repository_exists?(submodule_info[:full_path])
        end

        def git_repository_exists?(path = nil)
          check_path = path || project_root
          File.exist?(File.join(check_path, '.git')) || File.directory?(File.join(check_path, '.git'))
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
      end
    end
  end
end

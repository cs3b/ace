# frozen_string_literal: true

require_relative '../../atoms/git/git_command_executor'
require_relative '../../atoms/git/repository_scanner'
require_relative '../../atoms/project_root_detector'

module CodingAgentTools
  module Molecules
    module Search
      # GitScopeEnumerator provides enumeration of files based on git scopes
      # This is a molecule - it uses git command atoms to enumerate files with git awareness
      class GitScopeEnumerator
        def initialize(repository_path = nil)
          @repository_path = repository_path
          @git_executor = CodingAgentTools::Atoms::Git::GitCommandExecutor.new(repository_path: repository_path)
          @repository_scanner = CodingAgentTools::Atoms::Git::RepositoryScanner
        end

        # Enumerate files based on git scope
        # @param scope [Symbol] Git scope (:tracked, :staged, :changed, :recent)
        # @param options [Hash] Additional options
        # @return [Hash] Result with success status and file list
        def enumerate_files(scope, options = {})
          case scope
          when :tracked
            enumerate_tracked_files(options)
          when :staged
            enumerate_staged_files(options)
          when :changed
            enumerate_changed_files(options)
          when :recent
            enumerate_recent_files(options)
          when :untracked
            enumerate_untracked_files(options)
          else
            { success: false, error: "Unknown git scope: #{scope}" }
          end
        end

        # Get files that are tracked by git
        # @param options [Hash] Options (include_ignored, since, etc.)
        # @return [Hash] Result with file list
        def enumerate_tracked_files(options = {})
          command = 'git ls-files'
          command += ' --cached' # Only tracked files
          command += ' -z' # Null-terminated for safe parsing
          
          unless options[:include_ignored]
            command += ' --exclude-standard'
          end
          
          result = @git_executor.execute(command)
          
          if result[:success]
            files = parse_null_separated_files(result[:stdout])
            files = filter_by_time(files, options) if options[:since]
            
            {
              success: true,
              files: files,
              count: files.length,
              scope: :tracked
            }
          else
            {
              success: false,
              error: result[:error] || 'Failed to enumerate tracked files'
            }
          end
        end

        # Get files that are staged (in index)
        # @param options [Hash] Options
        # @return [Hash] Result with file list
        def enumerate_staged_files(options = {})
          command = 'git diff --cached --name-only -z'
          
          result = @git_executor.execute(command)
          
          if result[:success]
            files = parse_null_separated_files(result[:stdout])
            files = filter_by_time(files, options) if options[:since]
            
            {
              success: true,
              files: files,
              count: files.length,
              scope: :staged
            }
          else
            {
              success: false,
              error: result[:error] || 'Failed to enumerate staged files'
            }
          end
        end

        # Get files that have changes (modified, added, deleted)
        # @param options [Hash] Options (include_untracked, since, range)
        # @return [Hash] Result with file list  
        def enumerate_changed_files(options = {})
          files = []
          
          # Get modified and deleted files
          modified_result = get_modified_files(options)
          return modified_result unless modified_result[:success]
          files.concat(modified_result[:files])
          
          # Get untracked files if requested
          if options[:include_untracked]
            untracked_result = enumerate_untracked_files(options)
            return untracked_result unless untracked_result[:success]
            files.concat(untracked_result[:files])
          end
          
          # Get files changed in a specific range if provided
          if options[:range]
            range_result = get_files_changed_in_range(options[:range], options)
            return range_result unless range_result[:success]
            files.concat(range_result[:files])
          end
          
          # Remove duplicates and filter
          files = files.uniq
          files = filter_by_time(files, options) if options[:since]
          
          {
            success: true,
            files: files,
            count: files.length,
            scope: :changed
          }
        end

        # Get files changed recently
        # @param options [Hash] Options (since, author, etc.)
        # @return [Hash] Result with file list
        def enumerate_recent_files(options = {})
          since = options[:since] || '1 week ago'
          author = options[:author]
          
          command = "git log --since=\"#{since}\" --name-only --pretty=format: -z"
          command += " --author=\"#{author}\"" if author
          
          result = @git_executor.execute(command)
          
          if result[:success]
            # Parse output and remove empty lines
            files = result[:stdout].split("\0").map(&:strip).reject(&:empty?).uniq
            files = filter_by_time(files, options) if options[:since]
            
            {
              success: true,
              files: files,
              count: files.length,
              scope: :recent,
              since: since
            }
          else
            {
              success: false,
              error: result[:error] || 'Failed to enumerate recent files'
            }
          end
        end

        # Get untracked files
        # @param options [Hash] Options
        # @return [Hash] Result with file list
        def enumerate_untracked_files(options = {})
          command = 'git ls-files --others'
          command += ' --exclude-standard' unless options[:include_ignored]
          command += ' -z'
          
          result = @git_executor.execute(command)
          
          if result[:success]
            files = parse_null_separated_files(result[:stdout])
            files = filter_by_time(files, options) if options[:since]
            
            {
              success: true,
              files: files,
              count: files.length,
              scope: :untracked
            }
          else
            {
              success: false,
              error: result[:error] || 'Failed to enumerate untracked files'
            }
          end
        end

        # Check if current directory is a git repository
        # @return [Boolean] True if in git repository
        def git_repository?
          result = @git_executor.execute('git rev-parse --git-dir')
          result[:success]
        end

        # Get git repository root
        # @return [String, nil] Repository root path or nil if not in git repo
        def git_root
          result = @git_executor.execute('git rev-parse --show-toplevel')
          result[:success] ? result[:stdout].strip : nil
        end

        # Combine multiple scopes
        # @param scopes [Array<Symbol>] Array of scopes to combine
        # @param options [Hash] Options
        # @return [Hash] Combined result
        def enumerate_multiple_scopes(scopes, options = {})
          all_files = []
          errors = []
          
          scopes.each do |scope|
            result = enumerate_files(scope, options)
            
            if result[:success]
              all_files.concat(result[:files])
            else
              errors << "#{scope}: #{result[:error]}"
            end
          end
          
          if errors.empty?
            {
              success: true,
              files: all_files.uniq,
              count: all_files.uniq.length,
              scopes: scopes
            }
          else
            {
              success: false,
              error: "Failed to enumerate some scopes: #{errors.join(', ')}",
              partial_files: all_files.uniq
            }
          end
        end

        private

        # Parse null-separated file output from git
        # @param output [String] Null-separated file list
        # @return [Array<String>] Array of file paths
        def parse_null_separated_files(output)
          return [] if output.nil? || output.empty?
          
          output.split("\0").map(&:strip).reject(&:empty?)
        end

        # Get modified files (not including untracked)
        # @param options [Hash] Options
        # @return [Hash] Result with modified files
        def get_modified_files(options)
          command = 'git diff --name-only -z'
          
          # Add HEAD to compare against if we want all changes
          command += ' HEAD' if options[:include_staged]
          
          result = @git_executor.execute(command)
          
          if result[:success]
            files = parse_null_separated_files(result[:stdout])
            
            {
              success: true,
              files: files
            }
          else
            {
              success: false,
              error: result[:error] || 'Failed to get modified files'
            }
          end
        end

        # Get files changed in a specific commit range
        # @param range [String] Commit range (e.g., 'HEAD~3..HEAD')
        # @param options [Hash] Options
        # @return [Hash] Result with changed files
        def get_files_changed_in_range(range, options)
          command = "git diff --name-only #{range} -z"
          
          result = @git_executor.execute(command)
          
          if result[:success]
            files = parse_null_separated_files(result[:stdout])
            
            {
              success: true,
              files: files
            }
          else
            {
              success: false,
              error: result[:error] || "Failed to get files changed in range #{range}"
            }
          end
        end

        # Filter files by modification time
        # @param files [Array<String>] File paths
        # @param options [Hash] Options with :since key
        # @return [Array<String>] Filtered files
        def filter_by_time(files, options)
          since_time = parse_time(options[:since])
          return files unless since_time
          
          files.select do |file|
            File.exist?(file) && File.mtime(file) >= since_time
          rescue StandardError
            false # Skip files that can't be stat'd
          end
        end

        # Parse time string or Time object
        # @param time_input [String, Time] Time to parse
        # @return [Time, nil] Parsed time
        def parse_time(time_input)
          case time_input
          when Time
            time_input
          when String
            # Handle git-style relative times
            case time_input
            when /(\d+)\s*days?\s*ago/i
              Time.now - ($1.to_i * 24 * 60 * 60)
            when /(\d+)\s*weeks?\s*ago/i
              Time.now - ($1.to_i * 7 * 24 * 60 * 60)
            when /(\d+)\s*months?\s*ago/i
              Time.now - ($1.to_i * 30 * 24 * 60 * 60)
            when /(\d+)\s*hours?\s*ago/i
              Time.now - ($1.to_i * 60 * 60)
            else
              Time.parse(time_input)
            end
          else
            nil
          end
        rescue ArgumentError
          nil
        end
      end
    end
  end
end
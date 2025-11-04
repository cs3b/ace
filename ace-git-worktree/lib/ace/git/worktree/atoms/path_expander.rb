# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Path expansion and validation atom
        #
        # Provides utilities for expanding user paths (~), resolving relative paths,
        # and validating path accessibility for worktree operations.
        #
        # @example Expand a user path
        #   PathExpander.expand("~") # => "/home/user"
        #
        # @example Resolve a relative path
        #   PathExpander.resolve("./worktrees") # => "/current/dir/worktrees"
        #
        # @example Validate path accessibility
        #   PathExpander.writable?("/tmp/worktree") # => true/false
        class PathExpander
          # Maximum allowed path length to prevent issues
          MAX_PATH_LENGTH = 4096

          # Dangerous path patterns that should be blocked
          DANGEROUS_PATTERNS = [
            /\.\.\//,  # Directory traversal
            /\A\.\./,  # Starts with ..
            /\/\.\./,  # Contains /..
            /\x00/,    # Null bytes
            /[<>:"|?*]/, # Windows invalid characters (also good for Unix)
          ].freeze

          class << self
            # Validate that a path is safe for processing
            #
            # @param path [String] Path to validate
            # @return [Boolean] true if path is safe
            # @raise [ArgumentError] if path contains dangerous patterns
            def safe_path?(path)
              return false if path.nil? || path.empty?

              path_str = path.to_s.strip

              # Check for dangerous patterns
              DANGEROUS_PATTERNS.each do |pattern|
                if path_str.match?(pattern)
                  raise ArgumentError, "Path contains dangerous pattern: #{path_str.inspect}"
                end
              end

              # Check path length
              if path_str.length > MAX_PATH_LENGTH
                raise ArgumentError, "Path too long: #{path_str.length} > #{MAX_PATH_LENGTH}"
              end

              true
            end

            # Expand a path, resolving ~ and making it absolute
            #
            # @param path [String] Path to expand
            # @return [String] Expanded absolute path
            #
            # @example
            #   PathExpander.expand("~") # => "/home/user"
            #   PathExpander.expand("./worktree") # => "/current/dir/worktree"
            #   PathExpander.expand("/absolute/path") # => "/absolute/path"
            def expand(path)
              return "" if path.nil? || path.empty?

              # Validate path safety first
              safe_path?(path)

              # Convert to string and strip whitespace
              path_str = path.to_s.strip

              # Expand ~ to user home directory
              expanded = path_str.sub(/^~\//, "#{Dir.home}/")

              # Expand ~username to user's home directory
              if expanded =~ /^~([^\/]+)/
                username = $1
                begin
                  user_home = Dir.home(username)
                  expanded = expanded.sub(/^~#{username}/, user_home)
                rescue ArgumentError
                  # User not found, leave as-is
                end
              end

              # Make path absolute and normalize
              absolute_path = File.expand_path(expanded)

              # Realpath to resolve symlinks and get canonical path
              # Use this to ensure we have the real path, preventing symlink-based attacks
              begin
                File.realpath(absolute_path)
              rescue Errno::ENOENT
                # Path doesn't exist yet, return normalized absolute path
                File.absolute_path(absolute_path)
              end
            end

            # Resolve a path relative to a base directory
            #
            # @param path [String] Path to resolve
            # @param base [String] Base directory (default: current directory)
            # @return [String] Resolved absolute path
            #
            # @example
            #   PathExpander.resolve("worktrees", "/project") # => "/project/worktrees"
            #   PathExpander.resolve("../other") # => "/parent/dir/other"
            def resolve(path, base = Dir.pwd)
              return expand(path) if File.absolute_path?(path)

              expanded_base = expand(base)
              File.expand_path(path, expanded_base)
            end

            # Check if a path is writable
            #
            # @param path [String] Path to check
            # @param create_if_missing [Boolean] Create directory if it doesn't exist
            # @return [Boolean] true if path is writable
            #
            # @example
            #   PathExpander.writable?("/tmp/worktree") # => true
            #   PathExpander.writable?("/root/protected") # => false
            def writable?(path, create_if_missing: false)
              expanded_path = expand(path)

              return false if expanded_path.length > MAX_PATH_LENGTH

              begin
                # Check if path exists
                unless File.exist?(expanded_path)
                  if create_if_missing
                    FileUtils.mkdir_p(expanded_path)
                  else
                    return false
                  end
                end

                # Test writability by trying to create a temp file
                temp_file = File.join(expanded_path, ".ace_git_worktree_test_#{Time.now.to_i}_#{$$}")
                File.write(temp_file, "test")
                File.delete(temp_file)
                true
              rescue Errno::EACCES, Errno::EROFS, Errno::ENOSPC
                false
              rescue StandardError
                false
              end
            end

            # Validate a path for worktree creation
            #
            # @param path [String] Path to validate
            # @param git_root [String] Git repository root directory
            # @return [Hash] Validation result with :valid, :error, :expanded_path keys
            #
            # @example
            #   result = PathExpander.validate_for_worktree("~/worktrees", "/project")
            #   # => { valid: true, error: nil, expanded_path: "/home/user/worktrees" }
            def validate_for_worktree(path, git_root = nil)
              expanded_path = expand(path)

              # Check path length
              if expanded_path.length > MAX_PATH_LENGTH
                return {
                  valid: false,
                  error: "Path too long (#{expanded_path.length} > #{MAX_PATH_LENGTH} characters)",
                  expanded_path: expanded_path
                }
              end

              # Check if path is within git repository (worktrees should be outside)
              if git_root && expanded_path.start_with?(expand(git_root))
                return {
                  valid: false,
                  error: "Worktree path cannot be within the git repository (#{git_root})",
                  expanded_path: expanded_path
                }
              end

              # Check if parent directory exists and is writable
              parent_dir = File.dirname(expanded_path)
              unless File.exist?(parent_dir)
                return {
                  valid: false,
                  error: "Parent directory does not exist: #{parent_dir}",
                  expanded_path: expanded_path
                }
              end

              unless writable?(parent_dir)
                return {
                  valid: false,
                  error: "Parent directory is not writable: #{parent_dir}",
                  expanded_path: expanded_path
                }
              end

              # Check if path already exists
              if File.exist?(expanded_path)
                if File.directory?(expanded_path) && !Dir.empty?(expanded_path)
                  return {
                    valid: false,
                    error: "Directory already exists and is not empty: #{expanded_path}",
                    expanded_path: expanded_path
                  }
                elsif File.file?(expanded_path)
                  return {
                    valid: false,
                    error: "Path exists but is a file: #{expanded_path}",
                    expanded_path: expanded_path
                  }
                end
              end

              {
                valid: true,
                error: nil,
                expanded_path: expanded_path
              }
            end

            # Generate a relative path from git root
            #
            # @param path [String] Absolute path
            # @param git_root [String] Git repository root
            # @return [String] Relative path from git root
            #
            # @example
            #   PathExpander.relative_to_git_root("/project/.ace-wt/task.081", "/project")
            #   # => ".ace-wt/task.081"
            def relative_to_git_root(path, git_root)
              expanded_path = expand(path)
              expanded_root = expand(git_root)

              if expanded_path.start_with?(expanded_root)
                expanded_path.sub(expanded_root + "/", "")
              else
                expanded_path
              end
            end
          end
        end
      end
    end
  end
end
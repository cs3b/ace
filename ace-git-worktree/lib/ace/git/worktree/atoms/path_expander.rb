# frozen_string_literal: true

require "fileutils"

module Ace
  module Git
    module Worktree
      module Atoms
        # Path expansion and validation for worktree operations
        #
        # Simplified implementation focused on worktree-specific needs without
        # over-engineered security patterns.
        #
        # @example Expand a user path
        #   PathExpander.expand("~") # => "/home/user"
        #
        # @example Check if a directory is writable
        #   PathExpander.writable?("/tmp/worktree") # => true/false
        class PathExpander
          class << self
            # Expand a path using standard Ruby path expansion
            #
            # @param path [String] Path to expand
            # @return [String] Expanded absolute path
            def expand(path)
              return "" if path.nil? || path.empty?
              File.expand_path(path)
            end

            # Resolve a path relative to a base directory
            #
            # @param path [String] Path to resolve
            # @param base [String] Base directory (default: current directory)
            # @return [String] Resolved absolute path
            def resolve(path, base = Dir.pwd)
              expand_path = expand(path)
              expanded_base = expand(base)

              if File.absolute_path?(expand_path)
                expand_path
              else
                File.expand_path(path, expanded_base)
              end
            end

            # Check if a path is writable
            #
            # @param path [String] Path to check
            # @param create_if_missing [Boolean] Create directory if it doesn't exist
            # @return [Boolean] true if path is writable
            def writable?(path, create_if_missing: false)
              expanded_path = expand(path)

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
              rescue Errno::EACCES, Errno::EPERM
                false
              rescue StandardError
                false
              end
            end

            # Validate a path for worktree creation
            #
            # @param path [String] Path to validate
            # @param git_root [String] Git repository root
            # @return [Hash] Validation result with :valid, :error, :expanded_path keys
            def validate_for_worktree(path, git_root = nil)
              expanded_path = expand(path)

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

              # Check if worktree is being created directly in git root (not allowed)
              if git_root
                git_root_expanded = File.expand_path(git_root)
                expanded_path_abs = File.expand_path(expanded_path)

                if expanded_path_abs.start_with?(git_root_expanded + "/")
                  relative_path = expanded_path_abs[git_root_expanded.length..-1]
                  # Don't allow direct creation in git root, only allow in .ace-wt
                  unless relative_path.start_with?("/.ace-wt/")
                    return {
                      valid: false,
                      error: "Worktree cannot be created directly in git repository. Use .ace-wt/ directory instead.",
                      expanded_path: expanded_path
                    }
                  end
                end
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

            # Get a relative path from git root
            #
            # @param path [String] Absolute path
            # @param git_root [String] Git repository root
            # @return [String] Relative path from git root
            def relative_to_git_root(path, git_root)
              expanded_path = expand(path)
              expanded_root = expand(git_root)

              # Use File.expand_path for consistent comparison
              normalized_path = File.expand_path(expanded_path)
              normalized_root = File.expand_path(expanded_root)

              if normalized_path.start_with?(normalized_root + "/") || normalized_path == normalized_root
                if normalized_path == normalized_root
                  "."
                else
                  relative_path = normalized_path[normalized_root.length..-1]
                  relative_path.start_with?("/") ? relative_path[1..-1] : relative_path
                end
              else
                expanded_path
              end
            end

            # Simple path safety validation
            # Only checks for obviously dangerous patterns
            #
            # @param path [String] Path to validate
            # @return [Boolean] true if path appears safe
            def safe_path?(path)
              return false if path.nil? || path.empty?

              path_str = path.to_s

              # Check for null bytes and obviously dangerous patterns
              return false if path_str.include?("\x00")
              return false if path_str.include?("../../../")

              true
            end
          end
        end
      end
    end
  end
end
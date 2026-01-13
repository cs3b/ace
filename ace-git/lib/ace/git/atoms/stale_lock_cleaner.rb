# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Pure functions for detecting and cleaning stale git index lock files
      #
      # Git index.lock files can become stale when:
      # - Previous git operations were interrupted (Ctrl+C, crashes, timeouts)
      # - Agents are blocked mid-operation leaving orphan lock files
      #
      # A stale lock is one that hasn't been modified recently (>60 seconds by default),
      # indicating the owning process is no longer active.
      #
      # Lock File Format:
      # Git lock files contain the PID and hostname of the process that created them.
      # This information could be used for more precise verification (checking if PID
      # is still running), but age-based detection is simpler and works reliably
      # across different systems and scenarios (crashed processes, remote mounts, etc.).
      module StaleLockCleaner
        class << self
          # Check if a lock file is stale (older than threshold)
          #
          # @param lock_path [String] Path to the lock file
          # @param threshold_seconds [Integer] Age threshold in seconds (default: 60)
          # @return [Boolean] true if the lock file is stale
          #
          # @example Fresh lock (active process)
          #   File.utime(Time.now - 30, Time.now - 30, lock_path)
          #   stale?(lock_path, 60)  # => false
          #
          # @example Stale lock (orphaned)
          #   File.utime(Time.now - 120, Time.now - 120, lock_path)
          #   stale?(lock_path, 60)  # => true
          def stale?(lock_path, threshold_seconds = 60)
            age_seconds = Time.now - File.mtime(lock_path)
            age_seconds > threshold_seconds
          rescue Errno::ENOENT
            false
          end

          # Find index.lock file for a repository
          #
          # @param repo_path [String] Path to the git repository
          # @return [String, nil] Path to the index.lock file or nil if not found
          #
          # @example In main repo
          #   find_lock_file("/path/to/repo")
          #   # => "/path/to/repo/.git/index.lock"
          #
          # @example In worktree
          #   find_lock_file("/path/to/worktree")
          #   # => "/path/to/worktree/.git/index.lock"
          def find_lock_file(repo_path)
            return nil if repo_path.nil? || repo_path.empty?

            # First try to find .git directory
            git_dir = File.join(repo_path, ".git")

            # If .git is a file (worktree), read the gitdir path
            if File.file?(git_dir)
              git_file_path = git_dir
              git_dir_content = File.read(git_file_path)
              # Worktree .git files contain: "gitdir: /path/to/main/.git/worktrees/..."
              # Use greedy match to capture full path including spaces, trim trailing whitespace
              if git_dir_content =~ /^gitdir:\s*(.+)\s*$/
                raw_git_dir = Regexp.last_match(1).strip
                # Handle relative paths by expanding from .git file location
                git_dir = File.expand_path(raw_git_dir, File.dirname(git_file_path))
              else
                return nil
              end
            end

            # Check if git directory exists
            return nil unless File.directory?(git_dir)

            # Return path to index.lock
            lock_path = File.join(git_dir, "index.lock")
            File.exist?(lock_path) ? lock_path : nil
          rescue StandardError
            nil
          end

          # Clean a stale lock file if it exists and is stale
          #
          # @param repo_path [String] Path to the git repository
          # @param threshold_seconds [Integer] Age threshold for stale detection
          # @return [Hash] Result with :success, :cleaned, :message
          #
          # @example Successfully cleaned stale lock
          #   clean("/path/to/repo", 60)
          #   # => { success: true, cleaned: true, message: "..." }
          #
          # @example No lock to clean
          #   clean("/path/to/repo", 60)
          #   # => { success: true, cleaned: false, message: "No lock found" }
          #
          # @example Lock is fresh (not stale)
          #   clean("/path/to/repo", 60)
          #   # => { success: true, cleaned: false, message: "Lock is fresh" }
          def clean(repo_path, threshold_seconds = 60)
            lock_path = find_lock_file(repo_path)

            return { success: true, cleaned: false, message: "No lock file found" } if lock_path.nil?

            # Security check: ensure lock file is a regular file, not a symlink
            # This prevents accidental deletion of symlink targets, which could be
            # exploited to cause data loss or security issues.
            if File.symlink?(lock_path)
              return { success: false, cleaned: false, message: "Lock file is a symlink, refusing to delete: #{lock_path}" }
            end

            # Safety check: ensure it's a regular file (not directory or device)
            unless File.file?(lock_path)
              return { success: false, cleaned: false, message: "Lock path is not a regular file: #{lock_path}" }
            end

            if stale?(lock_path, threshold_seconds)
              File.delete(lock_path)
              { success: true, cleaned: true, message: "Removed stale lock file: #{lock_path}" }
            else
              { success: true, cleaned: false, message: "Lock file is fresh (< #{threshold_seconds}s old)" }
            end
          rescue Errno::ENOENT
            # Handle TOCTOU race: lock file was deleted between check and delete
            { success: true, cleaned: false, message: "Lock file already removed" }
          rescue StandardError => e
            { success: false, cleaned: false, message: "Failed to clean lock: #{e.message}" }
          end
        end
      end
    end
  end
end

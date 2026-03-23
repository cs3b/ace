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
      # A stale lock is one that hasn't been modified recently (>10 seconds by default),
      # indicating the owning process is no longer active.
      #
      # Lock File Format:
      # Git lock files contain the PID and hostname of the process that created them.
      # We use PID-based detection (checking if owning process is still running) as
      # the primary method, with age-based detection as a fallback for edge cases
      # (remote mounts, containers where PID check may not work).
      module StaleLockCleaner
        class << self
          # Extract PID from a git lock file
          #
          # Git lock files contain the PID on the first line, optionally followed by hostname.
          # @param lock_path [String] Path to the lock file
          # @return [Integer, nil] PID if present and positive, otherwise nil
          def lock_pid(lock_path)
            content = File.read(lock_path)
            pid = content.to_s.split.first.to_i
            (pid > 0) ? pid : nil
          rescue Errno::ENOENT
            nil
          rescue
            nil
          end

          # Check if a process exists (signal 0 = check only)
          # @param pid [Integer] Process ID
          # @return [Boolean] true if process exists, false if not
          def process_active?(pid)
            Process.kill(0, pid)
            true
          rescue Errno::ESRCH
            false
          rescue Errno::EPERM
            true
          end

          # Check if a lock file is stale (older than threshold)
          #
          # @param lock_path [String] Path to the lock file
          # @param threshold_seconds [Integer] Age threshold in seconds (default: 10)
          # @return [Boolean] true if the lock file is stale
          #
          # @example Fresh lock (active process)
          #   File.utime(Time.now - 30, Time.now - 30, lock_path)
          #   stale?(lock_path, 60)  # => false
          #
          # @example Stale lock (orphaned)
          #   File.utime(Time.now - 120, Time.now - 120, lock_path)
          #   stale?(lock_path, 60)  # => true
          def stale?(lock_path, threshold_seconds = 10)
            age_seconds = Time.now - File.mtime(lock_path)
            age_seconds > threshold_seconds
          rescue Errno::ENOENT
            false
          end

          # Check if lock file is orphaned (owning process no longer exists)
          #
          # Git lock files contain the PID of the process that created them.
          # If that process no longer exists, the lock is orphaned and safe to delete.
          #
          # @param lock_path [String] Path to the lock file
          # @return [Boolean] true if the lock is orphaned (PID doesn't exist)
          #
          # @example Orphaned lock (process crashed)
          #   File.write(lock_path, "99999")  # Non-existent PID
          #   orphaned?(lock_path)  # => true
          #
          # @example Active lock (process running)
          #   File.write(lock_path, Process.pid.to_s)
          #   orphaned?(lock_path)  # => false
          def orphaned?(lock_path)
            pid = lock_pid(lock_path)
            return false unless pid

            !process_active?(pid)
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
          rescue
            nil
          end

          # Clean a lock file if it is orphaned (dead PID) or stale (old age)
          #
          # Uses PID-based detection first (instant), then falls back to age-based
          # detection for edge cases (remote mounts, containers).
          #
          # @param repo_path [String] Path to the git repository
          # @param threshold_seconds [Integer] Age threshold for stale detection
          # @return [Hash] Result with :success, :cleaned, :message
          #
          # @example Cleaned orphaned lock (dead PID)
          #   clean("/path/to/repo", 60)
          #   # => { success: true, cleaned: true, message: "Removed orphaned lock..." }
          #
          # @example Cleaned stale lock (old age)
          #   clean("/path/to/repo", 60)
          #   # => { success: true, cleaned: true, message: "Removed stale lock..." }
          #
          # @example No lock to clean
          #   clean("/path/to/repo", 60)
          #   # => { success: true, cleaned: false, message: "No lock found" }
          #
          # @example Lock is active (PID running, fresh)
          #   clean("/path/to/repo", 60)
          #   # => { success: true, cleaned: false, message: "Lock is active..." }
          def clean(repo_path, threshold_seconds = 10)
            lock_path = find_lock_file(repo_path)

            if lock_path.nil?
              return {success: true, cleaned: false, status: :missing, pid: nil, age_seconds: nil,
                      message: "No lock file found"}
            end

            # Security check: ensure lock file is a regular file, not a symlink
            # This prevents accidental deletion of symlink targets, which could be
            # exploited to cause data loss or security issues.
            if File.symlink?(lock_path)
              return {success: false, cleaned: false, status: :symlink, pid: nil, age_seconds: nil,
                      message: "Lock file is a symlink, refusing to delete: #{lock_path}"}
            end

            # Safety check: ensure it's a regular file (not directory or device)
            unless File.file?(lock_path)
              return {success: false, cleaned: false, status: :invalid, pid: nil, age_seconds: nil,
                      message: "Lock path is not a regular file: #{lock_path}"}
            end

            pid = lock_pid(lock_path)
            age_seconds = begin
              Time.now - File.mtime(lock_path)
            rescue
              nil
            end

            pid_active = pid ? process_active?(pid) : false

            # Check PID-based activity first
            if pid_active
              return {
                success: true,
                cleaned: false,
                status: :active,
                pid: pid,
                age_seconds: age_seconds,
                message: "Lock file is active (PID running, < #{threshold_seconds}s old)"
              }
            end

            # Orphaned PID should be removed immediately
            if pid && !pid_active
              File.delete(lock_path)
              return {
                success: true,
                cleaned: true,
                status: :orphaned,
                pid: pid,
                age_seconds: age_seconds,
                message: "Removed orphaned lock file (dead PID): #{lock_path}"
              }
            end

            # Fallback to age-based stale detection
            if stale?(lock_path, threshold_seconds)
              File.delete(lock_path)
              return {
                success: true,
                cleaned: true,
                status: :stale,
                pid: pid,
                age_seconds: age_seconds,
                message: "Removed stale lock file: #{lock_path}"
              }
            end

            {
              success: true,
              cleaned: false,
              status: :unknown,
              pid: pid,
              age_seconds: age_seconds,
              message: "Lock file present but status unclear (< #{threshold_seconds}s old)"
            }
          rescue Errno::ENOENT
            # Handle TOCTOU race: lock file was deleted between check and delete
            {success: true, cleaned: false, status: :missing, pid: nil, age_seconds: nil,
             message: "Lock file already removed"}
          rescue => e
            {success: false, cleaned: false, status: :error, pid: nil, age_seconds: nil,
             message: "Failed to clean lock: #{e.message}"}
          end
        end
      end
    end
  end
end

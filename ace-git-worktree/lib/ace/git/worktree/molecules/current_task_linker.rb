# frozen_string_literal: true

require "fileutils"
require "pathname"

module Ace
  module Git
    module Worktree
      module Molecules
        # Creates and manages the _current symlink pointing to the active task directory
        #
        # This molecule provides quick access to the current working task without
        # needing to remember task IDs. The symlink is created at project root.
        #
        # @example Create symlink to task directory
        #   linker = CurrentTaskLinker.new(project_root: "/project")
        #   result = linker.link("/project/.ace-task/v.0.9.0/tasks/145-feat/")
        #   # => { success: true, symlink_path: "/project/_current", target: "..." }
        #
        # @example Remove symlink
        #   linker.unlink
        #   # => { success: true }
        class CurrentTaskLinker
          # Default name for the symlink
          DEFAULT_SYMLINK_NAME = "_current"

          # Initialize a new CurrentTaskLinker
          #
          # @param project_root [String, nil] Project root directory (defaults to Dir.pwd)
          # @param symlink_name [String] Name of the symlink (default: "_current")
          def initialize(project_root: nil, symlink_name: DEFAULT_SYMLINK_NAME)
            @project_root = project_root || Dir.pwd
            @symlink_name = symlink_name
          end

          # Create symlink to task directory
          #
          # Creates a symlink at project root pointing to the given task directory.
          # Uses relative paths for portability. Removes existing symlink if present.
          #
          # @param task_directory [String] Absolute path to task directory
          # @return [Hash] Result with :success, :symlink_path, :target, :relative_target, :error
          def link(task_directory)
            return { success: false, error: "Task directory is required" } if task_directory.nil? || task_directory.empty?
            return { success: false, error: "Task directory does not exist: #{task_directory}" } unless Dir.exist?(task_directory)

            symlink_path = File.join(@project_root, @symlink_name)

            # Remove existing symlink or file if present
            remove_existing(symlink_path)

            # Calculate relative path from project root to task directory
            relative_target = calculate_relative_path(task_directory)

            # Create the symlink
            File.symlink(relative_target, symlink_path)

            {
              success: true,
              symlink_path: symlink_path,
              target: task_directory,
              relative_target: relative_target
            }
          rescue StandardError => e
            { success: false, error: "Failed to create symlink: #{e.message}" }
          end

          # Remove the _current symlink
          #
          # @return [Hash] Result with :success, :error
          def unlink
            symlink_path = File.join(@project_root, @symlink_name)

            return { success: true, existed: false } unless File.symlink?(symlink_path)

            FileUtils.rm_f(symlink_path)
            { success: true, existed: true }
          rescue StandardError => e
            { success: false, error: "Failed to remove symlink: #{e.message}" }
          end

          # Get the path to the current symlink
          #
          # @return [String] Path to the symlink
          def symlink_path
            File.join(@project_root, @symlink_name)
          end

          # Check if symlink exists
          #
          # @return [Boolean] true if symlink exists
          def exists?
            File.symlink?(symlink_path)
          end

          # Get the target of the current symlink
          #
          # @return [String, nil] Target path or nil if symlink doesn't exist
          def current_target
            return nil unless exists?

            File.readlink(symlink_path)
          end

          # Get the absolute path to the current task directory
          #
          # @return [String, nil] Absolute path or nil if symlink doesn't exist
          def current_absolute_path
            return nil unless exists?

            File.realpath(symlink_path)
          rescue Errno::ENOENT
            nil
          end

          private

          # Remove existing symlink or file at path
          #
          # @param path [String] Path to remove
          def remove_existing(path)
            FileUtils.rm_f(path) if File.exist?(path) || File.symlink?(path)
          end

          # Calculate relative path from project root to target
          #
          # @param target [String] Absolute path to target
          # @return [String] Relative path
          def calculate_relative_path(target)
            Pathname.new(target).relative_path_from(Pathname.new(@project_root)).to_s
          end
        end
      end
    end
  end
end

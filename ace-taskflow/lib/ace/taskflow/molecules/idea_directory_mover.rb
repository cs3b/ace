# frozen_string_literal: true

require 'fileutils'
require 'time'
require_relative '../configuration'

module Ace
  module Taskflow
    module Molecules
      # Handles atomic move of idea files to _archive/ subdirectory
      class IdeaDirectoryMover
        # Move an idea file or directory to _archive/ subdirectory atomically
        # @param idea_path [String] Full path to the idea file or directory
        # @param timestamp [Time] Optional completion timestamp
        # @return [Hash] Result with :success, :new_path, and :message
        def move_to_archive(idea_path, timestamp = Time.now)
          return { success: false, message: "Idea path not provided" } unless idea_path
          return { success: false, message: "Idea not found: #{idea_path}" } unless File.exist?(idea_path) || Dir.exist?(idea_path)

          # Normalize: if it's a file, we need to move its parent folder
          # This ensures consistent behavior whether user passes file or folder
          is_file = File.file?(idea_path)
          if is_file
            idea_folder = File.dirname(idea_path)
            idea_name = File.basename(idea_folder)
            ideas_dir = File.dirname(idea_folder)
            is_directory = true  # We're moving the folder, not the file
          else
            idea_folder = idea_path
            idea_name = File.basename(idea_folder)
            ideas_dir = File.dirname(idea_folder)
            is_directory = true
          end

          # Create archive directory at ideas level (sibling to idea folders)
          archive_dir_name = Ace::Taskflow.configuration.done_dir
          archive_dir = File.join(ideas_dir, archive_dir_name)
          FileUtils.mkdir_p(archive_dir) unless File.directory?(archive_dir)

          # Target path in archive directory
          target_path = File.join(archive_dir, idea_name)

          # Check if target already exists
          if File.exist?(target_path) || Dir.exist?(target_path)
            return {
              success: false,
              message: "Target already exists in #{archive_dir_name}/: #{target_path}"
            }
          end

          begin
            # Update idea frontmatter before moving
            # Always working with the folder now (normalized above)
            # Look for idea.md or any .md file in the folder
            idea_file = File.join(idea_folder, "idea.md")
            if File.exist?(idea_file)
              update_idea_completion_metadata(idea_file, timestamp)
            else
              # Try to find any .md file in the folder
              md_files = Dir.glob(File.join(idea_folder, "*.md"))
              update_idea_completion_metadata(md_files.first, timestamp) if md_files.any?
            end

            # Perform atomic move of the folder
            FileUtils.mv(idea_folder, target_path)

            {
              success: true,
              new_path: target_path,
              message: "Idea moved to #{Ace::Taskflow.configuration.done_dir}/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to move idea: #{e.message}"
            }
          end
        end

        # Move an idea file or directory back from _archive/ subdirectory
        # @param idea_path [String] Full path to the idea file or directory in _archive/
        # @return [Hash] Result with :success, :new_path, and :message
        def restore_from_archive(idea_path)
          return { success: false, message: "Idea path not provided" } unless idea_path
          return { success: false, message: "Idea not found: #{idea_path}" } unless File.exist?(idea_path) || Dir.exist?(idea_path)

          # Get archive directory name from configuration
          archive_dir_name = Ace::Taskflow.configuration.done_dir

          # Verify idea is in archive directory
          unless idea_path.include?("/#{archive_dir_name}/")
            return {
              success: false,
              message: "Idea is not in #{archive_dir_name}/ directory"
            }
          end

          is_directory = Dir.exist?(idea_path) && !File.file?(idea_path)

          # Get idea name and determine restoration path
          archive_dir = File.dirname(idea_path)
          parent_dir = File.dirname(archive_dir)
          idea_name = File.basename(idea_path)

          # Target path in parent directory
          target_path = File.join(parent_dir, idea_name)

          # Check if target already exists
          if File.exist?(target_path) || Dir.exist?(target_path)
            return {
              success: false,
              message: "Target already exists: #{target_path}"
            }
          end

          begin
            # Update idea status back to pending
            if is_directory
              idea_file = File.join(idea_path, "idea.md")
              update_idea_status(idea_file, "pending") if File.exist?(idea_file)
            else
              update_idea_status(idea_path, "pending")
            end

            # Perform atomic move
            FileUtils.mv(idea_path, target_path)

            {
              success: true,
              new_path: target_path,
              message: "Idea restored from #{Ace::Taskflow.configuration.done_dir}/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to restore idea: #{e.message}"
            }
          end
        end

        # Backward compatibility alias for move_to_archive
        # @deprecated Use move_to_archive instead
        def move_to_done(idea_path, timestamp = Time.now)
          warn "[DEPRECATION] `move_to_done` is deprecated. Use `move_to_archive` instead."
          move_to_archive(idea_path, timestamp)
        end

        # Backward compatibility alias for restore_from_archive
        # @deprecated Use restore_from_archive instead
        def restore_from_done(idea_path)
          warn "[DEPRECATION] `restore_from_done` is deprecated. Use `restore_from_archive` instead."
          restore_from_archive(idea_path)
        end

        # Move an idea file or directory to _parked/ subdirectory atomically
        # @param idea_path [String] Full path to the idea file or directory
        # @return [Hash] Result with :success, :new_path, and :message
        def move_to_parked(idea_path)
          return { success: false, message: "Idea path not provided" } unless idea_path
          return { success: false, message: "Idea not found: #{idea_path}" } unless File.exist?(idea_path) || Dir.exist?(idea_path)

          # Normalize: if it's a file, we need to move its parent folder
          is_file = File.file?(idea_path)
          if is_file
            idea_folder = File.dirname(idea_path)
            idea_name = File.basename(idea_folder)
            ideas_dir = File.dirname(idea_folder)
          else
            idea_folder = idea_path
            idea_name = File.basename(idea_folder)
            ideas_dir = File.dirname(idea_folder)
          end

          # Create parked directory at ideas level (sibling to idea folders)
          parked_dir_name = Ace::Taskflow.configuration.parked_dir
          parked_dir = File.join(ideas_dir, parked_dir_name)
          FileUtils.mkdir_p(parked_dir) unless File.directory?(parked_dir)

          # Target path in parked directory
          target_path = File.join(parked_dir, idea_name)

          # Check if target already exists
          if File.exist?(target_path) || Dir.exist?(target_path)
            return {
              success: false,
              message: "Target already exists in #{parked_dir_name}/: #{target_path}"
            }
          end

          begin
            # Update idea status to parked before moving
            idea_file = File.join(idea_folder, "idea.md")
            if File.exist?(idea_file)
              update_idea_status(idea_file, "parked")
            else
              # Try to find any .md file in the folder
              md_files = Dir.glob(File.join(idea_folder, "*.md"))
              update_idea_status(md_files.first, "parked") if md_files.any?
            end

            # Perform atomic move of the folder
            FileUtils.mv(idea_folder, target_path)

            {
              success: true,
              new_path: target_path,
              message: "Idea moved to #{Ace::Taskflow.configuration.parked_dir}/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to move idea: #{e.message}"
            }
          end
        end

        # Move an idea file or directory back from _parked/ subdirectory
        # @param idea_path [String] Full path to the idea file or directory in _parked/
        # @return [Hash] Result with :success, :new_path, and :message
        def restore_from_parked(idea_path)
          return { success: false, message: "Idea path not provided" } unless idea_path
          return { success: false, message: "Idea not found: #{idea_path}" } unless File.exist?(idea_path) || Dir.exist?(idea_path)

          # Get parked directory name from configuration
          parked_dir_name = Ace::Taskflow.configuration.parked_dir

          # Verify idea is in parked directory
          unless idea_path.include?("/#{parked_dir_name}/")
            return {
              success: false,
              message: "Idea is not in #{parked_dir_name}/ directory"
            }
          end

          is_directory = Dir.exist?(idea_path) && !File.file?(idea_path)

          # Get idea name and determine restoration path
          parked_dir = File.dirname(idea_path)
          parent_dir = File.dirname(parked_dir)
          idea_name = File.basename(idea_path)

          # Target path in parent directory
          target_path = File.join(parent_dir, idea_name)

          # Check if target already exists
          if File.exist?(target_path) || Dir.exist?(target_path)
            return {
              success: false,
              message: "Target already exists: #{target_path}"
            }
          end

          begin
            # Update idea status back to pending
            if is_directory
              idea_file = File.join(idea_path, "idea.md")
              update_idea_status(idea_file, "pending") if File.exist?(idea_file)
            else
              update_idea_status(idea_path, "pending")
            end

            # Perform atomic move
            FileUtils.mv(idea_path, target_path)

            {
              success: true,
              new_path: target_path,
              message: "Idea restored from #{Ace::Taskflow.configuration.parked_dir}/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to restore idea: #{e.message}"
            }
          end
        end

        private

        # Update idea completion metadata in frontmatter
        def update_idea_completion_metadata(idea_path, timestamp)
          content = File.read(idea_path)

          # Update or add frontmatter
          if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
            frontmatter = $1
            body = $'

            # Parse YAML frontmatter
            lines = frontmatter.split("\n")
            updated_lines = []
            found_status = false
            found_completed = false

            lines.each do |line|
              if line =~ /^status:/
                updated_lines << "status: done"
                found_status = true
              elsif line =~ /^completed_at:/
                updated_lines << "completed_at: #{timestamp.iso8601}"
                found_completed = true
              else
                updated_lines << line
              end
            end

            # Add missing fields
            updated_lines << "status: done" unless found_status
            updated_lines << "completed_at: #{timestamp.iso8601}" unless found_completed

            # Reconstruct content
            new_content = "---\n#{updated_lines.join("\n")}\n---\n#{body}"
          else
            # No frontmatter, add it
            new_content = "---\nstatus: done\ncompleted_at: #{timestamp.iso8601}\n---\n\n#{content}"
          end

          File.write(idea_path, new_content)
        end

        # Update idea status in frontmatter
        def update_idea_status(idea_path, status)
          content = File.read(idea_path)

          # Update frontmatter
          if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
            frontmatter = $1
            body = $'

            # Update status and remove completed_at
            lines = frontmatter.split("\n")
            updated_lines = []

            lines.each do |line|
              if line =~ /^status:/
                updated_lines << "status: #{status}"
              elsif line !~ /^completed_at:/
                updated_lines << line
              end
            end

            # Reconstruct content
            new_content = "---\n#{updated_lines.join("\n")}\n---\n#{body}"
            File.write(idea_path, new_content)
          end
        end
      end
    end
  end
end
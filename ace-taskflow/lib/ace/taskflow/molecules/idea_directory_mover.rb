# frozen_string_literal: true

require 'fileutils'
require 'time'

module Ace
  module Taskflow
    module Molecules
      # Handles atomic move of idea files to done/ subdirectory
      class IdeaDirectoryMover
        # Move an idea file to done/ subdirectory atomically
        # @param idea_path [String] Full path to the idea file
        # @param timestamp [Time] Optional completion timestamp
        # @return [Hash] Result with :success, :new_path, and :message
        def move_to_done(idea_path, timestamp = Time.now)
          return { success: false, message: "Idea path not provided" } unless idea_path
          return { success: false, message: "Idea file not found: #{idea_path}" } unless File.exist?(idea_path)

          # Get idea directory and filename
          idea_dir = File.dirname(idea_path)
          idea_filename = File.basename(idea_path)

          # Create done directory if it doesn't exist
          done_dir = File.join(idea_dir, "done")
          FileUtils.mkdir_p(done_dir) unless File.directory?(done_dir)

          # Target path in done directory
          target_path = File.join(done_dir, idea_filename)

          # Check if target already exists
          if File.exist?(target_path)
            return {
              success: false,
              message: "Target already exists in done/: #{target_path}"
            }
          end

          begin
            # Update idea frontmatter before moving
            update_idea_completion_metadata(idea_path, timestamp)

            # Perform atomic move
            FileUtils.mv(idea_path, target_path)

            {
              success: true,
              new_path: target_path,
              message: "Idea moved to done/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to move idea file: #{e.message}"
            }
          end
        end

        # Move an idea file back from done/ subdirectory
        # @param idea_path [String] Full path to the idea file in done/
        # @return [Hash] Result with :success, :new_path, and :message
        def restore_from_done(idea_path)
          return { success: false, message: "Idea path not provided" } unless idea_path
          return { success: false, message: "Idea file not found: #{idea_path}" } unless File.exist?(idea_path)

          # Verify idea is in done/ directory
          unless idea_path.include?("/done/")
            return {
              success: false,
              message: "Idea is not in done/ directory"
            }
          end

          # Get idea filename and determine restoration path
          done_dir = File.dirname(idea_path)
          parent_dir = File.dirname(done_dir)
          idea_filename = File.basename(idea_path)

          # Target path in parent directory
          target_path = File.join(parent_dir, idea_filename)

          # Check if target already exists
          if File.exist?(target_path)
            return {
              success: false,
              message: "Target already exists: #{target_path}"
            }
          end

          begin
            # Update idea status back to pending
            update_idea_status(idea_path, "pending")

            # Perform atomic move
            FileUtils.mv(idea_path, target_path)

            {
              success: true,
              new_path: target_path,
              message: "Idea restored from done/"
            }
          rescue StandardError => e
            {
              success: false,
              message: "Failed to restore idea file: #{e.message}"
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
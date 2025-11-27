# frozen_string_literal: true

require "fileutils"
require_relative "../atoms/timestamp_generator"

module Ace
  module Prompt
    module Molecules
      # Archive prompt file with timestamp and symlink management
      class PromptArchiver
        # Class-level mutex for thread-safe symlink operations
        @symlink_mutex = Mutex.new

        # Get the class-level mutex
        # @return [Mutex]
        def self.symlink_mutex
          @symlink_mutex
        end
        # Archive prompt to timestamped file
        # @param source_path [String] Path to source prompt file
        # @param archive_dir [String] Directory to store archived prompts
        # @param enhancement_iteration [Integer, nil] Enhancement iteration number
        # @return [String] Path to archived file
        def self.archive(source_path, archive_dir, enhancement_iteration: nil)
          FileUtils.mkdir_p(archive_dir)

          timestamp = if enhancement_iteration
            Atoms::TimestampGenerator.generate_with_enhancement(enhancement_iteration)
          else
            Atoms::TimestampGenerator.generate
          end

          archive_path = File.join(archive_dir, "#{timestamp}.md")
          FileUtils.cp(source_path, archive_path)

          archive_path
        rescue => e
          warn "Warning: Failed to archive prompt: #{e.message}"
          nil
        end

        # Update _previous.md symlink to point to latest archive
        # @param target_path [String] Path to archived file
        # @param symlink_path [String] Path where symlink should be created
        # @return [Boolean] True if successful
        def self.update_symlink(target_path, symlink_path)
          # Check if target exists before creating symlink
          return false unless File.exist?(target_path)

          # Use mutex to prevent race conditions in concurrent symlink operations
          symlink_mutex.synchronize do
            # Remove existing symlink if present
            FileUtils.rm_f(symlink_path) if File.exist?(symlink_path) || File.symlink?(symlink_path)

            # Create relative symlink
            target_relative = File.basename(File.dirname(target_path)) + "/" + File.basename(target_path)
            FileUtils.ln_s(target_relative, symlink_path)

            true
          end
        rescue => e
          warn "Warning: Failed to update symlink: #{e.message}"
          false
        end
      end
    end
  end
end

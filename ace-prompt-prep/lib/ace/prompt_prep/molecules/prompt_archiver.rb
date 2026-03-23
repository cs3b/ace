# frozen_string_literal: true

require "fileutils"
require "ace/support/fs"
require_relative "../atoms/session_id_generator"

module Ace
  module PromptPrep
    module Molecules
      # Archives prompt file with timestamp and updates symlink
      class PromptArchiver
        # Default directories (fallback if config unavailable)
        DEFAULT_CACHE_DIR = Ace::PromptPrep::Defaults::DEFAULT_CACHE_DIR
        DEFAULT_ARCHIVE_DIR = "prompts/archive"
        DEFAULT_PREVIOUS_SYMLINK = "prompts/_previous.md"

        # Get archive directory from config
        # @return [String] Archive directory relative to project root
        def self.archive_dir_from_config
          config = Ace::PromptPrep.config
          cache_dir = config.dig("paths", "cache_dir") || DEFAULT_CACHE_DIR
          archive_dir = config.dig("paths", "archive_dir") || DEFAULT_ARCHIVE_DIR
          File.join(cache_dir, archive_dir)
        end

        # Get previous symlink path from config
        # @return [String] Previous symlink path relative to project root
        def self.previous_symlink_from_config
          config = Ace::PromptPrep.config
          cache_dir = config.dig("paths", "cache_dir") || DEFAULT_CACHE_DIR
          previous_symlink = config.dig("paths", "previous_symlink") || DEFAULT_PREVIOUS_SYMLINK
          File.join(cache_dir, previous_symlink)
        end

        # Archive prompt content
        #
        # @param content [String] Content to archive
        # @param timestamp [String, nil] Optional timestamp (default: generated)
        # @param archive_dir [String, nil] Optional custom archive directory
        # @param symlink_path [String, nil] Optional custom symlink path
        # @return [Hash] Hash with :archive_path, :symlink_path, :success, :error keys
        def self.call(content:, timestamp: nil, archive_dir: nil, symlink_path: nil)
          return {success: false, error: "Error: Content to archive cannot be nil"} if content.nil?

          project_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          archive_dir ||= File.join(project_root, archive_dir_from_config)
          FileUtils.mkdir_p(archive_dir)

          # Generate or use provided timestamp
          ts = timestamp || Atoms::SessionIdGenerator.call[:timestamp]

          # Handle timestamp collision by appending suffix
          archive_filename = "#{ts}.md"
          archive_path = File.join(archive_dir, archive_filename)
          counter = 1
          while File.exist?(archive_path)
            archive_filename = "#{ts}-#{counter}.md"
            archive_path = File.join(archive_dir, archive_filename)
            counter += 1
          end

          # Write archive file
          File.write(archive_path, content, encoding: "utf-8")

          # Update symlink
          symlink_path ||= File.join(project_root, previous_symlink_from_config)
          update_symlink_result = update_symlink(symlink_path, archive_path)

          {
            archive_path: archive_path,
            symlink_path: symlink_path,
            symlink_updated: update_symlink_result[:success],
            success: true,
            error: nil
          }
        rescue => e
          {
            archive_path: nil,
            symlink_path: nil,
            success: false,
            error: "Error: Failed to archive file: #{e.message}"
          }
        end

        # Update symlink to point to archive file
        #
        # @param symlink_path [String] Path to symlink
        # @param target_path [String] Path to target file
        # @return [Hash] Hash with :success, :error keys
        def self.update_symlink(symlink_path, target_path)
          # Remove existing symlink if it exists
          File.delete(symlink_path) if File.exist?(symlink_path) || File.symlink?(symlink_path)

          # Create relative path from symlink to target
          # Both are in .ace-local/prompt-prep/prompts/, target is in archive/ subdirectory
          target_basename = File.basename(target_path)
          relative_target = "archive/#{target_basename}"

          # Create new symlink
          File.symlink(relative_target, symlink_path)

          {success: true, error: nil}
        rescue => e
          {success: false, error: "Error: Failed to update symlink: #{e.message}"}
        end
      end
    end
  end
end

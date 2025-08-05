# frozen_string_literal: true

require 'fileutils'
require 'pathname'
require_relative '../atoms/timestamp_generator'
require_relative '../atoms/code/directory_creator'

module CodingAgentTools
  module Molecules
    # BackupCreator handles creating timestamped backups of directories
    # This is a molecule - it composes atoms to perform backup operations
    class BackupCreator
      def initialize(
        timestamp_generator: Atoms::TimestampGenerator,
        directory_creator: Atoms::Code::DirectoryCreator.new
      )
        @timestamp_generator = timestamp_generator
        @directory_creator = directory_creator
      end

      # Create a backup of a directory
      # @param source_path [String, Pathname] Directory to backup
      # @param options [Hash] Options for backup
      # @option options [Boolean] :dry_run Don't actually create backup
      # @option options [String] :suffix Suffix to add after timestamp
      # @return [Hash] Result with backup path and status
      def create_backup(source_path, options = {})
        source = normalize_path(source_path)

        # Check if source exists
        unless source.exist?
          return {
            success: false,
            path: nil,
            error: "Source directory does not exist: #{source}"
          }
        end

        # Generate backup path
        timestamp = @timestamp_generator.backup_timestamp
        suffix = options[:suffix] ? ".#{options[:suffix]}" : ''
        backup_path = source.parent / "#{source.basename}.backup.#{timestamp}#{suffix}"

        # Handle dry run
        if options[:dry_run]
          return {
            success: true,
            path: backup_path,
            dry_run: true,
            message: "Would create backup at: #{backup_path}"
          }
        end

        # Perform backup
        perform_backup(source, backup_path)
      end

      # List existing backups for a directory
      # @param target_path [String, Pathname] Original directory path
      # @return [Array<Pathname>] List of backup paths, sorted by date
      def list_backups(target_path)
        target = normalize_path(target_path)
        pattern = "#{target.basename}.backup.*"

        target.parent.glob(pattern).select(&:directory?).sort
      end

      # Clean old backups, keeping only the most recent ones
      # @param target_path [String, Pathname] Original directory path
      # @param keep_count [Integer] Number of backups to keep
      # @param options [Hash] Options
      # @option options [Boolean] :dry_run Don't actually delete
      # @return [Hash] Result with deleted paths
      def clean_old_backups(target_path, keep_count: 3, **options)
        backups = list_backups(target_path)
        to_delete = []

        if backups.size > keep_count
          # Keep the most recent backups
          to_delete = backups[0..-(keep_count + 1)]
        end

        if options[:dry_run]
          return {
            success: true,
            deleted: to_delete,
            dry_run: true,
            message: "Would delete #{to_delete.size} old backup(s)"
          }
        end

        # Delete old backups
        deleted = []
        errors = []

        to_delete.each do |backup|
          begin
            FileUtils.rm_rf(backup)
            deleted << backup
          rescue => e
            errors << { path: backup, error: e.message }
          end
        end

        {
          success: errors.empty?,
          deleted: deleted,
          errors: errors
        }
      end

      # Restore from a backup
      # @param backup_path [String, Pathname] Backup directory path
      # @param target_path [String, Pathname] Target directory to restore to
      # @param options [Hash] Options
      # @option options [Boolean] :force Overwrite existing target
      # @return [Hash] Result of restore operation
      def restore_backup(backup_path, target_path, options = {})
        backup = normalize_path(backup_path)
        target = normalize_path(target_path)

        unless backup.exist?
          return {
            success: false,
            error: "Backup does not exist: #{backup}"
          }
        end

        if target.exist? && !options[:force]
          return {
            success: false,
            error: "Target already exists: #{target}. Use force: true to overwrite."
          }
        end

        begin
          # Remove existing target if force is true
          FileUtils.rm_rf(target) if target.exist? && options[:force]

          # Copy backup to target
          FileUtils.cp_r(backup, target)

          {
            success: true,
            restored_from: backup,
            restored_to: target
          }
        rescue => e
          {
            success: false,
            error: "Failed to restore backup: #{e.message}"
          }
        end
      end

      private

      def normalize_path(path)
        path.is_a?(Pathname) ? path : Pathname.new(path.to_s)
      end

      def perform_backup(source, backup_path)
        begin
          FileUtils.cp_r(source, backup_path)
          {
            success: true,
            path: backup_path,
            message: "Backed up to: #{backup_path}"
          }
        rescue => e
          {
            success: false,
            path: nil,
            error: "Failed to create backup: #{e.message}"
          }
        end
      end
    end
  end
end

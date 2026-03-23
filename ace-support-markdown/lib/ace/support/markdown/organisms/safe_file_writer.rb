# frozen_string_literal: true

require "fileutils"
require "tempfile"

module Ace
  module Support
    module Markdown
      module Organisms
        # Safe file writing with backup and atomic operations
        # Prevents corruption through temp file + move pattern
        class SafeFileWriter
          # Write content to file safely with backup and rollback
          # @param file_path [String] Target file path
          # @param content [String] Content to write
          # @param backup [Boolean] Create backup before writing (default: true)
          # @param validate [Boolean] Validate content before writing (default: false)
          # @param validator [Proc, nil] Optional validation proc
          # @return [Hash] Result with :success, :backup_path, :errors
          def self.write(file_path, content, backup: true, validate: false, validator: nil)
            raise ArgumentError, "File path cannot be nil" if file_path.nil?
            raise ArgumentError, "Content cannot be nil" if content.nil?

            errors = []

            # Validate content if requested
            if validate || validator
              validation_errors = perform_validation(content, validator)
              unless validation_errors.empty?
                return {
                  success: false,
                  backup_path: nil,
                  errors: validation_errors
                }
              end
            end

            backup_path = nil

            begin
              # Create backup if requested and file exists
              if backup && File.exist?(file_path)
                backup_path = create_backup(file_path)
              end

              # Write atomically using temp file + move
              write_atomic(file_path, content)

              {
                success: true,
                backup_path: backup_path,
                errors: []
              }
            rescue => e
              # Rollback from backup if available
              if backup_path && File.exist?(backup_path)
                begin
                  FileUtils.cp(backup_path, file_path)
                  errors << "Write failed, restored from backup: #{e.message}"
                rescue => rollback_error
                  errors << "Write failed and rollback failed: #{e.message} | #{rollback_error.message}"
                end
              else
                errors << "Write failed: #{e.message}"
              end

              {
                success: false,
                backup_path: backup_path,
                errors: errors
              }
            end
          end

          # Write content with automatic validation
          # @param file_path [String] Target file path
          # @param content [String] Content to write
          # @param rules [Hash] Validation rules
          # @return [Hash] Result with :success, :backup_path, :errors
          def self.write_with_validation(file_path, content, rules: {})
            validator = lambda do |c|
              result = Atoms::DocumentValidator.validate(c, rules: rules)
              result[:valid] ? [] : result[:errors]
            end

            write(file_path, content, backup: true, validate: true, validator: validator)
          end

          # Create a backup of the file
          # @param file_path [String] File to backup
          # @return [String] Backup file path
          def self.create_backup(file_path)
            raise FileOperationError, "File not found: #{file_path}" unless File.exist?(file_path)

            timestamp = Time.now.strftime("%Y%m%d_%H%M%S_%L")
            backup_path = "#{file_path}.backup.#{timestamp}"

            FileUtils.cp(file_path, backup_path)
            backup_path
          end

          # Restore from backup
          # @param file_path [String] Target file path
          # @param backup_path [String] Backup file path
          # @return [Hash] Result with :success, :errors
          def self.restore_from_backup(file_path, backup_path)
            unless File.exist?(backup_path)
              return {
                success: false,
                errors: ["Backup file not found: #{backup_path}"]
              }
            end

            begin
              FileUtils.cp(backup_path, file_path)
              {
                success: true,
                errors: []
              }
            rescue => e
              {
                success: false,
                errors: ["Restore failed: #{e.message}"]
              }
            end
          end

          # Cleanup old backup files
          # @param file_path [String] Original file path
          # @param keep [Integer] Number of recent backups to keep (default: 5)
          # @return [Integer] Number of backups deleted
          def self.cleanup_backups(file_path, keep: 5)
            dir = File.dirname(file_path)
            basename = File.basename(file_path)

            # Find all backup files for this file
            backup_pattern = File.join(dir, "#{basename}.backup.*")
            backups = Dir.glob(backup_pattern).sort

            # Keep only the most recent N backups
            to_delete = backups[0...-keep] || []

            deleted = 0
            to_delete.each do |backup|
              File.delete(backup)
              deleted += 1
            rescue
              # Skip files that can't be deleted
              next
            end

            deleted
          end

          private

          # Write file atomically using temp file + move
          def self.write_atomic(file_path, content)
            # Get directory and ensure it exists
            dir = File.dirname(file_path)
            FileUtils.mkdir_p(dir) unless Dir.exist?(dir)

            # Create temp file in same directory (same filesystem for atomic move)
            temp = Tempfile.new([File.basename(file_path, ".*"), File.extname(file_path)], dir)

            begin
              # Write content to temp file
              temp.write(content)
              temp.close

              # Atomic move (rename) - this is the critical operation
              # On most filesystems, rename is atomic
              FileUtils.mv(temp.path, file_path)
            ensure
              # Clean up temp file if it still exists
              temp.close
              temp.unlink if File.exist?(temp.path)
            end
          end

          # Perform validation on content
          def self.perform_validation(content, validator)
            errors = []

            # Basic validation - check content can be parsed
            result = Atoms::FrontmatterExtractor.extract(content)
            unless result[:valid]
              errors.concat(result[:errors])
            end

            # Custom validator
            if validator.is_a?(Proc)
              custom_errors = validator.call(content)
              errors.concat(custom_errors) if custom_errors.is_a?(Array)
            end

            errors
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "fileutils"

module Ace
  module PromptPrep
    module Molecules
      # Manages template file operations (copy, archive, restore)
      class TemplateManager
        class << self
          # Copy template content to target path
          #
          # @param template_path [String] Source template file path
          # @param target_path [String] Destination file path
          # @param force [Boolean] Overwrite if target exists
          # @return [Hash] Result with :success, :path, :skipped, :error keys
          def copy_template(template_path:, target_path:, force: false)
            # Check if template exists
            unless File.exist?(template_path)
              return {
                success: false,
                path: nil,
                skipped: false,
                error: "Template file not found: #{template_path}"
              }
            end

            # Check if target already exists
            if File.exist?(target_path) && !force
              return {
                success: true,
                path: target_path,
                skipped: true,
                error: nil
              }
            end

            # Create target directory if needed
            target_dir = File.dirname(target_path)
            FileUtils.mkdir_p(target_dir) unless Dir.exist?(target_dir)

            # Copy template content
            template_content = File.read(template_path, encoding: "utf-8")
            File.write(target_path, template_content, encoding: "utf-8")

            {
              success: true,
              path: target_path,
              skipped: false,
              error: nil
            }
          rescue => e
            {
              success: false,
              path: nil,
              skipped: false,
              error: "Failed to copy template: #{e.message}"
            }
          end

          # Archive existing file with timestamp
          #
          # @param source_path [String] File to archive
          # @param archive_dir [String] Archive directory path
          # @return [Hash] Result with :success, :archive_path, :skipped, :error keys
          def archive_file(source_path:, archive_dir:)
            # Check if source exists
            unless File.exist?(source_path)
              return {
                success: true,
                archive_path: nil,
                skipped: true,
                error: nil
              }
            end

            # Create archive directory
            FileUtils.mkdir_p(archive_dir) unless Dir.exist?(archive_dir)

            # Generate archive filename with timestamp
            timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
            basename = File.basename(source_path, ".*")
            ext = File.extname(source_path)
            archive_filename = "#{basename}-#{timestamp}#{ext}"
            archive_path = File.join(archive_dir, archive_filename)

            # Copy to archive
            FileUtils.cp(source_path, archive_path)

            {
              success: true,
              archive_path: archive_path,
              skipped: false,
              error: nil
            }
          rescue => e
            {
              success: false,
              archive_path: nil,
              skipped: false,
              error: "Failed to archive file: #{e.message}"
            }
          end

          # Restore template to target path (archive current if exists)
          #
          # @param template_path [String] Source template file path
          # @param target_path [String] Destination file path
          # @param archive_dir [String] Archive directory path
          # @param force [Boolean] Skip archiving if true
          # @return [Hash] Result with :success, :path, :archive_path, :error keys
          def restore_template(template_path:, target_path:, archive_dir:, force: false)
            # Archive current file unless force
            archive_result = if force || !File.exist?(target_path)
              {success: true, archive_path: nil, skipped: true}
            else
              archive_file(source_path: target_path, archive_dir: archive_dir)
            end

            unless archive_result[:success]
              return {
                success: false,
                path: nil,
                archive_path: nil,
                error: archive_result[:error]
              }
            end

            # Copy template (force overwrite since we archived)
            copy_result = copy_template(
              template_path: template_path,
              target_path: target_path,
              force: true
            )

            unless copy_result[:success]
              return {
                success: false,
                path: nil,
                archive_path: archive_result[:archive_path],
                error: copy_result[:error]
              }
            end

            {
              success: true,
              path: copy_result[:path],
              archive_path: archive_result[:archive_path],
              error: nil
            }
          rescue => e
            {
              success: false,
              path: nil,
              archive_path: nil,
              error: "Failed to restore template: #{e.message}"
            }
          end
        end
      end
    end
  end
end

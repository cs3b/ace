# frozen_string_literal: true

require "fileutils"

module Ace
  module Taskflow
    module Molecules
      class AttachmentManager
        # Copy files to attachment directory and generate markdown references
        # @param file_paths [Array<String>] Array of file paths to copy
        # @param dest_dir [String] Destination directory for attachments
        # @return [Hash] Result with :success, :copied_files, :failed_files, :references
        def self.copy_files(file_paths, dest_dir)
          FileUtils.mkdir_p(dest_dir)

          copied_files = []
          failed_files = []

          file_paths.each do |file_path|
            begin
              if File.exist?(file_path) && File.file?(file_path)
                filename = File.basename(file_path)
                dest_path = File.join(dest_dir, filename)
                FileUtils.cp(file_path, dest_path)
                copied_files << filename
              else
                failed_files << { path: file_path, error: "File not found or not a regular file" }
              end
            rescue Errno::EACCES => e
              failed_files << { path: file_path, error: "Permission denied: #{e.message}" }
            rescue StandardError => e
              failed_files << { path: file_path, error: e.message }
            end
          end

          {
            success: failed_files.empty?,
            copied_files: copied_files,
            failed_files: failed_files,
            references: format_references(copied_files)
          }
        end

        # Save clipboard attachments (images, RTF, HTML, files) to directory
        # @param attachments [Array<Hash>] Array of attachment hashes from clipboard
        # @param dest_dir [String] Destination directory for attachments
        # @return [Hash] Result with :success, :saved_files, :failed_files, :references
        def self.save_attachments(attachments, dest_dir)
          FileUtils.mkdir_p(dest_dir)

          saved_files = []
          failed_files = []

          attachments.each do |att|
            begin
              case att[:type]
              when :image
                # Save image data
                filename = att[:filename]
                dest_path = File.join(dest_dir, filename)
                File.write(dest_path, att[:data], mode: "wb")
                saved_files << filename

              when :file
                # Copy file from source
                filename = att[:filename]
                dest_path = File.join(dest_dir, filename)
                FileUtils.cp(att[:source_path], dest_path)
                saved_files << filename

              when :rtf, :html
                # Save rich text data
                filename = att[:filename]
                dest_path = File.join(dest_dir, filename)
                File.write(dest_path, att[:data], mode: "wb")
                saved_files << filename
              end
            rescue StandardError => e
              failed_files << { filename: att[:filename], error: e.message }
            end
          end

          {
            success: failed_files.empty?,
            saved_files: saved_files,
            failed_files: failed_files,
            references: format_references(saved_files)
          }
        end

        # Format file references as markdown
        # @param filenames [Array<String>] Array of filenames
        # @return [String] Markdown-formatted file references
        def self.format_references(filenames)
          return "" if filenames.empty?

          references = filenames.map { |filename| "- [#{filename}](./#{filename})" }
          "\n\n## Attached Files\n\n#{references.join("\n")}"
        end
      end
    end
  end
end

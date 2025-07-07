# frozen_string_literal: true

require "pathname"
require "fileutils"

module CodingAgentTools
  module Molecules
    module TaskManagement
      # FileSynchronizer is a molecule that handles secure file synchronization
      # operations with validation, dry-run support, and diff preview capabilities.
      class FileSynchronizer
        # Synchronization result structure
        SyncResult = Struct.new(:status, :updated_content, :error_message, :diff_preview) do
          def success?
            status == :updated || status == :up_to_date
          end

          def updated?
            status == :updated
          end

          def up_to_date?
            status == :up_to_date
          end

          def error?
            status == :error
          end
        end

        # Sync operation statistics
        SyncStats = Struct.new(:files_processed, :documents_synchronized, :documents_up_to_date, :errors) do
          def initialize
            super(0, 0, 0, 0)
          end

          def total_documents
            documents_synchronized + documents_up_to_date
          end
        end

        # @param path_validator [SecurePathValidator] Path security validator
        # @param dry_run [Boolean] Whether to run in dry-run mode
        def initialize(path_validator: nil, dry_run: false)
          @path_validator = path_validator || create_path_validator
          @dry_run = dry_run
          @stats = SyncStats.new
        end

        # Synchronize a document from workflow content to its target file
        # @param workflow_content [String] The complete workflow file content
        # @param document [ParsedDocument] Document to synchronize
        # @param workflow_file_path [String] Path to the workflow file
        # @return [SyncResult] Result of the synchronization operation
        def synchronize_document(workflow_content, document, workflow_file_path)
          @stats.files_processed += 1

          # Validate document path
          validation_result = validate_document_path(document)
          if validation_result[:error]
            @stats.errors += 1
            return SyncResult.new(:error, nil, validation_result[:error], nil)
          end

          # Read target file
          target_content_result = read_target_file(document.path)
          if target_content_result[:error]
            @stats.errors += 1
            return SyncResult.new(:error, nil, target_content_result[:error], nil)
          end

          target_content = target_content_result[:content]

          # Compare content
          if content_differs?(document.content, target_content)
            result = handle_content_difference(workflow_content, document, target_content, workflow_file_path)
            @stats.documents_synchronized += 1 if result.updated?
            result
          else
            @stats.documents_up_to_date += 1
            SyncResult.new(:up_to_date, nil, nil, nil)
          end
        end

        # Update embedded document content in workflow file
        # @param workflow_content [String] Complete workflow content
        # @param document [ParsedDocument] Document with new content
        # @param new_content [String] New content to embed
        # @return [String] Updated workflow content
        def update_embedded_document(workflow_content, document, new_content)
          escaped_path = Regexp.escape(document.path)

          case document.source_format
          when :documents
            update_documents_format(workflow_content, document, new_content, escaped_path)
          when :templates
            update_templates_format(workflow_content, document, new_content, escaped_path)
          else
            raise "Unknown source format: #{document.source_format}"
          end
        end

        # Generate diff preview between embedded and file content
        # @param embedded_content [String] Content in the workflow file
        # @param file_content [String] Content in the target file
        # @param document_path [String] Path to the document
        # @return [String] Formatted diff preview
        def generate_diff_preview(embedded_content, file_content, document_path)
          lines = ["📋 WOULD UPDATE: #{document_path}", "", "Differences found:"]

          embedded_lines = embedded_content.split("\n")
          file_lines = file_content.split("\n")
          max_lines = [embedded_lines.length, file_lines.length].max

          (0...max_lines).each do |i|
            old_line = embedded_lines[i] || ""
            new_line = file_lines[i] || ""

            if old_line != new_line
              lines << "- Line #{i + 1}: [OLD] #{old_line}"
              lines << "+ Line #{i + 1}: [NEW] #{new_line}"
            end
          end

          lines.join("\n")
        end

        # Get synchronization statistics
        # @return [SyncStats] Current statistics
        def stats
          @stats.dup
        end

        # Reset statistics
        def reset_stats
          @stats = SyncStats.new
        end

        private

        attr_reader :path_validator, :dry_run

        def validate_document_path(document)
          # Use SecurePathValidator for path validation
          validation_result = path_validator.validate_path(document.path)
          
          if validation_result.invalid?
            return {error: "Security validation failed: #{validation_result.error_message}"}
          end

          # Additional document-type specific validation
          case document.type
          when :template
            unless document.path.start_with?("dev-handbook/templates/") && document.path.end_with?(".template.md")
              return {error: "Invalid template path: #{document.path} (must be in dev-handbook/templates/ and end with .template.md)"}
            end
          when :guide
            unless document.path.start_with?("dev-handbook/guides/") && document.path.end_with?(".g.md")
              return {error: "Invalid guide path: #{document.path} (must be in dev-handbook/guides/ and end with .g.md)"}
            end
          else
            return {error: "Unknown document type: #{document.type}"}
          end

          {error: nil}
        end

        def read_target_file(file_path)
          begin
            content = File.read(file_path)
            {content: content, error: nil}
          rescue Errno::ENOENT
            {content: nil, error: "Target file not found: #{file_path}"}
          rescue => e
            {content: nil, error: "Failed to read target file #{file_path}: #{e.message}"}
          end
        end

        def content_differs?(embedded_content, file_content)
          normalize_content(embedded_content) != normalize_content(file_content)
        end

        def normalize_content(content)
          # Remove leading/trailing whitespace and normalize line endings
          content.strip.gsub("\r\n", "\n")
        end

        def handle_content_difference(workflow_content, document, target_content, workflow_file_path)
          if dry_run
            diff_preview = generate_diff_preview(document.content, target_content, document.path)
            SyncResult.new(:updated, nil, nil, diff_preview)
          else
            # Update the embedded content (no confirmation needed for template sync)
            updated_content = update_embedded_document(workflow_content, document, target_content)
            SyncResult.new(:updated, updated_content, nil, nil)
          end
        end

        def update_documents_format(workflow_content, document, new_content, escaped_path)
          case document.type
          when :template
            pattern = /(<documents>.*?<template\s+path="#{escaped_path}">)(.*?)(<\/template>.*?<\/documents>)/m
            workflow_content.gsub(pattern) { "#{$1}#{new_content}#{$3}" }
          when :guide
            pattern = /(<documents>.*?<guide\s+path="#{escaped_path}">)(.*?)(<\/guide>.*?<\/documents>)/m
            workflow_content.gsub(pattern) { "#{$1}#{new_content}#{$3}" }
          else
            raise "Unsupported document type for documents format: #{document.type}"
          end
        end

        def update_templates_format(workflow_content, document, new_content, escaped_path)
          # Legacy templates format only supports template type
          unless document.type == :template
            raise "Legacy templates format only supports template type, got: #{document.type}"
          end

          pattern = /(<template\s+path="#{escaped_path}">)(.*?)(<\/template>)/m
          workflow_content.gsub(pattern) { "#{$1}#{new_content}#{$3}" }
        end

        def create_path_validator
          CodingAgentTools::Molecules::SecurePathValidator.new
        end
      end
    end
  end
end
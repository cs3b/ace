# frozen_string_literal: true

module Ace
  module Support
    module Markdown
      module Organisms
        # Main API for document editing with fluent interface
        # Provides safe editing with state management and validation
        class DocumentEditor
          attr_reader :document, :file_path, :original_content

          # Create a new DocumentEditor
          # @param file_path [String] Path to the markdown file
          def initialize(file_path)
            raise ArgumentError, "File path cannot be nil" if file_path.nil?
            raise FileOperationError, "File not found: #{file_path}" unless File.exist?(file_path)

            @file_path = file_path
            @original_content = File.read(file_path)
            @document = Models::MarkdownDocument.parse(@original_content, file_path: file_path)
            @backup_path = nil
          end

          # Update frontmatter fields
          # @param updates [Hash] Fields to update
          # @return [DocumentEditor] self for chaining
          def update_frontmatter(updates)
            @document = Molecules::FrontmatterEditor.update(@document, updates)
            self
          end

          # Update a single frontmatter field
          # @param key [String] The field key
          # @param value [Object] The field value
          # @return [DocumentEditor] self for chaining
          def set_field(key, value)
            @document = Molecules::FrontmatterEditor.update_field(@document, key, value)
            self
          end

          # Replace a section's content
          # @param heading [String] The section heading
          # @param new_content [String] The new content
          # @return [DocumentEditor] self for chaining
          def replace_section(heading, new_content)
            @document = Molecules::SectionEditor.replace_section(@document, heading, new_content)
            self
          end

          # Append to a section
          # @param heading [String] The section heading
          # @param content [String] Content to append
          # @return [DocumentEditor] self for chaining
          def append_to_section(heading, content)
            @document = Molecules::SectionEditor.append_to_section(@document, heading, content)
            self
          end

          # Delete a section
          # @param heading [String] The section heading
          # @return [DocumentEditor] self for chaining
          def delete_section(heading)
            @document = Molecules::SectionEditor.delete_section(@document, heading)
            self
          end

          # Add a new section
          # @param heading [String] The section heading
          # @param content [String] The section content
          # @param level [Integer] The heading level (default: 2)
          # @return [DocumentEditor] self for chaining
          def add_section(heading, content, level: 2)
            section = Models::Section.new(heading: heading, content: content, level: level)
            @document = Molecules::SectionEditor.add_section(@document, section)
            self
          end

          # Validate the current document state
          # @param rules [Hash] Optional validation rules
          # @return [Hash] Result with :valid, :errors, :warnings
          def validate(rules: {})
            content = @document.to_markdown
            Atoms::DocumentValidator.validate(content, rules: rules)
          end

          # Check if document is valid
          # @param rules [Hash] Optional validation rules
          # @return [Boolean]
          def valid?(rules: {})
            validate(rules: rules)[:valid]
          end

          # Save the document to file
          # @param backup [Boolean] Create backup before writing (default: true)
          # @param validate_before [Boolean] Validate before writing (default: true)
          # @param rules [Hash] Optional validation rules
          # @return [Hash] Result with :success, :backup_path, :errors
          def save!(backup: true, validate_before: true, rules: {})
            # Validate before save
            if validate_before
              validation = validate(rules: rules)
              unless validation[:valid]
                return {
                  success: false,
                  backup_path: nil,
                  errors: validation[:errors]
                }
              end
            end

            # Generate new content
            new_content = @document.to_markdown

            # Use SafeFileWriter for atomic write with backup
            result = SafeFileWriter.write(
              @file_path,
              new_content,
              backup: backup
            )

            if result[:success]
              @backup_path = result[:backup_path]
              @original_content = new_content
            end

            result
          end

          # Rollback to original content
          # @return [Hash] Result with :success, :errors
          def rollback
            if @backup_path && File.exist?(@backup_path)
              begin
                File.write(@file_path, File.read(@backup_path))
                File.delete(@backup_path)
                @backup_path = nil

                # Reload document
                @document = Models::MarkdownDocument.parse(@original_content, file_path: @file_path)

                {success: true, errors: []}
              rescue => e
                {success: false, errors: ["Rollback failed: #{e.message}"]}
              end
            else
              {success: false, errors: ["No backup available for rollback"]}
            end
          end

          # Get current document content as string
          # @return [String]
          def to_markdown
            @document.to_markdown
          end

          # Check if document has been modified
          # @return [Boolean]
          def modified?
            @document.to_markdown != @original_content
          end

          # Get document statistics
          # @return [Hash]
          def stats
            @document.stats
          end

          # Create a DocumentEditor from content string
          # @param content [String] The markdown content
          # @param file_path [String, nil] Optional file path for context
          # @return [DocumentEditor]
          def self.from_content(content, file_path: nil)
            # Create a temporary file if needed
            if file_path.nil?
              require "tempfile"
              temp = Tempfile.new(["markdown", ".md"])
              temp.write(content)
              temp.close
              file_path = temp.path
            else
              File.write(file_path, content)
            end

            new(file_path)
          end
        end
      end
    end
  end
end

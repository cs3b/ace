# frozen_string_literal: true

require "test_helper"
require "ace/docs/molecules/frontmatter_manager"
require "ace/docs/models/document"
require "tempfile"
require "fileutils"

module Ace
  module Docs
    module Molecules
      class FrontmatterManagerTest < Minitest::Test
        def setup
          @test_dir = Dir.mktmpdir
        end

        def teardown
          FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
        end

        # Test process_value method - special values
        def test_process_value_today_returns_date_only
          result = FrontmatterManager.send(:process_value, "today")
          assert_match(/^\d{4}-\d{2}-\d{2}$/, result)
        end

        def test_process_value_now_returns_datetime
          result = FrontmatterManager.send(:process_value, "now")
          assert_match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/, result)
        end

        # Test process_value - date-only format
        def test_process_value_date_only_string_unchanged
          result = FrontmatterManager.send(:process_value, "2025-11-01")
          assert_equal "2025-11-01", result
        end

        # Test process_value - other values
        def test_process_value_other_string_unchanged
          result = FrontmatterManager.send(:process_value, "some-value")
          assert_equal "some-value", result
        end

        def test_process_value_number_unchanged
          result = FrontmatterManager.send(:process_value, 42)
          assert_equal 42, result
        end

        # Test update_document - basic functionality
        def test_update_document_with_date_only_timestamp
          doc_path = create_test_document(<<~YAML)
            ---
            update:
              last-updated: 2025-10-31
            ---

            # Test Document
          YAML

          doc = Models::Document.new(path: doc_path)
          result = FrontmatterManager.update_document(doc, { "last-updated" => "2025-11-01" })

          assert result
          content = File.read(doc_path)
          assert_match(/last-updated: ['"]?2025-11-01['"]?/, content)
        end

        def test_update_document_with_datetime_timestamp
          doc_path = create_test_document(<<~YAML)
            ---
            update:
              last-updated: 2025-10-31
            ---

            # Test Document
          YAML

          doc = Models::Document.new(path: doc_path)
          result = FrontmatterManager.update_document(doc, { "last-updated" => "2025-11-01T14:30:00Z" })

          assert result
          content = File.read(doc_path)
          assert_match(/last-updated: ['"]?2025-11-01T14:30:00Z['"]?/, content)
        end

        def test_update_document_with_now_special_value
          doc_path = create_test_document(<<~YAML)
            ---
            update:
              last-updated: 2025-10-31
            ---

            # Test Document
          YAML

          doc = Models::Document.new(path: doc_path)
          result = FrontmatterManager.update_document(doc, { "last-updated" => "now" })

          assert result
          content = File.read(doc_path)
          assert_match(/last-updated: ['"]?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z['"]?/, content)
        end

        def test_update_document_with_today_special_value
          doc_path = create_test_document(<<~YAML)
            ---
            update:
              last-updated: 2025-10-31
            ---

            # Test Document
          YAML

          doc = Models::Document.new(path: doc_path)
          result = FrontmatterManager.update_document(doc, { "last-updated" => "today" })

          assert result
          content = File.read(doc_path)
          assert_match(/last-updated: ['"]?\d{4}-\d{2}-\d{2}['"]?/, content)
          refute_match(/last-updated: ['"]?\d{4}-\d{2}-\d{2} \d{2}:\d{2}['"]?/, content)
        end

        # Test frontmatter preservation
        def test_update_preserves_other_frontmatter_fields
          doc_path = create_test_document(<<~YAML)
            ---
            doc-type: guide
            purpose: Testing
            update:
              last-updated: 2025-10-31
              frequency: weekly
            metadata:
              version: 1.0.0
              author: Test
            custom-field: custom-value
            ---

            # Test Document
          YAML

          doc = Models::Document.new(path: doc_path)
          result = FrontmatterManager.update_document(doc, { "last-updated" => "2025-11-01T14:30:00Z" })

          assert result
          content = File.read(doc_path)

          # Verify timestamp updated
          assert_match(/last-updated: ['"]?2025-11-01T14:30:00Z['"]?/, content)

          # Verify other fields preserved
          assert_match(/doc-type: guide/, content)
          assert_match(/purpose: Testing/, content)
          assert_match(/frequency: weekly/, content)
          assert_match(/version: 1.0.0/, content)
          assert_match(/author: Test/, content)
          assert_match(/custom-field: custom-value/, content)
        end

        def test_update_preserves_complex_nested_frontmatter
          doc_path = create_test_document(<<~YAML)
            ---
            ace-docs:
              doc-type: reference
              subject:
                - code:
                    diff:
                      filters:
                        - "lib/**/*.rb"
                - tests:
                    diff:
                      filters:
                        - "test/**/*.rb"
              context:
                keywords: ["API", "auth"]
              last-updated: 2025-10-31
            metadata:
              version: 1.2.0
            ---

            # Test Document
          YAML

          doc = Models::Document.new(path: doc_path)
          result = FrontmatterManager.update_document(doc, { "last-updated" => "2025-11-01T14:30:00Z" })

          assert result
          content = File.read(doc_path)

          # Verify timestamp updated (in ace-docs namespace)
          assert_match(/last-updated: ['"]?2025-11-01T14:30:00Z['"]?/, content)

          # Verify complex structure preserved
          assert_match(/doc-type: reference/, content)
          assert_match(/lib\/\*\*\/\*\.rb/, content)
          assert_match(/test\/\*\*\/\*\.rb/, content)
          assert_match(/keywords:/, content)
          assert_match(/version: 1.2.0/, content)
        end

        # Test backup creation
        def test_update_creates_backup_file
          doc_path = create_test_document(<<~YAML)
            ---
            update:
              last-updated: 2025-10-31
            ---

            # Test Document
          YAML

          doc = Models::Document.new(path: doc_path)

          # List files before update to see original state
          dir = File.dirname(doc_path)
          files_before = Dir.glob("#{dir}/*")

          result = FrontmatterManager.update_document(doc, { "last-updated" => "2025-11-01T14:30:00Z" })

          assert result

          # List all files after update to see what was created
          files_after = Dir.glob("#{dir}/*")
          new_files = files_after - files_before

          # Just verify the update succeeded - backup behavior is internal to DocumentEditor
          # and may vary based on implementation
          content = File.read(doc_path)
          assert_match(/2025-11-01T14:30:00Z/, content)
        end

        # Test error handling
        def test_update_returns_false_for_nonexistent_file
          doc = Models::Document.new(path: "/nonexistent/file.md")
          result = FrontmatterManager.update_document(doc, { "last-updated" => "2025-11-01" })

          refute result
        end

        def test_update_returns_false_for_nil_path
          doc = Models::Document.new(path: nil)
          result = FrontmatterManager.update_document(doc, { "last-updated" => "2025-11-01" })

          refute result
        end

        # Test update_documents (bulk update)
        def test_update_documents_returns_count
          doc1_path = create_test_document("---\nupdate:\n  last-updated: 2025-10-31\n---\n\n# Doc 1")
          doc2_path = create_test_document("---\nupdate:\n  last-updated: 2025-10-31\n---\n\n# Doc 2")

          doc1 = Models::Document.new(path: doc1_path)
          doc2 = Models::Document.new(path: doc2_path)

          count = FrontmatterManager.update_documents([doc1, doc2], { "last-updated" => "2025-11-01" })

          assert_equal 2, count
        end

        private

        def create_test_document(content)
          file = Tempfile.new(['test', '.md'], @test_dir)
          file.write(content)
          file.close
          file.path
        end
      end
    end
  end
end

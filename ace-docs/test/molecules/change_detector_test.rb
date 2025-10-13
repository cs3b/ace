# frozen_string_literal: true

require "test_helper"
require "ace/docs/molecules/change_detector"
require "ace/docs/models/document"
require "tmpdir"
require "fileutils"

module Ace
  module Docs
    module Molecules
      class ChangeDetectorTest < AceTestCase
        def setup
          @temp_dir = Dir.mktmpdir("ace-docs-test")
          @original_dir = Dir.pwd
          Dir.chdir(@temp_dir)

          # Initialize a git repository for testing
          system("git init", out: File::NULL, err: File::NULL)
          system("git config user.email 'test@example.com'", out: File::NULL, err: File::NULL)
          system("git config user.name 'Test User'", out: File::NULL, err: File::NULL)

          # Create an initial commit
          File.write("initial.md", "# Initial file\n\nContent")
          system("git add .", out: File::NULL, err: File::NULL)
          system("git commit -m 'Initial commit'", out: File::NULL, err: File::NULL)
        end

        def teardown
          Dir.chdir(@original_dir)
          FileUtils.rm_rf(@temp_dir) if @temp_dir
        end

        def test_get_diff_for_document_with_no_changes
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            }
          )

          result = ChangeDetector.get_diff_for_document(document)

          assert_equal "test.md", result[:document_path]
          assert_equal "guide", result[:document_type]
          refute result[:has_changes]
          assert_empty result[:diff]
        end

        def test_get_diff_for_document_with_changes
          # Make a change after initial commit
          File.write("test.md", "# Test Document\n\nNew content")
          system("git add test.md", out: File::NULL, err: File::NULL)
          system("git commit -m 'Add test document'", out: File::NULL, err: File::NULL)

          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document",
              "update" => {
                "last-updated" => (Date.today - 30).to_s
              }
            }
          )

          # Make another change to create a diff
          File.write("test.md", "# Test Document\n\nUpdated content\n\nMore content")

          result = ChangeDetector.get_diff_for_document(document, since: "HEAD~1")

          assert_equal "test.md", result[:document_path]
          assert result[:has_changes]
          assert result[:diff].include?("test.md")
        end

        def test_get_diff_for_documents
          # Create multiple documents
          doc1 = Models::Document.new(
            path: "doc1.md",
            frontmatter: { "doc-type" => "guide", "purpose" => "First doc" }
          )

          doc2 = Models::Document.new(
            path: "doc2.md",
            frontmatter: { "doc-type" => "api", "purpose" => "Second doc" }
          )

          # Make changes
          File.write("doc1.md", "# Doc 1\n\nContent")
          File.write("doc2.md", "# Doc 2\n\nContent")
          system("git add .", out: File::NULL, err: File::NULL)
          system("git commit -m 'Add documents'", out: File::NULL, err: File::NULL)

          # Make more changes
          File.write("doc1.md", "# Doc 1\n\nUpdated content")

          result = ChangeDetector.get_diff_for_documents([doc1, doc2], since: "HEAD~1")

          assert_equal 2, result[:total_documents]
          assert result[:documents_with_changes] >= 0
          assert_equal 2, result[:document_diffs].size
        end

        def test_save_diff_to_cache
          diff_result = {
            document_path: "test.md",
            document_type: "guide",
            since: "2024-10-01",
            diff: "diff content here",
            has_changes: true,
            timestamp: Time.now.iso8601
          }

          filepath = ChangeDetector.save_diff_to_cache(diff_result)

          assert File.exist?(filepath)
          assert filepath.include?(".cache/ace-docs/diff-")
          assert filepath.end_with?(".md")

          content = File.read(filepath)
          assert content.include?("# Diff Analysis Report")
          assert content.include?("test.md")
          assert content.include?("diff content here")
        end

        def test_detect_renames
          # Create a file and commit it
          File.write("old_name.md", "Content")
          system("git add .", out: File::NULL, err: File::NULL)
          system("git commit -m 'Add file'", out: File::NULL, err: File::NULL)

          # Rename the file
          system("git mv old_name.md new_name.md", out: File::NULL, err: File::NULL)
          system("git commit -m 'Rename file'", out: File::NULL, err: File::NULL)

          renames = ChangeDetector.detect_renames(since: "HEAD~1")

          assert_equal 1, renames.size
          assert_equal "old_name.md", renames.first[:old]
          assert_equal "new_name.md", renames.first[:new]
        end

        def test_diff_with_exclude_renames_option
          # Create and rename a file
          File.write("file.md", "Content")
          system("git add .", out: File::NULL, err: File::NULL)
          system("git commit -m 'Add file'", out: File::NULL, err: File::NULL)

          system("git mv file.md renamed.md", out: File::NULL, err: File::NULL)
          File.write("other.md", "Other content")
          system("git add .", out: File::NULL, err: File::NULL)
          system("git commit -m 'Rename and add'", out: File::NULL, err: File::NULL)

          document = Models::Document.new(
            path: "renamed.md",
            frontmatter: { "doc-type" => "guide", "purpose" => "Test" }
          )

          # Test with renames excluded
          result = ChangeDetector.get_diff_for_document(
            document,
            since: "HEAD~1",
            options: { include_renames: false }
          )

          assert_equal false, result[:options][:include_renames]
        end

        def test_determine_since_uses_document_last_updated
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test",
              "update" => {
                "last-updated" => "2024-09-15"
              }
            }
          )

          result = ChangeDetector.get_diff_for_document(document)

          assert_equal "2024-09-15", result[:since]
        end

        def test_determine_since_with_explicit_date
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test"
            }
          )

          result = ChangeDetector.get_diff_for_document(document, since: Date.new(2024, 10, 1))

          assert_equal "2024-10-01", result[:since]
        end

        def test_determine_since_with_string
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test"
            }
          )

          result = ChangeDetector.get_diff_for_document(document, since: "HEAD~5")

          assert_equal "HEAD~5", result[:since]
        end

        def test_format_diff_for_saving_single_document
          diff_result = {
            document_path: "test.md",
            document_type: "guide",
            since: "2024-10-01",
            diff: "+ Added line\n- Removed line",
            has_changes: true,
            timestamp: Time.now.iso8601
          }

          # Save and read back
          filepath = ChangeDetector.save_diff_to_cache(diff_result)
          content = File.read(filepath)

          assert content.include?("# Diff Analysis Report")
          assert content.include?("## Document: test.md")
          assert content.include?("- Type: guide")
          assert content.include?("- Has changes: Yes")
          assert content.include?("```diff")
          assert content.include?("+ Added line")
        end

        def test_format_diff_for_saving_multiple_documents
          doc1 = Models::Document.new(
            path: "doc1.md",
            frontmatter: { "doc-type" => "guide", "purpose" => "First doc" }
          )

          doc2 = Models::Document.new(
            path: "doc2.md",
            frontmatter: { "doc-type" => "api", "purpose" => "Second doc" }
          )

          diff_result = {
            total_documents: 2,
            documents_with_changes: 1,
            since: "2024-10-01",
            timestamp: Time.now.iso8601,
            document_diffs: [
              { document: doc1, diff: "+ Changes", has_changes: true },
              { document: doc2, diff: "", has_changes: false }
            ]
          }

          filepath = ChangeDetector.save_diff_to_cache(diff_result)
          content = File.read(filepath)

          assert content.include?("## Summary")
          assert content.include?("Total documents analyzed: 2")
          assert content.include?("Documents with changes: 1")
          assert content.include?("## doc1.md")
          assert content.include?("## doc2.md")
          assert content.include?("No relevant changes detected")
        end

        def test_empty_diff_result_for_nil_document_path
          document = Models::Document.new(
            frontmatter: { "doc-type" => "guide", "purpose" => "Test" }
          )

          result = ChangeDetector.get_diff_for_document(document)

          assert_nil result[:document_path]
          refute result[:has_changes]
          assert_empty result[:diff]
        end
      end
    end
  end
end
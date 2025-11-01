# frozen_string_literal: true

require "test_helper"
require "ace/docs/molecules/change_detector"
require "ace/docs/models/document"
require "ace/git_diff"
require "tmpdir"
require "fileutils"

module Ace
  module Docs
    module Molecules
      class ChangeDetectorTest < AceTestCase
        # No setup/teardown needed - we mock git operations

        def test_get_diff_for_document_with_no_changes
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            }
          )

          # Mock ace-git-diff to return empty diff (no changes)
          empty_result = Ace::GitDiff::Models::DiffResult.empty
          Ace::GitDiff::Organisms::DiffOrchestrator.stub :generate, empty_result do
            result = ChangeDetector.get_diff_for_document(document)

            assert_equal "test.md", result[:document_path]
            assert_equal "guide", result[:document_type]
            refute result[:has_changes]
            assert_empty result[:diff]
          end
        end

        def test_get_diff_for_document_with_changes
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

          # Mock ace-git-diff to return a diff showing changes
          mock_diff = "diff --git a/test.md b/test.md\n+Updated content\n+More content"
          mock_result = Ace::GitDiff::Models::DiffResult.new(
            content: mock_diff,
            stats: { additions: 2, deletions: 0, files: 1, total_changes: 2, line_count: 3 },
            files: ["test.md"]
          )
          Ace::GitDiff::Organisms::DiffOrchestrator.stub :generate, mock_result do
            result = ChangeDetector.get_diff_for_document(document, since: "HEAD~1")

            assert_equal "test.md", result[:document_path]
            assert result[:has_changes]
            assert result[:diff].include?("test.md")
          end
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

          # Mock git to return diffs for both documents
          mock_diff = "diff --git a/doc1.md b/doc1.md\n+Updated content"
          ChangeDetector.stub :execute_git_command, mock_diff do
            result = ChangeDetector.get_diff_for_documents([doc1, doc2], since: "HEAD~1")

            assert_equal 2, result[:total_documents]
            assert result[:documents_with_changes] >= 0
            assert_equal 2, result[:document_diffs].size
          end
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
          # Mock git to return rename information
          mock_rename_output = "R100\told_name.md\tnew_name.md\n"
          ChangeDetector.stub :execute_git_command, mock_rename_output do
            renames = ChangeDetector.detect_renames(since: "HEAD~1")

            assert_equal 1, renames.size
            assert_equal "old_name.md", renames.first[:old]
            assert_equal "new_name.md", renames.first[:new]
          end
        end

        def test_diff_with_exclude_renames_option
          document = Models::Document.new(
            path: "renamed.md",
            frontmatter: { "doc-type" => "guide", "purpose" => "Test" }
          )

          # Mock git to return empty diff
          ChangeDetector.stub :execute_git_command, "" do
            # Test with renames excluded
            result = ChangeDetector.get_diff_for_document(
              document,
              since: "HEAD~1",
              options: { include_renames: false }
            )

            assert_equal false, result[:options][:include_renames]
          end
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

          # Mock git to avoid real git operations
          ChangeDetector.stub :execute_git_command, "" do
            result = ChangeDetector.get_diff_for_document(document)

            assert_equal "2024-09-15", result[:since]
          end
        end

        def test_determine_since_with_explicit_date
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test"
            }
          )

          # Mock git to avoid real git operations
          ChangeDetector.stub :execute_git_command, "" do
            result = ChangeDetector.get_diff_for_document(document, since: Date.new(2024, 10, 1))

            assert_equal "2024-10-01", result[:since]
          end
        end

        def test_determine_since_with_string
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test"
            }
          )

          # Mock git to avoid real git operations
          ChangeDetector.stub :execute_git_command, "" do
            result = ChangeDetector.get_diff_for_document(document, since: "HEAD~5")

            assert_equal "HEAD~5", result[:since]
          end
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

        def test_get_diff_for_document_multi_subject
          # Create a document with multi-subject configuration
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "reference",
              "purpose" => "Test multi-subject",
              "ace-docs" => {
                "subject" => [
                  {
                    "code" => {
                      "diff" => {
                        "filters" => ["**/*.rb"]
                      }
                    }
                  },
                  {
                    "docs" => {
                      "diff" => {
                        "filters" => ["**/*.md"]
                      }
                    }
                  }
                ]
              }
            }
          )

          # Mock git to return empty diffs for both subjects
          ChangeDetector.stub :execute_git_command, "" do
            result = ChangeDetector.get_diff_for_document(document)

            assert_equal "test.md", result[:document_path]
            assert result[:multi_subject], "Should be marked as multi-subject"
            assert_kind_of Hash, result[:diffs], "Diffs should be a hash for multi-subject"
            assert result[:diffs].key?("code"), "Should have code subject diff"
            assert result[:diffs].key?("docs"), "Should have docs subject diff"
          end
        end

        def test_get_diff_for_document_multi_subject_with_changes
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "reference",
              "purpose" => "Test",
              "ace-docs" => {
                "subject" => [
                  {
                    "code" => {
                      "diff" => {
                        "filters" => ["lib/**/*.rb"]
                      }
                    }
                  },
                  {
                    "docs" => {
                      "diff" => {
                        "filters" => ["**/*.md"]
                      }
                    }
                  }
                ]
              }
            }
          )

          # Mock ace-git-diff to return different diffs based on paths
          code_diff = "diff --git a/lib/test.rb b/lib/test.rb\n+  def hello\n+  end"
          docs_diff = "diff --git a/README.md b/README.md\n+Updated docs"

          call_count = 0
          Ace::GitDiff::Organisms::DiffOrchestrator.stub :generate, ->(options) {
            call_count += 1
            if call_count == 1 || (options[:paths] && options[:paths].include?("lib/**/*.rb"))
              Ace::GitDiff::Models::DiffResult.new(
                content: code_diff,
                stats: { additions: 2, deletions: 0, files: 1, total_changes: 2, line_count: 3 },
                files: ["lib/test.rb"]
              )
            elsif call_count == 2 || (options[:paths] && options[:paths].include?("**/*.md"))
              Ace::GitDiff::Models::DiffResult.new(
                content: docs_diff,
                stats: { additions: 1, deletions: 0, files: 1, total_changes: 1, line_count: 2 },
                files: ["README.md"]
              )
            else
              Ace::GitDiff::Models::DiffResult.empty
            end
          } do
            result = ChangeDetector.get_diff_for_document(document)

            assert result[:has_changes]
            assert result[:multi_subject]

            # Check code diff contains ruby changes
            assert result[:diffs]["code"].include?("lib/test.rb"), "Code diff should include ruby file"
            assert result[:diffs]["code"].include?("def hello"), "Code diff should show method addition"

            # Check docs diff contains markdown changes
            assert result[:diffs]["docs"].include?("README.md"), "Docs diff should include markdown file"
            assert result[:diffs]["docs"].include?("Updated docs"), "Docs diff should show content change"
          end
        end

        def test_get_diffs_for_subjects
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "reference",
              "purpose" => "Test",
              "ace-docs" => {
                "subject" => [
                  { "code" => { "diff" => { "filters" => ["**/*.rb"] } } },
                  { "config" => { "diff" => { "filters" => ["**/*.yml"] } } }
                ]
              }
            }
          )

          # Mock ace-git-diff to return different diffs based on file paths
          call_count = 0
          Ace::GitDiff::Organisms::DiffOrchestrator.stub :generate, ->(options) {
            call_count += 1
            if call_count == 1 || (options[:paths] && options[:paths].include?("**/*.rb"))
              Ace::GitDiff::Models::DiffResult.new(
                content: "diff --git a/app.rb b/app.rb\n+modified app",
                stats: { additions: 1, deletions: 0, files: 1, total_changes: 1, line_count: 2 },
                files: ["app.rb"]
              )
            elsif call_count == 2 || (options[:paths] && options[:paths].include?("**/*.yml"))
              Ace::GitDiff::Models::DiffResult.new(
                content: "diff --git a/config.yml b/config.yml\n+new_value",
                stats: { additions: 1, deletions: 0, files: 1, total_changes: 1, line_count: 2 },
                files: ["config.yml"]
              )
            else
              Ace::GitDiff::Models::DiffResult.empty
            end
          } do
            diffs = ChangeDetector.get_diffs_for_subjects(document, "HEAD", {})

            assert_equal 2, diffs.keys.length
            assert diffs.key?("code")
            assert diffs.key?("config")

            assert diffs["code"].include?("app.rb")
            assert diffs["code"].include?("modified app")

            assert diffs["config"].include?("config.yml")
            assert diffs["config"].include?("new_value")
          end
        end

        def test_save_diff_to_cache_multi_subject
          # This test checks the save_diff_to_cache method which takes a single hash argument
          # For multi-subject diffs, the result hash has :diffs (plural) instead of :diff
          diff_result = {
            document_path: "test.md",
            document_type: "reference",
            since: "2024-10-01",
            diffs: {
              "code" => "diff --git a/test.rb b/test.rb\n+puts 'hello'",
              "docs" => "diff --git a/README.md b/README.md\n+# Title"
            },
            multi_subject: true,
            has_changes: true,
            timestamp: Time.now.iso8601
          }

          filepath = ChangeDetector.save_diff_to_cache(diff_result)

          # The method returns a single file path to the analysis.md report
          assert File.exist?(filepath)
          assert filepath.include?(".cache/ace-docs/diff-")
          assert filepath.end_with?("analysis.md")

          # Verify the content includes information about both subjects
          content = File.read(filepath)
          assert content.include?("test.md")
        end

        def test_backward_compat_single_subject
          # Test that single subject still works as before
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test",
              "ace-docs" => {
                "subject" => {
                  "diff" => {
                    "filters" => ["**/*.rb", "**/*.md"]
                  }
                }
              }
            }
          )

          # Mock git to return diff with test.rb changes
          mock_diff = "diff --git a/test.rb b/test.rb\n+puts 'test'"
          ChangeDetector.stub :generate_git_diff, mock_diff do
            result = ChangeDetector.get_diff_for_document(document)

            refute result[:multi_subject], "Should not be multi-subject"
            assert_kind_of String, result[:diff], "Diff should be a string for single subject"
            assert result[:has_changes]
            assert result[:diff].include?("test.rb")
          end
        end
      end
    end
  end
end
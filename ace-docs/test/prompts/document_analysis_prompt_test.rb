# frozen_string_literal: true

require "test_helper"
require "ace/docs/prompts/document_analysis_prompt"
require "ace/docs/models/document"
require "tmpdir"
require "fileutils"

module Ace
  module Docs
    module Prompts
      class DocumentAnalysisPromptTest < AceTestCase
        def setup
          @temp_dir = Dir.mktmpdir("ace-docs-prompt-test")
          @session_dir = File.join(@temp_dir, "session")
          FileUtils.mkdir_p(@session_dir)

          @document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "reference",
              "purpose" => "Test document",
              "ace-docs" => {
                "context" => {
                  "files" => ["README.md", "CHANGELOG.md"]
                }
              }
            }
          )
        end

        def teardown
          FileUtils.rm_rf(@temp_dir) if @temp_dir
        end

        def test_build_prompt_multi_subject_diff_hash
          # Test handling of hash input with multiple subjects
          diffs = {
            "code" => "diff --git a/lib/test.rb b/lib/test.rb\n+class Test\nend",
            "config" => "diff --git a/config.yml b/config.yml\n+key: value",
            "docs" => "diff --git a/README.md b/README.md\n+# Title"
          }

          result = DocumentAnalysisPrompt.build(
            @document,
            diffs,
            since: "2025-10-01",
            cache_dir: @session_dir
          )

          assert result[:user]
          assert result[:system]

          # Verify all diffs were saved
          diff_files = Dir[File.join(@session_dir, "*.diff")]
          assert_equal 3, diff_files.length

          assert diff_files.any? { |f| f.end_with?("code.diff") }
          assert diff_files.any? { |f| f.end_with?("config.diff") }
          assert diff_files.any? { |f| f.end_with?("docs.diff") }
        end

        def test_build_prompt_multi_subject_saves_multiple_diff_files
          # Test that each subject gets its own .diff file
          diffs = {
            "code" => "diff for code",
            "docs" => "diff for docs"
          }

          DocumentAnalysisPrompt.build(@document, diffs, since: "2025-10-01", cache_dir: @session_dir)

          # Check files were created with correct content
          code_diff_path = File.join(@session_dir, "code.diff")
          docs_diff_path = File.join(@session_dir, "docs.diff")

          assert File.exist?(code_diff_path)
          assert File.exist?(docs_diff_path)

          assert_equal "diff for code", File.read(code_diff_path).strip
          assert_equal "diff for docs", File.read(docs_diff_path).strip
        end

        def test_build_prompt_single_subject_backward_compat
          # Test that string input still works (backward compatibility)
          diff = "diff --git a/test.rb b/test.rb\n+puts 'hello'"

          result = DocumentAnalysisPrompt.build(@document, diff, since: "2025-10-01", cache_dir: @session_dir)

          assert result[:user]
          assert result[:system]

          # Should save as repo-diff.diff for backward compatibility
          repo_diff_path = File.join(@session_dir, "repo-diff.diff")
          assert File.exist?(repo_diff_path)
          assert_equal diff, File.read(repo_diff_path).strip
        end

        def test_create_context_markdown_multi_subject_scope
          # Test that context shows multiple subject filters
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

          diffs = {
            "code" => "code changes",
            "config" => "config changes"
          }

          # Build the prompt which creates the context.md file
          DocumentAnalysisPrompt.build(document, diffs, since: "2025-10-01", cache_dir: @session_dir)

          # Read the generated context.md file
          context_path = File.join(@session_dir, "context.md")
          assert File.exist?(context_path), "Context file should be created"

          context = File.read(context_path)


          # Should include multiple subjects in analysis scope
          assert context.include?("`code`:"), "Should list code subject"
          assert context.include?("`config`:"), "Should list config subject"
          assert context.include?("**/*.rb"), "Should show code filters"
          assert context.include?("**/*.yml"), "Should show config filters"
        end

        def test_build_prompt_filters_empty_diffs
          # Test that empty subject diffs are handled properly
          diffs = {
            "code" => "diff --git a/test.rb b/test.rb\n+content",
            "docs" => "",  # Empty diff
            "config" => "  \n  "  # Whitespace-only diff
          }

          DocumentAnalysisPrompt.build(@document, diffs, since: "2025-10-01", cache_dir: @session_dir)

          diff_files = Dir[File.join(@session_dir, "*.diff")]

          # Only non-empty diffs should be saved (implementation skips empty)
          assert diff_files.any? { |f| f.end_with?("code.diff") }, "Should save code diff"

          # Verify code diff has content
          code_content = File.read(File.join(@session_dir, "code.diff"))
          assert code_content.include?("content")

          # Empty diffs should be skipped (not saved)
          refute diff_files.any? { |f| f.end_with?("docs.diff") }, "Should skip empty docs diff"
          refute diff_files.any? { |f| f.end_with?("config.diff") }, "Should skip whitespace-only config diff"
        end

        def test_build_prompt_with_context_files
          # Test that context markdown is generated
          result = DocumentAnalysisPrompt.build(
            @document,
            "test diff",
            since: "2025-10-01",
            cache_dir: @session_dir
          )

          # Check context.md was created
          context_path = File.join(@session_dir, "context.md")
          assert File.exist?(context_path)

          # Verify it contains analysis instructions
          context_content = File.read(context_path)
          assert context_content.include?("Change Analysis Instructions"), "Should include instructions"
          assert context_content.include?("Analysis Scope"), "Should include scope section"
        end

        def test_prompt_selection_for_multi_subject
          # Test that multi-subject documents get appropriate prompts
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "reference",
              "purpose" => "Test",
              "ace-docs" => {
                "subject" => [
                  { "code" => { "diff" => { "filters" => ["**/*.rb"] } } },
                  { "docs" => { "diff" => { "filters" => ["**/*.md"] } } }
                ]
              }
            }
          )

          diffs = {
            "code" => "code changes",
            "docs" => "doc changes"
          }

          result = DocumentAnalysisPrompt.build(document, diffs, since: "2025-10-01", cache_dir: @session_dir)

          # Should use appropriate prompts for multi-subject analysis
          assert result[:system]
          assert result[:user]

          # Context should reflect multi-subject nature
          context_path = File.join(@session_dir, "context.md")
          context = File.read(context_path)
          assert context.include?("`code`:"), "Should list code subject"
          assert context.include?("`docs`:"), "Should list docs subject"
        end
      end
    end
  end
end
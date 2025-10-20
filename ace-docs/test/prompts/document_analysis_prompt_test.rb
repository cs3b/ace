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

          prompt = DocumentAnalysisPrompt.new(@document)
          result = prompt.build(
            diffs,
            "2025-10-01",
            @session_dir,
            []
          )

          assert result[:user_prompt]
          assert result[:system_prompt]
          assert_equal @session_dir, result[:session_dir]

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

          prompt = DocumentAnalysisPrompt.new(@document)
          prompt.build(diffs, "2025-10-01", @session_dir, [])

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

          prompt = DocumentAnalysisPrompt.new(@document)
          result = prompt.build(diff, "2025-10-01", @session_dir, [])

          assert result[:user_prompt]
          assert result[:system_prompt]

          # Should save as repo-diff.diff for backward compatibility
          repo_diff_path = File.join(@session_dir, "repo-diff.diff")
          assert File.exist?(repo_diff_path)
          assert_equal diff, File.read(repo_diff_path).strip
        end

        def test_create_context_markdown_multi_subject_scope
          # Test that context shows multiple subject filters
          @document.instance_variable_set(:@frontmatter, {
            "doc-type" => "reference",
            "purpose" => "Test",
            "ace-docs" => {
              "subject" => [
                { "code" => { "diff" => { "filters" => ["**/*.rb"] } } },
                { "config" => { "diff" => { "filters" => ["**/*.yml"] } } }
              ]
            }
          })

          prompt = DocumentAnalysisPrompt.new(@document)

          # Create dummy diff files
          FileUtils.touch(File.join(@session_dir, "code.diff"))
          FileUtils.touch(File.join(@session_dir, "config.diff"))

          context = prompt.send(:create_context_markdown, @session_dir, [])

          # Should include multiple subjects in analysis scope
          assert context.include?("code:"), "Should list code subject"
          assert context.include?("config:"), "Should list config subject"
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

          prompt = DocumentAnalysisPrompt.new(@document)
          prompt.build(diffs, "2025-10-01", @session_dir, [])

          diff_files = Dir[File.join(@session_dir, "*.diff")]

          # Should save all files even if empty (for transparency)
          assert diff_files.any? { |f| f.end_with?("code.diff") }
          assert diff_files.any? { |f| f.end_with?("docs.diff") }
          assert diff_files.any? { |f| f.end_with?("config.diff") }

          # Verify code diff has content
          code_content = File.read(File.join(@session_dir, "code.diff"))
          assert code_content.include?("content")

          # Empty diffs should be saved as empty or whitespace
          docs_content = File.read(File.join(@session_dir, "docs.diff"))
          assert docs_content.strip.empty?
        end

        def test_build_prompt_with_context_files
          # Test that context files are properly included
          context_files = [
            "/path/to/README.md",
            "/path/to/CHANGELOG.md"
          ]

          prompt = DocumentAnalysisPrompt.new(@document)
          result = prompt.build(
            "test diff",
            "2025-10-01",
            @session_dir,
            context_files
          )

          # Check context.md includes the files
          context_path = File.join(@session_dir, "context.md")
          assert File.exist?(context_path)

          context_content = File.read(context_path)
          assert context_content.include?("README.md")
          assert context_content.include?("CHANGELOG.md")
        end

        def test_prompt_selection_for_multi_subject
          # Test that multi-subject documents get appropriate prompts
          @document.instance_variable_set(:@frontmatter, {
            "doc-type" => "reference",
            "purpose" => "Test",
            "ace-docs" => {
              "subject" => [
                { "code" => { "diff" => { "filters" => ["**/*.rb"] } } },
                { "docs" => { "diff" => { "filters" => ["**/*.md"] } } }
              ]
            }
          })

          diffs = {
            "code" => "code changes",
            "docs" => "doc changes"
          }

          prompt = DocumentAnalysisPrompt.new(@document)
          result = prompt.build(diffs, "2025-10-01", @session_dir, [])

          # Should use appropriate prompts for multi-subject analysis
          assert result[:system_prompt]
          assert result[:user_prompt]

          # Context should reflect multi-subject nature
          context_path = File.join(@session_dir, "context.md")
          context = File.read(context_path)
          assert context.include?("code:")
          assert context.include?("docs:")
        end
      end
    end
  end
end
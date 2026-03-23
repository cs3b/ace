# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/docs/cli/commands/update"
require "ace/docs/models/document"
require "ace/docs/molecules/frontmatter_manager"
require "ace/docs/organisms/document_registry"
require "tmpdir"
require "fileutils"

module Ace
  module Docs
    module CLI
      module Commands
        class UpdateTest < Minitest::Test
          def setup
            @command = Update.new
          end

          def test_infer_doc_type_readme
            result = @command.send(:infer_doc_type, "/path/to/README.md")
            assert_equal "readme", result
          end

          def test_infer_doc_type_workflow
            result = @command.send(:infer_doc_type, "/path/to/deploy.wf.md")
            assert_equal "workflow", result
          end

          def test_infer_doc_type_guide
            result = @command.send(:infer_doc_type, "/path/to/setup.g.md")
            assert_equal "guide", result
          end

          def test_infer_doc_type_template
            result = @command.send(:infer_doc_type, "/path/to/task.template.md")
            assert_equal "template", result
          end

          def test_infer_doc_type_docs_context
            result = @command.send(:infer_doc_type, "docs/architecture.md")
            assert_equal "context", result
          end

          def test_infer_doc_type_fallback
            result = @command.send(:infer_doc_type, "/random/file.md")
            assert_equal "reference", result
          end

          def test_call_with_help_returns_zero
            result = @command.call(file: "--help")
            assert_equal 0, result
          end

          def test_execute_update_no_file_or_preset_raises
            # Mock registry to return empty
            mock_registry = Minitest::Mock.new
            mock_registry.expect(:all, [])

            Ace::Docs::Organisms::DocumentRegistry.stub :new, mock_registry do
              # Should raise because no file or preset specified
              capture_io do
                @command.send(:execute_update, nil, {})
                # The error is raised in select_documents
              end
            end
          rescue RuntimeError => e
            assert_match(/Please specify a file or --preset/, e.message)
          end

          def test_execute_update_with_empty_documents
            # When no documents match, returns 0
            mock_registry = Minitest::Mock.new
            mock_registry.expect(:all, [])
            mock_registry.expect(:select, []) { |*_args| true }

            Ace::Docs::Organisms::DocumentRegistry.stub :new, mock_registry do
              output = capture_io do
                result = @command.send(:execute_update, nil, {preset: "nonexistent"})
                assert_equal 0, result
              end.first

              assert_match(/No documents to update/, output)
            end
          end

          def test_select_documents_with_scope_only
            temp_dir = Dir.mktmpdir("ace-docs-update-scope")

            FileUtils.mkdir_p(File.join(temp_dir, "docs"))
            FileUtils.mkdir_p(File.join(temp_dir, "other"))

            File.write(File.join(temp_dir, "docs", "guide.md"), <<~MARKDOWN)
              ---
              doc-type: guide
              purpose: scoped guide
              ---

              # Guide
            MARKDOWN

            File.write(File.join(temp_dir, "other", "note.md"), <<~MARKDOWN)
              ---
              doc-type: guide
              purpose: outside scope
              ---

              # Note
            MARKDOWN

            docs = @command.send(:select_documents, nil, {glob: ["docs/**/*.md"], project_root: temp_dir})
            assert_equal 1, docs.size
            assert_match(%r{/docs/guide\.md$}, docs.first.path)
          ensure
            FileUtils.rm_rf(temp_dir) if temp_dir
          end

          def test_update_documents_skips_frontmatter_free_paths
            doc = Ace::Docs::Models::Document.new(
              path: "/tmp/example/README.md",
              frontmatter: {"doc-type" => "user", "purpose" => "README"},
              content: "# README"
            )

            Ace::Docs.stub :config, {"frontmatter_free" => ["**/README.md"]} do
              output, = capture_io do
                updated = @command.send(:update_documents, [doc], {set: {"last-updated" => "today"}})
                assert_equal 0, updated
              end

              assert_match(/Skipped: .*README\.md/, output)
            end
          end
        end
      end
    end
  end
end

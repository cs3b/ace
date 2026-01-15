# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/docs/cli/commands/update"
require "ace/docs/molecules/frontmatter_manager"
require "ace/docs/organisms/document_registry"

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
            assert_equal "reference", result
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
              output = capture_io do
                result = @command.send(:execute_update, nil, {})
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
                result = @command.send(:execute_update, nil, { preset: "nonexistent" })
                assert_equal 0, result
              end.first

              assert_match(/No documents to update/, output)
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"
require "ace/docs/cli/commands/discover"
require "ace/docs/organisms/document_registry"
require "ace/docs/models/document"

module Ace
  module Docs
    module CLI
      module Commands
        class DiscoverTest < Minitest::Test
          def setup
            @command = Discover.new
          end

          def test_call_with_no_documents
            mock_registry = Minitest::Mock.new
            mock_registry.expect(:all, [])

            output = capture_io do
              Ace::Docs::Organisms::DocumentRegistry.stub :new, mock_registry do
                result = @command.call
                assert_equal 0, result
              end
            end.first

            assert_match(/No managed documents found/, output)
          end

          def test_call_with_documents
            mock_doc1 = create_mock_document("docs/guide.md", "guide")
            mock_doc2 = create_mock_document("README.md", "reference")

            mock_registry = Minitest::Mock.new
            mock_registry.expect(:all, [mock_doc1, mock_doc2])

            output = capture_io do
              Ace::Docs::Organisms::DocumentRegistry.stub :new, mock_registry do
                result = @command.call
                assert_equal 0, result
              end
            end.first

            assert_match(/Found 2 managed documents/, output)
            assert_match(/docs\/guide\.md.*guide/, output)
            assert_match(/README\.md.*reference/, output)
          end

          def test_call_handles_error
            mock_registry = Object.new
            def mock_registry.all
              raise StandardError, "Registry error"
            end

            output = capture_io do
              Ace::Docs::Organisms::DocumentRegistry.stub :new, mock_registry do
                result = @command.call
                assert_equal 1, result
              end
            end

            stderr = output.last
            assert_match(/Error discovering documents/, stderr)
          end

          private

          def create_mock_document(path, doc_type)
            mock = Object.new
            mock.define_singleton_method(:relative_path) { path }
            mock.define_singleton_method(:path) { path }
            mock.define_singleton_method(:doc_type) { doc_type }
            mock
          end
        end
      end
    end
  end
end

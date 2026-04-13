# frozen_string_literal: true

require "test_helper"
require "ace/docs/cli/commands/validate"
require "ace/docs/organisms/document_registry"

module Ace
  module Docs
    module CLI
      module Commands
        class ValidateTest < Minitest::Test
          def setup
            @command = Validate.new
          end

          def test_call_with_help_returns_zero
            result = @command.call(pattern: "--help")
            assert_equal 0, result
          end

          def test_select_documents_with_existing_file
            mock_doc = Minitest::Mock.new
            mock_registry = Minitest::Mock.new
            mock_registry.expect(:find_by_path, mock_doc, ["/path/to/file.md"])

            Ace::Docs::Organisms::DocumentRegistry.stub :new, mock_registry do
              File.stub :exist?, true, ["/path/to/file.md"] do
                result = @command.send(:select_documents, mock_registry, "/path/to/file.md")
                assert_equal [mock_doc], result
              end
            end
          end

          def test_select_documents_with_no_match
            # When file doesn't exist, code treats pattern as glob and calls registry.all
            # then filters by fnmatch - with no matches, returns empty array
            mock_doc = Object.new
            mock_doc.define_singleton_method(:path) { "some/other/file.md" }
            mock_doc.define_singleton_method(:relative_path) { "some/other/file.md" }

            mock_registry = Object.new
            mock_registry.define_singleton_method(:all) { [mock_doc] }

            File.stub :exist?, false, ["/nonexistent.md"] do
              result = @command.send(:select_documents, mock_registry, "/nonexistent.md")
              assert_equal [], result
            end
          end

          def test_select_documents_with_pattern
            mock_doc1 = Minitest::Mock.new
            mock_doc1.expect(:path, "docs/guide1.md")
            mock_doc1.expect(:relative_path, "docs/guide1.md")
            mock_doc2 = Minitest::Mock.new
            mock_doc2.expect(:path, "docs/guide2.md")
            mock_doc2.expect(:relative_path, "docs/guide2.md")
            mock_doc3 = Minitest::Mock.new
            mock_doc3.expect(:path, "src/code.rb")
            mock_doc3.expect(:relative_path, "src/code.rb")

            mock_registry = Minitest::Mock.new
            mock_registry.expect(:all, [mock_doc1, mock_doc2, mock_doc3])

            # Pattern docs/*.md should match guide1.md and guide2.md
            File.stub :exist?, false, ["docs/*.md"] do
              result = @command.send(:select_documents, mock_registry, "docs/*.md")
              assert_equal 2, result.size
            end
          end

          def test_select_documents_with_pattern_uses_relative_path
            doc = Object.new
            doc.define_singleton_method(:path) { "/tmp/project/docs/guide.md" }
            doc.define_singleton_method(:relative_path) { "docs/guide.md" }

            mock_registry = Object.new
            mock_registry.define_singleton_method(:all) { [doc] }

            File.stub :exist?, false, ["docs/*.md"] do
              result = @command.send(:select_documents, mock_registry, "docs/*.md")
              assert_equal 1, result.size
            end
          end

          def test_parse_lint_errors_extracts_errors
            stdout = "line 1: error - missing header\nline 5: ERROR - invalid syntax\nline 10: warning - style issue"
            stderr = ""

            errors = @command.send(:parse_lint_errors, stdout, stderr)
            assert_equal 2, errors.size
            assert errors.any? { |e| e.include?("missing header") }
            assert errors.any? { |e| e.include?("invalid syntax") }
          end

          def test_parse_lint_errors_includes_stderr
            stdout = ""
            stderr = "Fatal error occurred"

            errors = @command.send(:parse_lint_errors, stdout, stderr)
            assert_equal 1, errors.size
            assert_equal "Fatal error occurred", errors.first
          end

          def test_parse_lint_warnings_extracts_warnings
            stdout = "line 1: warning - style issue\nline 5: WARNING - consider using X\nline 10: error - fatal"

            warnings = @command.send(:parse_lint_warnings, stdout)
            assert_equal 2, warnings.size
            assert warnings.all? { |w| w.include?("warning") || w.include?("WARNING") }
          end
        end
      end
    end
  end
end

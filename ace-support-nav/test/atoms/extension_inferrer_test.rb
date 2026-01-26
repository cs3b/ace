# frozen_string_literal: true

require "test_helper"
require "ace/support/nav/atoms/extension_inferrer"

module Ace
  module Support
    module Nav
      module Atoms
        class ExtensionInferrerTest < Minitest::Test
          def test_infer_extensions_returns_pattern_when_disabled
            pattern = "test-file"
            result = ExtensionInferrer.infer_extensions(pattern, enabled: false)

            assert_equal 1, result.length
            assert_equal pattern, result[0]
          end

          def test_infer_extensions_returns_pattern_when_empty
            result = ExtensionInferrer.infer_extensions("")

            assert_equal 1, result.length
            assert_equal "", result[0]
          end

          def test_infer_extensions_with_shorthand_first
            pattern = "markdown-style"
            protocol_extensions = [".g.md", ".guide.md"]

            result = ExtensionInferrer.infer_extensions(pattern, protocol_extensions: protocol_extensions)

            # Should include shorthand extensions first
            assert_includes result, "markdown-style.g"
            assert_includes result, "markdown-style.guide"
            # Then full extensions
            assert_includes result, "markdown-style.g.md"
            assert_includes result, "markdown-style.guide.md"
            # Then generic markdown
            assert_includes result, "markdown-style.md"
            # Finally bare
            assert_includes result, "markdown-style"
          end

          def test_infer_extensions_with_wfi_protocol
            pattern = "setup"
            protocol_extensions = [".wf.md", ".wfi.md", ".workflow.md"]

            result = ExtensionInferrer.infer_extensions(pattern, protocol_extensions: protocol_extensions)

            # Should include shorthand extensions
            assert_includes result, "setup.wf"
            assert_includes result, "setup.wfi"
            assert_includes result, "setup.workflow"
            # Full extensions
            assert_includes result, "setup.wf.md"
            assert_includes result, "setup.wfi.md"
            assert_includes result, "setup.workflow.md"
            # Generic markdown
            assert_includes result, "setup.md"
            # Bare
            assert_includes result, "setup"
          end

          def test_infer_extensions_with_custom_fallback_order
            pattern = "test"
            protocol_extensions = [".t.md", ".test.md"]

            result = ExtensionInferrer.infer_extensions(
              pattern,
              protocol_extensions: protocol_extensions,
              fallback_order: %w[bare generic_markdown protocol_full]
            )

            # Bare should be first
            assert_equal "test", result[0]
            # Then generic markdown
            assert_equal "test.md", result[1]
            # Then full extensions
            assert_includes result, "test.t.md"
            assert_includes result, "test.test.md"
          end

          def test_infer_extensions_with_nil_fallback_order
            pattern = "test"
            protocol_extensions = [".t.md"]

            # Should not crash with nil fallback_order - uses default
            result = ExtensionInferrer.infer_extensions(
              pattern,
              protocol_extensions: protocol_extensions,
              fallback_order: nil
            )

            # Should use default fallback order
            assert_includes result, "test.t"        # protocol_shorthand
            assert_includes result, "test.t.md"     # protocol_full
            assert_includes result, "test.md"       # generic_markdown
            assert_includes result, "test"          # bare
          end

          def test_infer_extensions_no_duplicates
            pattern = "doc"
            protocol_extensions = [".md"]

            result = ExtensionInferrer.infer_extensions(pattern, protocol_extensions: protocol_extensions)

            # Count occurrences of each candidate
            counts = result.tally
            assert counts.values.all? { |v| v == 1 }, "Found duplicate candidates: #{counts.select { |_, v| v > 1 }}"
          end

          def test_has_extension_with_matching_extension
            pattern = "file.g.md"
            extensions = [".g.md", ".guide.md"]

            assert ExtensionInferrer.has_extension?(pattern, extensions)
          end

          def test_has_extension_with_no_matching_extension
            pattern = "file.txt"
            extensions = [".g.md", ".guide.md"]

            refute ExtensionInferrer.has_extension?(pattern, extensions)
          end

          def test_has_extension_with_empty_pattern
            refute ExtensionInferrer.has_extension?("", [".md"])
          end

          def test_has_extension_with_empty_extensions
            refute ExtensionInferrer.has_extension?("file.md", [])
          end

          def test_extract_shorthand_extensions
            protocol_extensions = [".g.md", ".guide.md", ".wf.md", ".workflow.md"]

            result = ExtensionInferrer.extract_shorthand_extensions(protocol_extensions)

            assert_includes result, ".g"
            assert_includes result, ".guide"
            assert_includes result, ".wf"
            assert_includes result, ".workflow"
            assert_equal 4, result.length
          end

          def test_extract_shorthand_extensions_with_empty_array
            result = ExtensionInferrer.extract_shorthand_extensions([])

            assert_equal 0, result.length
          end

          def test_extract_shorthand_extensions_no_duplicates
            protocol_extensions = [".g.md", ".g.md", ".guide.md"]

            result = ExtensionInferrer.extract_shorthand_extensions(protocol_extensions)

            # Should not have duplicates
            assert_equal 2, result.length
            assert_includes result, ".g"
            assert_includes result, ".guide"
          end

          def test_strip_extension_with_matching_extension
            pattern = "file.g.md"
            extensions = [".g.md"]

            result = ExtensionInferrer.strip_extension(pattern, extensions)

            assert_equal "file", result
          end

          def test_strip_extension_with_multiple_extensions
            pattern = "file.g.md"
            extensions = [".g.md", ".md"]

            result = ExtensionInferrer.strip_extension(pattern, extensions)

            assert_equal "file", result
          end

          def test_strip_extension_with_no_match
            pattern = "file.txt"
            extensions = [".g.md", ".md"]

            result = ExtensionInferrer.strip_extension(pattern, extensions)

            assert_equal "file.txt", result
          end

          def test_strip_extension_with_empty_extensions
            pattern = "file.g.md"

            result = ExtensionInferrer.strip_extension(pattern, [])

            assert_equal "file.g.md", result
          end

          def test_infer_extensions_with_no_protocol_extensions
            pattern = "test"

            result = ExtensionInferrer.infer_extensions(pattern, protocol_extensions: [])

            # Should still provide markdown and bare options
            assert_includes result, "test.md"
            assert_includes result, "test"
          end

          # Test backwards compatibility with instance method wrappers
          def test_instance_method_wrappers_work
            inferrer = ExtensionInferrer.new
            pattern = "test"

            result = inferrer.infer_extensions(pattern, protocol_extensions: [".t.md"])

            assert_includes result, "test.t.md"
            assert_includes result, "test"
          end
        end
      end
    end
  end
end

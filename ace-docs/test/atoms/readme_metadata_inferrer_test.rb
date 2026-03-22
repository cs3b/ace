# frozen_string_literal: true

require "test_helper"
require "ace/docs/atoms/readme_metadata_inferrer"

module Ace
  module Docs
    module Atoms
      class ReadmeMetadataInferrerTest < Minitest::Test
        def test_infer_metadata_from_readme_heading
          content = <<~MD
            # ace-docs

            content
          MD

          result = ReadmeMetadataInferrer.infer(
            path: "ace-docs/README.md",
            content: content,
            last_updated: Date.new(2026, 3, 20)
          )

          assert_equal "user", result["doc-type"]
          assert_equal "User-facing introduction for ace-docs", result["purpose"]
          assert_equal "ace-docs", result["title"]
          assert_equal({"frequency" => "on-change"}, result["update"])
          assert_equal({"last-updated" => "2026-03-20"}, result["ace-docs"])
        end

        def test_infer_falls_back_when_no_heading
          result = ReadmeMetadataInferrer.infer(path: "ace-bundle/README.md", content: "No H1")
          assert_equal "ace-bundle", result["title"]
        end

        def test_non_readme_returns_nil
          result = ReadmeMetadataInferrer.infer(path: "ace-docs/docs/usage.md", content: "# Usage")
          assert_nil result
        end
      end
    end
  end
end

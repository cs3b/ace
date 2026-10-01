# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/molecules/safe_capture"

module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          class SafeCaptureEncodingTest < Minitest::Test
            def test_scrubs_non_utf8_output_bytes_to_valid_utf8
              result = SafeCapture.call(
                ["ruby", "-e", "print \"ok \\xFF binary \\xFE done\""],
                timeout: 30,
                provider_name: "test"
              )

              assert_equal Models::CaptureResult::OUTCOME_COMPLETED, result.outcome
              assert result.stdout.valid_encoding?
              assert_includes result.stdout, "ok"
              assert_includes result.stdout, "binary"
              assert_includes result.stdout, "done"
              refute result.stdout.include?("\xFF")
            end
          end
        end
      end
    end
  end
end

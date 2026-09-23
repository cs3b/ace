# frozen_string_literal: true

require "test_helper"

module Ace
  module Hitl
    module Hermes
      module Molecules
        class HermesFormatsTest < AceHermesTestCase
          def test_decodes_v1_envelopes
            hash = HermesFormats.decode!(JSON.generate(question_payload))
            assert_equal "q-1", hash["id"]
            assert_equal "question", hash["kind"]
          end

          def test_rejects_oversize_before_parsing
            bytes = ("x" * (HermesContract::MAX_BYTES + 1))
            error = assert_raises(InvalidMessageError) { HermesFormats.decode!(bytes) }
            assert_match(/size bound/, error.message)
          end

          def test_rejects_non_utf8
            error = assert_raises(InvalidMessageError) do
              HermesFormats.decode!("\xFF\xFE\xFD".b)
            end
            assert_match(/UTF-8/, error.message)
          end

          def test_rejects_bad_json_and_non_objects
            error = assert_raises(InvalidMessageError) { HermesFormats.decode!("{nope") }
            assert_match(/not valid JSON/, error.message)

            error = assert_raises(InvalidMessageError) { HermesFormats.decode!("[1,2]") }
            assert_match(/JSON object/, error.message)
          end

          def test_rejects_unknown_or_absent_schema
            payload = question_payload
            payload["schema"] = "ace.hitl.hermes.message/v2"
            error = assert_raises(UnknownFormatError) do
              HermesFormats.decode!(JSON.generate(payload))
            end
            assert_match(/unsupported message schema/, error.message)
            assert_match(%r{ace.hitl.hermes.message/v1}, error.message)

            payload = question_payload
            payload.delete("schema")
            assert_raises(UnknownFormatError) { HermesFormats.decode!(JSON.generate(payload)) }
          end

          def test_supported_formats_pinned_to_v1
            assert_equal ["ace.hitl.hermes.message/v1"], HermesFormats.supported
          end
        end
      end
    end
  end
end

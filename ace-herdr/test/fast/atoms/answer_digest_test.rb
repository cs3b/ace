# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Atoms
      class AnswerDigestTest < Minitest::Test
        def test_produces_sha256_hex_of_content
          assert_equal Digest::SHA256.hexdigest("answer"), AnswerDigest.call("answer")
        end

        def test_output_is_64_lowercase_hex_characters
          assert_match(/\A[0-9a-f]{64}\z/, AnswerDigest.call("anything"))
        end

        def test_distinguishes_content
          refute_equal AnswerDigest.call("a"), AnswerDigest.call("b")
        end

        def test_nil_coerces_to_empty_string
          assert_equal Digest::SHA256.hexdigest(""), AnswerDigest.call(nil)
        end
      end
    end
  end
end

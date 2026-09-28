# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Assign
    class EvidenceDigestTest < AceAssignTestCase
      def test_canonical_json_sorts_keys_and_strips_whitespace
        left = Atoms::EvidenceDigest.canonical_json({ "b" => 1, "a" => { "d" => 2, "c" => 3 } })
        right = Atoms::EvidenceDigest.canonical_json({ "a" => { "c" => 3, "d" => 2 }, "b" => 1 })

        assert_equal left, right
        refute_includes left, " "
      end

      def test_digest_is_stable_and_hex
        digest = Atoms::EvidenceDigest.digest({ "attempt_id" => "abc123" })

        assert_equal 64, digest.length
        assert_match(/\A[0-9a-f]{64}\z/, digest)
        assert_equal digest, Atoms::EvidenceDigest.digest({ "attempt_id" => "abc123" })
        refute_equal digest, Atoms::EvidenceDigest.digest({ "attempt_id" => "zzz999" })
      end

      def test_digest_string_and_file_cover_raw_bytes
        path = nil
        with_temp_cache do |dir|
          path = File.join(dir, "artifact.txt")
          File.write(path, "payload-bytes")
        end

        assert_equal Atoms::EvidenceDigest.digest_string("payload-bytes"), Atoms::EvidenceDigest.digest_file(path)
        assert_equal Digest::SHA256.hexdigest("payload-bytes"), Atoms::EvidenceDigest.digest_string("payload-bytes")
      end

      def test_short_digest_is_prefix_of_full_digest
        full = Atoms::EvidenceDigest.digest({ "x" => 1 })
        assert_equal full[0, 12], Atoms::EvidenceDigest.short_digest({ "x" => 1 })
      end
    end
  end
end

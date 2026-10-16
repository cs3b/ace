# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/assign/atoms/git_blob_batch"

module Ace
  module Assign
    class GitBlobBatchTest < AceAssignTestCase
      Codec = Atoms::GitBlobBatch
      HELLO = "ce013625030ba8dba906f756967f9e9ca394464a"
      EMPTY = "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391"

      def test_sizes_require_exact_order_blob_type_count_and_canonical_numbers
        assert_equal [6, 0], Codec.sizes([HELLO, EMPTY], "#{HELLO} blob 6\n#{EMPTY} blob 0\n")
        ["#{HELLO} missing\n", "#{HELLO} tree 6\n", "#{HELLO} blob 06\n", "#{EMPTY} blob 6\n", "#{HELLO} blob 6", ""].each do |raw|
          assert_raises(Codec::Invalid) { Codec.sizes([HELLO], raw) }
        end
      end

      def test_decode_preserves_original_bytes_and_empty_objects
        raw = "#{HELLO} blob 6\nhello\n\n#{EMPTY} blob 0\n\n".b
        assert_equal ["hello\n".b, "".b], Codec.decode([[HELLO, 6], [EMPTY, 0]], raw)
        assert_equal [], Codec.decode([], "")
        assert_equal [], Codec.sizes([], "")
      end

      def test_decode_refuses_missing_truncated_corrupt_reordered_and_extra_bodies
        valid = "#{HELLO} blob 6\nhello\n\n".b
        [valid.delete_suffix("\n"), valid.sub("hello", "other"), valid + "trailing", valid.sub(HELLO, EMPTY),
          "#{HELLO} missing\n", valid.sub("blob 6", "blob 5"), ""].each do |raw|
          assert_raises(Codec::Invalid) { Codec.decode([[HELLO, 6]], raw) }
        end
      end

      def test_selector_cannot_inject_commands_types_or_unbounded_size_tokens
        [[["HEAD", 6]], [[HELLO, -1]], [[HELLO, "6"]], [[HELLO + "\n", 6]]].each do |entries|
          assert_raises(Codec::Invalid) { Codec.decode(entries, "") }
        end
        assert_raises(Codec::Invalid) { Codec.sizes(["HEAD"], "") }
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Atoms
        class DeepMergerTest < TestCase
          def test_merge_simple_hashes
            base = {"a" => 1, "b" => 2}
            other = {"b" => 3, "c" => 4}

            result = DeepMerger.merge(base, other)

            assert_equal({"a" => 1, "b" => 3, "c" => 4}, result)
          end

          def test_merge_nested_hashes
            base = {"a" => {"x" => 1, "y" => 2}}
            other = {"a" => {"y" => 3, "z" => 4}}

            result = DeepMerger.merge(base, other)

            assert_equal({"a" => {"x" => 1, "y" => 3, "z" => 4}}, result)
          end

          def test_merge_with_nil_base
            other = {"a" => 1}

            result = DeepMerger.merge(nil, other)

            assert_equal({"a" => 1}, result)
          end

          def test_merge_with_nil_other
            base = {"a" => 1}

            result = DeepMerger.merge(base, nil)

            assert_equal({"a" => 1}, result)
          end

          def test_merge_arrays_replace_strategy
            base = {"arr" => [1, 2]}
            other = {"arr" => [3, 4]}

            result = DeepMerger.merge(base, other, array_strategy: :replace)

            assert_equal({"arr" => [3, 4]}, result)
          end

          def test_merge_arrays_concat_strategy
            base = {"arr" => [1, 2]}
            other = {"arr" => [3, 4]}

            result = DeepMerger.merge(base, other, array_strategy: :concat)

            assert_equal({"arr" => [1, 2, 3, 4]}, result)
          end

          def test_merge_arrays_union_strategy
            base = {"arr" => [1, 2, 3]}
            other = {"arr" => [2, 3, 4]}

            result = DeepMerger.merge(base, other, array_strategy: :union)

            assert_equal({"arr" => [1, 2, 3, 4]}, result)
          end

          def test_merge_all
            hash1 = {"a" => 1}
            hash2 = {"b" => 2}
            hash3 = {"c" => 3}

            result = DeepMerger.merge_all(hash1, hash2, hash3)

            assert_equal({"a" => 1, "b" => 2, "c" => 3}, result)
          end

          def test_mergeable
            assert DeepMerger.mergeable?({})
            assert DeepMerger.mergeable?([])
            refute DeepMerger.mergeable?("string")
            refute DeepMerger.mergeable?(123)
          end

          def test_invalid_merge_strategy_raises_error
            assert_raises(MergeStrategyError) do
              DeepMerger.merge_arrays([1], [2], :invalid)
            end
          end
        end
      end
    end
  end
end

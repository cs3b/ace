# frozen_string_literal: true

require "test_helper"
require "ace/core/atoms/deep_merger"

class DeepMergerTest < Minitest::Test
  def test_merge_simple_hashes
    base = { "a" => 1, "b" => 2 }
    other = { "b" => 3, "c" => 4 }

    result = Ace::Core::Atoms::DeepMerger.merge(base, other)

    assert_equal({ "a" => 1, "b" => 3, "c" => 4 }, result)
  end

  def test_merge_nested_hashes
    base = {
      "level1" => {
        "level2" => {
          "a" => 1,
          "b" => 2
        }
      }
    }

    other = {
      "level1" => {
        "level2" => {
          "b" => 3,
          "c" => 4
        }
      }
    }

    result = Ace::Core::Atoms::DeepMerger.merge(base, other)

    assert_equal 1, result["level1"]["level2"]["a"]
    assert_equal 3, result["level1"]["level2"]["b"]
    assert_equal 4, result["level1"]["level2"]["c"]
  end

  def test_merge_arrays_replace_strategy
    base = { "items" => [1, 2, 3] }
    other = { "items" => [4, 5] }

    result = Ace::Core::Atoms::DeepMerger.merge(base, other, array_strategy: :replace)

    assert_equal [4, 5], result["items"]
  end

  def test_merge_arrays_concat_strategy
    base = { "items" => [1, 2] }
    other = { "items" => [3, 4] }

    result = Ace::Core::Atoms::DeepMerger.merge(base, other, array_strategy: :concat)

    assert_equal [1, 2, 3, 4], result["items"]
  end

  def test_merge_arrays_union_strategy
    base = { "items" => [1, 2, 3] }
    other = { "items" => [2, 3, 4] }

    result = Ace::Core::Atoms::DeepMerger.merge(base, other, array_strategy: :union)

    assert_equal [1, 2, 3, 4], result["items"]
  end

  def test_merge_with_nil
    base = { "a" => 1 }

    assert_equal({ "a" => 1 }, Ace::Core::Atoms::DeepMerger.merge(base, nil))
    assert_equal({ "a" => 1 }, Ace::Core::Atoms::DeepMerger.merge(nil, base))
  end

  def test_merge_all
    hash1 = { "a" => 1 }
    hash2 = { "b" => 2 }
    hash3 = { "a" => 3, "c" => 4 }

    result = Ace::Core::Atoms::DeepMerger.merge_all(hash1, hash2, hash3)

    assert_equal({ "a" => 3, "b" => 2, "c" => 4 }, result)
  end

  def test_mergeable_check
    assert Ace::Core::Atoms::DeepMerger.mergeable?({})
    assert Ace::Core::Atoms::DeepMerger.mergeable?([])
    refute Ace::Core::Atoms::DeepMerger.mergeable?("string")
    refute Ace::Core::Atoms::DeepMerger.mergeable?(123)
  end
end
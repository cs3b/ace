# frozen_string_literal: true

require "test_helper"
require "ace/support/config"

class DeepMergerTest < Minitest::Test
  def test_merge_simple_hashes
    base = { "a" => 1, "b" => 2 }
    other = { "b" => 3, "c" => 4 }

    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other)

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

    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other)

    assert_equal 1, result["level1"]["level2"]["a"]
    assert_equal 3, result["level1"]["level2"]["b"]
    assert_equal 4, result["level1"]["level2"]["c"]
  end

  def test_merge_arrays_replace_strategy
    base = { "items" => [1, 2, 3] }
    other = { "items" => [4, 5] }

    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :replace)

    assert_equal [4, 5], result["items"]
  end

  def test_merge_arrays_concat_strategy
    base = { "items" => [1, 2] }
    other = { "items" => [3, 4] }

    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :concat)

    assert_equal [1, 2, 3, 4], result["items"]
  end

  def test_merge_arrays_union_strategy
    base = { "items" => [1, 2, 3] }
    other = { "items" => [2, 3, 4] }

    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :union)

    assert_equal [1, 2, 3, 4], result["items"]
  end

  def test_merge_with_nil
    base = { "a" => 1 }

    assert_equal({ "a" => 1 }, Ace::Support::Config::Atoms::DeepMerger.merge(base, nil))
    assert_equal({ "a" => 1 }, Ace::Support::Config::Atoms::DeepMerger.merge(nil, base))
  end

  def test_merge_all
    hash1 = { "a" => 1 }
    hash2 = { "b" => 2 }
    hash3 = { "a" => 3, "c" => 4 }

    result = Ace::Support::Config::Atoms::DeepMerger.merge_all(hash1, hash2, hash3)

    assert_equal({ "a" => 3, "b" => 2, "c" => 4 }, result)
  end

  def test_mergeable_check
    assert Ace::Support::Config::Atoms::DeepMerger.mergeable?({})
    assert Ace::Support::Config::Atoms::DeepMerger.mergeable?([])
    refute Ace::Support::Config::Atoms::DeepMerger.mergeable?("string")
    refute Ace::Support::Config::Atoms::DeepMerger.mergeable?(123)
  end

  # coerce_union strategy tests
  def test_coerce_union_both_arrays
    base = { "files" => ["a.rb"] }
    other = { "files" => ["b.rb"] }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "files" => ["a.rb", "b.rb"] }, result)
  end

  def test_coerce_union_base_array_other_scalar
    base = { "files" => ["a.rb"] }
    other = { "files" => "b.rb" }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "files" => ["a.rb", "b.rb"] }, result)
  end

  def test_coerce_union_base_scalar_other_array
    base = { "files" => "a.rb" }
    other = { "files" => ["b.rb", "c.rb"] }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "files" => ["a.rb", "b.rb", "c.rb"] }, result)
  end

  def test_coerce_union_both_scalars
    base = { "pr" => "123" }
    other = { "pr" => "456" }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "pr" => ["123", "456"] }, result)
  end

  def test_coerce_union_new_key_scalar
    base = { "files" => ["a.rb"] }
    other = { "pr" => "123" }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    # New scalar key should remain scalar (no existing base to coerce)
    assert_equal({ "files" => ["a.rb"], "pr" => "123" }, result)
  end

  def test_coerce_union_new_key_array
    base = { "files" => ["a.rb"] }
    other = { "diffs" => ["HEAD~3"] }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "files" => ["a.rb"], "diffs" => ["HEAD~3"] }, result)
  end

  def test_coerce_union_removes_blanks
    base = { "files" => ["a.rb", "", nil] }
    other = { "files" => ["b.rb", nil] }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "files" => ["a.rb", "b.rb"] }, result)
  end

  def test_coerce_union_deduplicates
    base = { "files" => ["a.rb", "b.rb"] }
    other = { "files" => ["b.rb", "c.rb"] }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "files" => ["a.rb", "b.rb", "c.rb"] }, result)
  end

  def test_coerce_union_nested_hashes
    base = { "context" => { "diffs" => ["HEAD~3"] } }
    other = { "context" => { "diffs" => ["HEAD"] } }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "context" => { "diffs" => ["HEAD~3", "HEAD"] } }, result)
  end

  def test_coerce_union_deeply_nested
    base = { "a" => { "b" => { "c" => ["1"] } } }
    other = { "a" => { "b" => { "c" => ["2"] } } }
    result = Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)
    assert_equal({ "a" => { "b" => { "c" => ["1", "2"] } } }, result)
  end

  def test_coerce_union_does_not_mutate_inputs
    base = { "context" => { "diffs" => ["HEAD~3"] } }
    other = { "context" => { "diffs" => ["HEAD"] } }
    base_copy = Marshal.load(Marshal.dump(base))
    other_copy = Marshal.load(Marshal.dump(other))

    Ace::Support::Config::Atoms::DeepMerger.merge(base, other, array_strategy: :coerce_union)

    assert_equal base_copy, base, "base was mutated"
    assert_equal other_copy, other, "other was mutated"
  end
end
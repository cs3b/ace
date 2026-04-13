# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/bundle/atoms/bundle_normalizer"

class BundleNormalizerTest < AceTestCase
  def setup
    @normalizer = Ace::Bundle::Atoms::BundleNormalizer
  end

  # Test Case 1: String inputs (preset names)
  def test_normalize_string_input
    result = @normalizer.normalize_config("project")

    assert_equal({"bundle" => {"presets" => ["project"]}}, result)
  end

  def test_normalize_string_input_staged
    result = @normalizer.normalize_config("staged")

    assert_equal({"bundle" => {"presets" => ["staged"]}}, result)
  end

  # Test Case 2: Hash with top-level base (no context key)
  def test_normalize_hash_with_base_no_context
    input = {"base" => "custom content", "files" => ["README.md"]}
    result = @normalizer.normalize_config(input)

    expected = {
      "bundle" => {
        "base" => "custom content",
        "files" => ["README.md"]
      }
    }
    assert_equal expected, result
  end

  def test_normalize_hash_with_symbol_base_no_context
    input = {base: "custom content", files: ["README.md"]}
    result = @normalizer.normalize_config(input)

    expected = {
      "bundle" => {
        "base" => "custom content",
        "files" => ["README.md"]
      }
    }
    assert_equal expected, result
  end

  def test_normalize_hash_with_base_and_multiple_keys
    input = {
      "base" => "custom content",
      "files" => ["README.md"],
      "commands" => ["git status"],
      "diffs" => ["HEAD~1..HEAD"]
    }
    result = @normalizer.normalize_config(input)

    expected = {
      "bundle" => {
        "base" => "custom content",
        "files" => ["README.md"],
        "commands" => ["git status"],
        "diffs" => ["HEAD~1..HEAD"]
      }
    }
    assert_equal expected, result
  end

  # Test Case 3: Hash with both base and context keys
  def test_normalize_hash_with_both_base_and_context
    input = {
      "base" => "custom content",
      "bundle" => {"presets" => ["project"]}
    }
    result = @normalizer.normalize_config(input)

    expected = {
      "bundle" => {
        "base" => "custom content",
        "presets" => ["project"]
      }
    }
    assert_equal expected, result
  end

  def test_normalize_hash_with_both_base_and_context_complex
    input = {
      "base" => "custom content",
      "bundle" => {
        "presets" => ["project"],
        "sections" => {
          "code" => {"files" => ["lib/**/*.rb"]}
        }
      },
      "other_key" => "other_value"
    }
    result = @normalizer.normalize_config(input)

    expected = {
      "bundle" => {
        "base" => "custom content",
        "presets" => ["project"],
        "sections" => {
          "code" => {"files" => ["lib/**/*.rb"]}
        }
      },
      "other_key" => "other_value"
    }
    assert_equal expected, result
  end

  # Test Case 4: Properly structured configs (should pass through unchanged)
  def test_normalize_properly_structured_config
    input = {
      "bundle" => {
        "base" => "content",
        "presets" => ["project"]
      }
    }
    result = @normalizer.normalize_config(input)

    assert_equal input, result
  end

  def test_normalize_config_without_base
    input = {
      "bundle" => {
        "presets" => ["project"],
        "files" => ["README.md"]
      }
    }
    result = @normalizer.normalize_config(input)

    assert_equal input, result
  end

  # Edge Cases
  def test_normalize_nil_input
    result = @normalizer.normalize_config(nil)

    assert_equal({}, result)
  end

  def test_normalize_empty_hash
    result = @normalizer.normalize_config({})

    assert_equal({}, result)
  end

  def test_normalize_hash_with_only_context_key
    input = {"bundle" => {}}
    result = @normalizer.normalize_config(input)

    assert_equal input, result
  end

  def test_normalize_deeply_nested_structure
    input = {
      "base" => "custom content",
      "bundle" => {
        "presets" => ["project"],
        "sections" => {
          "level1" => {
            "level2" => {
              "level3" => {
                "files" => ["deep.rb"]
              }
            }
          }
        }
      }
    }
    result = @normalizer.normalize_config(input)

    expected = {
      "bundle" => {
        "base" => "custom content",
        "presets" => ["project"],
        "sections" => {
          "level1" => {
            "level2" => {
              "level3" => {
                "files" => ["deep.rb"]
              }
            }
          }
        }
      }
    }
    assert_equal expected, result
  end

  # Mixed symbol and string keys
  def test_normalize_mixed_keys
    input = {
      :base => "content",
      "bundle" => {:presets => ["project"], "files" => ["README.md"]}
    }
    result = @normalizer.normalize_config(input)

    expected = {
      "bundle" => {
        "base" => "content",
        :presets => ["project"],
        "files" => ["README.md"]
      }
    }
    assert_equal expected, result
  end

  # Test unexpected types
  def test_normalize_number_input
    result = @normalizer.normalize_config(123)

    assert_equal({}, result)
  end

  def test_normalize_array_input
    result = @normalizer.normalize_config(["project", "staged"])

    assert_equal({}, result)
  end
end

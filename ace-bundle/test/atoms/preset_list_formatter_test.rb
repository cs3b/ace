# frozen_string_literal: true

require_relative "../test_helper"
require "ace/bundle/atoms/preset_list_formatter"

class PresetListFormatterTest < AceTestCase
  def test_format_empty_presets
    result = Ace::Bundle::Atoms::PresetListFormatter.format([])

    assert_includes result[0], "No presets found"
    assert_includes result[1], "Create markdown files"
    assert_includes result[2], "Example presets"
  end

  def test_format_single_preset
    presets = [
      {
        name: "test-preset",
        description: "A test preset",
        output: "cache",
        source_file: "/path/to/preset.md"
      }
    ]

    result = Ace::Bundle::Atoms::PresetListFormatter.format(presets)

    assert_equal "Available presets:", result[0]
    assert_includes result[1], "test-preset"
    assert_includes result[2], "A test preset"
    assert_includes result[3], "cache"
    assert_includes result[4], "/path/to/preset.md"
  end

  def test_format_multiple_presets
    presets = [
      {name: "preset-a", description: "First preset"},
      {name: "preset-b", description: "Second preset"}
    ]

    result = Ace::Bundle::Atoms::PresetListFormatter.format(presets)

    assert_equal "Available presets:", result[0]
    assert result.any? { |line| line.include?("preset-a") }
    assert result.any? { |line| line.include?("preset-b") }
  end

  def test_format_preset_without_optional_fields
    presets = [{name: "minimal"}]

    result = Ace::Bundle::Atoms::PresetListFormatter.format(presets)

    assert_equal "Available presets:", result[0]
    assert_includes result[1], "minimal"
    # Should show default output as stdio
    assert result.any? { |line| line.include?("stdio") }
  end

  def test_format_returns_array_of_strings
    presets = [{name: "test"}]

    result = Ace::Bundle::Atoms::PresetListFormatter.format(presets)

    assert_kind_of Array, result
    result.each { |line| assert_kind_of String, line }
  end

  def test_empty_message_is_helpful
    result = Ace::Bundle::Atoms::PresetListFormatter.empty_message

    assert_kind_of Array, result
    assert result.length >= 2, "Should provide meaningful help"
    assert result.any? { |line| line.include?("preset") }
  end
end

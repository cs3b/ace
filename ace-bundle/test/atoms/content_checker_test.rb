# frozen_string_literal: true

require_relative "../test_helper"
require "ace/bundle/atoms/content_checker"

class ContentCheckerTest < AceTestCase
  # has_diffs_content? tests

  def test_has_diffs_content_with_ranges_symbol_key
    assert Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({ranges: ["HEAD~1..HEAD"]})
  end

  def test_has_diffs_content_with_ranges_string_key
    assert Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({"ranges" => ["HEAD~1..HEAD"]})
  end

  def test_has_diffs_content_with_diffs_symbol_key
    assert Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({diffs: ["HEAD~1..HEAD"]})
  end

  def test_has_diffs_content_with_diffs_string_key
    assert Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({"diffs" => ["HEAD~1..HEAD"]})
  end

  def test_has_diffs_content_with_processed_diffs_array_symbol_key
    assert Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({_processed_diffs: [{output: "diff content"}]})
  end

  def test_has_diffs_content_with_processed_diffs_array_string_key
    assert Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({"_processed_diffs" => [{output: "diff content"}]})
  end

  def test_has_diffs_content_returns_false_for_empty_processed_diffs
    # Empty arrays should NOT count as having diffs content
    refute Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({_processed_diffs: []})
    refute Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({"_processed_diffs" => []})
  end

  def test_has_diffs_content_returns_false_for_empty_section
    refute Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({})
  end

  def test_has_diffs_content_returns_false_for_nil_values
    refute Ace::Bundle::Atoms::ContentChecker.has_diffs_content?({ranges: nil, diffs: nil})
  end

  # has_files_content? tests

  def test_has_files_content_with_symbol_key
    assert Ace::Bundle::Atoms::ContentChecker.has_files_content?({files: ["lib/**/*.rb"]})
  end

  def test_has_files_content_with_string_key
    assert Ace::Bundle::Atoms::ContentChecker.has_files_content?({"files" => ["lib/**/*.rb"]})
  end

  def test_has_files_content_returns_false_for_empty_section
    refute Ace::Bundle::Atoms::ContentChecker.has_files_content?({})
  end

  # has_commands_content? tests

  def test_has_commands_content_with_symbol_key
    assert Ace::Bundle::Atoms::ContentChecker.has_commands_content?({commands: ["git status"]})
  end

  def test_has_commands_content_with_string_key
    assert Ace::Bundle::Atoms::ContentChecker.has_commands_content?({"commands" => ["git status"]})
  end

  def test_has_commands_content_returns_false_for_empty_section
    refute Ace::Bundle::Atoms::ContentChecker.has_commands_content?({})
  end

  # has_content_content? tests

  def test_has_content_content_with_symbol_key
    assert Ace::Bundle::Atoms::ContentChecker.has_content_content?({content: "Some inline content"})
  end

  def test_has_content_content_with_string_key
    assert Ace::Bundle::Atoms::ContentChecker.has_content_content?({"content" => "Some inline content"})
  end

  def test_has_content_content_returns_false_for_empty_section
    refute Ace::Bundle::Atoms::ContentChecker.has_content_content?({})
  end
end

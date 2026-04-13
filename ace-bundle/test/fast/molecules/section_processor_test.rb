# frozen_string_literal: true

require_relative "../../test_helper"

class SectionProcessorTest < AceTestCase
  def setup
    super
    @processor = Ace::Bundle::Molecules::SectionProcessor.new
  end

  # Test merge_section_data concatenates _processed_diffs arrays
  def test_merge_section_data_concatenates_processed_diffs
    existing_section = {
      "title" => "Test Section",
      :_processed_diffs => ["diff content 1"]
    }

    new_section = {
      _processed_diffs: ["diff content 2", "diff content 3"]
    }

    merged = @processor.send(:merge_section_data, existing_section, new_section)

    # Should concatenate the arrays
    assert_equal 3, merged[:_processed_diffs].length
    assert_equal ["diff content 1", "diff content 2", "diff content 3"], merged[:_processed_diffs]

    # Should not have string key version
    refute merged.key?("_processed_diffs"), "Should only use symbol key for _processed_diffs"
  end

  def test_merge_section_data_handles_empty_processed_diffs
    existing_section = {
      "title" => "Test Section",
      :_processed_diffs => []
    }

    new_section = {
      _processed_diffs: ["diff content 1"]
    }

    merged = @processor.send(:merge_section_data, existing_section, new_section)

    assert_equal 1, merged[:_processed_diffs].length
    assert_equal ["diff content 1"], merged[:_processed_diffs]
  end

  def test_merge_section_data_preserves_processed_diffs_when_only_in_existing
    existing_section = {
      "title" => "Test Section",
      :_processed_diffs => ["existing diff"]
    }

    new_section = {
      "files" => ["test.rb"]
    }

    merged = @processor.send(:merge_section_data, existing_section, new_section)

    assert_equal ["existing diff"], merged[:_processed_diffs]
    # Keys are now normalized to symbols
    assert_equal ["test.rb"], merged[:files]
  end

  # Test symbolize_keys_deep helper
  def test_symbolize_keys_deep_converts_string_keys
    input = {"title" => "Test", "nested" => {"key" => "value"}}
    result = @processor.send(:symbolize_keys_deep, input)

    assert_equal({title: "Test", nested: {key: "value"}}, result)
  end

  def test_symbolize_keys_deep_preserves_symbol_keys
    input = {title: "Test", nested: {key: "value"}}
    result = @processor.send(:symbolize_keys_deep, input)

    assert_equal({title: "Test", nested: {key: "value"}}, result)
  end

  def test_symbolize_keys_deep_handles_arrays
    input = {"items" => [{"name" => "a"}, {"name" => "b"}]}
    result = @processor.send(:symbolize_keys_deep, input)

    assert_equal({items: [{name: "a"}, {name: "b"}]}, result)
  end

  def test_symbolize_keys_deep_handles_mixed_keys
    input = {"string_key" => 1, :symbol_key => 2}
    result = @processor.send(:symbolize_keys_deep, input)

    assert_equal({string_key: 1, symbol_key: 2}, result)
  end

  # Test that merge_section_data normalizes string keys to symbols
  def test_merge_section_data_normalizes_string_keys
    existing = {"title" => "Original", "files" => ["a.rb"]}
    new_section = {"files" => ["b.rb"], "content" => "New content"}

    merged = @processor.send(:merge_section_data, existing, new_section)

    # Result should have symbol keys only
    assert_equal "Original", merged[:title]
    assert_equal ["a.rb", "b.rb"], merged[:files]
    assert_equal "New content", merged[:content]
    refute merged.key?("title"), "Should not have string key 'title'"
    refute merged.key?("files"), "Should not have string key 'files'"
  end

  def test_merge_section_data_handles_mixed_keys
    existing = {:title => "Symbol", "files" => ["a.rb"]}
    new_section = {"title" => "String", :files => ["b.rb"]}

    merged = @processor.send(:merge_section_data, existing, new_section)

    assert_equal "String", merged[:title]  # new wins for scalar
    assert_equal ["a.rb", "b.rb"], merged[:files]
  end

  # Test has_diffs_content? returns true for sections with only _processed_diffs
  def test_has_diffs_content_returns_true_for_processed_diffs
    section_with_processed_diffs = {
      _processed_diffs: ["diff content"]
    }

    assert @processor.send(:has_diffs_content?, section_with_processed_diffs),
      "Should return true when section has _processed_diffs (symbol key)"

    section_with_string_key = {
      "_processed_diffs" => ["diff content"]
    }

    assert @processor.send(:has_diffs_content?, section_with_string_key),
      "Should return true when section has _processed_diffs (string key)"
  end

  def test_has_diffs_content_returns_true_for_ranges
    section_with_ranges = {
      ranges: ["HEAD~1..HEAD"]
    }

    assert @processor.send(:has_diffs_content?, section_with_ranges)
  end

  def test_has_diffs_content_returns_true_for_diffs
    section_with_diffs = {
      "diffs" => ["origin/main...HEAD"]
    }

    assert @processor.send(:has_diffs_content?, section_with_diffs)
  end

  def test_has_diffs_content_returns_false_for_empty_section
    empty_section = {}

    refute @processor.send(:has_diffs_content?, empty_section)
  end

  def test_has_diffs_content_returns_false_for_other_content_types
    section_with_files = {
      "files" => ["test.rb"]
    }

    refute @processor.send(:has_diffs_content?, section_with_files)
  end

  # Test that empty _processed_diffs arrays don't trigger diff content detection
  def test_has_diffs_content_returns_false_for_empty_processed_diffs_array
    section_with_empty_processed = {
      _processed_diffs: []
    }

    refute @processor.send(:has_diffs_content?, section_with_empty_processed),
      "Empty _processed_diffs array should not be treated as having diff content"

    section_with_string_key_empty = {
      "_processed_diffs" => []
    }

    refute @processor.send(:has_diffs_content?, section_with_string_key_empty),
      "Empty _processed_diffs array (string key) should not be treated as having diff content"
  end

  # Test that merge_section_data works with mixed content types
  def test_merge_section_data_merges_all_content_types
    existing_section = {
      "title" => "Test Section",
      "files" => ["file1.rb"],
      "ranges" => ["HEAD~1..HEAD"],
      :_processed_diffs => ["processed 1"]
    }

    new_section = {
      "files" => ["file2.rb"],
      "diffs" => ["origin/main...HEAD"],
      :_processed_diffs => ["processed 2"]
    }

    merged = @processor.send(:merge_section_data, existing_section, new_section)

    # All content types should be merged (normalized to symbol keys)
    assert_equal ["file1.rb", "file2.rb"], merged[:files]
    assert_equal ["HEAD~1..HEAD"], merged[:ranges]
    assert_equal ["origin/main...HEAD"], merged[:diffs]
    assert_equal ["processed 1", "processed 2"], merged[:_processed_diffs]
  end
end

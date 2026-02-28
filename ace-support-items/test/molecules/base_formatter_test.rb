# frozen_string_literal: true

require "test_helper"

class BaseFormatterTest < AceSupportItemsTestCase
  BF = Ace::Support::Items::Molecules::BaseFormatter

  def test_format_item_hash
    item = { id: "8ppq7w", title: "Dark mode" }
    assert_equal "8ppq7w Dark mode", BF.format_item(item)
  end

  def test_format_item_with_scan_result
    item = { title: "My Idea" }
    scan = Ace::Support::Items::Models::ScanResult.new(id: "abc123", slug: "my-idea",
      folder_name: "abc123-my-idea", dir_path: "/tmp", file_path: "/tmp/f", special_folder: nil)

    assert_equal "abc123 My Idea", BF.format_item(item, scan_result: scan)
  end

  def test_format_item_loaded_document
    doc = Ace::Support::Items::Models::LoadedDocument.new(
      frontmatter: { "id" => "8ppq7w" },
      body: "",
      title: "Test Doc",
      file_path: "/tmp/f",
      dir_path: "/tmp",
      attachments: []
    )

    assert_equal "8ppq7w Test Doc", BF.format_item(doc)
  end

  def test_format_list
    items = [
      { id: "aaa111", title: "First" },
      { id: "bbb222", title: "Second" }
    ]

    result = BF.format_list(items)
    assert_includes result, "aaa111 First"
    assert_includes result, "bbb222 Second"
  end

  def test_format_list_empty
    assert_equal "No items found.", BF.format_list([])
  end

  def test_format_list_nil
    assert_equal "No items found.", BF.format_list(nil)
  end
end

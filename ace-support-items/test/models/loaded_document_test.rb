# frozen_string_literal: true

require "test_helper"

class LoadedDocumentTest < AceSupportItemsTestCase
  LD = Ace::Support::Items::Models::LoadedDocument

  def test_struct_attributes
    doc = LD.new(
      frontmatter: {"status" => "pending", "title" => "My Idea"},
      body: "# My Idea\n\nBody text.",
      title: "My Idea",
      file_path: "/root/8ppq7w-my-idea/8ppq7w-my-idea.idea.s.md",
      dir_path: "/root/8ppq7w-my-idea",
      attachments: ["screenshot.png"]
    )

    assert_equal({"status" => "pending", "title" => "My Idea"}, doc.frontmatter)
    assert_equal "# My Idea\n\nBody text.", doc.body
    assert_equal "My Idea", doc.title
    assert_equal "/root/8ppq7w-my-idea/8ppq7w-my-idea.idea.s.md", doc.file_path
    assert_equal "/root/8ppq7w-my-idea", doc.dir_path
    assert_equal ["screenshot.png"], doc.attachments
  end

  def test_bracket_access_string_key
    doc = LD.new(frontmatter: {"status" => "pending"}, body: "", title: "", file_path: "", dir_path: "", attachments: [])
    assert_equal "pending", doc["status"]
  end

  def test_bracket_access_symbol_key
    doc = LD.new(frontmatter: {status: "done"}, body: "", title: "", file_path: "", dir_path: "", attachments: [])
    assert_equal "done", doc[:status]
  end

  def test_bracket_access_returns_nil_for_missing_key
    doc = LD.new(frontmatter: {}, body: "", title: "", file_path: "", dir_path: "", attachments: [])
    assert_nil doc["nonexistent"]
  end

  def test_bracket_tries_string_then_symbol
    doc = LD.new(frontmatter: {"status" => "pending"}, body: "", title: "", file_path: "", dir_path: "", attachments: [])
    # Symbol key access converts to string first
    assert_equal "pending", doc[:status]
    assert_equal "pending", doc["status"]
  end
end

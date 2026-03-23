# frozen_string_literal: true

require_relative "../test_helper"

class FrontmatterSerializerTest < Minitest::Test
  include TestHelpers

  def setup
    @serializer = Ace::Support::Markdown::Atoms::FrontmatterSerializer
  end

  def test_serialize_valid_frontmatter
    frontmatter = {"id" => "test.001", "status" => "pending"}
    result = @serializer.serialize(frontmatter)

    assert result[:valid]
    assert_includes result[:content], "---"
    assert_includes result[:content], "id: test.001"
    assert_includes result[:content], "status: pending"
    assert_empty result[:errors]
  end

  def test_serialize_with_body
    frontmatter = {"id" => "test.001"}
    body = "# Title\n\nContent"
    result = @serializer.serialize(frontmatter, body: body)

    assert result[:valid]
    assert_includes result[:content], "---"
    assert_includes result[:content], "id: test.001"
    assert_includes result[:content], "# Title"
    assert_includes result[:content], "Content"
  end

  def test_serialize_empty_frontmatter
    result = @serializer.serialize({})

    assert result[:valid]
    assert_equal "---\n---", result[:content]
  end

  def test_serialize_nil_frontmatter
    result = @serializer.serialize(nil)

    assert result[:valid]
    assert_equal "---\n---", result[:content]
  end

  def test_serialize_invalid_type
    result = @serializer.serialize("not a hash")

    refute result[:valid]
    assert_includes result[:errors].first, "must be a hash"
  end

  def test_rebuild_document
    frontmatter = {"id" => "test"}
    body = "Content"
    markdown = @serializer.rebuild_document(frontmatter, body)

    assert_includes markdown, "---"
    assert_includes markdown, "id: test"
    assert_includes markdown, "Content"
  end

  def test_frontmatter_only
    frontmatter = {"id" => "test", "status" => "done"}
    result = @serializer.frontmatter_only(frontmatter)

    assert_includes result, "---"
    assert_includes result, "id: test"
    refute_includes result, "\n\n" # No extra newlines for body
  end

  def test_serialize_nested_structure
    frontmatter = {
      "id" => "test",
      "metadata" => {
        "author" => "Test",
        "version" => "1.0"
      },
      "tags" => ["tag1", "tag2"]
    }

    result = @serializer.serialize(frontmatter)

    assert result[:valid]
    assert_includes result[:content], "author: Test"
    assert_includes result[:content], "- tag1"
  end
end

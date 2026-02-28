# frozen_string_literal: true

require "test_helper"

class IdeaFrontmatterDefaultsTest < AceIdeaTestCase
  def test_build_returns_hash
    result = Ace::Idea::Atoms::IdeaFrontmatterDefaults.build(
      id: "8ppq7w",
      title: "Dark mode"
    )
    assert_equal "8ppq7w", result["id"]
    assert_equal "pending", result["status"]
    assert_equal "Dark mode", result["title"]
    assert_equal [], result["tags"]
  end

  def test_build_with_tags
    result = Ace::Idea::Atoms::IdeaFrontmatterDefaults.build(
      id: "8ppq7w",
      title: "Dark mode",
      tags: ["ux", "design"]
    )
    assert_equal ["ux", "design"], result["tags"]
  end

  def test_build_with_custom_status
    result = Ace::Idea::Atoms::IdeaFrontmatterDefaults.build(
      id: "8ppq7w",
      title: "Test",
      status: "in-progress"
    )
    assert_equal "in-progress", result["status"]
  end

  def test_serialize_produces_yaml_block
    frontmatter = {
      "id" => "8ppq7w",
      "status" => "pending",
      "title" => "Dark mode",
      "tags" => [],
      "created_at" => "2026-02-28 12:00:00"
    }
    result = Ace::Idea::Atoms::IdeaFrontmatterDefaults.serialize(frontmatter)

    assert result.start_with?("---")
    assert result.end_with?("---")
    assert_includes result, "id: 8ppq7w"
    assert_includes result, "status: pending"
  end

  def test_serialize_empty_array
    frontmatter = { "tags" => [] }
    result = Ace::Idea::Atoms::IdeaFrontmatterDefaults.serialize(frontmatter)
    assert_includes result, "tags: []"
  end

  def test_serialize_array_with_values
    frontmatter = { "tags" => ["ux", "design"] }
    result = Ace::Idea::Atoms::IdeaFrontmatterDefaults.serialize(frontmatter)
    assert_includes result, "tags: [ux, design]"
  end
end

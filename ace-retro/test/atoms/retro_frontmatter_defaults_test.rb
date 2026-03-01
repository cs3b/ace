# frozen_string_literal: true

require "test_helper"

class RetroFrontmatterDefaultsTest < AceRetroTestCase
  def test_build_returns_hash_with_all_fields
    fm = Ace::Retro::Atoms::RetroFrontmatterDefaults.build(
      id: "8ppq7w",
      title: "Sprint Review",
      type: "standard",
      tags: ["sprint"],
      created_at: Time.utc(2026, 2, 28, 12, 0, 0)
    )

    assert_equal "8ppq7w", fm["id"]
    assert_equal "Sprint Review", fm["title"]
    assert_equal "standard", fm["type"]
    assert_equal ["sprint"], fm["tags"]
    assert_equal "active", fm["status"]
    assert_equal "2026-02-28 12:00:00", fm["created_at"]
    refute fm.key?("task_ref")
  end

  def test_build_includes_task_ref_when_provided
    fm = Ace::Retro::Atoms::RetroFrontmatterDefaults.build(
      id: "8ppq7w",
      title: "Sprint Review",
      task_ref: "q7w"
    )

    assert_equal "q7w", fm["task_ref"]
  end

  def test_build_omits_task_ref_when_nil
    fm = Ace::Retro::Atoms::RetroFrontmatterDefaults.build(
      id: "8ppq7w",
      title: "Sprint Review"
    )

    refute fm.key?("task_ref")
  end

  def test_serialize_returns_yaml_string
    fm = Ace::Retro::Atoms::RetroFrontmatterDefaults.build(
      id: "8ppq7w",
      title: "Sprint Review"
    )
    result = Ace::Retro::Atoms::RetroFrontmatterDefaults.serialize(fm)

    assert result.start_with?("---\n")
    assert result.strip.end_with?("---")
    assert_includes result, "id: 8ppq7w"
  end
end

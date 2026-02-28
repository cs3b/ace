# frozen_string_literal: true

require "test_helper"

class IdeaModelTest < AceIdeaTestCase
  def make_idea(overrides = {})
    Ace::Idea::Models::Idea.new(
      {
        id: "8ppq7w",
        status: "pending",
        title: "Dark mode support",
        tags: ["ux", "design"],
        content: "# Dark mode support\n\nAdd dark mode.",
        path: "/tmp/8ppq7w-dark-mode",
        file_path: "/tmp/8ppq7w-dark-mode/8ppq7w-dark-mode.idea.s.md",
        special_folder: nil,
        created_at: Time.now,
        attachments: [],
        metadata: {}
      }.merge(overrides)
    )
  end

  def test_basic_attributes
    idea = make_idea
    assert_equal "8ppq7w", idea.id
    assert_equal "pending", idea.status
    assert_equal "Dark mode support", idea.title
    assert_equal ["ux", "design"], idea.tags
  end

  def test_to_s
    idea = make_idea
    assert_equal "Idea(8ppq7w: Dark mode support)", idea.to_s
  end

  def test_shortcut
    idea = make_idea
    assert_equal "q7w", idea.shortcut
  end

  def test_special_when_no_special_folder
    idea = make_idea(special_folder: nil)
    refute idea.special?
  end

  def test_special_when_in_special_folder
    idea = make_idea(special_folder: "_maybe")
    assert idea.special?
  end

  def test_with_attachments
    idea = make_idea(attachments: ["screenshot.png", "notes.txt"])
    assert_equal 2, idea.attachments.length
    assert_includes idea.attachments, "screenshot.png"
  end
end

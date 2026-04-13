# frozen_string_literal: true

require "test_helper"

class RetroModelTest < AceRetroTestCase
  def make_retro(overrides = {})
    Ace::Retro::Models::Retro.new(
      {
        id: "8ppq7w",
        status: "active",
        title: "Sprint Review",
        type: "standard",
        tags: ["sprint", "team"],
        content: "# Sprint Review\n\nContent here.",
        path: "/tmp/8ppq7w-sprint-review",
        file_path: "/tmp/8ppq7w-sprint-review/8ppq7w-sprint-review.retro.md",
        special_folder: nil,
        created_at: Time.now,
        folder_contents: [],
        metadata: {}
      }.merge(overrides)
    )
  end

  def test_basic_attributes
    retro = make_retro
    assert_equal "8ppq7w", retro.id
    assert_equal "active", retro.status
    assert_equal "Sprint Review", retro.title
    assert_equal "standard", retro.type
    assert_equal ["sprint", "team"], retro.tags
  end

  def test_to_s
    retro = make_retro
    assert_equal "Retro(8ppq7w: Sprint Review)", retro.to_s
  end

  def test_shortcut
    retro = make_retro
    assert_equal "q7w", retro.shortcut
  end

  def test_special_when_no_special_folder
    retro = make_retro(special_folder: nil)
    refute retro.special?
  end

  def test_special_when_in_special_folder
    retro = make_retro(special_folder: "_archive")
    assert retro.special?
  end

  def test_with_folder_contents
    retro = make_retro(folder_contents: ["report.md", "notes.txt"])
    assert_equal 2, retro.folder_contents.length
    assert_includes retro.folder_contents, "report.md"
  end
end

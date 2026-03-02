# frozen_string_literal: true

require "test_helper"

class IdeaDisplayFormatterTest < AceIdeaTestCase
  def make_idea(overrides = {})
    Ace::Idea::Models::Idea.new(
      {
        id: "8ppq7w",
        status: "pending",
        title: "Great Idea",
        tags: [],
        content: "Some content.",
        path: "/tmp/test",
        file_path: "/tmp/test/file.idea.s.md",
        special_folder: nil,
        created_at: Time.now,
        attachments: [],
        metadata: {}
      }.merge(overrides)
    )
  end

  # --- format_list stats line ---

  def test_format_list_includes_stats_line
    ideas = [
      make_idea(id: "aaa111", status: "pending"),
      make_idea(id: "bbb222", status: "done"),
      make_idea(id: "ccc333", status: "in-progress")
    ]
    output = Ace::Idea::Molecules::IdeaDisplayFormatter.format_list(ideas)

    assert_includes output, "Ideas: ⚪ 1 | 🟡 1 | 🟢 1 • 3 total • 33% complete"
  end

  def test_format_list_stats_line_omits_zero_counts
    ideas = [make_idea(status: "pending"), make_idea(status: "pending")]
    output = Ace::Idea::Molecules::IdeaDisplayFormatter.format_list(ideas)

    assert_includes output, "Ideas: ⚪ 2 • 2 total"
    refute_includes output, "🟡 0"
    refute_includes output, "🟢 0"
  end

  def test_format_list_stats_separated_by_blank_line
    ideas = [make_idea]
    output = Ace::Idea::Molecules::IdeaDisplayFormatter.format_list(ideas)

    assert_match(/\n\nIdeas:/, output)
  end

  def test_format_list_empty_returns_no_ideas_message
    output = Ace::Idea::Molecules::IdeaDisplayFormatter.format_list([])

    assert_equal "No ideas found.", output
  end

  # --- format_stats_line ---

  def test_format_stats_line
    ideas = [
      make_idea(status: "pending"),
      make_idea(status: "in-progress"),
      make_idea(status: "done"),
      make_idea(status: "done")
    ]
    line = Ace::Idea::Molecules::IdeaDisplayFormatter.format_stats_line(ideas)

    assert_equal "Ideas: ⚪ 1 | 🟡 1 | 🟢 2 • 4 total • 50% complete", line
  end
end

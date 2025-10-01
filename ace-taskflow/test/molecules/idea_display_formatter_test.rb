# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/idea_display_formatter"

class IdeaDisplayFormatterTest < Minitest::Test
  def test_context_name_current
    assert_equal "current release", Ace::Taskflow::Molecules::IdeaDisplayFormatter.context_name("current")
  end

  def test_context_name_active
    assert_equal "current release", Ace::Taskflow::Molecules::IdeaDisplayFormatter.context_name("active")
  end

  def test_context_name_backlog
    assert_equal "backlog", Ace::Taskflow::Molecules::IdeaDisplayFormatter.context_name("backlog")
  end

  def test_context_name_release
    assert_equal "release v.0.9.0", Ace::Taskflow::Molecules::IdeaDisplayFormatter.context_name("v.0.9.0")
  end

  def test_format_idea_header_minimal
    idea = { id: "idea-001" }
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_idea_header(idea)

    assert_equal 1, result.length
    assert_includes result, "Idea: idea-001"
  end

  def test_format_idea_header_with_filename_fallback
    idea = { filename: "my-idea.md" }
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_idea_header(idea)

    assert_includes result, "Idea: my-idea.md"
  end

  def test_format_idea_header_complete
    idea = {
      id: "idea-001",
      title: "Implement caching",
      created_at: "2025-10-01",
      context: "v.0.9.0"
    }
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_idea_header(idea)

    assert_equal 4, result.length
    assert_includes result, "Idea: idea-001"
    assert_includes result, "Title: Implement caching"
    assert_includes result, "Created: 2025-10-01"
    assert_includes result, "Context: v.0.9.0"
  end

  def test_format_idea_header_skips_missing_fields
    idea = {
      id: "idea-001",
      title: "My idea"
      # No created_at or context
    }
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_idea_header(idea)

    assert_equal 2, result.length
    refute result.any? { |line| line.include?("Created:") }
    refute result.any? { |line| line.include?("Context:") }
  end

  def test_format_idea_display_without_content
    idea = {
      id: "idea-001",
      title: "My idea"
    }
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_idea_display(idea, include_content: false)

    assert_includes result, "Idea: idea-001"
    refute_includes result, "--- Content ---"
  end

  def test_format_idea_display_with_content
    idea = {
      id: "idea-001",
      title: "My idea",
      content: "This is the full content"
    }
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_idea_display(idea, include_content: true)

    assert_includes result, "Idea: idea-001"
    assert_includes result, "--- Content ---"
    assert_includes result, "This is the full content"
  end

  def test_format_idea_display_with_path
    idea = {
      id: "idea-001",
      path: "/path/to/idea.md"
    }
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_idea_display(idea, include_content: false)

    assert_includes result, "Path: /path/to/idea.md"
  end

  def test_format_idea_display_complete
    idea = {
      id: "idea-001",
      title: "My idea",
      created_at: "2025-10-01",
      context: "v.0.9.0",
      path: "/path/to/idea.md",
      content: "Full content here"
    }
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_idea_display(idea)

    assert_includes result, "Idea: idea-001"
    assert_includes result, "Title: My idea"
    assert_includes result, "Created: 2025-10-01"
    assert_includes result, "Context: v.0.9.0"
    assert_includes result, "Path: /path/to/idea.md"
    assert_includes result, "--- Content ---"
    assert_includes result, "Full content here"
  end

  def test_format_capture_confirmation
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_capture_confirmation(
      "v.0.9.0/i/my-idea.md"
    )

    assert_equal "Idea captured: v.0.9.0/i/my-idea.md", result
  end

  def test_format_done_confirmation_with_timestamp
    timestamp = Time.new(2025, 10, 1, 14, 30, 0)
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_done_confirmation("idea-001", timestamp)

    assert_equal 2, result.length
    assert_equal "Idea 'idea-001' marked as done and moved to done/", result[0]
    assert_equal "Completed at: 2025-10-01 14:30:00", result[1]
  end

  def test_format_done_confirmation_without_timestamp
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_done_confirmation("idea-002")

    assert_equal 2, result.length
    assert_includes result[0], "idea-002"
    assert_includes result[1], "Completed at:"
  end

  def test_format_not_found_message_current
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_not_found_message(
      "missing-idea", "current"
    )

    assert_equal "No idea found matching 'missing-idea' in current release.", result
  end

  def test_format_not_found_message_backlog
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_not_found_message(
      "missing-idea", "backlog"
    )

    assert_equal "No idea found matching 'missing-idea' in backlog.", result
  end

  def test_format_not_found_message_release
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_not_found_message(
      "missing-idea", "v.0.9.0"
    )

    assert_equal "No idea found matching 'missing-idea' in release v.0.9.0.", result
  end

  def test_format_empty_state
    result = Ace::Taskflow::Molecules::IdeaDisplayFormatter.format_empty_state

    assert_equal 2, result.length
    assert_includes result[0], "No ideas found"
    assert_includes result[1], "ace-taskflow idea create"
  end
end

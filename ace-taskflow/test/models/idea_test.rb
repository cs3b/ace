# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/models/idea"

class IdeaModelTest < AceTaskflowTestCase
  def setup
    @idea_data = {
      id: "idea.001",
      title: "Implement dark mode",
      content: "Add dark mode support across the application",
      path: "/path/to/idea.001.md",
      context: "backlog",
      created_at: "2025-01-01 10:00:00",
      tags: ["feature", "ui"],
      status: "pending"
    }
  end

  def test_idea_initialization
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)

    assert_equal "idea.001", idea.id
    assert_equal "Implement dark mode", idea.title
    assert_equal "Add dark mode support across the application", idea.content
    assert_equal "/path/to/idea.001.md", idea.path
  end

  def test_idea_with_minimal_data
    minimal_data = {
      id: "idea.001",
      title: "Simple idea"
    }
    idea = Ace::Taskflow::Models::Idea.new(minimal_data)

    assert_equal "idea.001", idea.id
    assert_equal "Simple idea", idea.title
    assert_nil idea.content
  end

  def test_idea_id_accessor
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    assert_equal "idea.001", idea.id
  end

  def test_idea_title_accessor
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    assert_equal "Implement dark mode", idea.title
  end

  def test_idea_content_accessor
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    assert_equal "Add dark mode support across the application", idea.content
  end

  def test_idea_path_accessor
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    assert_equal "/path/to/idea.001.md", idea.path
  end

  def test_idea_context_accessor
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    assert_equal "backlog", idea.context
  end

  def test_idea_created_at_accessor
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    assert_equal "2025-01-01 10:00:00", idea.created_at
  end

  def test_idea_tags_accessor
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    assert_equal ["feature", "ui"], idea.tags
  end

  def test_idea_with_empty_tags
    data = @idea_data.merge(tags: [])
    idea = Ace::Taskflow::Models::Idea.new(data)
    assert_equal [], idea.tags
  end

  def test_idea_with_nil_tags
    data = @idea_data.dup
    data.delete(:tags)
    idea = Ace::Taskflow::Models::Idea.new(data)
    assert_equal [], idea.tags
  end

  def test_idea_status_accessor
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    assert_equal "pending", idea.status
  end

  def test_idea_with_string_keys
    string_key_data = {
      "id" => "idea.002",
      "title" => "String key idea",
      "content" => "Content here"
    }
    idea = Ace::Taskflow::Models::Idea.new(string_key_data)

    assert_equal "idea.002", idea.id
    assert_equal "String key idea", idea.title
    assert_equal "Content here", idea.content
  end

  def test_idea_to_hash
    idea = Ace::Taskflow::Models::Idea.new(@idea_data)
    hash = idea.to_h

    assert_instance_of Hash, hash
    assert_equal "idea.001", hash[:id]
    assert_equal "Implement dark mode", hash[:title]
  end

  def test_idea_with_multiline_content
    data = @idea_data.merge(
      content: "Line 1\nLine 2\nLine 3"
    )
    idea = Ace::Taskflow::Models::Idea.new(data)

    assert_equal "Line 1\nLine 2\nLine 3", idea.content
  end

  def test_idea_without_created_at
    data = @idea_data.dup
    data.delete(:created_at)
    idea = Ace::Taskflow::Models::Idea.new(data)

    assert_nil idea.created_at
  end
end

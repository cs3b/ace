# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentTest < AceAssignTestCase
  def test_initialization
    now = Time.now.utc
    assignment = Ace::Assign::Models::Assignment.new(
      id: "abc123",
      name: "test-session",
      description: "A test assignment",
      created_at: now,
      source_config: "job.yaml",
      cache_dir: "/tmp/test"
    )

    assert_equal "abc123", assignment.id
    assert_equal "test-session", assignment.name
    assert_equal "A test assignment", assignment.description
    assert_equal now, assignment.created_at
    assert_equal now, assignment.updated_at
    assert_equal "job.yaml", assignment.source_config
    assert_equal "/tmp/test", assignment.cache_dir
  end

  def test_phases_dir
    assignment = Ace::Assign::Models::Assignment.new(
      id: "abc123",
      name: "test",
      created_at: Time.now,
      source_config: "job.yaml",
      cache_dir: "/tmp/test"
    )

    assert_equal "/tmp/test/phases", assignment.phases_dir
  end

  def test_assignment_file
    assignment = Ace::Assign::Models::Assignment.new(
      id: "abc123",
      name: "test",
      created_at: Time.now,
      source_config: "job.yaml",
      cache_dir: "/tmp/test"
    )

    assert_equal "/tmp/test/assignment.yaml", assignment.assignment_file
  end

  def test_to_h
    now = Time.utc(2026, 1, 28, 12, 0, 0)
    assignment = Ace::Assign::Models::Assignment.new(
      id: "abc123",
      name: "test-session",
      description: "A test",
      created_at: now,
      source_config: "job.yaml"
    )

    hash = assignment.to_h

    assert_equal "abc123", hash["session_id"]
    assert_equal "test-session", hash["name"]
    assert_equal "A test", hash["description"]
    assert_equal "2026-01-28T12:00:00Z", hash["created_at"]
    assert_equal "job.yaml", hash["source_config"]
  end

  def test_from_h
    data = {
      "session_id" => "abc123",
      "name" => "test-session",
      "description" => "A test",
      "created_at" => "2026-01-28T12:00:00Z",
      "updated_at" => "2026-01-28T13:00:00Z",
      "source_config" => "job.yaml"
    }

    assignment = Ace::Assign::Models::Assignment.from_h(data, cache_dir: "/tmp/test")

    assert_equal "abc123", assignment.id
    assert_equal "test-session", assignment.name
    assert_equal "/tmp/test", assignment.cache_dir
  end
end

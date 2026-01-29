# frozen_string_literal: true

require_relative "../test_helper"

class SessionTest < AceCoworkerTestCase
  def test_initialization
    now = Time.now.utc
    session = Ace::Coworker::Models::Session.new(
      id: "abc123",
      name: "test-session",
      description: "A test session",
      created_at: now,
      source_config: "job.yaml",
      cache_dir: "/tmp/test"
    )

    assert_equal "abc123", session.id
    assert_equal "test-session", session.name
    assert_equal "A test session", session.description
    assert_equal now, session.created_at
    assert_equal now, session.updated_at
    assert_equal "job.yaml", session.source_config
    assert_equal "/tmp/test", session.cache_dir
  end

  def test_jobs_dir
    session = Ace::Coworker::Models::Session.new(
      id: "abc123",
      name: "test",
      created_at: Time.now,
      source_config: "job.yaml",
      cache_dir: "/tmp/test"
    )

    assert_equal "/tmp/test/jobs", session.jobs_dir
  end

  def test_session_file
    session = Ace::Coworker::Models::Session.new(
      id: "abc123",
      name: "test",
      created_at: Time.now,
      source_config: "job.yaml",
      cache_dir: "/tmp/test"
    )

    assert_equal "/tmp/test/session.yaml", session.session_file
  end

  def test_to_h
    now = Time.utc(2026, 1, 28, 12, 0, 0)
    session = Ace::Coworker::Models::Session.new(
      id: "abc123",
      name: "test-session",
      description: "A test",
      created_at: now,
      source_config: "job.yaml"
    )

    hash = session.to_h

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

    session = Ace::Coworker::Models::Session.from_h(data, cache_dir: "/tmp/test")

    assert_equal "abc123", session.id
    assert_equal "test-session", session.name
    assert_equal "/tmp/test", session.cache_dir
  end
end

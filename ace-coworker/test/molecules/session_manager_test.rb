# frozen_string_literal: true

require_relative "../test_helper"

class SessionManagerTest < AceCoworkerTestCase
  def test_create_session
    with_temp_cache do |cache_dir|
      manager = Ace::Coworker::Molecules::SessionManager.new(cache_base: cache_dir)

      session = manager.create(
        name: "test-session",
        description: "A test",
        source_config: "job.yaml"
      )

      assert_match(/\A[a-z0-9]{6}\z/, session.id)
      assert_equal "test-session", session.name
      assert_equal "A test", session.description
      assert_equal "job.yaml", session.source_config
      assert File.directory?(session.cache_dir)
      assert File.directory?(session.jobs_dir)
      assert File.exist?(session.session_file)
    end
  end

  def test_load_session
    with_temp_cache do |cache_dir|
      manager = Ace::Coworker::Molecules::SessionManager.new(cache_base: cache_dir)

      created = manager.create(
        name: "test-session",
        source_config: "job.yaml"
      )

      loaded = manager.load(created.id)

      assert_equal created.id, loaded.id
      assert_equal created.name, loaded.name
      assert_equal created.cache_dir, loaded.cache_dir
    end
  end

  def test_load_nonexistent_returns_nil
    with_temp_cache do |cache_dir|
      manager = Ace::Coworker::Molecules::SessionManager.new(cache_base: cache_dir)

      result = manager.load("nonexistent")

      assert_nil result
    end
  end

  def test_find_active
    with_temp_cache do |cache_dir|
      manager = Ace::Coworker::Molecules::SessionManager.new(cache_base: cache_dir)

      # Create two sessions
      manager.create(name: "first", source_config: "job.yaml")
      sleep(0.1) # Ensure different timestamps
      second = manager.create(name: "second", source_config: "job.yaml")

      active = manager.find_active

      assert_equal second.id, active.id
      assert_equal "second", active.name
    end
  end

  def test_find_active_none
    with_temp_cache do |cache_dir|
      manager = Ace::Coworker::Molecules::SessionManager.new(cache_base: cache_dir)

      active = manager.find_active

      assert_nil active
    end
  end

  def test_list_sessions
    with_temp_cache do |cache_dir|
      manager = Ace::Coworker::Molecules::SessionManager.new(cache_base: cache_dir)

      first = manager.create(name: "first", source_config: "job.yaml")
      second = manager.create(name: "second", source_config: "job.yaml")

      # Verify collision handling - IDs should be different
      refute_equal first.id, second.id

      sessions = manager.list

      assert_equal 2, sessions.size
    end
  end

  def test_update_session
    with_temp_cache do |cache_dir|
      manager = Ace::Coworker::Molecules::SessionManager.new(cache_base: cache_dir)

      created = manager.create(name: "test", source_config: "job.yaml")
      original_updated = created.updated_at

      sleep(0.1)
      updated = manager.update(created)

      assert updated.updated_at > original_updated
    end
  end
end

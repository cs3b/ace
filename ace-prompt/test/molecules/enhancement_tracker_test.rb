# frozen_string_literal: true

require "test_helper"

class EnhancementTrackerTest < Minitest::Test
  # Test fixture for Base36 session ID format
  BASE36_SESSION_ID = "i50jj3"

  def setup
    @test_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@test_dir)
  end

  def test_cache_key_generates_sha256
    content = "Test content"
    model = "glite"
    system_prompt_content = "You are a helpful assistant."
    temperature = 0.3

    key = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, model, system_prompt_content, temperature)

    assert_kind_of String, key
    assert_equal 64, key.length # SHA256 produces 64 hex characters
  end

  def test_cache_key_is_deterministic
    content = "Same content"
    model = "glite"
    system_prompt_content = "You are a helpful assistant."
    temperature = 0.3

    key1 = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, model, system_prompt_content, temperature)
    key2 = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, model, system_prompt_content, temperature)

    assert_equal key1, key2
  end

  def test_cache_key_changes_with_different_model
    content = "Same content"
    system_prompt = "You are a helpful assistant."
    key1 = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, "glite", system_prompt, 0.3)
    key2 = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, "claude", system_prompt, 0.3)

    refute_equal key1, key2
  end

  def test_cache_key_changes_with_different_system_prompt_content
    content = "Same content"
    # Different system prompt content should produce different cache keys
    key1 = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, "glite", "You are a helpful assistant.", 0.3)
    key2 = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, "glite", "You are an expert coder.", 0.3)

    refute_equal key1, key2
  end

  def test_cache_key_changes_with_different_temperature
    content = "Same content"
    system_prompt = "You are a helpful assistant."
    key1 = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, "glite", system_prompt, 0.3)
    key2 = Ace::Prompt::Molecules::EnhancementTracker.cache_key(content, "glite", system_prompt, 0.7)

    refute_equal key1, key2
  end

  def test_content_hash_generates_sha256
    content = "Test content for hashing"
    hash = Ace::Prompt::Molecules::EnhancementTracker.content_hash(content)

    assert_kind_of String, hash
    assert_equal 64, hash.length # SHA256 produces 64 hex characters
  end

  def test_content_hash_is_deterministic
    content = "Same content"
    hash1 = Ace::Prompt::Molecules::EnhancementTracker.content_hash(content)
    hash2 = Ace::Prompt::Molecules::EnhancementTracker.content_hash(content)

    assert_equal hash1, hash2
  end

  def test_cached_returns_false_when_not_cached
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      hash = "nonexistent123"
      refute Ace::Prompt::Molecules::EnhancementTracker.cached?(hash)
    end
  end

  def test_store_cache_and_get_cached
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      content = "Enhanced prompt content"
      hash = Ace::Prompt::Molecules::EnhancementTracker.content_hash(content)

      # Store in cache
      result = Ace::Prompt::Molecules::EnhancementTracker.store_cache(hash, content)
      assert result

      # Check it's cached
      assert Ace::Prompt::Molecules::EnhancementTracker.cached?(hash)

      # Retrieve from cache
      cached_content = Ace::Prompt::Molecules::EnhancementTracker.get_cached(hash)
      assert_equal content, cached_content
    end
  end

  def test_get_cached_returns_nil_for_nonexistent
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      hash = "nonexistent456"
      result = Ace::Prompt::Molecules::EnhancementTracker.get_cached(hash)
      assert_nil result
    end
  end

  def test_next_iteration_returns_1_when_no_archive_dir
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      iteration = Ace::Prompt::Molecules::EnhancementTracker.next_iteration(BASE36_SESSION_ID)
      assert_equal 1, iteration
    end
  end

  def test_next_iteration_returns_1_when_no_enhancement_files
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      archive_dir = File.join(@test_dir, ".cache/ace-prompt/prompts/archive")
      FileUtils.mkdir_p(archive_dir)

      # Create a regular archive file (not enhanced)
      File.write(File.join(archive_dir, "#{BASE36_SESSION_ID}.md"), "original")

      iteration = Ace::Prompt::Molecules::EnhancementTracker.next_iteration(BASE36_SESSION_ID)
      assert_equal 1, iteration
    end
  end

  def test_next_iteration_increments_from_existing
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      archive_dir = File.join(@test_dir, ".cache/ace-prompt/prompts/archive")
      FileUtils.mkdir_p(archive_dir)

      # Create some enhancement files
      File.write(File.join(archive_dir, "#{BASE36_SESSION_ID}_e001.md"), "enhanced 1")
      File.write(File.join(archive_dir, "#{BASE36_SESSION_ID}_e002.md"), "enhanced 2")

      iteration = Ace::Prompt::Molecules::EnhancementTracker.next_iteration(BASE36_SESSION_ID)
      assert_equal 3, iteration
    end
  end

  def test_next_iteration_handles_gaps_in_numbering
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      archive_dir = File.join(@test_dir, ".cache/ace-prompt/prompts/archive")
      FileUtils.mkdir_p(archive_dir)

      # Create files with gaps
      File.write(File.join(archive_dir, "#{BASE36_SESSION_ID}_e001.md"), "enhanced 1")
      File.write(File.join(archive_dir, "#{BASE36_SESSION_ID}_e005.md"), "enhanced 5")

      iteration = Ace::Prompt::Molecules::EnhancementTracker.next_iteration(BASE36_SESSION_ID)
      assert_equal 6, iteration # Should be max + 1
    end
  end

  def test_enhancement_filename_formats_correctly
    filename = Ace::Prompt::Molecules::EnhancementTracker.enhancement_filename(BASE36_SESSION_ID, 1)
    assert_equal "#{BASE36_SESSION_ID}_e001.md", filename
  end

  def test_enhancement_filename_pads_iteration_number
    filename1 = Ace::Prompt::Molecules::EnhancementTracker.enhancement_filename(BASE36_SESSION_ID, 1)
    filename10 = Ace::Prompt::Molecules::EnhancementTracker.enhancement_filename(BASE36_SESSION_ID, 10)
    filename100 = Ace::Prompt::Molecules::EnhancementTracker.enhancement_filename(BASE36_SESSION_ID, 100)

    assert_equal "#{BASE36_SESSION_ID}_e001.md", filename1
    assert_equal "#{BASE36_SESSION_ID}_e010.md", filename10
    assert_equal "#{BASE36_SESSION_ID}_e100.md", filename100
  end

  def test_cache_directory_created_automatically
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @test_dir do
      content = "Test content"
      hash = Ace::Prompt::Molecules::EnhancementTracker.content_hash(content)

      # Verify cache directory doesn't exist yet
      cache_dir = File.join(@test_dir, ".cache/ace-prompt/enhance-cache")
      refute Dir.exist?(cache_dir)

      # Store cache
      Ace::Prompt::Molecules::EnhancementTracker.store_cache(hash, content)

      # Verify cache directory was created
      assert Dir.exist?(cache_dir)
    end
  end
end

# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "ace/core/molecules/prompt_cache_manager"

class PromptCacheManagerTest < Minitest::Test
  def setup
    @test_dir = Dir.mktmpdir("prompt_cache_test")
  end

  def teardown
    FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
  end

  def test_create_session_creates_directory_with_timestamp
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "test-operation",
      project_root: @test_dir
    )

    assert Dir.exist?(session_dir), "Session directory should be created"
    assert_match(/test-operation-\d{8}-\d{6}$/, session_dir, "Session directory should include operation name and timestamp")
  end

  def test_create_session_creates_base_cache_structure
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "review",
      project_root: @test_dir
    )

    expected_base = File.join(@test_dir, ".ace-local", "test", "sessions")
    assert Dir.exist?(expected_base), "Base cache directory structure should be created"
    assert session_dir.start_with?(expected_base), "Session should be in base cache directory"
  end

  def test_save_system_prompt_creates_file_with_standard_name
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "test-op",
      project_root: @test_dir
    )
    content = "This is a system prompt"

    file_path = Ace::Core::Molecules::PromptCacheManager.save_system_prompt(content, session_dir)

    assert File.exist?(file_path), "System prompt file should be created"
    assert_equal "system.prompt.md", File.basename(file_path), "System prompt should use standard filename"
    assert_equal content, File.read(file_path), "System prompt content should match"
  end

  def test_save_user_prompt_creates_file_with_standard_name
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "test-op",
      project_root: @test_dir
    )
    content = "This is a user prompt"

    file_path = Ace::Core::Molecules::PromptCacheManager.save_user_prompt(content, session_dir)

    assert File.exist?(file_path), "User prompt file should be created"
    assert_equal "user.prompt.md", File.basename(file_path), "User prompt should use standard filename"
    assert_equal content, File.read(file_path), "User prompt content should match"
  end

  def test_save_metadata_creates_valid_yaml
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "test-op",
      project_root: @test_dir
    )
    metadata = {
      "timestamp" => "2025-11-15T14:30:22Z",
      "gem" => "ace-test",
      "operation" => "test-operation",
      "model" => "test-model",
      "prompt_sizes" => {"system" => 1234, "user" => 5678}
    }

    file_path = Ace::Core::Molecules::PromptCacheManager.save_metadata(metadata, session_dir)

    assert File.exist?(file_path), "Metadata file should be created"
    assert_equal "metadata.yml", File.basename(file_path), "Metadata should use standard filename"

    loaded_metadata = YAML.load_file(file_path)
    assert_equal metadata, loaded_metadata, "Metadata should round-trip correctly"
  end

  def test_class_method_create_session
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "operation",
      project_root: @test_dir
    )

    assert Dir.exist?(session_dir), "Session directory should be created via class method"
    assert_match(/operation-\d{8}-\d{6}$/, session_dir, "Should include operation name and timestamp")
  end

  def test_multiple_sessions_have_unique_directories
    session1 = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "op1",
      project_root: @test_dir
    )
    sleep 0.01 # Ensure different timestamp
    session2 = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "op2",
      project_root: @test_dir
    )

    refute_equal session1, session2, "Each session should have unique directory"
    assert Dir.exist?(session1), "First session directory should exist"
    assert Dir.exist?(session2), "Second session directory should exist"
  end

  def test_handles_special_characters_in_operation_names
    # Test that operation names with spaces or special chars work
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "analyze consistency",
      project_root: @test_dir
    )

    assert Dir.exist?(session_dir), "Should handle operation names with spaces"
    assert_match(/analyze consistency-\d{8}-\d{6}$/, session_dir)
  end

  def test_base_cache_path_created_once
    # First call creates the base path
    Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "op1",
      project_root: @test_dir
    )
    base_path = File.join(@test_dir, ".ace-local", "test", "sessions")

    # Second call should reuse existing base path
    Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "op2",
      project_root: @test_dir
    )

    assert Dir.exist?(base_path), "Base cache path should exist"
    assert_equal 2, Dir.glob(File.join(base_path, "*")).length, "Should have 2 session directories"
  end

  # Error handling tests
  def test_create_session_validates_arguments
    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.create_session(nil, "operation", project_root: @test_dir)
    end
    assert_match(/gem_name cannot be nil or empty/, error.message)

    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.create_session("ace-test", "", project_root: @test_dir)
    end
    assert_match(/operation cannot be nil or empty/, error.message)
  end

  def test_save_metadata_validates_arguments
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "test-op",
      project_root: @test_dir
    )

    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.save_metadata("not a hash", session_dir)
    end
    assert_match(/metadata must be a Hash/, error.message)

    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.save_metadata({}, nil)
    end
    assert_match(/session_dir cannot be nil or empty/, error.message)
  end

  def test_save_prompt_validates_arguments
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "test-op",
      project_root: @test_dir
    )

    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.save_system_prompt(nil, session_dir)
    end
    assert_match(/content cannot be nil/, error.message)

    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.save_user_prompt("content", "")
    end
    assert_match(/session_dir cannot be nil or empty/, error.message)
  end

  def test_validate_metadata_with_valid_data
    metadata = {
      "timestamp" => Time.now,
      "gem" => "ace-test",
      "operation" => "test-operation"
    }

    # Should not raise any error
    Ace::Core::Molecules::PromptCacheManager.validate_metadata(metadata)
  end

  def test_validate_metadata_missing_required_fields
    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.validate_metadata({
        "gem" => "ace-test"
        # Missing timestamp and operation
      })
    end
    assert_match(/Missing required metadata fields: timestamp, operation/, error.message)
  end

  def test_validate_metadata_invalid_field_types
    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.validate_metadata({
        "timestamp" => 123, # Invalid type
        "gem" => "ace-test",
        "operation" => "test-operation"
      })
    end
    assert_match(/timestamp.*must be a String or Time/, error.message)

    error = assert_raises(ArgumentError) do
      Ace::Core::Molecules::PromptCacheManager.validate_metadata({
        "timestamp" => Time.now,
        "gem" => "", # Empty string
        "operation" => "test-operation"
      })
    end
    assert_match(/gem.*must be a non-empty String/, error.message)
  end

  def test_save_metadata_can_skip_validation
    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "test-op",
      project_root: @test_dir
    )

    # Should work even with invalid metadata when validation is disabled
    metadata = {"custom" => "data"}
    file_path = Ace::Core::Molecules::PromptCacheManager.save_metadata(
      metadata,
      session_dir,
      validate: false
    )

    assert File.exist?(file_path), "Should save metadata without validation when requested"
  end

  def test_custom_timestamp_formatter
    custom_timestamp = "custom-timestamp-123"
    formatter = proc { |_time| custom_timestamp }

    session_dir = Ace::Core::Molecules::PromptCacheManager.create_session(
      "ace-test",
      "operation",
      project_root: @test_dir,
      timestamp_formatter: formatter
    )

    assert_match(/operation-custom-timestamp-123$/, session_dir, "Should use custom timestamp formatter")
  end
end

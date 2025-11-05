# frozen_string_literal: true

require "test_helper"

class ReviewManagerTest < AceReviewTest
  def setup
    @manager = Ace::Review::Organisms::ReviewManager.new
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_list_presets
    presets = @manager.list_presets
    assert_kind_of Array, presets
    refute_empty presets
  end

  def test_list_prompts
    prompts = @manager.list_prompts
    assert_kind_of Array, prompts
  end

  def test_execute_review_with_default_preset
    options = {
      subject: { "content" => "def test; end" },
      auto_execute: false  # Don't actually call LLM
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"
    assert result[:session_dir], "Should have session directory"
    assert Dir.exist?(result[:session_dir]), "Session directory should exist"

    # Check that session files are created with v0.13.0 architecture
    assert File.exist?(File.join(result[:session_dir], "system.prompt.md"))
    assert File.exist?(File.join(result[:session_dir], "user.prompt.md"))
    assert File.exist?(File.join(result[:session_dir], "subject.md"))
    assert File.exist?(File.join(result[:session_dir], "metadata.yml"))
  end

  def test_execute_review_with_context_creates_context_md
    options = {
      subject: { "content" => "def test; end" },
      context: { "files" => ["README.md"] },
      auto_execute: false
    }

    # Create a README.md file
    readme_path = File.join(@temp_dir, "README.md")
    File.write(readme_path, "# Test Project")

    Dir.chdir(@temp_dir) do
      result = @manager.execute_review(options)

      assert result[:success], "Review should succeed: #{result[:error]}"

      # Check that context.md is created in cache directory
      session_dir = result[:session_dir]
      context_file = File.join(session_dir, "context.md")
      assert File.exist?(context_file), "Context.md should be created"

      context_content = File.read(context_file)
      assert_match(/Test Project/, context_content)
    end
  end

  def test_execute_review_with_cache_first_storage
    options = {
      subject: { "content" => "def test; end" },
      session_dir: File.join(@temp_dir, "custom_session"),
      auto_execute: false
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"
    assert_equal File.join(@temp_dir, "custom_session"), result[:session_dir]

    # Verify files are created in custom session directory
    assert File.exist?(File.join(result[:session_dir], "system.prompt.md"))
    assert File.exist?(File.join(result[:session_dir], "user.prompt.md"))
  end

  def test_v0_13_0_architecture_system_user_prompt_separation
    options = {
      subject: { "content" => "def test_method; puts 'hello'; end" },
      context: "project",
      auto_execute: false
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"
    assert result[:session_dir], "Should have session directory"

    session_dir = result[:session_dir]

    # Verify v0.13.0 session structure
    assert File.exist?(File.join(session_dir, "system.context.md")), "Should have system.context.md"
    assert File.exist?(File.join(session_dir, "system.prompt.md")), "Should have system.prompt.md"
    assert File.exist?(File.join(session_dir, "user.context.md")), "Should have user.context.md"
    assert File.exist?(File.join(session_dir, "user.prompt.md")), "Should have user.prompt.md"
    assert File.exist?(File.join(session_dir, "subject.md")), "Should have subject.md"
    assert File.exist?(File.join(session_dir, "metadata.yml")), "Should have metadata.yml"

    # Verify system prompt has proper structure
    system_prompt_content = File.read(File.join(session_dir, "system.prompt.md"))
    refute_empty system_prompt_content, "System prompt should not be empty"

    # Verify user prompt has proper structure
    user_prompt_content = File.read(File.join(session_dir, "user.prompt.md"))
    refute_empty user_prompt_content, "User prompt should not be empty"

    # Verify metadata reflects new architecture
    metadata_content = File.read(File.join(session_dir, "metadata.yml"))
    assert metadata_content.include?("system_prompt_size"), "Metadata should include system_prompt_size"
    assert metadata_content.include?("user_prompt_size"), "Metadata should include user_prompt_size"
  end

  def test_create_cache_directory
    cache_dir = @manager.send(:create_cache_directory)

    assert_equal File.join(Dir.pwd, ".cache", "ace-review", "sessions"), cache_dir
    assert Dir.exist?(cache_dir)
  end

  def test_copy_to_release
    # Create a mock review file
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    review_file = File.join(session_dir, "review.md")
    File.write(review_file, "# Review Report\n\nThis is a test review.")

    review_data = {
      model: "gpt-4",
      preset: "pr"
    }

    # Mock preset manager to return a release base path
    preset_manager_mock = Minitest::Mock.new
    preset_manager_mock.expect(:review_base_path, @temp_dir)

    @manager.instance_variable_set(:@preset_manager, preset_manager_mock)

    release_path = @manager.send(:copy_to_release, session_dir, review_data)

    refute_nil release_path
    assert File.exist?(release_path)
    assert_match(/review-report-gpt-4-\d{8}-\d{6}\.md/, File.basename(release_path))

    release_content = File.read(release_path)
    assert_match(/# Review Report/, release_content)

    preset_manager_mock.verify
  end

  def test_copy_to_release_without_review_file
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    review_data = {
      model: "gpt-4",
      preset: "pr"
    }

    # Mock preset manager
    preset_manager_mock = Minitest::Mock.new
    preset_manager_mock.expect(:review_base_path, @temp_dir)

    @manager.instance_variable_set(:@preset_manager, preset_manager_mock)

    release_path = @manager.send(:copy_to_release, session_dir, review_data)

    assert_nil release_path

    preset_manager_mock.verify
  end

  def test_execute_review_with_invalid_preset
    options = {
      preset: "nonexistent-preset",
      subject: { "content" => "def test; end" },
      auto_execute: false
    }

    result = @manager.execute_review(options)

    refute result[:success]
    assert_match(/Preset 'nonexistent-preset' not found/, result[:error])
  end

  def test_execute_review_with_no_subject
    options = {
      subject: nil,
      auto_execute: false
    }

    result = @manager.execute_review(options)

    refute result[:success]
    assert_equal "No code to review", result[:error]
  end

  def test_backward_compatibility_without_cache_dir
    # Test that existing code still works
    options = {
      subject: { "content" => "def test; end" },
      auto_execute: false
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"
    assert result[:session_dir], "Should have session directory"

    # Should create cache directory automatically
    cache_dir = File.join(Dir.pwd, ".cache", "ace-review", "sessions")
    assert Dir.exist?(cache_dir), "Cache directory should be created"
  end
end
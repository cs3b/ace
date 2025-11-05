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

    # Check that session files are created without .tmp extensions
    assert File.exist?(File.join(result[:session_dir], "prompt-system.md"))
    assert File.exist?(File.join(result[:session_dir], "prompt-user.md"))
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
    assert File.exist?(File.join(result[:session_dir], "prompt-system.md"))
    assert File.exist?(File.join(result[:session_dir], "prompt-user.md"))
  end

  def test_split_and_save_prompts_with_yaml_separator
    prompt = <<~PROMPT
      You are a code reviewer.
      ---
      Please review the following code:
    PROMPT

    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    @manager.send(:split_and_save_prompts, session_dir, prompt)

    system_file = File.join(session_dir, "prompt-system.md")
    user_file = File.join(session_dir, "prompt-user.md")

    assert File.exist?(system_file)
    assert File.exist?(user_file)

    system_content = File.read(system_file)
    user_content = File.read(user_file)

    assert_match(/You are a code reviewer/, system_content)
    assert_match(/Please review the following code/, user_content)
  end

  def test_split_and_save_prompts_with_double_newline
    prompt = "You are a code reviewer.\n\nPlease review the following code:"

    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    @manager.send(:split_and_save_prompts, session_dir, prompt)

    system_file = File.join(session_dir, "prompt-system.md")
    user_file = File.join(session_dir, "prompt-user.md")

    system_content = File.read(system_file)
    user_content = File.read(user_file)

    assert_match(/You are a code reviewer/, system_content)
    assert_match(/Please review the following code/, user_content)
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
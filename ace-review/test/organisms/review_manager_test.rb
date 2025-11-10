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

    # Check that session files are created with v0.14.0 architecture (ace-context workflow)
    assert File.exist?(File.join(result[:session_dir], "system.prompt.md"))
    assert File.exist?(File.join(result[:session_dir], "user.prompt.md"))
    assert File.exist?(File.join(result[:session_dir], "system.context.md"))
    assert File.exist?(File.join(result[:session_dir], "user.context.md"))
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

      # Check that context is handled via ace-context workflow
      session_dir = result[:session_dir]
      system_context_file = File.join(session_dir, "system.context.md")
      assert File.exist?(system_context_file), "system.context.md should be created"

      # The context should be embedded in the system.context.md frontmatter
      system_context_content = File.read(system_context_file)
      assert_match(/presets/, system_context_content)
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

    # Verify v0.14.0 session structure (ace-context workflow)
    assert File.exist?(File.join(session_dir, "system.context.md")), "Should have system.context.md"
    assert File.exist?(File.join(session_dir, "system.prompt.md")), "Should have system.prompt.md"
    assert File.exist?(File.join(session_dir, "user.context.md")), "Should have user.context.md"
    assert File.exist?(File.join(session_dir, "user.prompt.md")), "Should have user.prompt.md"
    assert File.exist?(File.join(session_dir, "metadata.yml")), "Should have metadata.yml"
    # Note: subject.md is no longer created - subject content is handled via ace-context workflow

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

  # Tests for instructions-based section support
  def test_instructions_format_detection
    # Test format detection with instructions config
    config_with_instructions = {
      instructions: {
        base: "prompt://base/system",
        context: {
          sections: {
            format: {
              title: "Format Guidelines",
              files: ["prompt://format/standard"]
            }
          }
        }
      }
    }

    assert @manager.send(:uses_instructions_format?, config_with_instructions),
           "Should detect instructions format"

    # Test format detection with legacy system_prompt config
    config_with_system_prompt = {
      system_prompt: {
        base: "prompt://base/system",
        format: "prompt://format/standard"
      }
    }

    refute @manager.send(:uses_instructions_format?, config_with_system_prompt),
           "Should not detect instructions format for system_prompt"

    # Test format detection with neither
    config_empty = {}

    refute @manager.send(:uses_instructions_format?, config_empty),
           "Should not detect instructions format for empty config"
  end

  def test_system_context_file_creation_with_instructions
    # Create a temporary session directory
    session_dir = File.join(@temp_dir, "test_session")
    FileUtils.mkdir_p(session_dir)

    instructions_config = {
      base: "prompt://base/system",
      context: {
        sections: {
          format: {
            title: "Format Guidelines",
            description: "Output formatting and structure guidelines",
            files: ["prompt://format/standard"]
          },
          guidelines: {
            title: "Review Guidelines",
            description: "Communication style and visual indicators",
            files: ["prompt://guidelines/tone", "prompt://guidelines/icons"]
          },
          project_context: {
            title: "Project Context",
            description: "Project information and background",
            presets: ["project"]
          }
        }
      }
    }

    context_config = "project"

    # Call the new method
    system_context_path = @manager.send(
      :create_system_context_file_with_instructions,
      session_dir,
      instructions_config,
      context_config
    )

    assert_equal File.join(session_dir, "system.context.md"), system_context_path
    assert File.exist?(system_context_path), "system.context.md should be created"

    # Read and verify content
    content = File.read(system_context_path)

    # Should contain YAML frontmatter with sections
    assert_match(/^---/, content, "Should start with YAML frontmatter")
    assert_match(/sections:/, content, "Should contain sections in frontmatter")
    assert_match(/format:/, content, "Should contain format section")
    assert_match(/guidelines:/, content, "Should contain guidelines section")
    assert_match(/project_context:/, content, "Should contain project_context section")

    # Should preserve project context preset
    assert_match(/presets:\s*\n\s*-\s*project/, content, "Should include project preset")

    # Should contain base content after frontmatter
    assert_match(/---\s*\n\s*$/, content, "Should end frontmatter and have base content area")
  end

  def test_system_context_file_creation_with_instructions_and_additional_context
    session_dir = File.join(@temp_dir, "test_session_with_ctx")
    FileUtils.mkdir_p(session_dir)

    instructions_config = {
      base: "prompt://base/system",
      context: {
        sections: {
          test_section: {
            title: "Test Section",
            files: ["README.md"]
          }
        }
      }
    }

    # Test with additional context config
    context_config = { "presets" => ["base", "team"] }

    system_context_path = @manager.send(
      :create_system_context_file_with_instructions,
      session_dir,
      instructions_config,
      context_config
    )

    content = File.read(system_context_path)

    # Should merge additional presets
    assert_match(/presets:\s*\n\s*-\s*base\s*\n\s*-\s*team/, content,
                  "Should merge additional context presets")
  end

  def test_instructions_format_integration_in_compose_review_prompt
    # Create a mock config directly instead of using preset manager
    config = {
      "description" => "Test instructions preset",
      "instructions" => {
        "base" => "prompt://base/system",
        "context" => {
          "sections" => {
            "format" => {
              "title" => "Format Guidelines",
              "files" => ["prompt://format/standard"]
            }
          }
        }
      },
      "context" => "project",
      "model" => "test-model"
    }

    session_dir = File.join(@temp_dir, "integration_test")
    FileUtils.mkdir_p(session_dir)

    # Test the integration in compose_review_prompt
    result = @manager.send(
      :compose_review_prompt,
      config,
      {}, # context
      {}, # subject
      {}, # subject_config
      session_dir
    )

    assert result[:success], "compose_review_prompt should succeed with instructions format"

    # Verify system.context.md was created with sections
    system_context_file = File.join(session_dir, "system.context.md")
    assert File.exist?(system_context_file), "system.context.md should exist"

    content = File.read(system_context_file)
    assert_match(/sections:/, content, "Should contain sections in frontmatter")
    assert_match(/format:/, content, "Should contain format section")
  end

  def test_backward_compatibility_with_system_prompt_format
    # Test that system_prompt format still works (legacy compatibility)
    session_dir = File.join(@temp_dir, "legacy_test")
    FileUtils.mkdir_p(session_dir)

    system_prompt_config = {
      "base" => "prompt://base/system",
      "format" => "prompt://format/standard",
      "focus" => ["prompt://focus/ruby", "prompt://focus/testing"],
      "guidelines" => ["prompt://guidelines/tone"]
    }

    context_config = "project"

    # Call the legacy method
    system_context_path = @manager.send(
      :create_system_context_file,
      session_dir,
      system_prompt_config,
      context_config
    )

    assert_equal File.join(session_dir, "system.context.md"), system_context_path
    assert File.exist?(system_context_path), "system.context.md should be created"

    # Read and verify content
    content = File.read(system_context_path)

    # Should contain YAML frontmatter with files (not sections)
    assert_match(/^---/, content, "Should start with YAML frontmatter")
    assert_match(/files:/, content, "Should contain files in frontmatter")
    assert_match(/prompt:\/\/format\/standard/, content, "Should contain format prompt")
    assert_match(/prompt:\/\/focus\/ruby/, content, "Should contain focus prompts")
    assert_match(/prompt:\/\/guidelines\/tone/, content, "Should contain guidelines prompts")

    # Should NOT contain sections (legacy format)
    refute_match(/sections:/, content, "Legacy format should not contain sections")

    # Should preserve project context preset
    assert_match(/presets:\s*\n\s*-\s*project/, content, "Should include project preset")
  end

  def test_system_prompt_format_integration_in_compose_review_prompt
    # Test that system_prompt format works in the full workflow
    config = {
      "description" => "Test legacy preset",
      "system_prompt" => {
        "base" => "prompt://base/system",
        "format" => "prompt://format/standard",
        "focus" => ["prompt://focus/ruby"],
        "guidelines" => ["prompt://guidelines/tone"]
      },
      "context" => "project",
      "model" => "test-model"
    }

    session_dir = File.join(@temp_dir, "legacy_integration_test")
    FileUtils.mkdir_p(session_dir)

    # Test the integration in compose_review_prompt
    result = @manager.send(
      :compose_review_prompt,
      config,
      {}, # context
      {}, # subject
      {}, # subject_config
      session_dir
    )

    assert result[:success], "compose_review_prompt should succeed with system_prompt format"

    # Verify system.context.md was created with files (not sections)
    system_context_file = File.join(session_dir, "system.context.md")
    assert File.exist?(system_context_file), "system.context.md should exist"

    content = File.read(system_context_file)
    refute_match(/sections:/, content, "Legacy format should not contain sections")
    assert_match(/files:/, content, "Legacy format should contain files")
    assert_match(/prompt:\/\/format\/standard/, content, "Should contain format prompt")
  end
end
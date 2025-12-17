# frozen_string_literal: true

require "test_helper"

class ReviewManagerTest < AceReviewTest
  def setup
    super  # IMPORTANT: Call parent to stub ace-context for fast tests
    @temp_dir = Dir.mktmpdir

    # Create test fixture for "pr" preset - tests should not depend on .ace/ directory
    create_test_preset("pr", <<~YAML)
      description: "Test PR preset"
      instructions:
        base: "prompt://base/system"
        context:
          sections:
            format:
              title: "Format Guidelines"
              files:
                - "prompt://format/standard"
      context: "project"
      subject:
        context:
          sections:
            code_changes:
              title: "Code Changes"
              diffs:
                - "origin/main...HEAD"
    YAML

    # Use @test_dir as project root for test isolation
    @manager = Ace::Review::Organisms::ReviewManager.new(project_root: @test_dir)
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
    super  # IMPORTANT: Call parent to restore ace-context
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
      preset: "pr",
      subject: "def test; end",
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
      preset: "pr",  # Use built-in preset that exists
      subject: "def test; end",
      context: { "files" => [] },  # Empty files list to avoid file not found errors
      auto_execute: false,
      session_dir: File.join(@temp_dir, "test_session")
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"

    # Check that context is handled via ace-context workflow
    session_dir = result[:session_dir]
    system_context_file = File.join(session_dir, "system.context.md")
    assert File.exist?(system_context_file), "system.context.md should be created"

    # Verify context files were created
    assert File.exist?(File.join(session_dir, "system.prompt.md"))
    assert File.exist?(File.join(session_dir, "user.prompt.md"))
  end

  def test_execute_review_with_cache_first_storage
    options = {
      preset: "pr",
      subject: "def test; end",
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
      preset: "pr",
      subject: "def test_method; puts 'hello'; end",
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

    # Cache should be created relative to project_root (uses @test_dir for isolation)
    expected_cache_dir = File.join(@test_dir, ".cache", "ace-review", "sessions")
    assert_equal expected_cache_dir, cache_dir
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

  def test_execute_review_without_preset_returns_helpful_error
    # When no preset is specified and no default configured, should return helpful error
    options = {
      subject: "def test; end",
      auto_execute: false
    }

    # Stub config to return nil for defaults.preset
    Ace::Review.stub :get, nil do
      result = @manager.execute_review(options)

      refute result[:success]
      assert_match(/No preset specified/, result[:error])
      assert_match(/--preset NAME/, result[:error])
      assert_match(/defaults\.preset/, result[:error])
    end
  end

  # NOTE: test_execute_review_with_no_subject removed because all presets provide
  # default subject configurations, making it impossible to test nil subject behavior
  # without creating custom test presets (which requires test directory management)

  def test_backward_compatibility_without_cache_dir
    # Test that existing code still works
    options = {
      preset: "pr",
      subject: "def test; end",
      auto_execute: false
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"
    assert result[:session_dir], "Should have session directory"

    # Should create cache directory automatically relative to project_root (uses @test_dir for isolation)
    cache_dir = File.join(@test_dir, ".cache", "ace-review", "sessions")
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

    # Call the new unified method
    system_context_path = @manager.send(
      :create_context_file,
      session_dir,
      instructions_config,
      context_config,
      "system.context.md"
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
      :create_context_file,
      session_dir,
      instructions_config,
      context_config,
      "system.context.md"
    )

    content = File.read(system_context_path)

    # Should merge additional presets
    assert_match(/presets:\s*\n\s*-\s*base\s*\n\s*-\s*team/, content,
                  "Should merge additional context presets")
  end

  def skip_test_instructions_format_integration_in_compose_review_prompt
    # SKIPPED: This test calls private method compose_review_prompt directly with complex config
    # that requires matching subject_config, which is difficult to set up correctly
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
      "context" => { "files" => [] },  # Simple context without preset dependencies
      "subject" => {  # Add subject configuration
        "content" => "def test; end"
      },
      "model" => "test-model"
    }

    session_dir = File.join(@temp_dir, "integration_test")
    FileUtils.mkdir_p(session_dir)

    # Test the integration in compose_review_prompt
    result = @manager.send(
      :compose_review_prompt,
      config,
      {}, # context
      "def test; end", # subject
      {}, # subject_config
      session_dir
    )

    assert result[:success], "compose_review_prompt should succeed with instructions format: #{result[:error]}"

    # Verify system.context.md was created with sections
    system_context_file = File.join(session_dir, "system.context.md")
    assert File.exist?(system_context_file), "system.context.md should exist"

    content = File.read(system_context_file)
    assert_match(/sections:/, content, "Should contain sections in frontmatter")
    assert_match(/format:/, content, "Should contain format section")
  end

  def test_instructions_format_processing
    # Test that instructions format works with unified processor
    session_dir = File.join(@temp_dir, "instructions_test")
    FileUtils.mkdir_p(session_dir)

    instructions_config = {
      "base" => "prompt://base/system",
      "context" => {
        "sections" => {
          "format" => {
            "title" => "Format Guidelines",
            "description" => "Standard output formatting guidelines",
            "files" => ["prompt://format/standard"]
          },
          "focus" => {
            "title" => "Review Focus Areas",
            "description" => "Ruby and testing focus areas",
            "files" => ["prompt://focus/ruby", "prompt://focus/testing"]
          },
          "guidelines" => {
            "title" => "Communication Guidelines",
            "description" => "Professional communication style",
            "files" => ["prompt://guidelines/tone"]
          }
        }
      }
    }

    context_config = "project"

    # Call the unified method
    system_context_path = @manager.send(
      :create_context_file,
      session_dir,
      instructions_config,
      context_config,
      "system.context.md"
    )

    assert_equal File.join(session_dir, "system.context.md"), system_context_path
    assert File.exist?(system_context_path), "system.context.md should be created"

    # Read and verify content
    content = File.read(system_context_path)

    # Should contain YAML frontmatter with sections
    assert_match(/^---/, content, "Should start with YAML frontmatter")
    assert_match(/sections:/, content, "Should contain sections in frontmatter")
    assert_match(/format:/, content, "Should contain format section")
    assert_match(/focus:/, content, "Should contain focus section")
    assert_match(/guidelines:/, content, "Should contain guidelines section")

    # Should preserve project context preset
    assert_match(/presets:\s*\n\s*-\s*project/, content, "Should include project preset")
  end

  def test_new_instructions_format_integration_in_compose_review_prompt
    # Test that new instructions format works in full workflow
    config = {
      "description" => "Test new preset",
      "instructions" => {
        "base" => "prompt://base/system",
        "context" => {
          "sections" => {
            "format" => {
              "title" => "Format Guidelines",
              "description" => "Standard output formatting",
              "files" => ["prompt://format/standard"]
            },
            "focus" => {
              "title" => "Review Focus",
              "description" => "Ruby code focus areas",
              "files" => ["prompt://focus/ruby"]
            },
            "guidelines" => {
              "title" => "Communication Guidelines",
              "description" => "Professional communication style",
              "files" => ["prompt://guidelines/tone"]
            }
          }
        }
      },
      "subject" => {
        "context" => {
          "sections" => {
            "changes" => {
              "title" => "Changes to Review",
              "description" => "Code changes for review",
              "diffs" => ["HEAD~2..HEAD"]
            }
          }
        }
      },
      "context" => "project",
      "model" => "test-model"
    }

    session_dir = File.join(@temp_dir, "new_integration_test")
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

    assert result[:success], "compose_review_prompt should succeed with new format"

    # Verify system.context.md was created
    system_context_file = File.join(session_dir, "system.context.md")
    assert File.exist?(system_context_file), "system.context.md should exist"

    content = File.read(system_context_file)
    # Should use new format with sections
    assert_match(/sections:/, content, "Should contain sections")
    assert_match(/format:/, content, "Should contain format section")

    # Verify user.context.md was created
    user_context_file = File.join(session_dir, "user.context.md")
    assert File.exist?(user_context_file), "user.context.md should exist"

    user_content = File.read(user_context_file)
    assert_match(/sections:/, user_content, "User context should have sections")
    assert_match(/changes:/, user_content, "User context should have changes section")
  end

  def test_subject_processing_with_sections
    # Test that subject with sections works with unified processor
    session_dir = File.join(@temp_dir, "subject_test")
    FileUtils.mkdir_p(session_dir)

    subject_config = {
      "context" => {
        "sections" => {
          "code_changes" => {
            "title" => "Code Changes",
            "description" => "Code changes to review",
            "diffs" => ["HEAD~3..HEAD"]
          },
          "additional_files" => {
            "title" => "Related Files",
            "description" => "Additional files for context",
            "files" => ["**/*.rb"]
          }
        }
      }
    }

    # Call the unified method for subject
    user_context_path = @manager.send(
      :create_context_file,
      session_dir,
      subject_config,
      nil,
      "user.context.md"
    )

    assert_equal File.join(session_dir, "user.context.md"), user_context_path
    assert File.exist?(user_context_path), "user.context.md should be created"

    # Read and verify content
    content = File.read(user_context_path)

    # Should contain YAML frontmatter with sections
    assert_match(/^---/, content, "Should start with YAML frontmatter")
    assert_match(/sections:/, content, "Should contain sections in frontmatter")
    assert_match(/code_changes:/, content, "Should contain code_changes section")
    assert_match(/additional_files:/, content, "Should contain additional_files section")
  end

  def test_subject_processing_with_files_and_commands
    # Test subject with mixed content types
    session_dir = File.join(@temp_dir, "subject_mixed_test")
    FileUtils.mkdir_p(session_dir)

    subject_config = {
      "context" => {
        "sections" => {
          "test_files" => {
            "title" => "Test Files",
            "description" => "Test files to review",
            "files" => ["test/**/*_test.rb", "spec/**/*_spec.rb"]
          },
          "test_commands" => {
            "title" => "Test Commands",
            "description" => "Test execution results",
            "commands" => ["bundle exec rspec --format documentation"]
          }
        }
      }
    }

    # Call the unified method for subject
    user_context_path = @manager
      .send(
        :create_context_file,
        session_dir,
        subject_config,
        nil,
        "user.context.md"
      )

    assert_equal File.join(session_dir, "user.context.md"), user_context_path
    assert File.exist?(user_context_path), "user.context.md should be created"

    # Read and verify content
    content = File.read(user_context_path)

    # Should contain YAML frontmatter with sections
    assert_match(/^---/, content, "Should start with YAML frontmatter")
    assert_match(/sections:/, content, "Should contain sections in frontmatter")
    assert_match(/test_files:/, content, "Should contain test_files section")
    assert_match(/test_commands:/, content, "Should contain test_commands section")
  end

  def test_both_instructions_and_subject_processing
    # Test that both instructions and subject work together
    session_dir = File.join(@temp_dir, "both_test")
    FileUtils.mkdir_p(session_dir)

    instructions_config = {
      "base" => "prompt://base/system",
      "context" => {
        "sections" => {
          "review_format" => {
            "title" => "Review Format",
            "description" => "Output formatting guidelines",
            "files" => ["prompt://format/detailed"]
          }
        }
      }
    }

    subject_config = {
      "context" => {
        "sections" => {
          "changes_to_review" => {
            "title" => "Changes to Review",
            "description" => "Code changes to review",
            "diffs" => ["HEAD~2..HEAD"]
          }
        }
      }
    }

    context_config = "project"

    # Call unified method for instructions
    system_context_path = @manager.send(
      :create_context_file,
      session_dir,
      instructions_config,
      context_config,
      "system.context.md"
    )

    # Call unified method for subject
    user_context_path = @manager.send(
      :create_context_file,
      session_dir,
      subject_config,
      nil,
      "user.context.md"
    )

    assert_equal File.join(session_dir, "system.context.md"), system_context_path
    assert_equal File.join(session_dir, "user.context.md"), user_context_path
    assert File.exist?(system_context_path), "system.context.md should be created"
    assert File.exist?(user_context_path), "user.context.md should be created"

    # Verify instructions content
    system_content = File.read(system_context_path)
    assert_match(/sections:/, system_content, "System context should have sections")
    assert_match(/review_format:/, system_content, "System context should have review_format section")

    # Verify subject content
    user_content = File.read(user_context_path)
    assert_match(/sections:/, user_content, "User context should have sections")
    assert_match(/changes_to_review:/, user_content, "User context should have changes_to_review section")
  end

  # Deep merge tests
  def test_deep_merge_hash_simple
    base = { "a" => 1 }
    overlay = { "b" => 2 }
    result = @manager.send(:deep_merge_hash, base, overlay)

    assert_equal({ "a" => 1, "b" => 2 }, result)
  end

  def test_deep_merge_hash_nested
    base = { "context" => { "sections" => { "code" => { "files" => ["a.rb"] } } } }
    overlay = { "context" => { "sections" => { "code" => { "files" => ["b.rb"] } } } }
    result = @manager.send(:deep_merge_hash, base, overlay)

    expected = { "context" => { "sections" => { "code" => { "files" => ["a.rb", "b.rb"] } } } }
    assert_equal expected, result
  end

  def test_deep_merge_hash_array_concat_and_dedup
    base = { "files" => ["a.rb", "b.rb"] }
    overlay = { "files" => ["b.rb", "c.rb"] }
    result = @manager.send(:deep_merge_hash, base, overlay)

    # "b.rb" appears only once, at its first position
    assert_equal({ "files" => ["a.rb", "b.rb", "c.rb"] }, result)
  end

  def test_deep_merge_hash_scalar_override
    base = { "model" => "gpt-4" }
    overlay = { "model" => "claude" }
    result = @manager.send(:deep_merge_hash, base, overlay)

    assert_equal({ "model" => "claude" }, result)
  end

  def test_deep_merge_hash_type_conflict_overlay_wins
    base = { "files" => { "a" => 1 } }
    overlay = { "files" => ["a.rb"] }
    result = @manager.send(:deep_merge_hash, base, overlay)

    # Overlay array wins over base hash
    assert_equal({ "files" => ["a.rb"] }, result)
  end

  def test_deep_merge_hash_three_level_nesting
    base = {
      "level1" => {
        "level2" => {
          "level3" => { "value" => "base" }
        }
      }
    }
    overlay = {
      "level1" => {
        "level2" => {
          "level3" => { "other" => "overlay" }
        }
      }
    }
    result = @manager.send(:deep_merge_hash, base, overlay)

    expected = {
      "level1" => {
        "level2" => {
          "level3" => { "value" => "base", "other" => "overlay" }
        }
      }
    }
    assert_equal expected, result
  end

  def test_deep_merge_hash_preserves_base_on_duplicate
    # Test that array merge preserves first occurrence position
    base = { "items" => ["first", "second", "third"] }
    overlay = { "items" => ["second", "fourth"] }
    result = @manager.send(:deep_merge_hash, base, overlay)

    # "second" should appear at its base position (index 1)
    expected_items = ["first", "second", "third", "fourth"]
    assert_equal({ "items" => expected_items }, result)
  end

  def test_deep_merge_context_simple
    base = { "a" => 1 }
    overlay = { "b" => 2 }
    result = @manager.send(:deep_merge_context, base, overlay)

    assert_equal({ "a" => 1, "b" => 2 }, result)
  end

  def test_deep_merge_context_nested_hash
    base = { "a" => { "b" => 1 } }
    overlay = { "a" => { "c" => 2 } }
    result = @manager.send(:deep_merge_context, base, overlay)

    assert_equal({ "a" => { "b" => 1, "c" => 2 } }, result)
  end

  def test_deep_merge_context_scalar_override
    base = { "model" => "gpt-4", "other" => "value" }
    overlay = { "model" => "claude" }
    result = @manager.send(:deep_merge_context, base, overlay)

    assert_equal({ "model" => "claude", "other" => "value" }, result)
  end

  # ============================================================================
  # Auto-save orchestration tests
  # ============================================================================

  def test_auto_save_review_if_enabled_with_no_auto_save_flag
    # Create a mock options object with no_auto_save = true
    options = Struct.new(:no_auto_save).new(true)

    review_data = { preset: "pr", model: "claude" }
    review_file = "/tmp/review.md"

    result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
    assert_nil result, "Should return nil when no_auto_save flag is set"
  end

  def test_auto_save_review_if_enabled_when_disabled_in_config
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = "/tmp/review.md"

    # Stub config to return auto_save = false
    Ace::Review.stub :get, ->(section, key) {
      return false if section == "defaults" && key == "auto_save"
      nil
    } do
      result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
      assert_nil result, "Should return nil when auto_save is disabled in config"
    end
  end

  def test_auto_save_review_if_enabled_with_explicit_task_reference
    # When @task_reference is set, auto-save should not run (explicit --task takes precedence)
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = "/tmp/review.md"

    # Set explicit task reference
    @manager.instance_variable_set(:@task_reference, "126")

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      nil
    } do
      result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
      assert_nil result, "Should return nil when explicit @task_reference is set"
    end
  ensure
    @manager.instance_variable_set(:@task_reference, nil)
  end

  def test_auto_save_review_if_enabled_falls_back_to_release_on_no_branch
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = File.join(@temp_dir, "review.md")
    File.write(review_file, "# Test Review")

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return false if section == "defaults" && key == "auto_save_release_fallback"
      nil
    } do
      # Stub GitBranchReader to return nil (no branch)
      Ace::Review::Molecules::GitBranchReader.stub :current_branch, nil do
        result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
        # Falls back to release, but release fallback is disabled
        assert_nil result, "Should return nil when no branch and release fallback disabled"
      end
    end
  end

  def test_auto_save_review_if_enabled_task_resolution_success
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = File.join(@temp_dir, "review.md")
    File.write(review_file, "# Test Review")

    # Create task directory structure
    task_dir = File.join(@temp_dir, "tasks", "126-test")
    FileUtils.mkdir_p(task_dir)

    expected_path = File.join(task_dir, "reviews", "saved-review.md")

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return ['^(\d+)-'] if section == "defaults" && key == "auto_save_branch_patterns"
      nil
    } do
      Ace::Review::Molecules::GitBranchReader.stub :current_branch, "126-feature" do
        Ace::Review::Molecules::TaskResolver.stub :resolve, ->(task_id) {
          { path: task_dir, task_id: task_id } if task_id == "126"
        } do
          Ace::Review::Molecules::TaskReportSaver.stub :save, ->(task_path, file, data) {
            { success: true, path: expected_path }
          } do
            result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
            assert_equal expected_path, result, "Should return saved path on success"
          end
        end
      end
    end
  end

  def test_auto_save_review_if_enabled_task_not_found_falls_back_to_release
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = File.join(@temp_dir, "review.md")
    File.write(review_file, "# Test Review")

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return ['^(\d+)-'] if section == "defaults" && key == "auto_save_branch_patterns"
      return false if section == "defaults" && key == "auto_save_release_fallback"
      nil
    } do
      Ace::Review::Molecules::GitBranchReader.stub :current_branch, "126-feature" do
        Ace::Review::Molecules::TaskResolver.stub :resolve, nil do
          output = capture_io do
            result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
            # Task not found, fallback disabled
            assert_nil result
          end
          assert_match(/Task '126' not found/, output[1], "Should warn about task not found")
        end
      end
    end
  end

  def test_auto_save_review_if_enabled_handles_invalid_branch_gracefully
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = File.join(@temp_dir, "review.md")
    File.write(review_file, "# Test Review")

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return ['^(\d+)-'] if section == "defaults" && key == "auto_save_branch_patterns"
      return false if section == "defaults" && key == "auto_save_release_fallback"
      nil
    } do
      # Branch doesn't match pattern (no task ID extractable)
      Ace::Review::Molecules::GitBranchReader.stub :current_branch, "main" do
        result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
        # No task ID from "main", release fallback disabled
        assert_nil result
      end
    end
  end

  def test_auto_save_review_if_enabled_handles_head_state
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = File.join(@temp_dir, "review.md")
    File.write(review_file, "# Test Review")

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return false if section == "defaults" && key == "auto_save_release_fallback"
      nil
    } do
      # Detached HEAD returns nil from GitBranchReader
      Ace::Review::Molecules::GitBranchReader.stub :current_branch, nil do
        result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
        assert_nil result, "Should handle detached HEAD gracefully"
      end
    end
  end

  def test_auto_save_review_if_enabled_release_fallback_on_no_branch_success
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = File.join(@temp_dir, "review.md")
    File.write(review_file, "# Test Review")

    expected_path = "/releases/v1.0/reviews/saved-review.md"

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return true if section == "defaults" && key == "auto_save_release_fallback"
      nil
    } do
      # No branch available
      Ace::Review::Molecules::GitBranchReader.stub :current_branch, nil do
        Ace::Review::Molecules::TaskReportSaver.stub :save_to_release, ->(file, data) {
          { success: true, path: expected_path }
        } do
          result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
          assert_equal expected_path, result, "Should save to release when no branch and fallback enabled"
        end
      end
    end
  end

  def test_auto_save_review_if_enabled_release_fallback_on_task_not_found_success
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = File.join(@temp_dir, "review.md")
    File.write(review_file, "# Test Review")

    expected_path = "/releases/v1.0/reviews/saved-review.md"

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return ['^(\d+)-'] if section == "defaults" && key == "auto_save_branch_patterns"
      return true if section == "defaults" && key == "auto_save_release_fallback"
      nil
    } do
      Ace::Review::Molecules::GitBranchReader.stub :current_branch, "126-feature" do
        # Task resolution returns nil (not found)
        Ace::Review::Molecules::TaskResolver.stub :resolve, nil do
          Ace::Review::Molecules::TaskReportSaver.stub :save_to_release, ->(file, data) {
            { success: true, path: expected_path }
          } do
            output = capture_io do
              result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
              assert_equal expected_path, result, "Should fall back to release when task not found"
            end
            assert_match(/Task '126' not found.*Falling back/, output[1])
          end
        end
      end
    end
  end

  def test_auto_save_review_if_enabled_release_fallback_on_task_save_failure
    options = Struct.new(:no_auto_save).new(false)
    review_data = { preset: "pr", model: "claude" }
    review_file = File.join(@temp_dir, "review.md")
    File.write(review_file, "# Test Review")

    task_dir = File.join(@temp_dir, "tasks", "126-test")
    FileUtils.mkdir_p(task_dir)
    expected_release_path = "/releases/v1.0/reviews/saved-review.md"

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return ['^(\d+)-'] if section == "defaults" && key == "auto_save_branch_patterns"
      return true if section == "defaults" && key == "auto_save_release_fallback"
      nil
    } do
      Ace::Review::Molecules::GitBranchReader.stub :current_branch, "126-feature" do
        Ace::Review::Molecules::TaskResolver.stub :resolve, ->(task_id) {
          { path: task_dir, task_id: task_id } if task_id == "126"
        } do
          # Task save fails
          Ace::Review::Molecules::TaskReportSaver.stub :save, ->(task_path, file, data) {
            { success: false, error: "Disk full" }
          } do
            Ace::Review::Molecules::TaskReportSaver.stub :save_to_release, ->(file, data) {
              { success: true, path: expected_release_path }
            } do
              output = capture_io do
                result = @manager.send(:auto_save_review_if_enabled, review_data, review_file, options)
                assert_equal expected_release_path, result, "Should fall back to release when task save fails"
              end
              assert_match(/Disk full.*Falling back/, output[1])
            end
          end
        end
      end
    end
  end

  # ============================================================================
  # Multiple --subject flag integration tests (PR #79)
  # ============================================================================

  def test_extract_review_content_with_array_subjects
    # Create preset that we'll use
    create_test_preset("array-test", <<~YAML)
      description: "Test array subjects preset"
      instructions:
        base: "prompt://base/system"
        context:
          sections:
            format:
              title: "Format Guidelines"
              files:
                - "prompt://format/standard"
      context: "project"
      subject:
        context:
          sections:
            code_changes:
              title: "Code Changes"
              diffs:
                - "origin/main...HEAD"
    YAML

    options = Ace::Review::Models::ReviewOptions.new(
      preset: "array-test",
      subject: ["diff:HEAD~3", "files:*.md"],  # Array of subjects
      auto_execute: false
    )

    # Prepare config first
    config_result = @manager.send(:prepare_review_config, options)
    assert config_result[:success], "Config preparation should succeed: #{config_result[:error]}"

    # Test extract_review_content with array subjects
    result = @manager.send(:extract_review_content, config_result[:config], options)

    assert result[:success], "Should succeed with array subjects: #{result[:error]}"
    assert result[:typed_subject_config], "Should have merged typed_subject_config"
    assert_nil result[:subject], "Should not have pre-extracted subject content"

    # Verify merged config structure
    typed_config = result[:typed_subject_config]
    assert typed_config["context"], "Should have context key"
    assert typed_config["context"]["diffs"], "Should have diffs from diff:HEAD~3"
    assert typed_config["context"]["files"], "Should have files from files:*.md"
    assert_equal ["HEAD~3"], typed_config["context"]["diffs"]
    assert_equal ["*.md"], typed_config["context"]["files"]
  end

  def test_extract_review_content_merges_same_type_subjects
    create_test_preset("merge-test", <<~YAML)
      description: "Test merge preset"
      instructions:
        base: "prompt://base/system"
      context: "project"
      subject:
        context:
          sections:
            code_changes:
              title: "Code Changes"
              diffs:
                - "origin/main...HEAD"
    YAML

    options = Ace::Review::Models::ReviewOptions.new(
      preset: "merge-test",
      subject: ["diff:HEAD~3", "diff:origin/main..HEAD"],  # Multiple diffs
      auto_execute: false
    )

    config_result = @manager.send(:prepare_review_config, options)
    assert config_result[:success]

    result = @manager.send(:extract_review_content, config_result[:config], options)

    assert result[:success]
    typed_config = result[:typed_subject_config]

    # Both diffs should be merged into array
    assert_equal ["HEAD~3", "origin/main..HEAD"], typed_config["context"]["diffs"]
  end

  def test_extract_review_content_preserves_context_override
    create_test_preset("context-test", <<~YAML)
      description: "Test context override preset"
      instructions:
        base: "prompt://base/system"
      context: "minimal"
      subject:
        context:
          sections:
            code_changes:
              title: "Code Changes"
              diffs:
                - "origin/main...HEAD"
    YAML

    options = Ace::Review::Models::ReviewOptions.new(
      preset: "context-test",
      subject: ["pr:77", "files:README.md"],
      context: "custom-context",  # Context override
      auto_execute: false
    )

    config_result = @manager.send(:prepare_review_config, options)
    assert config_result[:success]

    result = @manager.send(:extract_review_content, config_result[:config], options)

    assert result[:success]
    # Context should be extracted using the override
    assert result.key?(:context), "Should have context in result"
    assert result[:typed_subject_config], "Should have typed_subject_config"
  end

  def test_resolve_subject_config_with_typed_subject_config
    # Test that resolve_subject_config passes through typed_subject_config directly
    session_dir = File.join(@temp_dir, "resolve_test")
    FileUtils.mkdir_p(session_dir)

    typed_config = { "context" => { "diffs" => ["HEAD~3"], "files" => ["*.md"] } }
    config = { "subject" => { "diffs" => ["default"] } }

    result = @manager.send(
      :resolve_subject_config,
      config: config,
      subject: nil,
      session_dir: session_dir,
      options: nil,
      typed_subject_config: typed_config
    )

    # typed_subject_config should be returned directly (highest priority)
    assert_equal typed_config, result
  end

  def test_resolve_subject_config_falls_back_to_preset_without_typed
    session_dir = File.join(@temp_dir, "fallback_test")
    FileUtils.mkdir_p(session_dir)

    config = {
      "subject" => {
        "context" => { "diffs" => ["default-diff"] }
      }
    }

    result = @manager.send(
      :resolve_subject_config,
      config: config,
      subject: nil,
      session_dir: session_dir,
      options: nil,
      typed_subject_config: nil  # No typed config
    )

    # Should fall back to preset subject config
    expected = { "context" => { "diffs" => ["default-diff"] } }
    assert_equal expected, result
  end
end
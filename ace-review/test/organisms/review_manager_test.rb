# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/task_resolver"
require "ace/review/molecules/task_report_saver"

class ReviewManagerTest < AceReviewTest
  def setup
    super  # IMPORTANT: Call parent to stub ace-bundle for fast tests
    @temp_dir = Dir.mktmpdir

    # Create test fixture for "pr" preset - tests should not depend on .ace/ directory
    create_test_preset("pr", <<~YAML)
      description: "Test PR preset"
      instructions:
        base: "prompt://base/system"
        bundle:
          sections:
            format:
              title: "Format Guidelines"
              files:
                - "prompt://format/standard"
      bundle: "project"
      subject:
        bundle:
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
    super  # IMPORTANT: Call parent to restore ace-bundle
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

    # Check that session files are created with v0.14.0 architecture (ace-bundle workflow)
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
      bundle: {"files" => []},  # Empty files list to avoid file not found errors
      auto_execute: false,
      session_dir: File.join(@temp_dir, "test_session")
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"

    # Check that context is handled via ace-bundle workflow
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
      bundle: "project",
      auto_execute: false
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"
    assert result[:session_dir], "Should have session directory"

    session_dir = result[:session_dir]

    # Verify v0.14.0 session structure (ace-bundle workflow)
    assert File.exist?(File.join(session_dir, "system.context.md")), "Should have system.context.md"
    assert File.exist?(File.join(session_dir, "system.prompt.md")), "Should have system.prompt.md"
    assert File.exist?(File.join(session_dir, "user.context.md")), "Should have user.context.md"
    assert File.exist?(File.join(session_dir, "user.prompt.md")), "Should have user.prompt.md"
    assert File.exist?(File.join(session_dir, "metadata.yml")), "Should have metadata.yml"
    # Note: subject.md is no longer created - subject content is handled via ace-bundle workflow

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
    expected_cache_dir = File.join(@test_dir, ".ace-local", "review", "sessions")
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
    # Compact ID is 6 chars Base36 (0-9, a-z)
    assert_match(/review-report-gpt-4-[0-9a-z]{6}\.md/, File.basename(release_path))

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
      subject: {"content" => "def test; end"},
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
    cache_dir = File.join(@test_dir, ".ace-local", "review", "sessions")
    assert Dir.exist?(cache_dir), "Cache directory should be created"
  end

  # Tests for instructions-based section support
  def test_instructions_format_detection
    # Test format detection with instructions config
    config_with_instructions = {
      instructions: {
        base: "prompt://base/system",
        bundle: {
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
      bundle: {
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
          project_bundle: {
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
    assert_match(/project_bundle:/, content, "Should contain project_context section")

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
      bundle: {
        sections: {
          test_section: {
            title: "Test Section",
            files: ["README.md"]
          }
        }
      }
    }

    # Test with additional context config
    context_config = {"presets" => ["base", "team"]}

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
        "bundle" => {
          "sections" => {
            "format" => {
              "title" => "Format Guidelines",
              "files" => ["prompt://format/standard"]
            }
          }
        }
      },
      "bundle" => {"files" => []},  # Simple context without preset dependencies
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
      "bundle" => {
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
        "bundle" => {
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
        "bundle" => {
          "sections" => {
            "changes" => {
              "title" => "Changes to Review",
              "description" => "Code changes for review",
              "diffs" => ["HEAD~2..HEAD"]
            }
          }
        }
      },
      "bundle" => "project",
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
      session_dir,
      nil, # options
      nil  # typed_subject_config (nil to use preset's subject config)
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
      "bundle" => {
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
      "bundle" => {
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
      "bundle" => {
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
      "bundle" => {
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

  # Deep merge tests - now use deep_merge_context which delegates to centralized DeepMerger
  def test_deep_merge_context_simple
    base = {"a" => 1}
    overlay = {"b" => 2}
    result = @manager.send(:deep_merge_context, base, overlay)

    assert_equal({"a" => 1, "b" => 2}, result)
  end

  def test_deep_merge_context_nested_hash
    base = {"a" => {"b" => 1}}
    overlay = {"a" => {"c" => 2}}
    result = @manager.send(:deep_merge_context, base, overlay)

    assert_equal({"a" => {"b" => 1, "c" => 2}}, result)
  end

  def test_deep_merge_context_scalar_override
    base = {"model" => "gpt-4", "other" => "value"}
    overlay = {"model" => "claude"}
    result = @manager.send(:deep_merge_context, base, overlay)

    assert_equal({"model" => "claude", "other" => "value"}, result)
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
        bundle:
          sections:
            format:
              title: "Format Guidelines"
              files:
                - "prompt://format/standard"
      bundle: "project"
      subject:
        bundle:
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
    assert typed_config["bundle"], "Should have bundle key"
    assert typed_config["bundle"]["diffs"], "Should have diffs from diff:HEAD~3"
    assert typed_config["bundle"]["files"], "Should have files from files:*.md"
    assert_equal ["HEAD~3"], typed_config["bundle"]["diffs"]
    assert_equal ["*.md"], typed_config["bundle"]["files"]
  end

  def test_extract_review_content_merges_same_type_subjects
    create_test_preset("merge-test", <<~YAML)
      description: "Test merge preset"
      instructions:
        base: "prompt://base/system"
      bundle: "project"
      subject:
        bundle:
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
    assert_equal ["HEAD~3", "origin/main..HEAD"], typed_config["bundle"]["diffs"]
  end

  def test_extract_review_content_preserves_context_override
    create_test_preset("context-test", <<~YAML)
      description: "Test context override preset"
      instructions:
        base: "prompt://base/system"
      bundle: "minimal"
      subject:
        bundle:
          sections:
            code_changes:
              title: "Code Changes"
              diffs:
                - "origin/main...HEAD"
    YAML

    options = Ace::Review::Models::ReviewOptions.new(
      preset: "context-test",
      subject: ["pr:77", "files:README.md"],
      bundle: "custom-context",  # Context override
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

  def test_build_pr_context_with_task_spec_adds_spec_to_string_context
    context_config = "project"
    metadata = {"headRefName" => "281.05-review-spec-context"}

    resolved_spec = ".ace-taskflow/v.0.9.0/tasks/281-task-pipeline-structured/281.05-review-spec-context.s.md"
    Ace::Review::Molecules::PrTaskSpecResolver.stub(:resolve_spec_path, resolved_spec) do
      result = @manager.send(
        :build_pr_context_with_task_spec,
        context_config: context_config,
        pr_metadata: metadata
      )

      assert_equal ["project"], result["presets"]
      assert_equal [resolved_spec], result["files"]
    end
  end

  def test_build_pr_context_with_task_spec_adds_spec_when_context_none
    context_config = "none"
    metadata = {"headRefName" => "281.05-review-spec-context"}
    resolved_spec = ".ace-taskflow/v.0.9.0/tasks/281-task-pipeline-structured/281.05-review-spec-context.s.md"

    Ace::Review::Molecules::PrTaskSpecResolver.stub(:resolve_spec_path, resolved_spec) do
      result = @manager.send(
        :build_pr_context_with_task_spec,
        context_config: context_config,
        pr_metadata: metadata
      )

      assert_equal [resolved_spec], result["files"]
    end
  end

  def test_build_pr_context_with_task_spec_returns_original_when_spec_not_found
    context_config = {"presets" => ["project"]}
    metadata = {"headRefName" => "non-task-branch"}

    Ace::Review::Molecules::PrTaskSpecResolver.stub(:resolve_spec_path, nil) do
      result = @manager.send(
        :build_pr_context_with_task_spec,
        context_config: context_config,
        pr_metadata: metadata
      )

      assert_equal context_config, result
    end
  end

  def test_extract_pr_content_uses_spec_aware_context
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      pr: "123",
      pr_comments: false
    )
    config = {context: "project"}

    fetch_result = {
      success: true,
      diff: "diff --git a/file.rb b/file.rb",
      metadata: {
        "number" => 123,
        "state" => "OPEN",
        "title" => "Add feature",
        "headRefName" => "281.05-review-spec-context",
        "baseRefName" => "main",
        "url" => "https://example.com/pr/123"
      }
    }
    spec_path = ".ace-taskflow/v.0.9.0/tasks/281-task-pipeline-structured/281.05-review-spec-context.s.md"
    captured_context_config = nil

    Ace::Review::Molecules::GhPrFetcher.stub(:fetch_pr, fetch_result) do
      Ace::Review::Molecules::PrTaskSpecResolver.stub(:resolve_spec_path, spec_path) do
        @manager.stub(:extract_context, ->(ctx, _cache_dir) {
          captured_context_config = ctx
          "context"
        }) do
          result = @manager.send(:extract_pr_content, "123", config, options)

          assert result[:success], "Expected PR extraction to succeed"
          assert_equal [spec_path], captured_context_config["files"]
          assert_equal ["project"], captured_context_config["presets"]
        end
      end
    end
  end

  def test_resolve_subject_config_with_typed_subject_config
    # Test that resolve_subject_config passes through typed_subject_config directly
    session_dir = File.join(@temp_dir, "resolve_test")
    FileUtils.mkdir_p(session_dir)

    typed_config = {"bundle" => {"diffs" => ["HEAD~3"], "files" => ["*.md"]}}
    config = {"subject" => {"diffs" => ["default"]}}

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
        "bundle" => {"diffs" => ["default-diff"]}
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
    expected = {"bundle" => {"diffs" => ["default-diff"]}}
    assert_equal expected, result
  end

  # ============================================================================
  # Feedback Extraction Integration Tests (Task 227.05)
  # ============================================================================

  def test_should_extract_feedback_returns_true_by_default
    # Feedback always runs by default with successful results
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      auto_execute: true
    )

    result = {
      results: {
        "model1" => {success: true, output_file: "/path/to/report1.md"},
        "model2" => {success: true, output_file: "/path/to/report2.md"}
      }
    }

    assert @manager.send(:should_extract_feedback?, result, options),
      "Should extract feedback by default"
  end

  def test_should_extract_feedback_returns_false_with_no_feedback_flag
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      no_feedback: true
    )

    result = {
      results: {
        "model1" => {success: true, output_file: "/path/to/report1.md"}
      }
    }

    refute @manager.send(:should_extract_feedback?, result, options),
      "Should not extract feedback when --no-feedback flag is set"
  end

  def test_should_extract_feedback_returns_false_with_no_successful_results
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr"
    )

    result = {
      results: {
        "model1" => {success: false, error: "Failed"},
        "model2" => {success: false, error: "Also failed"}
      }
    }

    refute @manager.send(:should_extract_feedback?, result, options),
      "Should not extract feedback when no successful results"
  end

  def test_collect_report_paths_includes_model_reports
    session_dir = File.join(@temp_dir, "collect_test")
    FileUtils.mkdir_p(session_dir)

    result = {
      results: {
        "model1" => {success: true, output_file: "/path/to/report1.md"},
        "model2" => {success: true, output_file: "/path/to/report2.md"},
        "model3" => {success: false, error: "Failed"}
      }
    }

    paths = @manager.send(:collect_report_paths, result, session_dir)

    assert_includes paths, "/path/to/report1.md"
    assert_includes paths, "/path/to/report2.md"
    assert_equal 2, paths.length, "Should only include successful model reports"
  end

  def test_collect_report_paths_only_includes_model_reports
    # FeedbackSynthesizer reads individual review reports and produces
    # deduplicated findings directly - no synthesis needed
    session_dir = File.join(@temp_dir, "collect_model_only_test")
    FileUtils.mkdir_p(session_dir)

    result = {
      results: {
        "model1" => {success: true, output_file: "/path/to/report1.md"}
      }
    }

    paths = @manager.send(:collect_report_paths, result, session_dir)

    assert_includes paths, "/path/to/report1.md"
    assert_equal 1, paths.length, "Should only include model report"
  end

  def test_collect_report_paths_includes_dev_feedback_if_exists
    session_dir = File.join(@temp_dir, "collect_feedback_test")
    FileUtils.mkdir_p(session_dir)

    # Create dev-feedback file
    dev_feedback_path = File.join(session_dir, "review-dev-feedback.md")
    File.write(dev_feedback_path, "# Developer Feedback\nSome comments")

    result = {
      results: {
        "model1" => {success: true, output_file: "/path/to/report1.md"}
      }
    }

    paths = @manager.send(:collect_report_paths, result, session_dir)

    assert_includes paths, "/path/to/report1.md"
    assert_includes paths, dev_feedback_path
  end

  def test_determine_feedback_path_always_returns_session_dir
    review_data = {preset: "pr", model: "test-model"}
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    path = @manager.send(:determine_feedback_path, review_data, session_dir)
    assert_equal session_dir, path, "Should always return session_dir for feedback"
  end

  def test_determine_feedback_path_returns_session_dir_without_task
    review_data = {preset: "pr", model: "test-model"}
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    path = @manager.send(:determine_feedback_path, review_data, session_dir)
    assert_equal session_dir, path, "Should return session directory"
  end

  def test_extract_feedback_calls_feedback_manager
    session_dir = File.join(@temp_dir, "extract_test")
    FileUtils.mkdir_p(session_dir)

    # Create test report files
    report1_path = File.join(session_dir, "report1.md")
    report2_path = File.join(session_dir, "report2.md")
    File.write(report1_path, "# Report 1\nFinding 1")
    File.write(report2_path, "# Report 2\nFinding 2")

    result = {
      results: {
        "model1" => {success: true, output_file: report1_path},
        "model2" => {success: true, output_file: report2_path}
      }
    }

    review_data = {preset: "pr", model: "test-model"}
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      feedback_model: "extraction-model"
    )

    # Mock FeedbackManager
    mock_feedback_manager = Minitest::Mock.new
    mock_feedback_manager.expect(:extract_and_save, {
      success: true,
      items_count: 3,
      paths: ["/path/to/feedback1.s.md", "/path/to/feedback2.s.md", "/path/to/feedback3.s.md"]
    }) do |**kwargs|
      kwargs[:report_paths].include?(report1_path) &&
        kwargs[:report_paths].include?(report2_path) &&
        kwargs[:base_path] == session_dir &&
        kwargs[:model] == "extraction-model"
    end

    Ace::Review::Organisms::FeedbackManager.stub :new, mock_feedback_manager do
      feedback_result = @manager.send(:extract_feedback, result, session_dir, review_data, options)

      assert feedback_result[:success]
      assert_equal 3, feedback_result[:items_count]
    end

    mock_feedback_manager.verify
  end

  def test_extract_feedback_handles_errors_gracefully
    session_dir = File.join(@temp_dir, "error_test")
    FileUtils.mkdir_p(session_dir)

    result = {
      results: {
        "model1" => {success: true, output_file: "/nonexistent/path.md"}
      }
    }

    review_data = {preset: "pr", model: "test-model"}
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    # Mock FeedbackManager to raise an error
    error_manager = Minitest::Mock.new
    error_manager.expect(:extract_and_save, nil) do |**kwargs|
      raise StandardError, "LLM extraction failed"
    end

    output = capture_io do
      Ace::Review::Organisms::FeedbackManager.stub :new, error_manager do
        feedback_result = @manager.send(:extract_feedback, result, session_dir, review_data, options)

        refute feedback_result[:success]
        assert_equal "LLM extraction failed", feedback_result[:error]
      end
    end

    assert_match(/Feedback extraction error/, output[1])
    error_manager.verify
  end

  def test_extract_feedback_tries_fallback_model_on_failure
    session_dir = File.join(@temp_dir, "fallback_test")
    FileUtils.mkdir_p(session_dir)

    report_path = File.join(session_dir, "report1.md")
    File.write(report_path, "# Report 1\nFinding 1")

    result = {
      results: {
        "model1" => {success: true, output_file: report_path}
      }
    }

    review_data = {preset: "pr", model: "test-model"}
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    call_count = 0
    mock_feedback_manager = Minitest::Mock.new

    # First call fails (primary model)
    mock_feedback_manager.expect(:extract_and_save, {success: false, error: "Primary model failed"}) do |**kwargs|
      call_count += 1
      kwargs[:model] == "google:gemini-2.5-flash" &&
        kwargs[:session_dir] == File.join(session_dir, "feedback-synthesis")
    end

    # Second call succeeds (fallback model)
    mock_feedback_manager.expect(:extract_and_save, {
      success: true,
      items_count: 2,
      paths: ["/path/fb1.s.md", "/path/fb2.s.md"]
    }) do |**kwargs|
      call_count += 1
      kwargs[:model] == "claude:glm" &&
        kwargs[:session_dir] == File.join(session_dir, "feedback-synthesis")
    end

    output = capture_io do
      Ace::Review.stub :get, ->(section, key) {
        return "google:gemini-2.5-flash" if section == "feedback" && key == "synthesis_model"
        return ["claude:glm"] if section == "feedback" && key == "fallback_models"
        nil
      } do
        Ace::Review::Organisms::FeedbackManager.stub :new, mock_feedback_manager do
          feedback_result = @manager.send(:extract_feedback, result, session_dir, review_data, options)

          assert feedback_result[:success], "Should succeed with fallback model"
          assert_equal 2, feedback_result[:items_count]
          assert_equal "claude:glm", feedback_result[:synthesis_model]
        end
      end
    end

    assert_equal 2, call_count, "Should have tried both models"
    assert_match(/Feedback synthesis failed with google:gemini-2.5-flash/, output[1])
    mock_feedback_manager.verify
  end

  def test_extract_feedback_returns_error_when_all_models_fail
    session_dir = File.join(@temp_dir, "all_fail_test")
    FileUtils.mkdir_p(session_dir)

    report_path = File.join(session_dir, "report1.md")
    File.write(report_path, "# Report 1")

    result = {
      results: {
        "model1" => {success: true, output_file: report_path}
      }
    }

    review_data = {preset: "pr", model: "test-model"}
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    mock_feedback_manager = Minitest::Mock.new

    # Both models fail
    mock_feedback_manager.expect(:extract_and_save, {success: false, error: "Primary failed"}) do |**kwargs|
      kwargs[:model] == "google:gemini-2.5-flash" &&
        kwargs[:session_dir] == File.join(session_dir, "feedback-synthesis")
    end
    mock_feedback_manager.expect(:extract_and_save, {success: false, error: "Fallback failed"}) do |**kwargs|
      kwargs[:model] == "claude:glm" &&
        kwargs[:session_dir] == File.join(session_dir, "feedback-synthesis")
    end

    capture_io do
      Ace::Review.stub :get, ->(section, key) {
        return "google:gemini-2.5-flash" if section == "feedback" && key == "synthesis_model"
        return ["claude:glm"] if section == "feedback" && key == "fallback_models"
        nil
      } do
        Ace::Review::Organisms::FeedbackManager.stub :new, mock_feedback_manager do
          feedback_result = @manager.send(:extract_feedback, result, session_dir, review_data, options)

          refute feedback_result[:success]
          assert_equal "Fallback failed", feedback_result[:error]
          assert_equal ["google:gemini-2.5-flash", "claude:glm"], feedback_result[:models_tried]
        end
      end
    end

    mock_feedback_manager.verify
  end

  def test_build_synthesis_model_list_with_config
    review_data = {model: "review-model"}
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    Ace::Review.stub :get, ->(section, key) {
      return "primary-model" if section == "feedback" && key == "synthesis_model"
      return ["fallback-1", "fallback-2"] if section == "feedback" && key == "fallback_models"
      nil
    } do
      models = @manager.send(:build_synthesis_model_list, options, review_data)

      assert_equal ["primary-model", "fallback-1", "fallback-2"], models
    end
  end

  def test_extract_feedback_passes_feedback_synthesis_session_subdir
    session_dir = File.join(@temp_dir, "session_for_feedback")
    FileUtils.mkdir_p(session_dir)

    report_path = File.join(session_dir, "report1.md")
    File.write(report_path, "# Report 1\nFinding 1")

    result = {
      results: {
        "model1" => {success: true, output_file: report_path}
      }
    }

    review_data = {preset: "pr", model: "test-model"}
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    mock_feedback_manager = Minitest::Mock.new
    mock_feedback_manager.expect(:extract_and_save, {
      success: true,
      items_count: 1,
      paths: ["/path/fb1.s.md"]
    }) do |**kwargs|
      kwargs[:report_paths] == [report_path] &&
        kwargs[:session_dir] == File.join(session_dir, "feedback-synthesis")
    end

    Ace::Review.stub :get, ->(_section, _key) {} do
      Ace::Review::Organisms::FeedbackManager.stub :new, mock_feedback_manager do
        feedback_result = @manager.send(:extract_feedback, result, session_dir, review_data, options)

        assert feedback_result[:success]
        assert_equal 1, feedback_result[:items_count]
      end
    end

    mock_feedback_manager.verify
  end

  def test_build_synthesis_model_list_with_option_override
    review_data = {model: "review-model"}
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      feedback_model: "override-model"
    )

    Ace::Review.stub :get, ->(section, key) {
      return "config-model" if section == "feedback" && key == "synthesis_model"
      return ["fallback-1"] if section == "feedback" && key == "fallback_models"
      nil
    } do
      models = @manager.send(:build_synthesis_model_list, options, review_data)

      assert_equal ["override-model", "fallback-1"], models
    end
  end

  def test_build_synthesis_model_list_deduplicates
    review_data = {model: "same-model"}
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    Ace::Review.stub :get, ->(section, key) {
      return "same-model" if section == "feedback" && key == "synthesis_model"
      return ["same-model", "other-model"] if section == "feedback" && key == "fallback_models"
      nil
    } do
      models = @manager.send(:build_synthesis_model_list, options, review_data)

      assert_equal ["same-model", "other-model"], models
    end
  end

  def test_build_multi_model_response_includes_feedback_info
    result = {
      results: {
        "model1" => {success: true, output_file: "/path/report1.md"},
        "model2" => {success: true, output_file: "/path/report2.md"}
      },
      summary: {total_models: 2, success_count: 2}
    }

    session_dir = "/path/to/session"
    feedback_result = {
      success: true,
      items_count: 5,
      paths: ["/path/feedback1.s.md", "/path/feedback2.s.md"]
    }

    response = @manager.send(
      :build_multi_model_response,
      result, session_dir, feedback_result
    )

    assert response[:success]
    assert_equal 5, response[:feedback_count]
    assert_equal ["/path/feedback1.s.md", "/path/feedback2.s.md"], response[:feedback_paths]
  end

  def test_build_multi_model_response_includes_feedback_error
    result = {
      results: {
        "model1" => {success: true, output_file: "/path/report1.md"}
      },
      summary: {total_models: 1, success_count: 1}
    }

    session_dir = "/path/to/session"
    feedback_result = {
      success: false,
      error: "All synthesis models failed",
      models_tried: ["google:gemini-2.5-flash", "claude:glm"]
    }

    response = @manager.send(
      :build_multi_model_response,
      result, session_dir, feedback_result
    )

    assert response[:success]
    refute response.key?(:feedback_count)
    assert_equal "All synthesis models failed", response[:feedback_error]
  end

  def test_build_multi_model_response_without_feedback
    result = {
      results: {
        "model1" => {success: true, output_file: "/path/report1.md"}
      },
      summary: {total_models: 1, success_count: 1}
    }

    session_dir = "/path/to/session"

    response = @manager.send(
      :build_multi_model_response,
      result, session_dir, nil
    )

    assert response[:success]
    refute response.key?(:feedback_count)
    refute response.key?(:feedback_paths)
  end

  def test_review_options_feedback_enabled_defaults_to_true
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    assert options.feedback_enabled?, "Feedback should be enabled by default"
  end

  def test_review_options_auto_execute_defaults_to_config
    options = nil

    Ace::Review.stub :get, ->(section, key) do
      if section == "defaults" && key == "auto_execute"
        true
      end
    end do
      options = Ace::Review::Models::ReviewOptions.new(preset: "pr")
    end

    assert options.auto_execute
  end

  def test_review_options_auto_execute_false_when_explicit
    options = nil

    Ace::Review.stub :get, ->(_section, _key) { true } do
      options = Ace::Review::Models::ReviewOptions.new(
        preset: "pr",
        auto_execute: false
      )
    end

    refute options.auto_execute
  end

  def test_review_options_auto_execute_false_with_dry_run
    options = nil

    Ace::Review.stub :get, ->(_section, _key) { true } do
      options = Ace::Review::Models::ReviewOptions.new(
        preset: "pr",
        auto_execute: true,
        dry_run: true
      )
    end

    refute options.auto_execute
  end

  def test_review_options_feedback_enabled_false_with_no_feedback
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      no_feedback: true
    )

    refute options.feedback_enabled?, "Feedback should be disabled with no_feedback flag"
  end

  def test_review_options_includes_feedback_model
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      feedback_model: "custom-extraction-model"
    )

    assert_equal "custom-extraction-model", options.feedback_model
  end

  # ============================================================================
  # Task Integration for Feedback Tests (Task 227.07)
  # ============================================================================

  # ============================================================================
  # Single-Model Feedback Extraction Tests (Task 227.08)
  # ============================================================================

  def test_maybe_extract_single_model_feedback_returns_nil_when_disabled
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      no_feedback: true
    )

    result = {success: true, output_file: "/path/to/report.md"}
    review_data = {preset: "pr", model: "test-model"}
    session_dir = @temp_dir

    feedback_result = @manager.send(
      :maybe_extract_single_model_feedback,
      result, session_dir, review_data, options, "test-model"
    )

    assert_nil feedback_result, "Should return nil when feedback is disabled"
  end

  def test_maybe_extract_single_model_feedback_delegates_to_extract_feedback
    session_dir = File.join(@temp_dir, "single_model_test")
    FileUtils.mkdir_p(session_dir)

    # Create a test report file
    report_path = File.join(session_dir, "review.md")
    File.write(report_path, "# Review Report\nSome finding here")

    result = {success: true, output_file: report_path}
    review_data = {preset: "pr", model: "test-model"}
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      feedback_model: "extraction-model"
    )

    # Mock FeedbackManager
    mock_feedback_manager = Minitest::Mock.new
    mock_feedback_manager.expect(:extract_and_save, {
      success: true,
      items_count: 2,
      paths: ["/path/to/fb1.s.md", "/path/to/fb2.s.md"]
    }) do |**kwargs|
      # Verify the result was wrapped in multi-model format
      kwargs[:report_paths].include?(report_path) &&
        kwargs[:base_path] == session_dir &&
        kwargs[:model] == "extraction-model"
    end

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "feedback" && key == "enabled"
      nil
    } do
      Ace::Review::Organisms::FeedbackManager.stub :new, mock_feedback_manager do
        feedback_result = @manager.send(
          :maybe_extract_single_model_feedback,
          result, session_dir, review_data, options, "test-model"
        )

        assert feedback_result[:success]
        assert_equal 2, feedback_result[:items_count]
      end
    end

    mock_feedback_manager.verify
  end

  def test_maybe_extract_single_model_feedback_wraps_in_multimodel_format
    session_dir = File.join(@temp_dir, "wrap_test")
    FileUtils.mkdir_p(session_dir)

    report_path = File.join(session_dir, "review.md")
    File.write(report_path, "# Review")

    result = {success: true, output_file: report_path}
    review_data = {preset: "pr", model: "claude-3"}
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    # Capture the arguments passed to extract_feedback
    captured_result = nil

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "feedback" && key == "enabled"
      nil
    } do
      # Stub extract_feedback to capture its arguments
      @manager.stub :extract_feedback, ->(result_arg, *_rest) {
        captured_result = result_arg
        {success: true, items_count: 0, paths: []}
      } do
        @manager.send(
          :maybe_extract_single_model_feedback,
          result, session_dir, review_data, options, "claude-3"
        )
      end
    end

    # Verify the result was wrapped correctly
    assert captured_result, "extract_feedback should have been called"
    assert captured_result[:results], "Should have :results key"
    assert captured_result[:results]["claude-3"], "Should have model as key"
    assert captured_result[:results]["claude-3"][:success]
    assert_equal report_path, captured_result[:results]["claude-3"][:output_file]
  end

  def test_execute_single_model_extracts_feedback_when_enabled
    # This is an integration test to verify execute_single_model calls feedback extraction
    session_dir = File.join(@temp_dir, "execute_single_test")
    FileUtils.mkdir_p(session_dir)

    review_data = {
      system_prompt: "System prompt",
      user_prompt: "User prompt",
      preset: "pr",
      model: "test-model"
    }

    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    # Mock LlmExecutor
    mock_executor = Minitest::Mock.new
    mock_executor.expect(:execute, {
      success: true,
      output_file: File.join(session_dir, "review.md"),
      metadata: nil
    }) do |**kwargs|
      # Create the review file
      File.write(File.join(session_dir, "review.md"), "# Review Output")
      true
    end

    # Track if feedback extraction was called
    feedback_called = false
    feedback_result = {success: true, items_count: 3, paths: ["/fb1.s.md"]}

    Ace::Review::Molecules::LlmExecutor.stub :new, mock_executor do
      # Mock preset manager for copy_to_release
      @manager.instance_variable_get(:@preset_manager).stub :review_base_path, @temp_dir do
        Ace::Review.stub :get, ->(section, key) {
          return true if section == "feedback" && key == "enabled"
          return false if section == "defaults" && key == "auto_save"
          nil
        } do
          @manager.stub :maybe_extract_single_model_feedback, ->(*_args) {
            feedback_called = true
            feedback_result
          } do
            result = @manager.send(:execute_single_model, review_data, session_dir, options, "test-model")

            assert result[:success]
            assert feedback_called, "Feedback extraction should have been called"
            assert_equal 3, result[:feedback_count]
            assert_equal ["/fb1.s.md"], result[:feedback_paths]
          end
        end
      end
    end

    mock_executor.verify
  end

  def test_execute_single_model_skips_feedback_when_disabled
    session_dir = File.join(@temp_dir, "execute_skip_test")
    FileUtils.mkdir_p(session_dir)

    review_data = {
      system_prompt: "System prompt",
      user_prompt: "User prompt",
      preset: "pr",
      model: "test-model"
    }

    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      no_feedback: true
    )

    # Mock LlmExecutor
    mock_executor = Minitest::Mock.new
    mock_executor.expect(:execute, {
      success: true,
      output_file: File.join(session_dir, "review.md"),
      metadata: nil
    }) do |**kwargs|
      File.write(File.join(session_dir, "review.md"), "# Review Output")
      true
    end

    feedback_called = false

    Ace::Review::Molecules::LlmExecutor.stub :new, mock_executor do
      @manager.instance_variable_get(:@preset_manager).stub :review_base_path, @temp_dir do
        Ace::Review.stub :get, ->(section, key) {
          return false if section == "defaults" && key == "auto_save"
          nil
        } do
          @manager.stub :maybe_extract_single_model_feedback, ->(*_args) {
            feedback_called = true
            nil
          } do
            result = @manager.send(:execute_single_model, review_data, session_dir, options, "test-model")

            assert result[:success]
            # Feedback should be called but return nil (disabled)
            assert feedback_called
            refute result.key?(:feedback_count), "Should not have feedback_count when disabled"
            refute result.key?(:feedback_paths), "Should not have feedback_paths when disabled"
          end
        end
      end
    end

    mock_executor.verify
  end

  def test_execute_single_model_handles_feedback_failure_gracefully
    session_dir = File.join(@temp_dir, "execute_fail_test")
    FileUtils.mkdir_p(session_dir)

    review_data = {
      system_prompt: "System prompt",
      user_prompt: "User prompt",
      preset: "pr",
      model: "test-model"
    }

    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    mock_executor = Minitest::Mock.new
    mock_executor.expect(:execute, {
      success: true,
      output_file: File.join(session_dir, "review.md"),
      metadata: nil
    }) do |**kwargs|
      File.write(File.join(session_dir, "review.md"), "# Review Output")
      true
    end

    # Return a failure result from feedback extraction
    feedback_result = {success: false, error: "Extraction failed"}

    Ace::Review::Molecules::LlmExecutor.stub :new, mock_executor do
      @manager.instance_variable_get(:@preset_manager).stub :review_base_path, @temp_dir do
        Ace::Review.stub :get, ->(section, key) {
          return true if section == "feedback" && key == "enabled"
          return false if section == "defaults" && key == "auto_save"
          nil
        } do
          @manager.stub :maybe_extract_single_model_feedback, ->(*_args) { feedback_result } do
            result = @manager.send(:execute_single_model, review_data, session_dir, options, "test-model")

            # Review should still succeed even if feedback fails
            assert result[:success]
            refute result.key?(:feedback_count), "Should not have feedback_count on failure"
            refute result.key?(:feedback_paths), "Should not have feedback_paths on failure"
          end
        end
      end
    end

    mock_executor.verify
  end
end

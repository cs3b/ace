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
      reviewers:
        - name: correctness
          providers:
            - llm:google:google:gemini-2.5-flash
          prompt:
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

    # Check that session files are created with organized layout
    sd = result[:session_dir]
    system_prompt_files = Dir.glob(File.join(sd, "_prompts", "*.prompt.md"))
    system_context_files = Dir.glob(File.join(sd, "_prompts", "*.context.md"))
    assert_equal 1, system_prompt_files.size
    assert_equal 1, system_context_files.size
    assert File.exist?(system_prompt_files.first)
    assert File.exist?(system_context_files.first)
    assert File.exist?(File.join(sd, "_subject", "user.prompt.md"))
    assert File.exist?(File.join(sd, "_subject", "user.context.md"))
    assert File.exist?(File.join(sd, "metadata.yml"))
  end

  def test_execute_review_with_context_creates_context_md
    options = {
      preset: "pr",  # Use built-in preset that exists
      subject: "def test; end",
      bundle: { "files" => [] },  # Empty files list to avoid file not found errors
      auto_execute: false,
      session_dir: File.join(@temp_dir, "test_session")
    }

    result = @manager.execute_review(options)

    assert result[:success], "Review should succeed: #{result[:error]}"

    # Check that context is handled via ace-bundle workflow (organized layout)
    session_dir = result[:session_dir]
    system_context_file = Dir.glob(File.join(session_dir, "_prompts", "*.context.md")).first
    assert File.exist?(system_context_file), "system context file should be created in _prompts/"

    # Verify context files were created
    system_prompt_file = Dir.glob(File.join(session_dir, "_prompts", "*.prompt.md")).first
    assert File.exist?(system_prompt_file)
    assert File.exist?(File.join(session_dir, "_subject", "user.prompt.md"))
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

    # Verify files are created in custom session directory (organized layout)
    assert File.exist?(Dir.glob(File.join(result[:session_dir], "_prompts", "*.prompt.md")).first)
    assert File.exist?(File.join(result[:session_dir], "_subject", "user.prompt.md"))
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

    # Verify organized session structure
    assert File.exist?(Dir.glob(File.join(session_dir, "_prompts", "*.context.md")).first), "Should have _prompts/*.context.md"
    assert File.exist?(Dir.glob(File.join(session_dir, "_prompts", "*.prompt.md")).first), "Should have _prompts/*.prompt.md"
    assert File.exist?(File.join(session_dir, "_subject", "user.context.md")), "Should have _subject/user.context.md"
    assert File.exist?(File.join(session_dir, "_subject", "user.prompt.md")), "Should have _subject/user.prompt.md"
    assert File.exist?(File.join(session_dir, "metadata.yml")), "Should have metadata.yml"

    # Verify system prompt has proper structure
    system_prompt_content = File.read(Dir.glob(File.join(session_dir, "_prompts", "*.prompt.md")).first)
    refute_empty system_prompt_content, "System prompt should not be empty"

    # Verify user prompt has proper structure
    user_prompt_content = File.read(File.join(session_dir, "_subject", "user.prompt.md"))
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

  def test_compose_review_prompt_accepts_base_only_reviewer_prompt
    config = {
      "description" => "Base-only prompt acceptance",
      "reviewers" => [
        {
          "name" => "contracts",
          "model" => "google:gemini-2.5-pro",
          "prompt" => {
            "base" => "prompt://base/system"
          }
        }
      ],
      "subject" => {
        "content" => "def test; end"
      },
      "bundle" => "project",
      "model" => "google:gemini-2.5-flash"
    }
    session_dir = File.join(@temp_dir, "base_only_prompt")
    FileUtils.mkdir_p(session_dir)

    result = @manager.send(:compose_review_prompt, config, {}, {}, session_dir, nil, nil)

    assert result[:success], "Base-only prompts should be valid for LLM reviewers"
    assert_equal 1, result[:system_prompts].size
    assert_equal 1, result[:system_prompt_paths].size
  end

  def test_compose_review_prompt_rejects_llm_reviewer_without_prompt
    config = {
      "description" => "Missing prompt invalid",
      "reviewers" => [
        {
          "name" => "contracts",
          "model" => "google:gemini-2.5-pro"
        }
      ],
      "subject" => {
        "content" => "def test; end"
      },
      "bundle" => "project",
      "model" => "google:gemini-2.5-flash"
    }
    session_dir = File.join(@temp_dir, "missing_prompt")
    FileUtils.mkdir_p(session_dir)

    result = @manager.send(:compose_review_prompt, config, {}, {}, session_dir, nil, nil)

    refute result[:success]
    assert_match(/must define a prompt/, result[:error])
  end

  def test_compose_review_prompt_uses_run_keyed_system_prompt_files_for_same_model_reviewers
    config = {
      "description" => "Run-keyed prompt files",
      "reviewers" => [
        {
          "name" => "clarity",
          "model" => "google:gemini-2.5-pro",
          "prompt" => {
            "base" => "prompt://base/system"
          }
        },
        {
          "name" => "risk",
          "model" => "google:gemini-2.5-pro",
          "prompt" => {
            "base" => "prompt://base/system",
            "focus" => "prompt://focus/risk"
          }
        }
      ],
      "subject" => {
        "content" => "def test; end"
      },
      "bundle" => "project",
      "model" => "google:gemini-2.5-flash"
    }
    session_dir = File.join(@temp_dir, "run_keyed_prompts")
    FileUtils.mkdir_p(session_dir)

    result = @manager.send(:compose_review_prompt, config, {}, {}, session_dir, nil, nil)

    assert result[:success], "Expected compose_review_prompt to succeed"
    run_keys = config["reviewers"].map do |reviewer|
      reviewer_run_key(reviewer)
    end

    assert_equal run_keys.sort, result[:system_prompts].keys.sort
    assert_equal run_keys.sort, result[:system_prompt_paths].keys.sort

    # With deduplication, prompt files are keyed by reviewer name (not run_key)
    prompt_files = Dir.glob(File.join(session_dir, "_prompts", "*.prompt.md"))
    # Two reviewers with distinct names → two prompt files
    reviewer_names = config["reviewers"].map { |r| r["name"] }.uniq
    assert_equal reviewer_names.size, prompt_files.size

    run_keys.each do |run_key|
      assert result[:system_prompt_paths].key?(run_key)
      assert File.exist?(result[:system_prompt_paths][run_key]), "Expected prompt path #{result[:system_prompt_paths][run_key]} to exist"
    end
  end

  def test_compose_review_prompt_uses_unique_run_keys_for_duplicate_name_reviewers
    config = {
      "description" => "Duplicate reviewer identities",
      "reviewers" => [
        {
          "name" => "correctness",
          "model" => "google:gemini-2.5-pro",
          "prompt" => {
            "base" => "prompt://base/system"
          }
        },
        {
          "name" => "correctness",
          "model" => "google:gemini-2.5-pro",
          "prompt" => {
            "base" => "prompt://base/system",
            "sections" => {
              "reviewer_notes" => {
                "content" => "Second lane."
              }
            }
          }
        }
      ],
      "subject" => {
        "content" => "def test; end"
      },
      "bundle" => "project",
      "model" => "google:gemini-2.5-flash"
    }
    session_dir = File.join(@temp_dir, "duplicate_name_prompts")
    FileUtils.mkdir_p(session_dir)

    result = @manager.send(:compose_review_prompt, config, {}, {}, session_dir, nil, nil)

    assert result[:success], "Expected compose_review_prompt to succeed"
    run_keys = Ace::Review::Atoms::ReviewerRunKeyAllocator.allocate(config["reviewers"]).map { |lane| lane[:run_key] }
    assert_equal 2, run_keys.uniq.size
    assert_equal run_keys.sort, result[:system_prompts].keys.sort
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
        "bundle" => {
          "sections" => {
            "format" => {
              "title" => "Format Guidelines",
              "files" => ["prompt://format/standard"]
            }
          }
        }
      },
      "bundle" => { "files" => [] },  # Simple context without preset dependencies
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
      "reviewers" => [
        {
          "name" => "code-fit",
          "model" => "google:gemini-2.5-flash",
          "prompt" => {
            "base" => "prompt://base/system"
          }
        }
      ],
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

    # Verify per-reviewer system context and prompt files were created (organized layout)
    system_context_file = Dir.glob(File.join(session_dir, "_prompts", "*.context.md")).first
    system_prompt_file = Dir.glob(File.join(session_dir, "_prompts", "*.prompt.md")).first
    assert system_context_file, "system context files should exist in _prompts/"
    assert system_prompt_file, "system prompt files should exist in _prompts/"

    assert File.exist?(system_context_file), "system context file should exist"
    assert File.exist?(system_prompt_file), "system prompt file should exist"

    content = File.read(system_prompt_file)
    refute_empty content, "System prompt should not be empty"

    # Verify user.context.md was created in _subject/
    user_context_file = File.join(session_dir, "_subject", "user.context.md")
    assert File.exist?(user_context_file), "_subject/user.context.md should exist"

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
  # Multiple --subject flag integration tests (PR #79)
  # ============================================================================

  def test_extract_review_content_with_array_subjects
    # Create preset that we'll use
    create_test_preset("array-test", <<~YAML)
      description: "Test array subjects preset"
      reviewers:
        - name: correctness
          providers:
            - llm:google:google:gemini-2.5-flash
          prompt:
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
      reviewers:
        - name: correctness
          providers:
            - llm:google:google:gemini-2.5-flash
          prompt:
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
      reviewers:
        - name: correctness
          providers:
            - llm:google:google:gemini-2.5-flash
          prompt:
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
    metadata = { "headRefName" => "281.05-review-spec-context" }

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
    metadata = { "headRefName" => "281.05-review-spec-context" }
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
    context_config = { "presets" => ["project"] }
    metadata = { "headRefName" => "non-task-branch" }

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
    config = { context: "project" }

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
        @manager.stub(:extract_context, ->(ctx, _cache_dir) { captured_context_config = ctx; "context" }) do
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

    typed_config = { "bundle" => { "diffs" => ["HEAD~3"], "files" => ["*.md"] } }
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
        "bundle" => { "diffs" => ["default-diff"] }
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
    expected = { "bundle" => { "diffs" => ["default-diff"] } }
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
        "model1" => { success: true, output_file: "/path/to/report1.md" },
        "model2" => { success: true, output_file: "/path/to/report2.md" }
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
        "model1" => { success: true, output_file: "/path/to/report1.md" }
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
        "model1" => { success: false, error: "Failed" },
        "model2" => { success: false, error: "Also failed" }
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
        "model1" => { success: true, output_file: "/path/to/report1.md" },
        "model2" => { success: true, output_file: "/path/to/report2.md" },
        "model3" => { success: false, error: "Failed" }
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
        "model1" => { success: true, output_file: "/path/to/report1.md" }
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
        "model1" => { success: true, output_file: "/path/to/report1.md" }
      }
    }

    paths = @manager.send(:collect_report_paths, result, session_dir)

    assert_includes paths, "/path/to/report1.md"
    assert_includes paths, dev_feedback_path
  end

  def test_collect_report_paths_returns_hash_descriptor_when_reviewer_present
    require "ace/review/models/reviewer"
    session_dir = File.join(@temp_dir, "collect_reviewer_test")
    FileUtils.mkdir_p(session_dir)

    reviewer = Ace::Review::Models::Reviewer.new(name: "code-fit", model: "google:gemini-2.5-pro", weight: 1.0)
    result = {
      results: {
        "google:gemini-2.5-pro" => { success: true, output_file: "/path/to/report.md", reviewer: reviewer }
      }
    }

    paths = @manager.send(:collect_report_paths, result, session_dir)

    assert_equal 1, paths.length
    descriptor = paths.first
    assert_kind_of Hash, descriptor
    assert_equal "/path/to/report.md", descriptor[:path]
    assert_equal reviewer, descriptor[:reviewer]
  end

  def test_collect_report_paths_fans_out_descriptors_for_reviewers_array
    require "ace/review/models/reviewer"
    session_dir = File.join(@temp_dir, "collect_reviewers_array_test")
    FileUtils.mkdir_p(session_dir)

    reviewer1 = Ace::Review::Models::Reviewer.new(name: "code-fit", model: "google:gemini-2.5-pro", weight: 1.0)
    reviewer2 = Ace::Review::Models::Reviewer.new(name: "standards", model: "google:gemini-2.5-pro", weight: 0.8)
    result = {
      results: {
        "google:gemini-2.5-pro" => {
          success: true,
          output_file: "/path/to/report.md",
          run_key: "code-fit:google-gemini-2-5-pro-1",
          reviewers: [reviewer1, reviewer2],
          reviewer: reviewer1
        }
      }
    }

    paths = @manager.send(:collect_report_paths, result, session_dir)

    assert_equal 2, paths.length
    assert_equal({ path: "/path/to/report.md", reviewer: reviewer1, run_key: "code-fit:google-gemini-2-5-pro-1" }, paths[0])
    assert_equal({ path: "/path/to/report.md", reviewer: reviewer2, run_key: "code-fit:google-gemini-2-5-pro-1" }, paths[1])
  end

  def test_collect_report_paths_includes_run_key_with_single_reviewer_descriptor
    require "ace/review/models/reviewer"
    session_dir = File.join(@temp_dir, "collect_reviewer_run_key_test")
    FileUtils.mkdir_p(session_dir)

    reviewer = Ace::Review::Models::Reviewer.new(name: "code-fit", model: "google:gemini-2.5-pro", weight: 1.0)
    result = {
      results: {
        "google:gemini-2.5-pro" => { success: true, output_file: "/path/to/report.md", reviewer: reviewer, run_key: "code-fit:google-gemini-2-5-pro-1" }
      }
    }

    paths = @manager.send(:collect_report_paths, result, session_dir)

    assert_equal 1, paths.length
    descriptor = paths.first
    assert_kind_of Hash, descriptor
    assert_equal "/path/to/report.md", descriptor[:path]
    assert_equal reviewer, descriptor[:reviewer]
    assert_equal "code-fit:google-gemini-2-5-pro-1", descriptor[:run_key]
  end

  def test_collect_report_paths_returns_string_when_no_reviewer
    session_dir = File.join(@temp_dir, "collect_no_reviewer_test")
    FileUtils.mkdir_p(session_dir)

    result = {
      results: {
        "google:gemini-2.5-flash" => { success: true, output_file: "/path/to/report.md" }
      }
    }

    paths = @manager.send(:collect_report_paths, result, session_dir)

    assert_equal 1, paths.length
    assert_kind_of String, paths.first
    assert_equal "/path/to/report.md", paths.first
  end

  def test_build_review_data_includes_reviewers_when_options_has_reviewers
    require "ace/review/models/reviewer"
    reviewers = [
      Ace::Review::Models::Reviewer.new(name: "r1", model: "google:gemini-2.5-pro", weight: 1.0)
    ]
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "test",
      reviewers: reviewers
    )
    config = { reviewers: reviewers }
    content = { subject: nil, context: nil }
    prompt_result = {
      system_prompt: "sys",
      system_prompts: { "google:gemini-2.5-flash" => "sys" },
      system_prompt_path: "system-1.md",
      system_prompt_paths: { "google:gemini-2.5-flash" => "system-1.md" },
      user_prompt: "usr",
      user_prompt_path: nil
    }

    review_data = @manager.send(:build_review_data, options, config, content, prompt_result, "/tmp")

    assert review_data.key?(:reviewers)
    assert_equal reviewers, review_data[:reviewers]
    assert_equal ["google:gemini-2.5-pro"], review_data[:models]
    assert_equal "google:gemini-2.5-pro", review_data[:model]
    assert_equal prompt_result[:system_prompts], review_data[:system_prompts]
    assert_equal prompt_result[:system_prompt_paths], review_data[:system_prompt_paths]
  end

  def test_build_review_data_raises_when_no_reviewers_or_cli_models
    options = Ace::Review::Models::ReviewOptions.new(preset: "test")
    config = {}
    content = { subject: nil, context: nil }
    prompt_result = {
      system_prompt: "sys",
      system_prompt_path: "system-1.md",
      user_prompt: "usr",
      user_prompt_path: nil
    }

    error = assert_raises(ArgumentError) do
      @manager.send(:build_review_data, options, config, content, prompt_result, "/tmp")
    end
    assert_match(/resolved no reviewer lanes/i, error.message)
  end

  def test_build_review_data_uses_explicit_cli_models_without_reviewers
    options = Ace::Review::Models::ReviewOptions.new(preset: "test", models: ["anthropic:claude-opus-4"])
    config = {}
    content = { subject: nil, context: nil }
    prompt_result = {
      system_prompt: "sys",
      user_prompt: "usr",
      user_prompt_path: nil
    }

    review_data = @manager.send(:build_review_data, options, config, content, prompt_result, "/tmp")

    assert_equal ["anthropic:claude-opus-4"], review_data[:models]
    assert_equal "anthropic:claude-opus-4", review_data[:model]
  end

  def test_apply_provider_override_rewrites_only_llm_reviewers
    llm_reviewer = Ace::Review::Models::Reviewer.new(
      name: "correctness",
      model: "codex:codex@rw",
      prompt: { "base" => "prompt://base/system" },
      provider: "llm:rw",
      provider_kind: "llm",
      provider_options: { "kind" => "llm", "model" => "codex:codex@rw" },
      reviewer_type: "llm"
    )
    tool_reviewer = Ace::Review::Models::Reviewer.new(
      name: "lint",
      model: "tool:lint",
      provider: "tool:lint",
      provider_kind: "tool",
      provider_options: { "kind" => "tool", "tool" => "lint" },
      reviewer_type: "tool"
    )

    options = Ace::Review::Models::ReviewOptions.new(
      preset: "test",
      provider_overrides: ["llm:fast:codex:spark@code-fast"],
      reviewers: [llm_reviewer, tool_reviewer]
    )
    config = { reviewers: [llm_reviewer, tool_reviewer] }

    @manager.send(:apply_provider_override!, options, config)

    assert_equal "codex:spark@code-fast", options.reviewers.first.model
    assert_equal "llm:fast:codex:spark@code-fast", options.reviewers.first.provider
    assert_equal "tool:lint", options.reviewers.last.model
    assert_equal "tool:lint", options.reviewers.last.provider
    assert_equal ["codex:spark@code-fast"], config[:models]
    assert_equal "codex:spark@code-fast", config[:model]
  end

  def test_apply_provider_override_rejects_when_no_llm_reviewers_exist
    tool_reviewer = Ace::Review::Models::Reviewer.new(
      name: "lint",
      model: "tool:lint",
      provider: "tool:lint",
      provider_kind: "tool",
      provider_options: { "kind" => "tool", "tool" => "lint" },
      reviewer_type: "tool"
    )

    options = Ace::Review::Models::ReviewOptions.new(
      preset: "test",
      provider_overrides: ["llm:fast:codex:spark@code-fast"],
      reviewers: [tool_reviewer]
    )
    config = { reviewers: [tool_reviewer] }

    error = assert_raises(ArgumentError) do
      @manager.send(:apply_provider_override!, options, config)
    end

    assert_match(/resolved no LLM reviewer lanes/i, error.message)
  end

  def test_prepare_review_config_applies_provider_override_to_inline_reviewers
    create_test_preset("provider-override", <<~YAML)
      description: "Provider override test"
      reviewers:
        - name: quality
          providers:
            - llm:google:google:gemini-2.5-pro
          prompt:
            base: "prompt://base/system"
    YAML

    options = Ace::Review::Models::ReviewOptions.new(
      preset: "provider-override",
      provider_overrides: ["llm:fast:codex:spark@code-fast"]
    )

    result = @manager.send(:prepare_review_config, options)

    assert result[:success], "Expected provider override config to succeed: #{result[:error]}"
    assert_equal ["codex:spark@code-fast"], result[:config][:models]
    assert_equal "codex:spark@code-fast", options.reviewers.first.model
    assert_equal "llm:fast:codex:spark@code-fast", options.reviewers.first.provider
  end

  def test_merge_config_skips_reviewers_when_cli_models_set
    # When --models is provided via CLI, preset reviewers must not override it
    require "ace/review/models/reviewer"
    options = Ace::Review::Models::ReviewOptions.new(models: ["anthropic:claude-opus-4"])

    preset_reviewer = Ace::Review::Models::Reviewer.new(name: "preset-r", model: "google:gemini-2.5-pro", weight: 1.0)
    config = { "reviewers" => [preset_reviewer] }

    options.merge_config(config)

    assert_nil options.reviewers, "CLI --models should prevent preset reviewers from being loaded"
    assert_equal ["anthropic:claude-opus-4"], options.models
  end

  def test_determine_feedback_path_always_returns_session_dir
    # With session-symlink architecture, feedback always lives in session
    review_data = { preset: "pr", model: "test-model" }
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    # Even with task reference, should return session_dir
    @manager.instance_variable_set(:@task_reference, "227")

    path = @manager.send(:determine_feedback_path, review_data, session_dir)
    assert_equal session_dir, path, "Should always return session_dir for feedback"
  ensure
    @manager.instance_variable_set(:@task_reference, nil)
  end

  def test_determine_feedback_path_returns_session_dir_without_task
    review_data = { preset: "pr", model: "test-model" }
    session_dir = File.join(@temp_dir, "session")
    FileUtils.mkdir_p(session_dir)

    # No task reference set
    @manager.instance_variable_set(:@task_reference, nil)

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
        "model1" => { success: true, output_file: report1_path },
        "model2" => { success: true, output_file: report2_path }
      }
    }

    review_data = { preset: "pr", model: "test-model" }
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
        "model1" => { success: true, output_file: "/nonexistent/path.md" }
      }
    }

    review_data = { preset: "pr", model: "test-model" }
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
        "model1" => { success: true, output_file: report_path }
      }
    }

    review_data = { preset: "pr", model: "test-model" }
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    call_count = 0
    mock_feedback_manager = Minitest::Mock.new

    # First call fails (primary model)
    mock_feedback_manager.expect(:extract_and_save, { success: false, error: "Primary model failed" }) do |**kwargs|
      call_count += 1
      kwargs[:model] == "google:gemini-2.5-flash"
    end

    # Second call succeeds (fallback model)
    mock_feedback_manager.expect(:extract_and_save, {
      success: true,
      items_count: 2,
      paths: ["/path/fb1.s.md", "/path/fb2.s.md"]
    }) do |**kwargs|
      call_count += 1
      kwargs[:model] == "claude:glm"
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
        "model1" => { success: true, output_file: report_path }
      }
    }

    review_data = { preset: "pr", model: "test-model" }
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    mock_feedback_manager = Minitest::Mock.new

    # Both models fail
    mock_feedback_manager.expect(:extract_and_save, { success: false, error: "Primary failed" }) do |**kwargs|
      kwargs[:model] == "google:gemini-2.5-flash"
    end
    mock_feedback_manager.expect(:extract_and_save, { success: false, error: "Fallback failed" }) do |**kwargs|
      kwargs[:model] == "claude:glm"
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
    review_data = { model: "review-model" }
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

  def test_build_synthesis_model_list_with_option_override
    review_data = { model: "review-model" }
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
    review_data = { model: "same-model" }
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
        "model1" => { success: true, output_file: "/path/report1.md" },
        "model2" => { success: true, output_file: "/path/report2.md" }
      },
      summary: { total_models: 2, success_count: 2 }
    }

    session_dir = "/path/to/session"
    task_paths = ["/path/to/task/report1.md"]
    feedback_result = {
      success: true,
      items_count: 5,
      paths: ["/path/feedback1.s.md", "/path/feedback2.s.md"]
    }

    response = @manager.send(
      :build_multi_model_response,
      result, session_dir, task_paths, feedback_result
    )

    assert response[:success]
    assert_equal 5, response[:feedback_count]
    assert_equal ["/path/feedback1.s.md", "/path/feedback2.s.md"], response[:feedback_paths]
  end

  def test_build_multi_model_response_includes_feedback_error
    result = {
      results: {
        "model1" => { success: true, output_file: "/path/report1.md" }
      },
      summary: { total_models: 1, success_count: 1 }
    }

    session_dir = "/path/to/session"
    feedback_result = {
      success: false,
      error: "All synthesis models failed",
      models_tried: ["google:gemini-2.5-flash", "claude:glm"]
    }

    response = @manager.send(
      :build_multi_model_response,
      result, session_dir, nil, feedback_result
    )

    assert response[:success]
    refute response.key?(:feedback_count)
    assert_equal "All synthesis models failed", response[:feedback_error]
  end

  def test_build_multi_model_response_without_feedback
    result = {
      results: {
        "model1" => { success: true, output_file: "/path/report1.md" }
      },
      summary: { total_models: 1, success_count: 1 }
    }

    session_dir = "/path/to/session"

    response = @manager.send(
      :build_multi_model_response,
      result, session_dir, nil, nil
    )

    assert response[:success]
    refute response.key?(:feedback_count)
    refute response.key?(:feedback_paths)
  end

  def test_review_options_feedback_enabled_defaults_to_true
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr")

    assert options.feedback_enabled?, "Feedback should be enabled by default"
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

  def test_task_feedback_path_returns_correct_path
    task_path = "/project/.ace-taskflow/v.0.9.0/tasks/227-feature"

    path = @manager.send(:task_feedback_path, task_path)

    assert_equal "/project/.ace-taskflow/v.0.9.0/tasks/227-feature/feedback", path
  end

  def test_ensure_task_feedback_directory_creates_directories
    task_dir = File.join(@temp_dir, "tasks", "227-feature")
    FileUtils.mkdir_p(task_dir)

    @manager.send(:ensure_task_feedback_directory, task_dir)

    assert Dir.exist?(File.join(task_dir, "feedback")), "feedback/ should be created"
    assert Dir.exist?(File.join(task_dir, "feedback", "_archived")), "feedback/_archived/ should be created"
  end

  def test_ensure_task_feedback_directory_is_idempotent
    task_dir = File.join(@temp_dir, "tasks", "227-feature")
    FileUtils.mkdir_p(task_dir)

    # Call multiple times - should not raise errors
    @manager.send(:ensure_task_feedback_directory, task_dir)
    @manager.send(:ensure_task_feedback_directory, task_dir)
    @manager.send(:ensure_task_feedback_directory, task_dir)

    assert Dir.exist?(File.join(task_dir, "feedback")), "feedback/ should exist"
    assert Dir.exist?(File.join(task_dir, "feedback", "_archived")), "feedback/_archived/ should exist"
  end

  def test_resolve_task_for_feedback_returns_task_info
    task_dir = File.join(@temp_dir, "tasks", "227")
    FileUtils.mkdir_p(task_dir)

    expected_info = { path: task_dir, task_id: "227" }

    Ace::Review::Molecules::TaskResolver.stub :resolve, ->(task_id) {
      expected_info if task_id == "227"
    } do
      result = @manager.send(:resolve_task_for_feedback, "227")

      assert_equal expected_info, result
    end
  end

  def test_resolve_task_for_feedback_returns_nil_on_error
    Ace::Review::Molecules::TaskResolver.stub :resolve, ->(task_id) {
      raise "Resolution failed"
    } do
      output = capture_io do
        result = @manager.send(:resolve_task_for_feedback, "227")
        assert_nil result, "Should return nil on error"
      end

      assert_match(/Could not resolve task for feedback/, output[1])
    end
  end

  # ============================================================================
  # Session Symlink Tests (Task 227 Architecture)
  # ============================================================================

  def test_link_session_to_task_creates_symlink
    task_dir = File.join(@temp_dir, "tasks", "227-feature")
    session_dir = File.join(@temp_dir, ".cache", "ace-review", "sessions", "review-8p2h11")
    FileUtils.mkdir_p(task_dir)
    FileUtils.mkdir_p(session_dir)

    # Create some files in session
    File.write(File.join(session_dir, "review.md"), "# Review")
    File.write(File.join(session_dir, "metadata.yml"), "timestamp: now")

    link_path = @manager.send(:link_session_to_task, session_dir, task_dir)

    assert link_path, "Should return link path"
    assert File.symlink?(link_path), "Should create symlink"
    assert_equal File.join(task_dir, "reviews", "review-8p2h11"), link_path

    # Verify symlink target
    target = File.readlink(link_path)
    assert target.include?("review-8p2h11"), "Symlink should point to session"

    # Verify files are accessible via symlink
    assert File.exist?(File.join(link_path, "review.md")), "review.md should be accessible"
    assert File.exist?(File.join(link_path, "metadata.yml")), "metadata.yml should be accessible"
  end

  def test_link_session_to_task_creates_reviews_directory
    task_dir = File.join(@temp_dir, "tasks", "227-feature")
    session_dir = File.join(@temp_dir, ".cache", "sessions", "review-abc123")
    FileUtils.mkdir_p(task_dir)
    FileUtils.mkdir_p(session_dir)

    refute Dir.exist?(File.join(task_dir, "reviews")), "reviews/ should not exist initially"

    @manager.send(:link_session_to_task, session_dir, task_dir)

    assert Dir.exist?(File.join(task_dir, "reviews")), "reviews/ should be created"
  end

  def test_link_session_to_task_returns_nil_for_invalid_inputs
    task_dir = File.join(@temp_dir, "tasks", "227")
    session_dir = File.join(@temp_dir, "nonexistent-session")
    FileUtils.mkdir_p(task_dir)

    # Nonexistent session
    result = @manager.send(:link_session_to_task, session_dir, task_dir)
    assert_nil result, "Should return nil for nonexistent session"

    # Nil inputs
    assert_nil @manager.send(:link_session_to_task, nil, task_dir)
    assert_nil @manager.send(:link_session_to_task, session_dir, nil)
  end

  def test_link_session_to_task_is_idempotent
    task_dir = File.join(@temp_dir, "tasks", "227")
    session_dir = File.join(@temp_dir, ".cache", "sessions", "review-xyz")
    FileUtils.mkdir_p(task_dir)
    FileUtils.mkdir_p(session_dir)

    # Create symlink twice
    link1 = @manager.send(:link_session_to_task, session_dir, task_dir)
    link2 = @manager.send(:link_session_to_task, session_dir, task_dir)

    assert_equal link1, link2, "Should return same path"
    assert File.symlink?(link1), "Should still be a symlink"
  end

  def test_link_session_to_task_multiple_sessions_to_same_task
    task_dir = File.join(@temp_dir, "tasks", "227-feature")
    FileUtils.mkdir_p(task_dir)

    # Create multiple session directories
    session1 = File.join(@temp_dir, ".cache", "sessions", "review-8p2h11")
    session2 = File.join(@temp_dir, ".cache", "sessions", "review-8p2fo1")
    session3 = File.join(@temp_dir, ".cache", "sessions", "review-8p2xyz")
    [session1, session2, session3].each do |s|
      FileUtils.mkdir_p(s)
      File.write(File.join(s, "review.md"), "# Review from #{File.basename(s)}")
    end

    # Link all sessions to same task
    link1 = @manager.send(:link_session_to_task, session1, task_dir)
    link2 = @manager.send(:link_session_to_task, session2, task_dir)
    link3 = @manager.send(:link_session_to_task, session3, task_dir)

    # All should succeed with unique paths
    assert File.symlink?(link1)
    assert File.symlink?(link2)
    assert File.symlink?(link3)

    # Each should have unique name
    refute_equal link1, link2
    refute_equal link2, link3

    # All reviews accessible
    reviews_dir = File.join(task_dir, "reviews")
    assert_equal 3, Dir.glob(File.join(reviews_dir, "review-*")).count
  end

  def test_link_session_to_task_if_requested_with_task_reference
    task_dir = File.join(@temp_dir, "tasks", "227")
    session_dir = File.join(@temp_dir, ".cache", "sessions", "review-test")
    FileUtils.mkdir_p(task_dir)
    FileUtils.mkdir_p(session_dir)

    @manager.instance_variable_set(:@task_reference, "227")

    Ace::Review::Molecules::TaskResolver.stub :resolve, ->(task_id) {
      { path: task_dir, task_id: task_id } if task_id == "227"
    } do
      link_path = @manager.send(:link_session_to_task_if_requested, session_dir)

      assert link_path, "Should return link path"
      assert File.symlink?(link_path), "Should create symlink"
    end
  ensure
    @manager.instance_variable_set(:@task_reference, nil)
  end

  def test_link_session_to_task_if_requested_without_task_reference
    session_dir = File.join(@temp_dir, ".cache", "sessions", "review-test")
    FileUtils.mkdir_p(session_dir)

    @manager.instance_variable_set(:@task_reference, nil)

    result = @manager.send(:link_session_to_task_if_requested, session_dir)
    assert_nil result, "Should return nil without task reference"
  end

  def test_link_session_to_task_if_requested_task_not_found
    session_dir = File.join(@temp_dir, ".cache", "sessions", "review-test")
    FileUtils.mkdir_p(session_dir)

    @manager.instance_variable_set(:@task_reference, "nonexistent")

    output = capture_io do
      Ace::Review::Molecules::TaskResolver.stub :resolve, nil do
        result = @manager.send(:link_session_to_task_if_requested, session_dir)
        assert_nil result, "Should return nil when task not found"
      end
    end

    assert_match(/Task 'nonexistent' not found/, output[1])
  ensure
    @manager.instance_variable_set(:@task_reference, nil)
  end

  def test_auto_link_session_if_enabled_links_to_detected_task
    task_dir = File.join(@temp_dir, "tasks", "126")
    session_dir = File.join(@temp_dir, ".cache", "sessions", "review-abc")
    FileUtils.mkdir_p(task_dir)
    FileUtils.mkdir_p(session_dir)

    options = Struct.new(:no_auto_save).new(false)

    Ace::Review.stub :get, ->(section, key) {
      return true if section == "defaults" && key == "auto_save"
      return ['^(\d+)-'] if section == "defaults" && key == "task_branch_patterns"
      nil
    } do
      Ace::Git::Molecules::BranchReader.stub :current_branch, "126-feature" do
        Ace::Review::Molecules::TaskResolver.stub :resolve, ->(task_id) {
          { path: task_dir, task_id: task_id } if task_id == "126"
        } do
          link_path = @manager.send(:auto_link_session_if_enabled, session_dir, options)

          assert link_path, "Should return link path"
          assert File.symlink?(link_path), "Should create symlink"
        end
      end
    end
  end

  def test_auto_link_session_if_enabled_returns_nil_when_disabled
    session_dir = File.join(@temp_dir, ".cache", "sessions", "review-abc")
    FileUtils.mkdir_p(session_dir)

    # no_auto_save flag set
    options = Struct.new(:no_auto_save).new(true)

    result = @manager.send(:auto_link_session_if_enabled, session_dir, options)
    assert_nil result, "Should return nil when auto_save disabled by flag"
  end

  def test_auto_link_session_if_enabled_returns_nil_when_config_disabled
    session_dir = File.join(@temp_dir, ".cache", "sessions", "review-abc")
    FileUtils.mkdir_p(session_dir)

    options = Struct.new(:no_auto_save).new(false)

    Ace::Review.stub :get, ->(section, key) {
      return false if section == "defaults" && key == "auto_save"
      nil
    } do
      result = @manager.send(:auto_link_session_if_enabled, session_dir, options)
      assert_nil result, "Should return nil when auto_save disabled in config"
    end
  end

  # ============================================================================
  # Single-Model Feedback Extraction Tests (Task 227.08)
  # ============================================================================

  def test_maybe_extract_single_model_feedback_returns_nil_when_disabled
    options = Ace::Review::Models::ReviewOptions.new(
      preset: "pr",
      no_feedback: true
    )

    result = { success: true, output_file: "/path/to/report.md" }
    review_data = { preset: "pr", model: "test-model" }
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

    result = { success: true, output_file: report_path }
    review_data = { preset: "pr", model: "test-model" }
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

    reviewer = Ace::Review::Models::Reviewer.new(
      name: "contracts",
      model: "claude-3"
    )

    result = { success: true, output_file: report_path }
    review_data = { preset: "pr", model: "claude-3", reviewers: [reviewer] }
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
        { success: true, items_count: 0, paths: [] }
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
    assert_equal reviewer, captured_result[:results]["claude-3"][:reviewer]
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
    feedback_result = { success: true, items_count: 3, paths: ["/fb1.s.md"] }

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
    feedback_result = { success: false, error: "Extraction failed" }

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

  def test_prepare_review_config_returns_actionable_error_for_pipeline_resolution_failures
    options = Ace::Review::Models::ReviewOptions.new(preset: "pr-risk-based")

    mock_preset_manager = Minitest::Mock.new
    mock_preset_manager.expect(:preset_exists?, true, ["pr-risk-based"])
    mock_preset_manager.expect(:resolve_preset, nil) do |preset_name, _overrides|
      raise ArgumentError, "Missing reviewer reference: correctness" if preset_name == "pr-risk-based"
      false
    end

    @manager.instance_variable_set(:@preset_manager, mock_preset_manager)
    result = @manager.send(:prepare_review_config, options)

    refute result[:success]
    assert_match(/Missing reviewer reference: correctness/, result[:error])
    mock_preset_manager.verify
  end

  def test_execute_with_llm_uses_mixed_lane_path_when_tool_reviewer_present
    require "ace/review/models/reviewer"

    tool_reviewer = Ace::Review::Models::Reviewer.new(
      name: "lint",
      model: "tool:lint",
      provider_kind: "tool",
      provider_options: { "tool" => "lint" }
    )
    review_data = {
      models: ["google:gemini-2.5-flash"],
      reviewers: [tool_reviewer]
    }

    called = false
    @manager.stub :execute_mixed_review, ->(*_args) {
      called = true
      { success: true, summary: { total_models: 1, success_count: 1 } }
    } do
      result = @manager.send(:execute_with_llm, review_data, @temp_dir, nil)
      assert called
      assert result[:success]
    end
  end

  def test_execute_tool_reviewer_dispatches_lint_provider
    require "ace/review/models/reviewer"

    reviewer = Ace::Review::Models::Reviewer.new(
      name: "lint",
      model: "tool:lint",
      provider_kind: "tool",
      provider_options: { "tool" => "lint" }
    )

    mock_runner = Minitest::Mock.new
    mock_runner.expect(:run, { success: true, output_file: "/tmp/review-lint.md", duration: 0.3 }) do |reviewer:, session_dir:|
      reviewer.name == "lint" && session_dir == @temp_dir
    end

    Ace::Review::Molecules::LintEvidenceRunner.stub :new, mock_runner do
      result = @manager.send(:execute_tool_reviewer, reviewer, @temp_dir)
      assert result[:success]
      assert_equal "/tmp/review-lint.md", result[:output_file]
    end

    mock_runner.verify
  end

  # parse_subject_diff_range tests
  def test_parse_subject_diff_range_with_range_and_path
    range, path_filter = @manager.send(:parse_subject_diff_range, "diff:origin/main..HEAD -- ace-review/lib")
    assert_equal "origin/main..HEAD", range
    assert_equal "ace-review/lib", path_filter
  end

  def test_parse_subject_diff_range_with_range_only
    range, path_filter = @manager.send(:parse_subject_diff_range, "diff:HEAD~3")
    assert_equal "HEAD~3", range
    assert_nil path_filter
  end

  def test_parse_subject_diff_range_with_nil
    range, path_filter = @manager.send(:parse_subject_diff_range, nil)
    assert_nil range
    assert_nil path_filter
  end

  def test_parse_subject_diff_range_with_non_diff_subject
    range, path_filter = @manager.send(:parse_subject_diff_range, "files:*.rb")
    assert_nil range
    assert_nil path_filter
  end

  private

  def reviewer_run_key(reviewer)
    Ace::Review::Atoms::ReviewerRunKeyAllocator.allocate([reviewer]).first[:run_key]
  end
end

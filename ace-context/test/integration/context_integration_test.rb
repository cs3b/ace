# frozen_string_literal: true

require_relative "../test_helper"

class ContextIntegrationTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    @env = Ace::TestSupport::TestEnvironment.new("context")
    @env.setup
  end

  def teardown
    @env.teardown
  end

  def test_full_context_loading_workflow
    # Create markdown preset
    FileUtils.mkdir_p(File.join(@env.project_dir, ".ace/context"))
    File.write(File.join(@env.project_dir, ".ace/context/project.md"), <<~MARKDOWN
      ---
      description: Project preset
      params:
        output: cache
        embed_itself: true
      context:
        files:
          - "*.md"
        exclude:
          - "skip.md"
      ---
      # Project Context
      This is the project preset.
    MARKDOWN
    )

    # Create test files
    @env.create_sample_file("README.md", "# Project")
    @env.create_sample_file("docs.md", "# Documentation")
    @env.create_sample_file("skip.md", "Should be excluded")

    # Load using the API
    Dir.chdir(@env.project_dir) do
      context = Ace::Context.load_preset("project")

      assert_equal 2, context.file_count
      assert context.content.include?("Project")
      assert context.content.include?("Documentation")
      refute context.content.include?("Should be excluded")
      assert_equal "cache", context.metadata[:output]
    end
  end

  def test_list_presets_from_directory
    # Create multiple presets
    FileUtils.mkdir_p(File.join(@env.project_dir, ".ace/context"))
    File.write(File.join(@env.project_dir, ".ace/context/preset1.md"), <<~MARKDOWN
      ---
      description: First preset
      params:
        output: stdio
      context:
        files: ["*.txt"]
      ---
      First preset
    MARKDOWN
    )

    File.write(File.join(@env.project_dir, ".ace/context/preset2.md"), <<~MARKDOWN
      ---
      description: Second preset
      params:
        output: cache
      context:
        files: ["*.md"]
      ---
      Second preset
    MARKDOWN
    )

    Dir.chdir(@env.project_dir) do
      presets = Ace::Context.list_presets

      assert_equal 2, presets.size
      names = presets.map { |p| p[:name] }
      assert_includes names, "preset1"
      assert_includes names, "preset2"

      # Check descriptions
      preset1 = presets.find { |p| p[:name] == "preset1" }
      assert_equal "First preset", preset1[:description]
      assert_equal "stdio", preset1[:output]
    end
  end

  def test_load_file_api
    @env.create_sample_file("test.md", "# Test Content")
    full_path = File.join(@env.project_dir, "test.md")

    context = Ace::Context.load_file(full_path)

    assert_equal 1, context.file_count
    assert_equal "# Test Content", context.files.first[:content]
  end

  def test_handles_large_files
    # Create a file larger than max size
    large_content = "x" * (11 * 1024 * 1024)  # 11MB
    @env.create_sample_file("large.txt", large_content)
    full_path = File.join(@env.project_dir, "large.txt")

    context = Ace::Context.load_file(full_path)

    assert context.metadata[:error]
    assert context.metadata[:error].include?("too large")
  end

  def test_write_output_with_chunking
    # Create preset
    FileUtils.mkdir_p(File.join(@env.project_dir, ".ace/context"))
    File.write(File.join(@env.project_dir, ".ace/context/test.md"), <<~MARKDOWN
      ---
      description: Test preset
      params:
        output: stdio
        embed_itself: true
      context:
        files:
          - "*.txt"
      ---
      Test preset
    MARKDOWN
    )

    # Create a test file
    @env.create_sample_file("test.txt", "Test content")

    Dir.chdir(@env.project_dir) do
      context = Ace::Context.load_preset("test")
      output_path = File.join(@env.project_dir, "output.md")

      result = Ace::Context.write_output(context, output_path)

      assert result[:success]
      assert File.exist?(output_path)
      assert result[:lines] > 0
      assert result[:size_formatted]
    end
  end

  def test_integration_with_commands
    # Create preset with commands
    FileUtils.mkdir_p(File.join(@env.project_dir, ".ace/context"))
    File.write(File.join(@env.project_dir, ".ace/context/cmd.md"), <<~MARKDOWN
      ---
      description: Command preset
      params:
        output: stdio
        timeout: 5
      context:
        commands:
          - echo "Integration test"
          - pwd
      ---
      Command preset
    MARKDOWN
    )

    Dir.chdir(@env.project_dir) do
      context = Ace::Context.load_preset("cmd")

      assert context.commands
      assert context.commands.any? { |c| c[:command] == 'echo "Integration test"' }
      assert context.commands.all? { |c| c[:success] }
    end
  end

  def test_multiple_preset_loading
    # Create presets
    FileUtils.mkdir_p(File.join(@env.project_dir, ".ace/context"))
    File.write(File.join(@env.project_dir, ".ace/context/preset1.md"), <<~MARKDOWN
      ---
      description: First
      params:
        embed_itself: true
      context:
        files: ["file1.txt"]
      ---
      First
    MARKDOWN
    )

    File.write(File.join(@env.project_dir, ".ace/context/preset2.md"), <<~MARKDOWN
      ---
      description: Second
      params:
        embed_itself: true
      context:
        files: ["file2.txt"]
      ---
      Second
    MARKDOWN
    )

    @env.create_sample_file("file1.txt", "Content 1")
    @env.create_sample_file("file2.txt", "Content 2")

    # Change to project directory for context loading
    Dir.chdir(@env.project_dir) do
      # Load multiple presets
      context = Ace::Context.load_multiple_presets(["preset1", "preset2"])

      assert_equal 2, context.file_count
      assert context.content.include?("Content 1")
      assert context.content.include?("Content 2")
      assert context.metadata[:merged]
    end
  end
end
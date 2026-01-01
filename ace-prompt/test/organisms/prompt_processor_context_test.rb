# frozen_string_literal: true

require 'test_helper'
require 'ace/prompt/organisms/prompt_processor'

class PromptProcessorContextTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@tmpdir) if @tmpdir && Dir.exist?(@tmpdir)
  end

  def test_process_without_context_flag_returns_body_only
    create_prompt_with_frontmatter

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: false)

      assert result[:success]
      assert_equal "Review this project.\n", result[:content]
      refute_includes result[:content], "README.md"
    end
  end

  def test_process_with_context_flag_but_no_frontmatter_returns_body
    create_prompt_without_frontmatter

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

      assert result[:success]
      assert_equal "Just plain content.\n", result[:content]
    end
  end

  def test_process_archives_original_content_before_context_expansion
    create_prompt_with_frontmatter

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: false)

      assert result[:success]

      # Archive should contain the original content with frontmatter
      archived_content = File.read(result[:archive_path])
      assert_includes archived_content, "---"
      assert_includes archived_content, "context:"
      assert_includes archived_content, "Review this project."
    end
  end

  def test_extract_frontmatter_from_prompt
    create_prompt_with_frontmatter

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      # Read the prompt
      prompt_path = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts', 'the-prompt.md')
      content = File.read(prompt_path)

      # Extract frontmatter
      extracted = Ace::Prompt::Atoms::FrontmatterExtractor.extract(content)

      assert extracted[:has_frontmatter]
      assert_equal ['README.md'], extracted[:frontmatter]['context']['files']
      assert_equal "Review this project.\n", extracted[:body]
    end
  end

  def test_complex_frontmatter_with_multiple_context_sources
    create_complex_frontmatter_prompt

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

      assert result[:success]
      # Content should include both the original prompt and context
      assert_includes result[:content], "Review this comprehensive feature."
      # Should attempt to load multiple sources
    end
  end

  def test_invalid_context_specification_handling
    create_prompt_with_invalid_context

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

      assert result[:success]
      # Should still return body content even if context is invalid
      assert_includes result[:content], "Review this code."
    end
  end

  def test_context_loading_failure_scenarios
    create_prompt_with_nonexistent_file_context

    # Mock ContextLoader to return empty string (simulating failure)
    Ace::Prompt::Molecules::ContextLoader.stub(:call, "") do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
        result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

        assert result[:success]
        # Should gracefully fallback to body content when context loading fails
        assert_includes result[:content], "Review this implementation."
      end
    end
  end

  def test_context_with_enabled_false_in_frontmatter
    create_prompt_with_context_disabled

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

      assert result[:success]
      # Should not include context when explicitly disabled
      assert_equal "Analyze this design.\n", result[:content]
    end
  end

  def test_context_loader_with_stubbed_response
    create_prompt_with_frontmatter

    # Mock successful context loading that includes the original content
    mock_context_content = "# Project Context\nThis is the project context.\n\n## Original Prompt\nReview this project."
    Ace::Prompt::Molecules::ContextLoader.stub(:call, mock_context_content) do
      Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
        result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

        assert result[:success]
        # Should return the context content (which includes the original prompt)
        assert_equal mock_context_content, result[:content]
        assert_includes result[:content], "Project Context"
        assert_includes result[:content], "Review this project."
      end
    end
  end

  def test_empty_frontmatter_context_block
    create_prompt_with_empty_context

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

      assert result[:success]
      # Should still return body content
      assert_includes result[:content], "Evaluate this approach."
    end
  end

  def test_malformed_yaml_frontmatter
    create_prompt_with_malformed_frontmatter

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

      assert result[:success]
      # Should treat malformed frontmatter as body content
      assert_includes result[:content], "---"
      assert_includes result[:content], "context:"
      assert_includes result[:content], "files:"
      assert_includes result[:content], "invalid: yaml: content"
    end
  end

  def test_context_with_only_commands
    create_prompt_with_command_context

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::Prompt::Organisms::PromptProcessor.call(context: true)

      assert result[:success]
      assert_includes result[:content], "Check this implementation."
    end
  end

  private

  def create_prompt_with_frontmatter
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, <<~MARKDOWN)
      ---
      context:
        files:
          - README.md
      ---
      Review this project.
    MARKDOWN
  end

  def create_prompt_without_frontmatter
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, "Just plain content.\n")
  end

  def create_complex_frontmatter_prompt
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, <<~MARKDOWN)
      ---
      context:
        enabled: true
        sources:
          - file: "docs/architecture.md"
          - preset: "project-overview"
          - command: "git status --short"
          - file: "README.md"
      tags:
        - review
        - feature
      priority: high
      ---
      Review this comprehensive feature.
    MARKDOWN
  end

  def create_prompt_with_invalid_context
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, <<~MARKDOWN)
      ---
      context:
        sources:
          - invalid_type: "not_supported"
          - file: 12345  # invalid file reference
          - command: ""   # empty command
      ---
      Review this code.
    MARKDOWN
  end

  def create_prompt_with_nonexistent_file_context
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, <<~MARKDOWN)
      ---
      context:
        sources:
          - file: "nonexistent/file.md"
          - command: "nonexistent-command"
      ---
      Review this implementation.
    MARKDOWN
  end

  def create_prompt_with_context_disabled
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, <<~MARKDOWN)
      ---
      context:
        enabled: false
        sources:
          - file: "docs/architecture.md"
      ---
      Analyze this design.
    MARKDOWN
  end

  def create_prompt_with_empty_context
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, <<~MARKDOWN)
      ---
      context:
        enabled: true
        sources: []
      ---
      Evaluate this approach.
    MARKDOWN
  end

  def create_prompt_with_malformed_frontmatter
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, <<~MARKDOWN)
      ---
      context:
        files:
      invalid: yaml: content
        - not_properly_formatted
      ---
      Some content here.
    MARKDOWN
  end

  def create_prompt_with_command_context
    prompt_dir = File.join(@tmpdir, '.cache', 'ace-prompt', 'prompts')
    FileUtils.mkdir_p(prompt_dir)

    prompt_path = File.join(prompt_dir, 'the-prompt.md')
    File.write(prompt_path, <<~MARKDOWN)
      ---
      context:
        enabled: true
        sources:
          - command: "git log --oneline -5"
          - command: "git diff --name-only HEAD~1"
      ---
      Check this implementation.
    MARKDOWN
  end
end

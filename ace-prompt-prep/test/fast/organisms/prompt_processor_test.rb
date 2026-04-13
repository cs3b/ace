# frozen_string_literal: true

require "test_helper"

class PromptProcessorTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @prompt_dir = File.join(@tmpdir, ".ace-local/prompt-prep/prompts")
    @archive_dir = File.join(@prompt_dir, "archive")
    FileUtils.mkdir_p(@prompt_dir)

    @prompt_file = File.join(@prompt_dir, "the-prompt.md")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_processes_prompt_successfully
    File.write(@prompt_file, "Test prompt")

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Organisms::PromptProcessor.call

      assert result[:success]
      assert_equal "Test prompt", result[:content]
      assert result[:archive_path]
      assert File.exist?(result[:archive_path])
      assert result[:symlink_path]
      assert result[:symlink_updated]
    end
  end

  def test_handles_missing_prompt_file
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Organisms::PromptProcessor.call

      refute result[:success]
      assert_nil result[:content]
      assert_match(/not found/, result[:error])
    end
  end

  def test_archives_and_returns_content
    content = "Important prompt content"
    File.write(@prompt_file, content)

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Organisms::PromptProcessor.call

      assert result[:success]
      assert_equal content, result[:content]

      # Verify archive exists
      assert File.exist?(result[:archive_path])
      assert_equal content, File.read(result[:archive_path])
    end
  end

  def test_updates_symlink_to_archive
    File.write(@prompt_file, "Test")

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Organisms::PromptProcessor.call

      assert result[:success]
      assert File.symlink?(result[:symlink_path])

      # Symlink should point to archive file
      symlink_target = File.readlink(result[:symlink_path])
      archive_basename = File.basename(result[:archive_path])
      assert_equal "archive/#{archive_basename}", symlink_target
    end
  end

  def test_handles_custom_input_path
    custom_file = File.join(@tmpdir, "custom-prompt.md")
    File.write(custom_file, "Custom content")

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Organisms::PromptProcessor.call(input_path: custom_file)

      assert result[:success]
      assert_equal "Custom content", result[:content]
      assert result[:archive_path]
    end
  end

  def test_handles_empty_prompt
    File.write(@prompt_file, "")

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Organisms::PromptProcessor.call

      # Empty content should still succeed
      assert result[:success]
      assert_equal "", result[:content]
    end
  end

  def test_handles_unicode_content
    content = "日本語 Привет café 🎉"
    File.write(@prompt_file, content, encoding: "utf-8")

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Organisms::PromptProcessor.call

      assert result[:success]
      assert_equal content, result[:content]
      assert_equal content, File.read(result[:archive_path], encoding: "utf-8")
    end
  end
end

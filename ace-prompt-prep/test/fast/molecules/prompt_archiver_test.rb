# frozen_string_literal: true

require "test_helper"

class PromptArchiverTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @original_root = Dir.pwd

    # Mock ProjectRootFinder to return our tmpdir
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      # Set up archive directory
      @archive_dir = File.join(@tmpdir, ".ace-local/prompt-prep/prompts/archive")
      @symlink_path = File.join(@tmpdir, ".ace-local/prompt-prep/prompts/_previous.md")
      FileUtils.mkdir_p(@archive_dir)
    end
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_archives_content_with_session_id
    content = "Test prompt content"
    session_id = "i50jj3"

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Molecules::PromptArchiver.call(
        content: content,
        timestamp: session_id
      )

      assert result[:success]
      assert result[:archive_path]
      assert File.exist?(result[:archive_path])
      assert_equal content, File.read(result[:archive_path])
      assert result[:archive_path].end_with?("i50jj3.md")
    end
  end

  def test_updates_symlink
    content = "Test content"
    session_id = "i50jj3"

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Molecules::PromptArchiver.call(
        content: content,
        timestamp: session_id
      )

      assert result[:success]
      assert result[:symlink_updated]
      assert File.symlink?(result[:symlink_path])

      # Check symlink points to archive file
      target = File.readlink(result[:symlink_path])
      assert_match(/archive\/i50jj3\.md$/, target)
    end
  end

  def test_handles_nil_content
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Molecules::PromptArchiver.call(content: nil)

      refute result[:success]
      assert_match(/nil/, result[:error])
    end
  end

  def test_handles_empty_content
    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Molecules::PromptArchiver.call(content: "")

      assert result[:success]
      assert File.exist?(result[:archive_path])
      assert_equal "", File.read(result[:archive_path])
    end
  end

  def test_handles_session_id_collision
    content1 = "First content"
    content2 = "Second content"
    session_id = "i50jj3"

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result1 = Ace::PromptPrep::Molecules::PromptArchiver.call(
        content: content1,
        timestamp: session_id
      )
      result2 = Ace::PromptPrep::Molecules::PromptArchiver.call(
        content: content2,
        timestamp: session_id
      )

      assert result1[:success]
      assert result2[:success]
      refute_equal result1[:archive_path], result2[:archive_path]

      # Second file should have -1 suffix
      assert result1[:archive_path].end_with?("i50jj3.md")
      assert result2[:archive_path].end_with?("i50jj3-1.md")

      # Both files should exist with correct content
      assert_equal content1, File.read(result1[:archive_path])
      assert_equal content2, File.read(result2[:archive_path])
    end
  end

  def test_handles_unicode_content
    content = "日本語 Привет café 🎉"

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Molecules::PromptArchiver.call(content: content)

      assert result[:success]
      assert_equal content, File.read(result[:archive_path], encoding: "utf-8")
    end
  end

  def test_handles_large_content
    content = "x" * 100_000

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Molecules::PromptArchiver.call(content: content)

      assert result[:success]
      assert_equal content, File.read(result[:archive_path])
    end
  end

  def test_overwrites_existing_symlink
    content1 = "First"
    content2 = "Second"
    session_id1 = "i40aaa"
    session_id2 = "i60bbb"

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result1 = Ace::PromptPrep::Molecules::PromptArchiver.call(
        content: content1,
        timestamp: session_id1
      )
      result2 = Ace::PromptPrep::Molecules::PromptArchiver.call(
        content: content2,
        timestamp: session_id2
      )

      assert result1[:success]
      assert result2[:success]

      # Symlink should point to second archive
      target = File.readlink(result2[:symlink_path])
      assert_match(/i60bbb\.md$/, target)
    end
  end

  def test_creates_archive_directory_if_missing
    # Remove archive directory
    FileUtils.rm_rf(@archive_dir)
    content = "Test"

    Ace::Support::Fs::Molecules::ProjectRootFinder.stub :find_or_current, @tmpdir do
      result = Ace::PromptPrep::Molecules::PromptArchiver.call(content: content)

      assert result[:success]
      assert File.directory?(@archive_dir)
      assert File.exist?(result[:archive_path])
    end
  end
end

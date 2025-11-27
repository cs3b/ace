# frozen_string_literal: true

require_relative "../test_helper"

class PromptArchiverTest < Ace::Prompt::TestCase
  def setup
    super
    @temp_dir = @test_dir
    @prompts_dir = File.join(@temp_dir, "prompts")
    @archive_dir = File.join(@temp_dir, "archive")
    FileUtils.mkdir_p(@prompts_dir)
    FileUtils.mkdir_p(@archive_dir)

    @source_path = File.join(@prompts_dir, "the-prompt.md")
    @symlink_path = File.join(@prompts_dir, "_previous.md")

    # Create a default source file for testing
    File.write(@source_path, "Test prompt content")
  end

  def teardown
    # Don't need custom teardown since parent handles cleanup
    super
  end

  def test_archive_basic_prompt
    # Create source file
    content = "Test prompt content"
    File.write(@source_path, content)

    archived_path = Ace::Prompt::Molecules::PromptArchiver.archive(@source_path, @archive_dir)

    assert File.exist?(archived_path)
    assert archived_path.include?(@archive_dir)
    assert File.read(archived_path) == content
    assert archived_path.end_with?(".md")
  end

  def test_archive_with_enhancement_iteration
    # Create source file
    content = "Enhanced prompt content"
    File.write(@source_path, content)

    archived_path = Ace::Prompt::Molecules::PromptArchiver.archive(
      @source_path,
      @archive_dir,
      enhancement_iteration: 1
    )

    assert File.exist?(archived_path)
    assert archived_path.include?("_e001.md")
    assert File.read(archived_path) == content
  end

  def test_archive_creates_directory_if_missing
    new_archive_dir = File.join(@temp_dir, "new_archive")

    archived_path = Ace::Prompt::Molecules::PromptArchiver.archive(@source_path, new_archive_dir)

    assert File.exist?(new_archive_dir)
    assert File.exist?(archived_path)
  end

  def test_archive_handles_missing_source_gracefully
    archived_path = Ace::Prompt::Molecules::PromptArchiver.archive("nonexistent.md", @archive_dir)

    assert_nil archived_path
  end

  def test_archive_with_empty_file
    File.write(@source_path, "")

    archived_path = Ace::Prompt::Molecules::PromptArchiver.archive(@source_path, @archive_dir)

    assert File.exist?(archived_path)
    assert File.read(archived_path) == ""
  end

  def test_update_symlink_creates_relative_symlink
    # Create target file
    target_path = File.join(@archive_dir, "20251122-150000.md")
    File.write(target_path, "content")

    result = Ace::Prompt::Molecules::PromptArchiver.update_symlink(target_path, @symlink_path)

    assert_equal true, result
    assert File.symlink?(@symlink_path)

    # Should be a relative symlink, not absolute
    symlink_target = File.readlink(@symlink_path)
    assert_equal "archive/20251122-150000.md", symlink_target
  end

  def test_update_symlink_overwrites_existing
    # Create initial symlink
    old_target = File.join(@archive_dir, "old.md")
    File.write(old_target, "old content")
    File.symlink("archive/old.md", @symlink_path)

    # Create new target
    new_target = File.join(@archive_dir, "new.md")
    File.write(new_target, "new content")

    result = Ace::Prompt::Molecules::PromptArchiver.update_symlink(new_target, @symlink_path)

    assert_equal true, result
    assert File.symlink?(@symlink_path)
    assert_equal "archive/new.md", File.readlink(@symlink_path)
  end

  def test_update_symlink_handles_invalid_target_gracefully
    result = Ace::Prompt::Molecules::PromptArchiver.update_symlink("nonexistent.md", @symlink_path)

    assert_equal false, result
    refute File.symlink?(@symlink_path)
  end

  def test_multiple_enhancement_archives
    File.write(@source_path, "content")

    # Archive original
    original_archive = Ace::Prompt::Molecules::PromptArchiver.archive(@source_path, @archive_dir)

    # Archive enhancements
    enhancement_1 = Ace::Prompt::Molecules::PromptArchiver.archive(
      @source_path,
      @archive_dir,
      enhancement_iteration: 1
    )

    enhancement_2 = Ace::Prompt::Molecules::PromptArchiver.archive(
      @source_path,
      @archive_dir,
      enhancement_iteration: 2
    )

    assert File.exist?(original_archive)
    assert File.exist?(enhancement_1)
    assert File.exist?(enhancement_2)

    assert enhancement_1.include?("_e001.md")
    assert enhancement_2.include?("_e002.md")
  end

  def test_full_archive_workflow_with_symlink
    # Create and archive original
    File.write(@source_path, "original content")

    archived_path = Ace::Prompt::Molecules::PromptArchiver.archive(@source_path, @archive_dir)
    symlink_result = Ace::Prompt::Molecules::PromptArchiver.update_symlink(archived_path, @symlink_path)

    assert File.exist?(archived_path)
    assert_equal true, symlink_result
    assert File.symlink?(@symlink_path)

    # Verify symlink points to archived file
    archived_basename = File.basename(archived_path)
    expected_symlink_target = "archive/#{archived_basename}"
    assert_equal expected_symlink_target, File.readlink(@symlink_path)
  end

  def test_archive_preserves_file_permissions
    # Create source with specific content
    content = "Content with special chars: àáâãäå"
    File.write(@source_path, content)

    archived_path = Ace::Prompt::Molecules::PromptArchiver.archive(@source_path, @archive_dir)

    assert File.exist?(archived_path)
    archived_content = File.read(archived_path, encoding: "UTF-8")
    assert_equal content, archived_content
  end

  def test_concurrent_archiving
    threads = []
    results = []

    3.times do |i|
      threads << Thread.new do
        source = File.join(@prompts_dir, "file_#{i}.md")
        File.write(source, "content #{i}")

        archived = Ace::Prompt::Molecules::PromptArchiver.archive(source, @archive_dir)
        results << archived
      end
    end

    threads.each(&:join)

    # All should succeed and be unique
    results.compact!
    assert_equal 3, results.length
    assert_equal 3, results.uniq.length
    results.each { |path| assert File.exist?(path) }
  end

  def test_archive_with_very_long_content
    long_content = "Very long content " * 1000
    File.write(@source_path, long_content)

    archived_path = Ace::Prompt::Molecules::PromptArchiver.archive(@source_path, @archive_dir)

    assert File.exist?(archived_path)
    assert_equal long_content, File.read(archived_path)
  end
end
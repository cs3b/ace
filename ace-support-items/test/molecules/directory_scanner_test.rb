# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class DirectoryScannerTest < AceSupportItemsTestCase
  def setup
    @tmpdir = Dir.mktmpdir("items-scanner-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_returns_empty_for_nonexistent_dir
    scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
      "/nonexistent/path",
      file_pattern: "*.idea.s.md"
    )
    assert_equal [], scanner.scan
  end

  def test_returns_empty_for_empty_dir
    scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
      @tmpdir,
      file_pattern: "*.idea.s.md"
    )
    assert_equal [], scanner.scan
  end

  def test_finds_idea_in_directory
    # Create: {id}-{slug}/{id}-{slug}.idea.s.md
    idea_dir = File.join(@tmpdir, "8ppq7w-dark-mode")
    FileUtils.mkdir_p(idea_dir)
    File.write(File.join(idea_dir, "8ppq7w-dark-mode.idea.s.md"), "# Dark Mode")

    scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
      @tmpdir,
      file_pattern: "*.idea.s.md"
    )
    results = scanner.scan

    assert_equal 1, results.length
    result = results.first
    assert_equal "8ppq7w", result.id
    assert_equal "dark-mode", result.slug
    assert_equal "8ppq7w-dark-mode", result.folder_name
    assert_nil result.special_folder
  end

  def test_finds_idea_in_special_folder
    special_dir = File.join(@tmpdir, "_maybe")
    idea_dir = File.join(special_dir, "9xzr1k-future-idea")
    FileUtils.mkdir_p(idea_dir)
    File.write(File.join(idea_dir, "9xzr1k-future-idea.idea.s.md"), "# Future Idea")

    scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
      @tmpdir,
      file_pattern: "*.idea.s.md"
    )
    results = scanner.scan

    assert_equal 1, results.length
    result = results.first
    assert_equal "9xzr1k", result.id
    assert_equal "_maybe", result.special_folder
  end

  def test_finds_multiple_ideas_sorted_by_id
    # Create two ideas
    dir1 = File.join(@tmpdir, "aaaaaa-first")
    dir2 = File.join(@tmpdir, "zzzzzz-second")
    FileUtils.mkdir_p(dir1)
    FileUtils.mkdir_p(dir2)
    File.write(File.join(dir1, "aaaaaa-first.idea.s.md"), "# First")
    File.write(File.join(dir2, "zzzzzz-second.idea.s.md"), "# Second")

    scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
      @tmpdir,
      file_pattern: "*.idea.s.md"
    )
    results = scanner.scan

    assert_equal 2, results.length
    assert_equal "aaaaaa", results[0].id
    assert_equal "zzzzzz", results[1].id
  end

  def test_skips_directories_without_matching_files
    # Directory with .task.s.md files (wrong pattern)
    task_dir = File.join(@tmpdir, "8ppq7w-task")
    FileUtils.mkdir_p(task_dir)
    File.write(File.join(task_dir, "8ppq7w-task.task.s.md"), "# Task")

    scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
      @tmpdir,
      file_pattern: "*.idea.s.md"
    )
    results = scanner.scan

    assert_equal [], results
  end
end

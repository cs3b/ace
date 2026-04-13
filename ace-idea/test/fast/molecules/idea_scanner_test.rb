# frozen_string_literal: true

require "test_helper"

class IdeaScannerTest < AceIdeaTestCase
  def test_returns_empty_for_nonexistent_root
    scanner = Ace::Idea::Molecules::IdeaScanner.new("/nonexistent")
    assert_equal [], scanner.scan
  end

  def test_finds_ideas_in_root
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")

      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      results = scanner.scan

      assert_equal 1, results.length
      assert_equal "8ppq7w", results.first.id
    end
  end

  def test_finds_ideas_in_special_folders
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "9xzr1k", slug: "future-idea", special_folder: "_maybe")

      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      results = scanner.scan

      assert_equal 1, results.length
      assert_equal "_maybe", results.first.special_folder
    end
  end

  def test_does_not_find_task_files
    with_ideas_dir do |root|
      # Create a task file (wrong extension)
      task_dir = File.join(root, "8ppq7w-my-task")
      FileUtils.mkdir_p(task_dir)
      File.write(File.join(task_dir, "8ppq7w-my-task.s.md"), "# Task")

      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      results = scanner.scan

      assert_equal [], results
    end
  end

  def test_root_exists_check
    with_ideas_dir do |root|
      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      assert scanner.root_exists?
    end

    scanner = Ace::Idea::Molecules::IdeaScanner.new("/nonexistent")
    refute scanner.root_exists?
  end

  def test_scan_in_folder_filters_by_special_folder
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "active-idea")
      create_idea_fixture(root, id: "9xzr1k", slug: "maybe-idea", special_folder: "_maybe")

      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      results = scanner.scan_in_folder("_maybe")

      assert_equal 1, results.length
      assert_equal "9xzr1k", results.first.id
    end
  end

  def test_scan_in_folder_next_returns_root_items_only
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "active-idea")
      create_idea_fixture(root, id: "9xzr1k", slug: "maybe-idea", special_folder: "_maybe")

      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      results = scanner.scan_in_folder("next")

      assert_equal 1, results.length
      assert_equal "8ppq7w", results.first.id
      assert_nil results.first.special_folder
    end
  end

  def test_scan_in_folder_all_returns_everything
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "active-idea")
      create_idea_fixture(root, id: "9xzr1k", slug: "maybe-idea", special_folder: "_maybe")

      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      results = scanner.scan_in_folder("all")

      assert_equal 2, results.length
    end
  end
end

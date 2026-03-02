# frozen_string_literal: true

require "test_helper"

class RetroScannerTest < AceRetroTestCase
  def test_returns_empty_for_nonexistent_root
    scanner = Ace::Retro::Molecules::RetroScanner.new("/nonexistent")
    assert_equal [], scanner.scan
  end

  def test_finds_retros_in_root
    with_retros_dir do |root|
      create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      results = scanner.scan

      assert_equal 1, results.length
      assert_equal "8ppq7w", results.first.id
    end
  end

  def test_finds_retros_in_special_folders
    with_retros_dir do |root|
      create_retro_fixture(root, id: "9xzr1k", slug: "old-retro", special_folder: "_archive")

      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      results = scanner.scan

      assert_equal 1, results.length
      assert_equal "_archive", results.first.special_folder
    end
  end

  def test_does_not_find_task_files
    with_retros_dir do |root|
      task_dir = File.join(root, "8ppq7w-my-task")
      FileUtils.mkdir_p(task_dir)
      File.write(File.join(task_dir, "8ppq7w-my-task.s.md"), "# Task")

      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      results = scanner.scan

      assert_equal [], results
    end
  end

  def test_does_not_find_idea_files
    with_retros_dir do |root|
      idea_dir = File.join(root, "8ppq7w-my-idea")
      FileUtils.mkdir_p(idea_dir)
      File.write(File.join(idea_dir, "8ppq7w-my-idea.idea.s.md"), "# Idea")

      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      results = scanner.scan

      assert_equal [], results
    end
  end

  def test_root_exists_check
    with_retros_dir do |root|
      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      assert scanner.root_exists?
    end

    scanner = Ace::Retro::Molecules::RetroScanner.new("/nonexistent")
    refute scanner.root_exists?
  end

  def test_scan_in_folder_filters_by_special_folder
    with_retros_dir do |root|
      create_retro_fixture(root, id: "8ppq7w", slug: "active-retro")
      create_retro_fixture(root, id: "9xzr1k", slug: "archived-retro", special_folder: "_archive")

      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      results = scanner.scan_in_folder("_archive")

      assert_equal 1, results.length
      assert_equal "9xzr1k", results.first.id
    end
  end

  def test_scan_in_folder_next_returns_root_items_only
    with_retros_dir do |root|
      create_retro_fixture(root, id: "8ppq7w", slug: "active-retro")
      create_retro_fixture(root, id: "9xzr1k", slug: "archived-retro", special_folder: "_archive")

      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      results = scanner.scan_in_folder("next")

      assert_equal 1, results.length
      assert_equal "8ppq7w", results.first.id
      assert_nil results.first.special_folder
    end
  end

  def test_scan_in_folder_all_returns_everything
    with_retros_dir do |root|
      create_retro_fixture(root, id: "8ppq7w", slug: "active-retro")
      create_retro_fixture(root, id: "9xzr1k", slug: "archived-retro", special_folder: "_archive")

      scanner = Ace::Retro::Molecules::RetroScanner.new(root)
      results = scanner.scan_in_folder("all")

      assert_equal 2, results.length
    end
  end
end

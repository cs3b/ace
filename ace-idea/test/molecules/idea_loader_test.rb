# frozen_string_literal: true

require "test_helper"

class IdeaLoaderTest < AceIdeaTestCase
  def test_loads_idea_from_directory
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode",
                                     tags: ["ux", "design"])

      loader = Ace::Idea::Molecules::IdeaLoader.new
      idea = loader.load(idea_dir, id: "8ppq7w")

      refute_nil idea
      assert_equal "8ppq7w", idea.id
      assert_equal "pending", idea.status
      assert_equal ["ux", "design"], idea.tags
      assert_equal idea_dir, idea.path
    end
  end

  def test_returns_nil_for_nonexistent_directory
    loader = Ace::Idea::Molecules::IdeaLoader.new
    result = loader.load("/nonexistent/path")
    assert_nil result
  end

  def test_returns_nil_for_directory_without_spec_file
    with_ideas_dir do |root|
      empty_dir = File.join(root, "8ppq7w-empty")
      FileUtils.mkdir_p(empty_dir)

      loader = Ace::Idea::Molecules::IdeaLoader.new
      result = loader.load(empty_dir, id: "8ppq7w")
      assert_nil result
    end
  end

  def test_enumerates_attachments
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "with-attachments")

      # Add attachment files
      File.write(File.join(idea_dir, "screenshot.png"), "fake png")
      File.write(File.join(idea_dir, "notes.txt"), "notes")

      loader = Ace::Idea::Molecules::IdeaLoader.new
      idea = loader.load(idea_dir, id: "8ppq7w")

      assert_includes idea.attachments, "screenshot.png"
      assert_includes idea.attachments, "notes.txt"
      # Should not include the spec file
      refute idea.attachments.any? { |a| a.end_with?(".idea.s.md") }
    end
  end

  def test_extracts_title_from_body_heading
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "test-idea")

      loader = Ace::Idea::Molecules::IdeaLoader.new
      idea = loader.load(idea_dir, id: "8ppq7w")

      # Title should come from the # heading in the body
      assert_equal "Test idea", idea.title
    end
  end

  def test_loads_idea_with_special_folder
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "9xzr1k", slug: "maybe-idea",
                                     special_folder: "_maybe")

      loader = Ace::Idea::Molecules::IdeaLoader.new
      idea = loader.load(idea_dir, id: "9xzr1k", special_folder: "_maybe")

      assert_equal "_maybe", idea.special_folder
      assert idea.special?
    end
  end

  def test_from_scan_result
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")

      scanner = Ace::Idea::Molecules::IdeaScanner.new(root)
      scan_results = scanner.scan

      idea = Ace::Idea::Molecules::IdeaLoader.from_scan_result(scan_results.first)

      refute_nil idea
      assert_equal "8ppq7w", idea.id
    end
  end
end

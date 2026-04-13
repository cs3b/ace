# frozen_string_literal: true

require "test_helper"

class IdeaFilePatternTest < AceIdeaTestCase
  def test_file_glob_pattern
    assert_equal "*.idea.s.md", Ace::Idea::Atoms::IdeaFilePattern::FILE_GLOB
  end

  def test_file_extension
    assert_equal ".idea.s.md", Ace::Idea::Atoms::IdeaFilePattern::FILE_EXTENSION
  end

  def test_spec_filename
    result = Ace::Idea::Atoms::IdeaFilePattern.spec_filename("8ppq7w", "dark-mode")
    assert_equal "8ppq7w-dark-mode.idea.s.md", result
  end

  def test_folder_name
    result = Ace::Idea::Atoms::IdeaFilePattern.folder_name("8ppq7w", "dark-mode")
    assert_equal "8ppq7w-dark-mode", result
  end

  def test_idea_file_detection
    assert Ace::Idea::Atoms::IdeaFilePattern.idea_file?("my-idea.idea.s.md")
    refute Ace::Idea::Atoms::IdeaFilePattern.idea_file?("my-task.s.md")
    refute Ace::Idea::Atoms::IdeaFilePattern.idea_file?("README.md")
  end
end

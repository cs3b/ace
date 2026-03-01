# frozen_string_literal: true

require "test_helper"

class RetroFilePatternTest < AceRetroTestCase
  def test_retro_filename
    result = Ace::Retro::Atoms::RetroFilePattern.retro_filename("8ppq7w", "sprint-review")
    assert_equal "8ppq7w-sprint-review.retro.md", result
  end

  def test_folder_name
    result = Ace::Retro::Atoms::RetroFilePattern.folder_name("8ppq7w", "sprint-review")
    assert_equal "8ppq7w-sprint-review", result
  end

  def test_retro_file_detection
    assert Ace::Retro::Atoms::RetroFilePattern.retro_file?("8ppq7w-sprint.retro.md")
    refute Ace::Retro::Atoms::RetroFilePattern.retro_file?("8ppq7w-sprint.s.md")
    refute Ace::Retro::Atoms::RetroFilePattern.retro_file?("8ppq7w-sprint.idea.s.md")
    refute Ace::Retro::Atoms::RetroFilePattern.retro_file?("readme.md")
  end

  def test_file_extension_constant
    assert_equal ".retro.md", Ace::Retro::Atoms::RetroFilePattern::FILE_EXTENSION
  end

  def test_file_glob_constant
    assert_equal "*.retro.md", Ace::Retro::Atoms::RetroFilePattern::FILE_GLOB
  end
end

# frozen_string_literal: true

require "test_helper"

class SpecialFolderDetectorTest < AceSupportItemsTestCase
  def test_detects_underscore_prefixed_folder
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.special?("_archive")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.special?("_maybe")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.special?("_anytime")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.special?("_next")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.special?("_custom")
  end

  def test_non_special_folder
    refute Ace::Support::Items::Atoms::SpecialFolderDetector.special?("regular")
    refute Ace::Support::Items::Atoms::SpecialFolderDetector.special?("8ppq7w-my-idea")
  end

  def test_nil_and_empty
    refute Ace::Support::Items::Atoms::SpecialFolderDetector.special?(nil)
    refute Ace::Support::Items::Atoms::SpecialFolderDetector.special?("")
  end

  def test_normalize_short_alias
    assert_equal "_archive", Ace::Support::Items::Atoms::SpecialFolderDetector.normalize("archive")
    assert_equal "_maybe", Ace::Support::Items::Atoms::SpecialFolderDetector.normalize("maybe")
    assert_equal "_anytime", Ace::Support::Items::Atoms::SpecialFolderDetector.normalize("anytime")
    assert_equal "_next", Ace::Support::Items::Atoms::SpecialFolderDetector.normalize("next")
  end

  def test_normalize_already_prefixed
    assert_equal "_archive", Ace::Support::Items::Atoms::SpecialFolderDetector.normalize("_archive")
    assert_equal "_custom", Ace::Support::Items::Atoms::SpecialFolderDetector.normalize("_custom")
  end

  def test_detect_in_path
    path = "/root/_maybe/8ppq7w-my-idea"
    result = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(path, root: "/root")
    assert_equal "_maybe", result
  end

  def test_detect_in_path_no_special_folder
    path = "/root/8ppq7w-my-idea"
    result = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(path, root: "/root")
    assert_nil result
  end
end

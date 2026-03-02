# frozen_string_literal: true

require "test_helper"

class SpecialFolderDetectorTest < AceSupportItemsTestCase
  def test_detects_underscore_prefixed_folder
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.special?("_archive")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.special?("_maybe")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.special?("_anytime")
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
  end

  def test_normalize_does_not_expand_virtual_filters
    # "next" and "all" are virtual filters, not physical folders
    assert_equal "next", Ace::Support::Items::Atoms::SpecialFolderDetector.normalize("next")
    assert_equal "all", Ace::Support::Items::Atoms::SpecialFolderDetector.normalize("all")
  end

  def test_virtual_filter_returns_symbol_for_known_filters
    assert_equal :next, Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?("next")
    assert_equal :all, Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?("all")
  end

  def test_virtual_filter_is_case_insensitive
    assert_equal :next, Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?("Next")
    assert_equal :all, Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?("ALL")
  end

  def test_virtual_filter_returns_nil_for_non_filters
    assert_nil Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?("maybe")
    assert_nil Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?("archive")
    assert_nil Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?(nil)
    assert_nil Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?("")
  end

  def test_move_to_root_recognizes_aliases
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?("next")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?("root")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?("/")
  end

  def test_move_to_root_is_case_insensitive
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?("Next")
    assert Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?("ROOT")
  end

  def test_move_to_root_rejects_non_aliases
    refute Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?("archive")
    refute Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?("maybe")
    refute Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?(nil)
    refute Ace::Support::Items::Atoms::SpecialFolderDetector.move_to_root?("")
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

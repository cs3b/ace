# frozen_string_literal: true

require "test_helper"

class TitleExtractorTest < AceSupportItemsTestCase
  TE = Ace::Support::Items::Atoms::TitleExtractor

  def test_extract_h1_heading
    assert_equal "My Idea", TE.extract("# My Idea\n\nSome body text.")
  end

  def test_extract_strips_whitespace
    assert_equal "Trimmed Title", TE.extract("#   Trimmed Title  \n\nBody.")
  end

  def test_extract_returns_nil_for_no_heading
    assert_nil TE.extract("No heading here.\n\nJust text.")
  end

  def test_extract_returns_nil_for_nil
    assert_nil TE.extract(nil)
  end

  def test_extract_returns_nil_for_empty
    assert_nil TE.extract("")
  end

  def test_extract_ignores_h2_headings
    assert_nil TE.extract("## Not an H1\n\nBody.")
  end

  def test_extract_finds_first_h1_in_multiline
    body = "Some intro text\n\n# First Title\n\n# Second Title\n"
    assert_equal "First Title", TE.extract(body)
  end

  def test_extract_with_leading_newlines
    assert_equal "Title", TE.extract("\n\n# Title\n\nBody.")
  end
end

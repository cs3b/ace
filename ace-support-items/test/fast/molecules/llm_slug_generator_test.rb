# frozen_string_literal: true

require "test_helper"

class LlmSlugGeneratorTest < AceSupportItemsTestCase
  Generator = Ace::Support::Items::Molecules::LlmSlugGenerator

  def test_fallback_task_generation_splits_slug
    gen = Generator.new
    result = gen.generate_task_slugs("Fix login authentication bug")

    assert result[:success]
    assert_equal :fallback, result[:source]
    assert result[:folder_slug].is_a?(String)
    assert result[:file_slug].is_a?(String)
    refute result[:folder_slug].empty?
    refute result[:file_slug].empty?
  end

  def test_fallback_task_slug_format_valid
    gen = Generator.new
    result = gen.generate_task_slugs("Add dark mode support")

    assert result[:folder_slug].match?(/^[a-z0-9]+(-[a-z0-9]+)*$/)
    assert result[:file_slug].match?(/^[a-z0-9]+(-[a-z0-9]+)*$/)
  end

  def test_fallback_idea_generation
    gen = Generator.new
    result = gen.generate_idea_slugs("Create a new search feature for docs")

    assert result[:success]
    assert_equal :fallback, result[:source]
    assert result[:folder_slug].is_a?(String)
    assert result[:file_slug].is_a?(String)
  end

  def test_fallback_short_title_uses_same_slug
    gen = Generator.new
    result = gen.generate_task_slugs("Fix bug")

    assert result[:success]
    # With only 2 words, folder and file slug should be the same
    assert_equal result[:folder_slug], result[:file_slug]
  end
end

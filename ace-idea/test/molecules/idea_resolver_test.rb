# frozen_string_literal: true

require "test_helper"

class IdeaResolverTest < AceIdeaTestCase
  def test_resolves_suffix_shortcut
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")

      resolver = Ace::Idea::Molecules::IdeaResolver.new(root)
      result = resolver.resolve("q7w")

      refute_nil result
      assert_equal "8ppq7w", result.id
    end
  end

  def test_resolves_full_id
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")

      resolver = Ace::Idea::Molecules::IdeaResolver.new(root)
      result = resolver.resolve("8ppq7w")

      refute_nil result
      assert_equal "8ppq7w", result.id
    end
  end

  def test_returns_nil_for_nonexistent
    with_ideas_dir do |root|
      resolver = Ace::Idea::Molecules::IdeaResolver.new(root)
      result = resolver.resolve("zzz")
      assert_nil result
    end
  end

  def test_resolve_with_info_detects_ambiguity
    with_ideas_dir do |root|
      # Both IDs end in "q7w"
      create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")
      create_idea_fixture(root, id: "zzzq7w", slug: "another")

      resolver = Ace::Idea::Molecules::IdeaResolver.new(root)
      info = resolver.resolve_with_info("q7w")

      assert info[:ambiguous]
      assert_equal 2, info[:matches].length
    end
  end

  def test_resolve_with_info_no_match
    with_ideas_dir do |root|
      resolver = Ace::Idea::Molecules::IdeaResolver.new(root)
      info = resolver.resolve_with_info("zzz")

      refute info[:ambiguous]
      assert_nil info[:result]
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class RetroResolverTest < AceRetroTestCase
  def test_resolves_full_id
    with_retros_dir do |root|
      create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      resolver = Ace::Retro::Molecules::RetroResolver.new(root)
      result = resolver.resolve("8ppq7w")

      refute_nil result
      assert_equal "8ppq7w", result.id
    end
  end

  def test_resolves_shortcut
    with_retros_dir do |root|
      create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      resolver = Ace::Retro::Molecules::RetroResolver.new(root)
      result = resolver.resolve("q7w")

      refute_nil result
      assert_equal "8ppq7w", result.id
    end
  end

  def test_returns_nil_for_unknown_ref
    with_retros_dir do |root|
      resolver = Ace::Retro::Molecules::RetroResolver.new(root)
      result = resolver.resolve("zzz")

      assert_nil result
    end
  end

  def test_resolve_with_info_returns_hash
    with_retros_dir do |root|
      create_retro_fixture(root, id: "8ppq7w", slug: "sprint-review")

      resolver = Ace::Retro::Molecules::RetroResolver.new(root)
      info = resolver.resolve_with_info("q7w")

      refute_nil info[:result]
      refute info[:ambiguous]
      assert_equal 1, info[:matches].length
    end
  end

  def test_resolve_with_info_empty_for_unknown
    with_retros_dir do |root|
      resolver = Ace::Retro::Molecules::RetroResolver.new(root)
      info = resolver.resolve_with_info("zzz")

      assert_nil info[:result]
      refute info[:ambiguous]
      assert_equal 0, info[:matches].length
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class ShortcutResolverTest < AceSupportItemsTestCase
  def make_result(id, slug = "test")
    Ace::Support::Items::Models::ScanResult.new(
      id: id,
      slug: slug,
      folder_name: "#{id}-#{slug}",
      dir_path: "/tmp/#{id}-#{slug}",
      file_path: "/tmp/#{id}-#{slug}/#{id}-#{slug}.idea.s.md",
      special_folder: nil
    )
  end

  def test_resolves_full_id
    results = [make_result("8ppq7w"), make_result("9xzr1k")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)

    found = resolver.resolve("8ppq7w")
    assert_equal "8ppq7w", found.id
  end

  def test_resolves_suffix_shortcut
    results = [make_result("8ppq7w"), make_result("9xzr1k")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)

    found = resolver.resolve("q7w")
    assert_equal "8ppq7w", found.id
  end

  def test_returns_nil_for_no_match
    results = [make_result("8ppq7w")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)

    assert_nil resolver.resolve("xxx")
  end

  def test_returns_nil_for_empty_ref
    results = [make_result("8ppq7w")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)

    assert_nil resolver.resolve("")
    assert_nil resolver.resolve(nil)
  end

  def test_warns_on_ambiguity_and_returns_most_recent
    # Both IDs end in "q7w"
    results = [make_result("8ppq7w"), make_result("zzzq7w")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)

    warnings = []
    found = resolver.resolve("q7w", on_ambiguity: ->(matches) { warnings << matches })

    assert_equal 1, warnings.length
    assert_equal 2, warnings.first.length
    # Returns most recent (last by sorted order)
    assert_equal "zzzq7w", found.id
  end

  def test_ambiguous_returns_true_for_multiple_matches
    results = [make_result("8ppq7w"), make_result("zzzq7w")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)

    assert resolver.ambiguous?("q7w")
    refute resolver.ambiguous?("8ppq7w")
  end

  def test_all_matches_returns_all
    results = [make_result("8ppq7w"), make_result("zzzq7w"), make_result("aaa111")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)

    matches = resolver.all_matches("q7w")
    assert_equal 2, matches.length
    assert_equal ["8ppq7w", "zzzq7w"], matches.map(&:id)
  end

  def test_case_insensitive_resolution
    results = [make_result("8ppq7w")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results)

    found = resolver.resolve("Q7W")
    assert_equal "8ppq7w", found.id
  end

  # Tests for full_id_length parameter (task-format IDs)
  def test_resolves_full_task_id_with_custom_length
    results = [make_result("8pp.t.q7w"), make_result("9xz.t.r1k")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results, full_id_length: 9)

    found = resolver.resolve("8pp.t.q7w")
    assert_equal "8pp.t.q7w", found.id
  end

  def test_resolves_task_suffix_shortcut_with_custom_length
    results = [make_result("8pp.t.q7w"), make_result("9xz.t.r1k")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results, full_id_length: 9)

    found = resolver.resolve("q7w")
    assert_equal "8pp.t.q7w", found.id
  end

  def test_ambiguous_with_custom_length
    results = [make_result("8pp.t.q7w"), make_result("zzz.t.q7w")]
    resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(results, full_id_length: 9)

    assert resolver.ambiguous?("q7w")
    refute resolver.ambiguous?("8pp.t.q7w")
  end
end

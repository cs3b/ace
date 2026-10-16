# frozen_string_literal: true
require_relative "../../test_helper"
class CatalogTest < DesignTest
  def card
    "---\nid: example\nsurface: shared\ntitle: Example\nuse_when: Dense content\navoid_when: No need\nsource: https://example.com/pattern\nverified_at: 2026-10-16\n---\n# Example\nConcrete guidance.\n"
  end
  def test_valid_card_and_duplicate_are_distinguished
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "one.md"), card)
      catalog = Ace::Design::Molecules::Catalog.new
      assert_empty catalog.validate(dir)["errors"]
      File.write(File.join(dir, "two.md"), card)
      assert_match(/duplicate/, catalog.validate(dir)["errors"].first)
    end
  end
  def test_invalid_metadata_and_empty_catalog_fail
    Dir.mktmpdir do |dir|
      catalog = Ace::Design::Molecules::Catalog.new
      assert_raises(Ace::Design::Error) { catalog.validate(dir) }
      File.write(File.join(dir, "one.md"), card.sub("surface: shared", "surface: native"))
      assert_match(/invalid surface/, catalog.validate(dir)["errors"].first)
      File.write(File.join(dir, "one.md"), "---\n[]\n---\nbody")
      assert_match(/mapping/, catalog.validate(dir)["errors"].first)
    end
  end
end

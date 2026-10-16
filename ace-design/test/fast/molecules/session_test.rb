# frozen_string_literal: true
require_relative "../../test_helper"
class SessionTest < DesignTest
  def test_cli_resolves_session_tokens_under_configured_root
    assert_equal File.join(Ace::Design.config.fetch("run_root"), "8xabc"), Ace::Design::CLI.session_path("8xabc")
    assert_equal "/tmp/session", Ace::Design::CLI.session_path("/tmp/session")
  end
  def test_gallery_escapes_titles_and_preserves_variants
    with_session do |root|
      before = File.read(File.join(root, "variants/a/index.html"))
      session = Ace::Design::Molecules::Session.new(root)
      html = File.read(session.write_gallery)
      assert_includes html, "Mock &amp; &lt;test&gt;"
      assert_equal 3, html.scan("<iframe").size
      assert_equal before, File.read(File.join(root, "variants/a/index.html"))
    end
  end
  def test_partial_preview_is_explicit_and_available
    with_session do |root|
      FileUtils.rm_r(File.join(root, "variants/c"))
      session = Ace::Design::Molecules::Session.new(root)
      assert_equal ["c"], session.validate["missing_variants"]
      assert_includes File.read(session.write_gallery), "Still preparing: c"
    end
  end
  def test_no_variants_is_not_success
    with_session do |root|
      FileUtils.rm_r(File.join(root, "variants"))
      assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Session.new(root).validate }
    end
  end
  def test_selection_verifies_surface_variant_decisions_and_shared_data
    with_session do |root|
      choose(root)
      session = Ace::Design::Molecules::Session.new(root)
      assert session.validate["selected"]
      File.write(File.join(root, "fixtures.json"), '{"changed":true}')
      assert_match(/stale/, assert_raises(Ace::Design::Error) { session.validate }.message)
      choose(root, variant: "missing")
      assert_raises(Ace::Design::Error) { session.validate }
      choose(root)
      path = File.join(root, "selection.json")
      data = JSON.parse(File.read(path)).merge("decisions" => [])
      File.write(path, JSON.generate(data))
      assert_raises(Ace::Design::Error) { session.validate }
    end
  end
  def test_symlinks_cannot_escape_or_replace_gallery
    with_session do |root|
      Dir.mktmpdir do |other|
        secret = File.join(other, "secret.html")
        File.write(secret, "secret")
        path = File.join(root, "variants/a/index.html")
        File.unlink(path)
        File.symlink(secret, path)
        assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Session.new(root).validate }
        File.unlink(path)
        File.write(path, "local")
        File.symlink(secret, File.join(root, "gallery.html"))
        assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Session.new(root).write_gallery }
        assert_equal "secret", File.read(secret)
      end
    end
  end
  def test_malformed_metadata_is_actionable
    with_session do |root|
      File.write(File.join(root, "session.json"), "[]")
      assert_match(/JSON object/, assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Session.new(root) }.message)
      File.write(File.join(root, "session.json"), "{")
      assert_match(/Invalid session/, assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Session.new(root) }.message)
    end
  end
  def test_unfinished_worker_does_not_hide_other_ready_directions
    with_session do |root|
      File.delete(File.join(root, "variants/b/direction.md"))
      session = Ace::Design::Molecules::Session.new(root)
      assert_equal %w[a c], session.validate["variants"]
      assert_includes File.read(session.write_gallery), "Still preparing: b"
    end
  end

  def test_dangling_variant_and_selection_symlinks_are_actionable
    with_session do |root|
      path = File.join(root, "variants/b/index.html")
      File.delete(path)
      File.symlink(File.join(root, "missing.html"), path)
      error = assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Session.new(root).validate }
      assert_includes error.message, "Symlinks are not design artifacts: index.html"
    end
    with_session do |root|
      File.symlink(File.join(root, "missing.json"), File.join(root, "selection.json"))
      error = assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Session.new(root).validate }
      assert_includes error.message, "broken symlink: selection.json"
    end
  end

  def test_cyclic_selection_symlink_is_actionable
    with_session do |root|
      File.symlink("selection.json", File.join(root, "selection.json"))
      error = assert_raises(Ace::Design::Error) { Ace::Design::Molecules::Session.new(root).validate }
      assert_includes error.message, "broken symlink: selection.json"
    end
  end
end

# frozen_string_literal: true
require_relative "../test_helper"
require "open3"
class SkillSourcesTest < DesignTest
  def test_pinned_snapshot_materializes_internal_links_and_preserves_original_bytes
    Dir.mktmpdir do |root|
      repo = File.join(root, "repo")
      FileUtils.mkdir_p(File.join(repo, "skill"))
      File.write(File.join(repo, "skill/SKILL.md"), "Original instructions\n")
      File.symlink("skill/SKILL.md", File.join(repo, "REFERENCE.md"))
      [["git", "init", "-q", repo], ["git", "-C", repo, "add", "."],
       ["git", "-C", repo, "-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "-qm", "fixture"]].each do |command|
        _, error, status = Open3.capture3(*command)
        assert status.success?, error
      end
      revision, = Open3.capture3("git", "-C", repo, "rev-parse", "HEAD")
      source = {"source" => repo, "revision" => revision.strip, "entry" => "skill/SKILL.md"}
      preset = {"variants" => [{"id" => "a", "skills" => [source]}]}
      session = File.join(root, "session")
      Ace::Design::Molecules::SkillSources.new.snapshot(session, preset)
      copy = File.join(session, "skills/a/0")
      assert_equal "Original instructions\n", File.read(File.join(copy, "REFERENCE.md"))
      refute File.symlink?(File.join(copy, "REFERENCE.md"))
      File.write(File.join(repo, "skill/SKILL.md"), "Changed upstream")
      assert_equal "Original instructions\n", File.read(File.join(copy, "skill/SKILL.md"))
      assert_equal "skills/a/0/skill/SKILL.md", source["snapshot"]
    end
  end
  def test_escaping_and_cyclic_resources_are_rejected
    Dir.mktmpdir do |root|
      repo = File.join(root, "repo")
      FileUtils.mkdir_p(repo)
      File.write(File.join(root, "secret"), "private")
      File.symlink("../secret", File.join(repo, "escape"))
      sources = Ace::Design::Molecules::SkillSources.new
      assert_raises(Ace::Design::Error) { sources.copy_tree(repo, File.join(root, "out"), File.realpath(repo), []) }
      File.unlink(File.join(repo, "escape"))
      File.symlink(".", File.join(repo, "cycle"))
      assert_raises(Ace::Design::Error) { sources.copy_tree(repo, File.join(root, "out"), File.realpath(repo), []) }
    end
  end
  def test_external_completion_is_required_and_ace_fast_instructions_are_absent
    prompts = Ace::Design::Molecules::DesignPrompts
    slot = {"id" => "d", "process" => "external", "prompt" => "", "skills" => [{"entry" => "SKILL.md"}]}
    metadata = {"surface" => "site", "kind" => "view", "language" => "en", "intent" => "explore"}
    prompt = prompts.variant(metadata, slot)
    refute_includes prompt, "300 readable lines"
    refute_includes prompt, "Do not run browser audits"
    assert_includes prompt, "ALL original workflow requirements"
    Dir.mktmpdir do |root|
      File.write(File.join(root, "index.html"), "<h1>Result</h1>")
      File.write(File.join(root, "direction.md"), "Browser blocked")
      a = Ace::Design::Molecules::Artifacts
      a.json(File.join(root, "artifact.json"), {"type" => "html", "entry" => "index.html", "status" => "incomplete",
        "checks" => [{"name" => "browser", "status" => "blocked"}]})
      assert_raises(Ace::Design::Error) { a.validate_variant(root, shared_reference: false) }
    end
  end
end

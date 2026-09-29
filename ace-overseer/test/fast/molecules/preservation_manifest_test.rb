# frozen_string_literal: true

require "tmpdir"
require_relative "../../test_helper"
require_relative "../../support/prune_git_fixtures"

class PreservationManifestTest < AceOverseerTestCase
  def setup
    super
    @tmp = Dir.mktmpdir("prune-manifest")
    @source = PruneGitFixtures::Repo.new(File.join(@tmp, "source")).init
    @source.write("a.txt", "a\n")
    @base = @source.commit("base")
    @source.checkout("task-work", create: true)
    @source.write("a.txt", "b\n")
    @head = @source.commit("work")

    @successor = PruneGitFixtures::Repo.new(File.join(@tmp, "successor")).init
    @successor.write("z.txt", "z\n")
    @successor.commit("successor base")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def write_manifest(records)
    path = File.join(@tmp, "destinations.yml")
    File.write(path, YAML.dump("version" => 1, "candidates" => records))
    path
  end

  def base_record(worktree: File.join(@tmp, "wt"))
    {
      "worktree_path" => worktree,
      "source_repo" => @source.path,
      "source_base" => @base,
      "source_head" => @head,
      "destination_repo" => @successor.path,
      "destination_base" => @successor.rev("HEAD"),
      "destination_head" => @successor.rev("HEAD"),
      "destination_branch" => "refs/heads/main"
    }
  end

  def test_parses_and_resolves_revisions
    path = write_manifest([base_record])

    manifest = Ace::Overseer::Molecules::PreservationManifest.load(path)

    assert_equal 1, manifest.records.length
    record = manifest.records.first
    assert_equal @base, record.resolved_source_base
    assert_equal @head, record.resolved_source_head
    assert_equal @successor.rev("refs/heads/main"), record.resolved_destination_branch_tip
  end

  def test_finds_record_for_worktree_by_realpath
    FileUtils.mkdir_p(File.join(@tmp, "wt"))
    path = write_manifest([base_record])

    manifest = Ace::Overseer::Molecules::PreservationManifest.load(path)

    refute_nil manifest.for_worktree(File.join(@tmp, "wt"))
    assert_nil manifest.for_worktree(File.join(@tmp, "other"))
  end

  def test_rejects_missing_file_and_malformed_yaml
    assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(File.join(@tmp, "absent.yml"))
    end

    broken = File.join(@tmp, "broken.yml")
    File.write(broken, "version: 1\n candidates: [oops\n")
    assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(broken)
    end
  end

  def test_rejects_wrong_version_and_missing_candidates
    path = File.join(@tmp, "v2.yml")
    File.write(path, YAML.dump("version" => 2, "candidates" => []))
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "version: 1"

    path = File.join(@tmp, "nocands.yml")
    File.write(path, YAML.dump("version" => 1))
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "candidates"
  end

  def test_rejects_unknown_and_missing_fields
    record = base_record.merge("surprise" => "x")
    path = write_manifest([record])
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "unknown fields"

    record = base_record
    record.delete("destination_branch")
    path = write_manifest([record])
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "missing"
  end

  def test_rejects_relative_paths_and_missing_repositories
    record = base_record.merge("source_repo" => "relative/repo")
    path = write_manifest([record])
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "absolute path"

    record = base_record.merge("destination_repo" => "/nonexistent/repo")
    path = write_manifest([record])
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "not a directory"
  end

  def test_rejects_unresolvable_revisions
    record = base_record.merge("source_head" => "deadbeef" * 5)
    path = write_manifest([record])
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "does not resolve"
  end

  def test_rejects_duplicate_worktree_entries
    path = write_manifest([base_record, base_record])
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "duplicate"
  end

  def test_rejects_source_checkout_as_its_own_destination
    FileUtils.mkdir_p(File.join(@tmp, "wt"))
    record = base_record.merge("destination_repo" => File.join(@tmp, "wt"))
    path = write_manifest([record])
    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      Ace::Overseer::Molecules::PreservationManifest.load(path)
    end
    assert_includes e.message, "scheduled for deletion"
  end

def test_rejects_commit_sha_as_destination_branch
  record = base_record.merge("destination_branch" => @head)
  path = write_manifest([record])
  e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
    Ace::Overseer::Molecules::PreservationManifest.load(path)
  end
  assert_includes e.message, "must name an existing branch ref"
end

  def test_rejects_entries_not_matching_selected_worktrees
    FileUtils.mkdir_p(File.join(@tmp, "wt"))
    manifest = Ace::Overseer::Molecules::PreservationManifest.load(write_manifest([base_record]))

    e = assert_raises(Ace::Overseer::Molecules::PreservationManifest::Invalid) do
      manifest.ensure_all_match!([File.join(@tmp, "selected-elsewhere")])
    end
    assert_includes e.message, "do not match"

    manifest.ensure_all_match!([File.join(@tmp, "wt")])
  end
end

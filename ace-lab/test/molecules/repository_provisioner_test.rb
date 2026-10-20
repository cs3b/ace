# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

module Molecules
  class RepositoryProvisionerTest < Minitest::Test
    def setup
      @tmp = Dir.mktmpdir("repo-provisioner")
      @source = File.join(@tmp, "atlas.git")
      Open3.capture3("git", "init", "--bare", "-q", @source)
    end

    def teardown
      FileUtils.remove_entry(@tmp)
    end

    def provisioner(dry_run: false)
      Ace::Lab::Molecules::RepositoryProvisioner.new(dry_run: dry_run)
    end

    def test_clones_missing_path_from_remote
      path = File.join(@tmp, "atlas")

      result = provisioner.call(path: path, remote: @source)

      assert_equal "created", result["status"]
      assert File.directory?(File.join(path, ".git"))
    end

    def test_clones_into_existing_empty_directory
      path = File.join(@tmp, "atlas")
      Dir.mkdir(path)

      result = provisioner.call(path: path, remote: @source)

      assert_equal "created", result["status"]
    end

    def test_existing_repository_with_matching_origin_reports_exists
      path = clone_atlas
      add_origin(path)

      result = provisioner.call(path: path, remote: @source)

      assert_equal "exists", result["status"]
    end

    def test_existing_repository_without_origin_sets_it
      path = clone_atlas
      Open3.capture3("git", "-C", path, "remote", "remove", "origin")
      assert_nil origin_of(path)

      result = provisioner.call(path: path, remote: @source)

      assert_equal "created", result["status"]
      assert_equal @source, origin_of(path)
    end

    def test_repository_without_remote_and_no_declared_remote_reports_exists
      path = clone_atlas

      result = provisioner.call(path: path, remote: nil)

      assert_equal "exists", result["status"]
    end

    def test_conflicting_origin_is_refused_before_overwrite
      path = clone_atlas
      other = File.join(@tmp, "other.git")
      Open3.capture3("git", "init", "--bare", "-q", other)
      add_origin(path)

      result = provisioner.call(path: path, remote: other)

      assert_equal "failed", result["status"]
      assert_includes result["message"], "refusing to overwrite"
      assert_equal @source, origin_of(path)
    end

    def test_foreign_non_empty_directory_is_refused
      path = File.join(@tmp, "atlas")
      FileUtils.mkdir_p(File.join(path, "payload"))
      File.write(File.join(path, "payload", "keep.txt"), "team data\n")

      result = provisioner.call(path: path, remote: @source)

      assert_equal "failed", result["status"]
      assert_includes result["message"], "refusing to take over"
      assert File.file?(File.join(path, "payload", "keep.txt"))
    end

    def test_nested_directory_inside_a_parent_repo_is_refused_as_foreign
      # A non-empty directory inside an existing repository's work tree
      # is NOT that repository's toplevel: it must be refused as a
      # foreign location, never converged and never mutating the
      # parent's origin (review 8xikzhvh).
      parent = File.join(@tmp, "parent")
      Open3.capture3("git", "init", "-q", parent)
      path = File.join(parent, "nested")
      FileUtils.mkdir_p(path)
      File.write(File.join(path, "keep.txt"), "team data\n")

      result = provisioner.call(path: path, remote: @source)

      assert_equal "failed", result["status"]
      assert_includes result["message"], "refusing to take over"
      assert File.file?(File.join(path, "keep.txt"))
      # The parent repository's config was not mutated either.
      out, _err, status = Open3.capture3("git", "-C", parent, "remote", "get-url", "origin")
      refute status.success?
      assert_equal "", out.strip
    end

    def test_nested_directory_inside_a_parent_repo_is_refused_in_dry_run_too
      parent = File.join(@tmp, "parent")
      Open3.capture3("git", "init", "-q", parent)
      path = File.join(parent, "nested")
      FileUtils.mkdir_p(path)
      File.write(File.join(path, "keep.txt"), "team data\n")

      result = provisioner(dry_run: true).call(path: path, remote: @source)

      assert_equal "failed", result["status"]
      assert_includes result["message"], "refusing to take over"
      assert File.file?(File.join(path, "keep.txt"))
    end

    def test_missing_path_without_remote_fails_with_actionable_message
      path = File.join(@tmp, "atlas")

      result = provisioner.call(path: path, remote: nil)

      assert_equal "failed", result["status"]
      assert_includes result["message"], "no --remote"
    end

    def test_dry_run_predicts_clone_without_touching_the_filesystem
      path = File.join(@tmp, "atlas")

      result = provisioner(dry_run: true).call(path: path, remote: @source)

      assert_equal "would_create", result["status"]
      refute File.exist?(path)
    end

    private

    def clone_atlas
      path = File.join(@tmp, "atlas")
      Open3.capture3("git", "clone", "-q", @source, path)
      path
    end

    def add_origin(path)
      Open3.capture3("git", "-C", path, "remote", "add", "origin", @source)
    end

    def origin_of(path)
      out, _err, status = Open3.capture3("git", "-C", path, "remote", "get-url", "origin")
      status.success? ? out.strip : nil
    end

    # --- LAB-7: insteadOf rewrites must not break idempotent reuse -----

    def test_insteadof_rewrite_does_not_break_identical_project_reuse
      path = clone_atlas
      remote = "https://forge.example/atlas.git"
      Open3.capture3("git", "-C", path, "remote", "add", "origin", remote)
      Open3.capture3("git", "-C", path, "config", "url.ssh://git@forge.example/.insteadOf",
        "https://forge.example/")

      result = provisioner.call(path: path, remote: remote)

      assert_equal "exists", result["status"], result.inspect
    end
  end
end

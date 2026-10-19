# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

module Molecules
  class OverseerProvisionerTest < Minitest::Test
    def git_root
      # The ignore decision is real Git evaluation (`git check-ignore`),
      # so every root is an actual repository — exactly the surface
      # project add runs on (the repository step converges first).
      Dir.mktmpdir do |root|
        Open3.capture3("git", "init", "-q", root)
        skip "git unavailable" unless File.directory?(File.join(root, ".git"))

        yield root
      end
    end

    def provisioner(dry_run: false)
      Ace::Lab::Molecules::OverseerProvisioner.new(dry_run: dry_run)
    end

    def ignored?(root)
      _out, _err, status = Open3.capture3("git", "-C", root, "check-ignore", "--",
        ".ace-tasks/_overseer")
      status.success?
    end

    def test_creates_folder_and_gitignore_entry
      git_root do |root|
        result = provisioner.call(root: root)

        assert_equal "created", result["status"]
        assert File.directory?(File.join(root, ".ace-tasks", "_overseer"))
        assert_includes File.read(File.join(root, ".gitignore")), ".ace-tasks/_overseer/"
        assert ignored?(root), "provisioned folder must be effectively ignored"
      end
    end

    def test_re_run_reports_exists_without_rewriting
      git_root do |root|
        provisioner.call(root: root)
        gitignore = File.join(root, ".gitignore")
        content = File.read(gitignore)

        result = provisioner.call(root: root)

        assert_equal "exists", result["status"]
        assert_equal content, File.read(gitignore)
      end
    end

    def test_appends_to_existing_gitignore_without_destroying_content
      git_root do |root|
        gitignore = File.join(root, ".gitignore")
        File.write(gitignore, ".ace-local/\n")

        result = provisioner.call(root: root)

        assert_equal "created", result["status"]
        content = File.read(gitignore)
        assert content.start_with?(".ace-local/\n")
        assert_includes content, ".ace-tasks/_overseer/"
        assert ignored?(root)
      end
    end

    def test_recognizes_equivalent_existing_ignore_entry
      git_root do |root|
        FileUtils.mkdir_p(File.join(root, ".ace-tasks", "_overseer"))
        File.write(File.join(root, ".gitignore"), "/.ace-tasks/_overseer\n")

        result = provisioner.call(root: root)

        assert_equal "exists", result["status"]
        assert_equal "/.ace-tasks/_overseer\n", File.read(File.join(root, ".gitignore"))
      end
    end

    def test_negation_line_does_not_count_as_an_ignore_entry
      git_root do |root|
        FileUtils.mkdir_p(File.join(root, ".ace-tasks", "_overseer"))
        File.write(File.join(root, ".gitignore"), "!.ace-tasks/_overseer\n")

        result = provisioner.call(root: root)

        assert_equal "created", result["status"]
        content = File.read(File.join(root, ".gitignore"))
        assert_includes content, ".ace-tasks/_overseer/\n"
        assert content.start_with?("!.ace-tasks/_overseer\n")
        assert ignored?(root), "appended rule must beat the earlier negation"
      end
    end

    def test_dry_run_predicts_without_writing
      git_root do |root|
        result = provisioner(dry_run: true).call(root: root)

        assert_equal "would_create", result["status"]
        refute File.exist?(File.join(root, ".ace-tasks"))
        refute File.exist?(File.join(root, ".gitignore"))
      end
    end

    # --- LAB-5: later negation un-ignores a positive line -------------

    def test_effective_ignore_is_decided_by_real_git_not_line_matching
      git_root do |root|
        File.write(File.join(root, ".gitignore"), ".ace-tasks/_overseer/\n!.ace-tasks/_overseer/\n")

        result = provisioner.call(root: root)

        assert_includes %w[created exists], result["status"], result.inspect
        assert ignored?(root), "successful provisioning leaves the private folder unignored"
      end
    end

    # --- LAB-1: privileged writes never follow repo symlinks -----------

    def test_gitignore_symlink_is_refused_and_outside_files_survive
      Dir.mktmpdir do |dir|
        repo = File.join(dir, "repo")
        Open3.capture3("git", "init", "-q", repo)
        skip "git unavailable" unless File.directory?(File.join(repo, ".git"))

        victim = File.join(dir, "outside")
        File.write(victim, "outside file\n")
        File.symlink(victim, File.join(repo, ".gitignore"))

        result = Ace::Lab::Molecules::OverseerProvisioner.new.call(root: repo)

        assert_equal "failed", result["status"], result.inspect
        assert_match(/symbolic link/, result["message"])
        assert_equal "outside file\n", File.read(victim), "privileged write escaped the project"
        refute File.exist?(File.join(repo, ".ace-tasks"))
      end
    end

    def test_ace_tasks_symlink_is_refused_before_mkdir
      Dir.mktmpdir do |dir|
        repo = File.join(dir, "repo")
        Open3.capture3("git", "init", "-q", repo)
        skip "git unavailable" unless File.directory?(File.join(repo, ".git"))

        outside = File.join(dir, "outside")
        FileUtils.mkdir_p(outside)
        File.symlink(outside, File.join(repo, ".ace-tasks"))

        result = Ace::Lab::Molecules::OverseerProvisioner.new.call(root: repo)

        assert_equal "failed", result["status"], result.inspect
        assert_match(/symbolic link/, result["message"])
        # the mkdir never happened through the link
        assert_empty Dir.children(outside)
        assert File.symlink?(File.join(repo, ".ace-tasks"))
      end
    end
  end
end

    # Review round 2: a symlinked .gitignore is refused even when the
    # folder would already be considered ignored — no privileged
    # read-through (git check-ignore follows the link) either.
    def test_gitignore_symlink_is_refused_even_when_the_rule_already_matches
      Dir.mktmpdir do |dir|
        repo = File.join(dir, "repo")
        Open3.capture3("git", "init", "-q", repo)
        skip "git unavailable" unless File.directory?(File.join(repo, ".git"))

        FileUtils.mkdir_p(File.join(repo, ".ace-tasks", "_overseer"))
        victim = File.join(dir, "outside-ignore")
        File.write(victim, ".ace-tasks/_overseer/\n")
        File.symlink(victim, File.join(repo, ".gitignore"))

        result = Ace::Lab::Molecules::OverseerProvisioner.new.call(root: repo)

        assert_equal "failed", result["status"], result.inspect
        assert_match(/symbolic link/, result["message"])
        assert_equal ".ace-tasks/_overseer/\n", File.read(victim),
          "privileged read-through must not accept the link as evidence"
      end
    end

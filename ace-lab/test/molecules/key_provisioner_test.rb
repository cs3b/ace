# frozen_string_literal: true

require_relative "../test_helper"
require "delegate"
require "rbconfig"

module Molecules
  class KeyProvisionerTest < Minitest::Test
    def self_entry
      FakeEntry.new(name: "self", uid: Process.uid, gid: Process.gid, dir: Dir.home)
    end

    def provisioner(runner: nil, lookup: ->(_name) { self_entry }, dry_run: false)
      Ace::Lab::Molecules::KeyProvisioner.new(
        runner: runner, account_lookup: lookup, dry_run: dry_run
      )
    end

    def key(path)
      {"account" => "ace-worker", "type" => "ed25519", "path" => path}
    end

    def account
      {"username" => "ace-worker", "role" => "worker", "create" => false, "home" => "/home/ace-worker"}
    end

    def test_real_keygen_creates_pair_with_modes_ownership_and_fingerprint
      Dir.mktmpdir do |dir|
        path = File.join(dir, "home", ".ssh", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "created", result["status"]
        assert_nil result["message"]
        assert_match(/\ASHA256:[A-Za-z0-9+\/=]+\z/, result["fingerprint"])
        ssh_stat = File.stat(File.dirname(path))
        assert_equal 0o700, ssh_stat.mode & 0o7777
        assert_equal Process.uid, ssh_stat.uid
        assert_equal 0o600, File.stat(path).mode & 0o7777
        assert_equal Process.uid, File.stat(path).uid
        assert_equal 0o644, File.stat("#{path}.pub").mode & 0o7777
        assert_equal Process.uid, File.stat("#{path}.pub").uid
        # comment carries account@machine
        assert_includes File.read("#{path}.pub"), "ace-worker@lab01"
      end
    end

    def test_existing_pair_repairs_modes_and_reports_fingerprint
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        File.chmod(0o644, path)

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "exists", result["status"]
        assert_match(/\ASHA256:/, result["fingerprint"])
        assert_equal 0o600, File.stat(path).mode & 0o7777
      end
    end

    def test_missing_pub_is_regenerated_from_private_key
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        original_pub = File.read("#{path}.pub")
        File.delete("#{path}.pub")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "exists", result["status"]
        assert_match(/\ASHA256:/, result["fingerprint"])
        assert_equal original_pub, File.read("#{path}.pub")
        assert_equal 0o644, File.stat("#{path}.pub").mode & 0o7777
      end
    end

    def test_key_path_inside_git_worktree_is_refused
      Dir.mktmpdir do |dir|
        repo = File.join(dir, "repo")
        FileUtils.mkdir_p(File.join(repo, ".git"))
        path = File.join(repo, "secrets", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/inside a git worktree; secrets must not live in Git/, result["message"])
        refute File.exist?(path)
      end
    end

    # PR #392 F2: an ancestor symlink (alias -> repo/nested) hides the
    # physical target from a purely lexical walk. The guard must judge
    # the resolved location, including when `.ssh` does not exist yet
    # behind the existing alias.
    def test_ancestor_symlink_into_git_worktree_is_refused_even_without_ssh
      Dir.mktmpdir do |dir|
        repo = File.join(dir, "repo")
        FileUtils.mkdir_p([File.join(repo, ".git"), File.join(repo, "nested")])
        File.symlink(File.join(repo, "nested"), File.join(dir, "alias"))
        path = File.join(dir, "alias", ".ssh", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/inside a git worktree; secrets must not live in Git/, result["message"])
        refute File.exist?(File.join(repo, "nested", ".ssh"))
      end
    end

    # F2 with the alias target's `.ssh` already present as a plain
    # directory: the final-component symlink guard does not apply, only
    # physical-ancestor resolution catches it.
    def test_ancestor_symlink_with_existing_ssh_dir_into_git_is_refused
      Dir.mktmpdir do |dir|
        repo = File.join(dir, "repo")
        FileUtils.mkdir_p([File.join(repo, ".git"), File.join(repo, "nested", ".ssh")])
        File.symlink(File.join(repo, "nested"), File.join(dir, "alias"))
        path = File.join(dir, "alias", ".ssh", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/inside a git worktree; secrets must not live in Git/, result["message"])
        refute File.exist?(path)
      end
    end

    # A symlinked ancestor that resolves OUTSIDE any git worktree stays
    # legitimate: the guard resolves, it does not ban symlinks.
    def test_ancestor_symlink_outside_git_still_creates
      Dir.mktmpdir do |dir|
        homes = File.join(dir, "homes")
        FileUtils.mkdir_p(homes)
        File.symlink(homes, File.join(dir, "alias"))
        path = File.join(dir, "alias", ".ssh", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "created", result["status"]
        assert_match(/\ASHA256:/, result["fingerprint"])
        assert File.exist?(File.join(homes, ".ssh", "id_ed25519"))
      end
    end

    # PR #392 F4: unreadable garbage at the pair's paths is a failed
    # item, never exists with fingerprint:nil.
    def test_existing_broken_pair_files_fail
      Dir.mktmpdir do |dir|
        ssh = File.join(dir, ".ssh")
        Dir.mkdir(ssh, 0o700)
        path = File.join(ssh, "id_ed25519")
        File.write(path, "not a private key")
        File.chmod(0o600, path)
        File.write("#{path}.pub", "not a public key")
        File.chmod(0o644, "#{path}.pub")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_nil result["fingerprint"]
        assert_match(/not usable/, result["message"])
        # the unknown pair is never overwritten (takeover-refusal policy)
        assert_equal "not a private key", File.read(path)
      end
    end

    # F4: a public key belonging to a DIFFERENT private key fails the
    # match check — usable pairs only.
    def test_mismatched_public_key_fails_pair_verification
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        other_private = File.join(dir, "other_ed25519")
        provisioner.call(key: key(other_private), account: account, machine: "lab01")
        FileUtils.cp("#{other_private}.pub", "#{path}.pub")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_nil result["fingerprint"]
        assert_match(/not usable/, result["message"])
      end
    end

    def test_non_file_at_key_path_is_refused
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        FileUtils.mkdir(path)

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/not a regular file; refusing to overwrite/, result["message"])
      end
    end

    def test_unavailable_account_fails_with_dependency_message
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")

        result = provisioner(lookup: ->(_name) { nil })
          .call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/account 'ace-worker' is not available/, result["message"])
        assert_match(/fix the account phase first/, result["message"])
      end
    end

    def test_missing_ssh_keygen_binary_is_classified
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        # Runner mirrors the default runner's Errno::ENOENT classification
        runner = ->(_argv) { {"status" => "enoent", "out" => "", "err" => ""} }

        result = provisioner(runner: runner).call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/ssh-keygen not found in PATH/, result["message"])
      end
    end

    def test_eperm_is_classified_as_missing_permissions
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")

        FileUtils.stub :chown, ->(*_args) { raise Errno::EPERM } do
          result = provisioner.call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/insufficient permissions while preparing/, result["message"])
          assert_match(/rerun ace-lab prepare with sudo/, result["message"])
        end
      end
    end

    def test_dry_run_predicts_creation_without_mutating
      Dir.mktmpdir do |dir|
        path = File.join(dir, ".ssh", "id_ed25519")

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "would_create", result["status"]
        refute File.exist?(File.dirname(path))
      end
    end

    def test_dry_run_on_existing_pair_reports_exists_with_fingerprint_no_mutation
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        mtime = File.mtime(path)

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "exists", result["status"]
        assert_match(/\ASHA256:/, result["fingerprint"])
        assert_equal 0o600, File.stat(path).mode & 0o7777
        assert_equal mtime, File.mtime(path)
      end
    end

    def test_planted_ssh_dir_symlink_is_refused_without_touching_the_target
      Dir.mktmpdir do |dir|
        target = File.join(dir, "target-dir")
        Dir.mkdir(target)
        home = File.join(dir, "home")
        Dir.mkdir(home)
        File.symlink(target, File.join(home, ".ssh"))
        path = File.join(home, ".ssh", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/key directory .* is a symbolic link; refusing/, result["message"])
        # zero mutation of the symlink target: no chmod-to-0700, no
        # chown, no key material written through the link
        assert_equal 0o755, File.stat(target).mode & 0o7777
        assert_equal Process.uid, File.stat(target).uid
        assert_empty Dir.children(target)
        assert File.symlink?(File.join(home, ".ssh"))
      end
    end

    # F-1 regression: the wet existing-key path must refuse too. A
    # regular file at the key path (found through lstat) previously
    # went straight to chmod/chown — following the planted .ssh
    # symlink and taking over the victim's private key.
    def test_wet_existing_key_behind_planted_ssh_symlink_is_refused_victim_untouched
      Dir.mktmpdir do |dir|
        victim_ssh = File.join(dir, "victim-ssh")
        Dir.mkdir(victim_ssh)
        victim_key = File.join(victim_ssh, "id_ed25519")
        provisioner.call(key: key(victim_key), account: account, machine: "lab01")
        File.chmod(0o666, victim_key)
        File.chmod(0o666, "#{victim_key}.pub")
        home = File.join(dir, "home")
        Dir.mkdir(home)
        File.symlink(victim_ssh, File.join(home, ".ssh"))
        path = File.join(home, ".ssh", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/key directory .* is a symbolic link; refusing/, result["message"])
        # the victim's private/public key mode and owner are unchanged
        assert_equal 0o666, File.stat(victim_key).mode & 0o7777
        assert_equal 0o666, File.stat("#{victim_key}.pub").mode & 0o7777
        assert_equal Process.uid, File.stat(victim_key).uid
      end
    end

    # F-2: the .ssh leaf is swapped for a symlink mid-flight (after the
    # lstat guard, at the mkdir step) — the post-creation re-lstat must
    # refuse before any chmod/chown runs.
    def test_symlink_planted_mid_flight_at_mkdir_is_refused_without_chmod_chown
      Dir.mktmpdir do |dir|
        target = File.join(dir, "target-dir")
        Dir.mkdir(target)
        home = File.join(dir, "home")
        Dir.mkdir(home)
        path = File.join(home, ".ssh", "id_ed25519")
        chmod_calls = []

        FileUtils.stub :chmod, ->(*args) { chmod_calls << args } do
          Dir.stub :mkdir, ->(leaf) { File.symlink(target, leaf) } do
            result = provisioner.call(key: key(path), account: account, machine: "lab01")

            assert_equal "failed", result["status"]
            assert_match(/key directory .* changed while preparing; refusing/, result["message"])
            assert_match(/rerun ace-lab prepare/, result["message"])
            assert_empty chmod_calls
          end
        end

        # the planted symlink's target was not mutated
        assert_equal 0o755, File.stat(target).mode & 0o7777
        assert File.symlink?(File.join(home, ".ssh"))
      end
    end

    # F-3: genuine filesystem ENOENT prescribes a convergence rerun,
    # not "install ssh-keygen" (a missing binary is classified through
    # the runner's enoent status instead). The fd-based enforce opens
    # the private key with O_NOFOLLOW, so the ENOENT surfaces there.
    def test_filesystem_enoent_is_classified_as_disappeared_not_missing_binary
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")

        File.stub :open, ->(*_args) { raise Errno::ENOENT } do
          result = provisioner.call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/disappeared while preparing; rerun ace-lab prepare/, result["message"])
          refute_match(/ssh-keygen not found/, result["message"])
        end
      end
    end

    # Round-3 HIGH: the private-key chmod/chown is fd-based
    # (O_NOFOLLOW); a symlink swapped in at the private-key path after
    # the lstat guards raises ELOOP, which is refused — never followed.
    def test_eloop_on_fd_based_enforce_is_refused
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")

        File.stub :open, ->(*_args) { raise Errno::ELOOP } do
          result = provisioner.call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/replaced by a symbolic link while preparing; refusing/, result["message"])
          assert_match(/rerun ace-lab prepare/, result["message"])
        end
      end
    end

    # Round-3 HIGH (QA 1): mid-flight symlink swap at the private-key
    # path between keygen and the mode/ownership transfer — the
    # post-keygen regular-file lstat check must refuse before any
    # chmod/chown reaches the swap target.
    def test_mid_flight_symlink_swap_at_private_key_path_is_refused_without_chmod_chown
      Dir.mktmpdir do |dir|
        victim = File.join(dir, "victim-key")
        File.write(victim, "victim material")
        home = File.join(dir, "home")
        FileUtils.mkdir_p(home)
        path = File.join(home, "id_ed25519")
        swap_runner = lambda do |argv|
          if argv.first == "ssh-keygen" && argv.include?("-q")
            # fake keygen: write the pair, then swap the private key
            # for a symlink before the provisioner enforces modes
            File.write(path, "fake private\n")
            File.write("#{path}.pub", "fake public\n")
            File.delete(path)
            File.symlink(victim, path)
            {"status" => "ok", "out" => "", "err" => ""}
          else
            {"status" => "ok", "out" => "", "err" => ""}
          end
        end

        result = provisioner(runner: swap_runner).call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/not written as a regular file; refusing/, result["message"])
        # zero mutation of the swap target: content, mode and owner unchanged
        assert_equal "victim material", File.read(victim)
        assert_equal 0o644, File.stat(victim).mode & 0o7777
        assert_equal Process.uid, File.stat(victim).uid
        assert File.symlink?(path)
      end
    end

    def test_planted_ssh_dir_symlink_is_refused_in_dry_run_too
      Dir.mktmpdir do |dir|
        target = File.join(dir, "target-dir")
        Dir.mkdir(target)
        home = File.join(dir, "home")
        Dir.mkdir(home)
        File.symlink(target, File.join(home, ".ssh"))
        path = File.join(home, ".ssh", "id_ed25519")

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/symbolic link; refusing/, result["message"])
        assert_empty Dir.children(target)
      end
    end

    # Round-3 MEDIUM (QA 3): the wet existing-key path refuses a planted
    # .ssh symlink — dry-run must predict that refusal, not `exists`.
    def test_dry_run_existing_key_behind_planted_ssh_symlink_is_refused_not_exists
      Dir.mktmpdir do |dir|
        victim_ssh = File.join(dir, "victim-ssh")
        Dir.mkdir(victim_ssh)
        victim_key = File.join(victim_ssh, "id_ed25519")
        provisioner.call(key: key(victim_key), account: account, machine: "lab01")
        home = File.join(dir, "home")
        Dir.mkdir(home)
        File.symlink(victim_ssh, File.join(home, ".ssh"))
        path = File.join(home, ".ssh", "id_ed25519")

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/key directory .* is a symbolic link; refusing/, result["message"])
        assert_nil result["fingerprint"]
      end
    end

    # Round-3 MEDIUM (QA 5): ownership-drift policy mirrors directories —
    # a pre-existing pair owned by a foreign uid is refused, never
    # silently chowned to the account. A delegator stat simulates the
    # foreign uid (tests run unprivileged and cannot really chown).
    class SwappedUidStat < SimpleDelegator
      def initialize(stat, uid)
        super(stat)
        @uid = uid
      end

      def uid
        @uid
      end
    end

    def with_foreign_owned_private_key(path)
      foreign_uid = Process.uid + 999
      real_lstat = File.method(:lstat)
      File.stub :lstat, ->(p) { p == path ? SwappedUidStat.new(real_lstat.call(p), foreign_uid) : real_lstat.call(p) } do
        yield foreign_uid
      end
    end

    def test_foreign_owned_existing_pair_is_refused_never_taken_over
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        before = File.stat(path).mode & 0o7777

        with_foreign_owned_private_key(path) do |foreign_uid|
          result = provisioner.call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/owned by uid #{foreign_uid}/, result["message"])
          assert_match(/expected account 'self'; refusing takeover/, result["message"])
          assert_match(/resolve ownership manually/, result["message"])
        end
        # no mutation happened while the foreign stat was visible
        assert_equal before, File.stat(path).mode & 0o7777
        assert_equal Process.uid, File.stat(path).uid
      end
    end

    def test_foreign_owned_existing_pair_is_refused_in_dry_run_too
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")

        with_foreign_owned_private_key(path) do |foreign_uid|
          result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/owned by uid #{foreign_uid}.*refusing takeover/, result["message"])
        end
      end
    end

    def test_non_directory_at_ssh_dir_path_is_refused
      Dir.mktmpdir do |dir|
        home = File.join(dir, "home")
        Dir.mkdir(home)
        File.write(File.join(home, ".ssh"), "occupied")
        path = File.join(home, ".ssh", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/exists but is not a directory; refusing/, result["message"])
      end
    end

    def test_dangling_pub_symlink_is_refused_without_arbitrary_write
      Dir.mktmpdir do |dir|
        victim = File.join(dir, "victim")
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        File.delete("#{path}.pub")
        File.symlink(victim, "#{path}.pub")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/public key .* exists but is not a regular file; refusing/, result["message"])
        # the regenerated public key must not land on the symlink target
        refute File.exist?(victim)
        assert File.symlink?("#{path}.pub")
      end
    end

    def test_pub_symlink_to_directory_is_refused
      Dir.mktmpdir do |dir|
        victim = File.join(dir, "victim-dir")
        Dir.mkdir(victim)
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        File.delete("#{path}.pub")
        File.symlink(victim, "#{path}.pub")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/not a regular file; refusing/, result["message"])
        assert_empty Dir.children(victim)
      end
    end

    def test_dangling_pub_symlink_is_refused_in_dry_run_too
      Dir.mktmpdir do |dir|
        victim = File.join(dir, "victim")
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        File.delete("#{path}.pub")
        File.symlink(victim, "#{path}.pub")

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/not a regular file; refusing/, result["message"])
        refute File.exist?(victim)
      end
    end

    def test_dry_run_missing_pub_predicts_repair_not_failure
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        File.delete("#{path}.pub")

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        # the wet run regenerates the .pub — the prediction must say so
        assert_equal "would_repair_public", result["status"]
        assert_nil result["message"]
        refute File.exist?("#{path}.pub")
      end
    end

    def test_dry_run_mode_drift_on_existing_pair_predicts_fix
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        File.chmod(0o644, path)

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "would_fix_mode", result["status"]
        assert_nil result["message"]
        assert_equal 0o644, File.stat(path).mode & 0o7777
      end
    end

    # 8xi16mz2: dry-run/wet parity for a garbage pair with mode drift.
    # The wet run converges the modes and then fails verification, so
    # the prediction must say failed (not usable) too — never
    # would_fix_mode, which would green-light a failing prepare.
    def test_dry_run_wet_parity_for_broken_pair_with_mode_drift
      Dir.mktmpdir do |dir|
        ssh = File.join(dir, ".ssh")
        Dir.mkdir(ssh, 0o700)
        path = File.join(ssh, "id_ed25519")
        File.write(path, "not a private key")
        File.chmod(0o644, path)
        File.write("#{path}.pub", "not a public key")
        File.chmod(0o644, "#{path}.pub")

        dry = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")
        wet = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal wet["status"], dry["status"]
        assert_equal "failed", dry["status"]
        assert_match(/not usable/, dry["message"])
        assert_match(/not usable/, wet["message"])
        # the wet run converged the modes but never overwrote the pair
        assert_equal 0o600, File.stat(path).mode & 0o7777
        assert_equal "not a private key", File.read(path)
      end
    end

    def test_dry_run_with_unresolvable_account_predicts_creation_instead_of_failing
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")

        # production lookup for a not-yet-created account returns nil —
        # the account phase would create it, so dry-run must predict
        result = provisioner(lookup: ->(_name) { nil }, dry_run: true)
          .call(key: key(path), account: account, machine: "lab01")

        assert_equal "would_create", result["status"]
        assert_nil result["message"]
        refute File.exist?(path)
      end
    end

    def test_secret_hygiene_canary_fingerprint_but_never_private_key_bytes
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        created = provisioner.call(key: key(path), account: account, machine: "lab01")
        exists = provisioner.call(key: key(path), account: account, machine: "lab01")
        private_bytes = File.read(path)

        rendered = JSON.generate([created, exists])

        # fingerprint present, private key material absent — everywhere
        assert_match(/SHA256:/, rendered)
        private_bytes.lines.each do |line|
          next if line.strip.empty? || line.start_with?("-----")

          refute_includes rendered, line.strip
        end
        refute_includes rendered, "OPENSSH PRIVATE KEY"
      end
    end

    # Round-4 H1: the manifest home is a leftover regular file —
    # mkdir_p re-raises EEXIST — which previously escaped the molecule
    # as a raw backtrace. It must be a classified failed item.
    def test_regular_file_at_manifest_home_is_classified_failure_not_crash
      Dir.mktmpdir do |dir|
        home = File.join(dir, "ace-worker")
        File.write(home, "leftover")
        path = File.join(home, ".ssh", "id_ed25519")

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_nil result["fingerprint"]
        assert_match(/key directory .* could not be created/, result["message"])
        assert_match(/check the parent path and rerun ace-lab prepare/, result["message"])
        # the leftover file is untouched
        assert File.file?(home)
        assert_equal "leftover", File.read(home)
      end
    end

    # Round-4 H1: any other SystemCallError on the provision path
    # (here ELOOP on the path-based directory chmod in a race) hits the
    # method-level classifier — classified failed item, errno named.
    def test_unclassified_systemcallerror_is_classified_with_errno_name
      Dir.mktmpdir do |dir|
        path = File.join(dir, ".ssh", "id_ed25519")

        FileUtils.stub :chmod, ->(*_args) { raise Errno::ELOOP } do
          result = provisioner.call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/key path .* could not be prepared \(Errno::ELOOP\)/, result["message"])
          assert_match(/rerun ace-lab prepare/, result["message"])
        end
      end
    end

    # Round-4 M1: the ".ssh is 0700" invariant is converged on the
    # existing-key path, not only at creation.
    def test_existing_pair_converges_ssh_dir_mode_drift
      Dir.mktmpdir do |dir|
        path = File.join(dir, ".ssh", "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        File.chmod(0o755, File.dirname(path))

        result = provisioner.call(key: key(path), account: account, machine: "lab01")

        assert_equal "exists", result["status"]
        assert_match(/\ASHA256:/, result["fingerprint"])
        assert_equal 0o700, File.stat(File.dirname(path)).mode & 0o7777
      end
    end

    def test_dry_run_predicts_ssh_dir_mode_drift_as_would_fix_mode
      Dir.mktmpdir do |dir|
        path = File.join(dir, ".ssh", "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        File.chmod(0o755, File.dirname(path))

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "would_fix_mode", result["status"]
        assert_nil result["message"]
        assert_equal 0o755, File.stat(File.dirname(path)).mode & 0o7777
      end
    end

    # Round-4 M1: an installer-owned .ssh (uid not the account's) is
    # drift on the existing path, predicted by dry-run like file drift.
    def test_dry_run_predicts_ssh_dir_ownership_drift_as_would_fix_mode
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        other = FakeEntry.new(name: "ace-worker", uid: Process.uid + 1, gid: Process.gid,
          dir: "/home/ace-worker")

        result = provisioner(lookup: ->(_name) { other }, dry_run: true)
          .call(key: key(path), account: account, machine: "lab01")

        # key files and .ssh are installer-owned here, the account owns
        # nothing yet — the wet run would transfer all of it
        assert_equal "would_fix_mode", result["status"]
        assert_nil result["message"]
      end
    end

    # Round-4 M3: a pre-existing foreign-uid .ssh plus missing key —
    # the generate path refuses the takeover (chmod/chown to the
    # account would silently take over a third party's directory).
    def test_preexisting_foreign_owned_ssh_dir_is_refused_without_takeover
      Dir.mktmpdir do |dir|
        home = File.join(dir, "home")
        Dir.mkdir(home)
        ssh_dir = File.join(home, ".ssh")
        Dir.mkdir(ssh_dir)
        File.chmod(0o755, ssh_dir)
        path = File.join(ssh_dir, "id_ed25519")
        foreign_uid = Process.uid + 999
        real_lstat = File.method(:lstat)

        File.stub :lstat, ->(p) { p == ssh_dir ? SwappedUidStat.new(real_lstat.call(p), foreign_uid) : real_lstat.call(p) } do
          result = provisioner.call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/key directory .* is owned by uid #{foreign_uid}/, result["message"])
          assert_match(/refusing takeover/, result["message"])
          assert_match(/resolve ownership manually/, result["message"])
        end
        # zero mutation: mode and owner unchanged, no key written
        assert_equal 0o755, File.stat(ssh_dir).mode & 0o7777
        assert_equal Process.uid, File.stat(ssh_dir).uid
        assert_empty Dir.children(ssh_dir)
      end
    end

    def test_dry_run_foreign_owned_ssh_dir_predicts_the_refusal
      Dir.mktmpdir do |dir|
        home = File.join(dir, "home")
        Dir.mkdir(home)
        ssh_dir = File.join(home, ".ssh")
        Dir.mkdir(ssh_dir)
        File.chmod(0o755, ssh_dir)
        path = File.join(ssh_dir, "id_ed25519")
        foreign_uid = Process.uid + 999
        real_lstat = File.method(:lstat)

        File.stub :lstat, ->(p) { p == ssh_dir ? SwappedUidStat.new(real_lstat.call(p), foreign_uid) : real_lstat.call(p) } do
          result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/owned by uid #{foreign_uid}.*refusing takeover/, result["message"])
        end
        assert_equal 0o755, File.stat(ssh_dir).mode & 0o7777
        assert_empty Dir.children(ssh_dir)
      end
    end

    # Round-4 M3 on the existing-key path: a foreign-owned .ssh around
    # an account-owned pair is refused before any convergence runs.
    def test_existing_pair_under_foreign_owned_ssh_dir_is_refused
      Dir.mktmpdir do |dir|
        path = File.join(dir, ".ssh", "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")
        ssh_dir = File.dirname(path)
        File.chmod(0o755, ssh_dir)
        foreign_uid = Process.uid + 999
        real_lstat = File.method(:lstat)

        File.stub :lstat, ->(p) { p == ssh_dir ? SwappedUidStat.new(real_lstat.call(p), foreign_uid) : real_lstat.call(p) } do
          result = provisioner.call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/key directory .* owned by uid #{foreign_uid}/, result["message"])
          assert_match(/refusing takeover/, result["message"])
        end
        # nothing converged while the foreign stat was visible
        assert_equal 0o755, File.stat(ssh_dir).mode & 0o7777
        assert_equal Process.uid, File.stat(ssh_dir).uid
      end
    end
    # Round-5 S1: a pre-planted dangling <key>.pub symlink on the
    # GENERATE path must be refused before ssh-keygen is invoked —
    # keygen creates the .pub by path and would write through the
    # symlink (root-owned file creation at an account-chosen location).
    def test_preplanted_dangling_pub_symlink_on_generate_is_refused_with_zero_mutation
      Dir.mktmpdir do |dir|
        victim = File.join(dir, "victim")
        home = File.join(dir, "home")
        FileUtils.mkdir_p(File.join(home, ".ssh"))
        path = File.join(home, ".ssh", "id_ed25519")
        File.symlink(victim, "#{path}.pub")
        runner_calls = []
        runner = ->(argv) { runner_calls << argv; {"status" => "ok", "out" => "", "err" => ""} }

        result = provisioner(runner: runner).call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/public key .* exists but is not a regular file; refusing/, result["message"])
        # zero mutation: ssh-keygen never ran, the victim was not
        # created through the symlink, the private key does not exist
        assert_empty runner_calls
        refute File.exist?(victim)
        refute File.exist?(path)
        assert File.symlink?("#{path}.pub")
      end
    end

    # Round-5 S1 predict parity: dry-run must predict the wet refusal,
    # not would_create.
    def test_dry_run_predicts_preplanted_pub_symlink_refusal_on_missing_private
      Dir.mktmpdir do |dir|
        victim = File.join(dir, "victim")
        home = File.join(dir, "home")
        FileUtils.mkdir_p(File.join(home, ".ssh"))
        path = File.join(home, ".ssh", "id_ed25519")
        File.symlink(victim, "#{path}.pub")

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/not a regular file; refusing/, result["message"])
        assert_nil result["fingerprint"]
        refute File.exist?(victim)
        refute File.exist?(path)
      end
    end

    # Round-5 S2: the .ssh ownership transfer is deferred until after
    # the post-keygen verification — during keygen the directory is
    # still installer-owned (unwritable by the account).
    def test_ssh_dir_chown_is_deferred_until_after_keygen_verification
      Dir.mktmpdir do |dir|
        path = File.join(dir, ".ssh", "id_ed25519")
        order = []
        runner = lambda do |argv|
          if argv.first == "ssh-keygen" && argv.include?("-q")
            order << :keygen
            # fake keygen: materialize the pair so the post-keygen
            # verification passes
            File.write(path, "fake private\n")
            File.write("#{path}.pub", "fake public\n")
            {"status" => "ok", "out" => "", "err" => ""}
          elsif argv.first == "ssh-keygen" && argv.include?("-lf")
            # pair verification: any fingerprint matches itself
            {"status" => "ok", "out" => "256 SHA256:FAKEFAKEFAKE test (ED25519)\n", "err" => ""}
          elsif argv.first == "ssh-keygen" && argv.include?("-y")
            {"status" => "ok", "out" => "ssh-ed25519 fake-derived\n", "err" => ""}
          else
            {"status" => "ok", "out" => "", "err" => ""}
          end
        end

        FileUtils.stub :chown, ->(_uid, _gid, p) { order << [:chown, p] } do
          result = provisioner(runner: runner).call(key: key(path), account: account, machine: "lab01")

          assert_equal "created", result["status"]
        end

        keygen_at = order.index(:keygen)
        chown_at = order.index { |entry| entry.is_a?(Array) && entry.last == File.dirname(path) }
        refute_nil keygen_at
        refute_nil chown_at
        assert_operator chown_at, :>, keygen_at
      end
    end

    # Round-5 C2: a signal-killed ssh-keygen (nil exitstatus) renders
    # "signal <termsig>", never a malformed "exit ".
    def test_signal_killed_keygen_renders_signal_not_malformed_exit
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        runner = ->(_argv) { {"status" => "signal 9", "out" => "", "err" => ""} }

        result = provisioner(runner: runner).call(key: key(path), account: account, machine: "lab01")

        assert_equal "failed", result["status"]
        assert_match(/ssh-keygen failed \(signal 9\)/, result["message"])
        refute_match(/exit \)/, result["message"])
      end
    end

    # Round-5 C2: the default runner maps a real signal death of the
    # child to "signal <termsig>" (exitstatus is nil there).
    def test_run_argv_renders_signal_for_signal_killed_child
      result = provisioner.send(:run_argv,
        [RbConfig.ruby, "-e", "Process.kill('KILL', Process.pid)"])

      assert_equal "signal 9", result["status"]
    end

    # Round-5 C4: an existing pair owned by a foreign uid under an
    # account the phase would create — the wet run (uid resolvable
    # after creation) would refuse takeover, so dry-run predicts the
    # refusal conservatively instead of `exists`.
    def test_dry_run_foreign_owned_pair_with_would_create_account_predicts_takeover_refusal
      Dir.mktmpdir do |dir|
        path = File.join(dir, "id_ed25519")
        provisioner.call(key: key(path), account: account, machine: "lab01")

        with_foreign_owned_private_key(path) do |foreign_uid|
          result = provisioner(lookup: ->(_name) { nil }, dry_run: true)
            .call(key: key(path), account: account, machine: "lab01")

          assert_equal "failed", result["status"]
          assert_match(/owned by uid #{foreign_uid}/, result["message"])
          assert_match(/refuse takeover/, result["message"])
          assert_match(/resolve ownership manually/, result["message"])
          refute_match(/fix the account phase/, result["message"])
        end
      end
    end
  end
end

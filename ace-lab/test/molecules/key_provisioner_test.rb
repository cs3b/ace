# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class KeyProvisionerTest < Minitest::Test
    FakeEntry = Struct.new(:name, :uid, :gid, :dir, keyword_init: true)

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
        assert_match(/\ASHA256:[A-Za-z0-9+\/=+]+\z/, result["fingerprint"])
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
        File.chmod(0o644, path)
        mtime = File.mtime(path)

        result = provisioner(dry_run: true).call(key: key(path), account: account, machine: "lab01")

        assert_equal "exists", result["status"]
        assert_match(/\ASHA256:/, result["fingerprint"])
        assert_equal 0o644, File.stat(path).mode & 0o7777
        assert_equal mtime, File.mtime(path)
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
  end
end

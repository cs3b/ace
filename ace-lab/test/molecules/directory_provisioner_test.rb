# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class DirectoryProvisionerTest < Minitest::Test
    FakeEntry = Struct.new(:name, :uid, :gid, :dir, keyword_init: true)

    def self_entry
      FakeEntry.new(name: "self", uid: Process.uid, gid: Process.gid, dir: Dir.home)
    end

    def provisioner(lookup: ->(_name) { self_entry }, dry_run: false)
      Ace::Lab::Molecules::DirectoryProvisioner.new(account_lookup: lookup, dry_run: dry_run)
    end

    def directory(path, owner: "self", mode: "0750")
      {"path" => path, "owner" => owner, "mode" => mode}
    end

    def test_creates_missing_directory_with_mode_and_ownership
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")

        result = provisioner.call(directory: directory(path))

        assert_equal "created", result["status"]
        stat = File.stat(path)
        assert stat.directory?
        assert_equal 0o750, stat.mode & 0o7777
        assert_equal Process.uid, stat.uid
      end
    end

    def test_existing_matching_directory_reports_exists
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        Dir.mkdir(path)
        File.chmod(0o750, path)

        result = provisioner.call(directory: directory(path))

        assert_equal "exists", result["status"]
        assert_nil result["message"]
      end
    end

    def test_mode_drift_is_repaired
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        Dir.mkdir(path)
        File.chmod(0o700, path)

        result = provisioner.call(directory: directory(path))

        assert_equal "mode_fixed", result["status"]
        assert_equal 0o750, File.stat(path).mode & 0o7777
      end
    end

    def test_foreign_owner_directory_is_refused_never_taken_over
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        Dir.mkdir(path)
        File.chmod(0o750, path)
        other = FakeEntry.new(name: "other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        result = provisioner(lookup: ->(_name) { other }).call(directory: directory(path))

        assert_equal "failed", result["status"]
        assert_match(/exists but is owned by uid #{Process.uid}/, result["message"])
        assert_match(/expected account 'self'/, result["message"])
        assert_match(/refusing takeover/, result["message"])
        # ownership untouched
        assert_equal Process.uid, File.stat(path).uid
      end
    end

    def test_symlink_at_path_is_refused
      Dir.mktmpdir do |dir|
        target = File.join(dir, "real")
        Dir.mkdir(target)
        link = File.join(dir, "labs")
        File.symlink(target, link)

        result = provisioner.call(directory: directory(link))

        assert_equal "failed", result["status"]
        assert_match(/is a symbolic link; refusing/, result["message"])
      end
    end

    def test_regular_file_at_path_is_refused
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        File.write(path, "occupied")

        result = provisioner.call(directory: directory(path))

        assert_equal "failed", result["status"]
        assert_match(/occupied by a non-directory; refusing/, result["message"])
      end
    end

    def test_eperm_on_chown_is_classified_as_missing_permissions
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        directory_entry = directory(path)

        FileUtils.stub :chown, ->(*_args) { raise Errno::EPERM } do
          result = provisioner.call(directory: directory_entry)

          assert_equal "failed", result["status"]
          assert_match(/insufficient permissions while preparing/, result["message"])
          assert_match(/rerun ace-lab prepare with sudo/, result["message"])
        end
      end
    end

    def test_eperm_on_chmod_is_classified_as_missing_permissions
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        Dir.mkdir(path)

        FileUtils.stub :chmod, ->(*_args) { raise Errno::EPERM } do
          result = provisioner.call(directory: directory(path))

          assert_equal "failed", result["status"]
          assert_match(/insufficient permissions while preparing/, result["message"])
        end
      end
    end

    def test_unresolvable_owner_account_fails_with_dependency_message
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")

        result = provisioner(lookup: ->(_name) { nil }).call(directory: directory(path))

        assert_equal "failed", result["status"]
        assert_match(/owner account 'self' is not available on this machine/, result["message"])
        assert_match(/fix the account phase first/, result["message"])
        refute File.exist?(path)
      end
    end

    def test_dry_run_never_mutates_the_filesystem
      Dir.mktmpdir do |dir|
        missing = File.join(dir, "missing")
        drifted = File.join(dir, "drifted")
        Dir.mkdir(drifted)
        File.chmod(0o700, drifted)

        predicted_missing = provisioner(dry_run: true).call(directory: directory(missing))
        predicted_drift = provisioner(dry_run: true).call(directory: directory(drifted))

        assert_equal "would_create", predicted_missing["status"]
        assert_equal "would_fix_mode", predicted_drift["status"]
        refute File.exist?(missing)
        assert_equal 0o700, File.stat(drifted).mode & 0o7777
      end
    end

    def test_dry_run_on_matching_existing_directory_reports_exists
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        Dir.mkdir(path)
        File.chmod(0o750, path)

        result = provisioner(dry_run: true).call(directory: directory(path))

        assert_equal "exists", result["status"]
      end
    end
  end
end

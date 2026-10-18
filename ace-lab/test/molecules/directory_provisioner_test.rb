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

    # Every failed entry must carry the full {path, owner, mode} shape —
    # one shape per section for JSON consumers, rescue paths included.
    def test_refused_entries_carry_owner_and_mode_keys
      Dir.mktmpdir do |dir|
        occupied = File.join(dir, "occupied")
        File.write(occupied, "occupied")
        link = File.join(dir, "link")
        File.symlink(occupied, link)

        occupied_result = provisioner.call(directory: directory(occupied))
        link_result = provisioner.call(directory: directory(link))

        [occupied_result, link_result].each do |result|
          assert_equal "failed", result["status"]
          assert_equal "self", result["owner"]
          assert_equal "0750", result["mode"]
          assert_equal %w[path owner mode status message].sort, result.keys.sort
        end
      end
    end

    def test_dry_run_existing_directory_with_would_create_owner_reports_prediction_limit
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        Dir.mkdir(path)
        File.chmod(0o750, path)

        result = provisioner(lookup: ->(_name) { nil }, dry_run: true).call(directory: directory(path))

        assert_equal "failed", result["status"]
        assert_match(/the account phase would create it/, result["message"])
        assert_match(/cannot be predicted before the account exists/, result["message"])
        assert_equal 0o750, File.stat(path).mode & 0o7777
      end
    end

    # F-2: the declared leaf is swapped for a symlink mid-flight (after
    # the top-level lstat, at the mkdir step) — the post-creation
    # re-lstat must refuse before any chmod/chown runs.
    def test_symlink_planted_mid_flight_at_mkdir_is_refused_without_chmod_chown
      Dir.mktmpdir do |dir|
        target = File.join(dir, "target-dir")
        Dir.mkdir(target)
        path = File.join(dir, "labs")
        chmod_calls = []

        FileUtils.stub :chmod, ->(*args) { chmod_calls << args } do
          Dir.stub :mkdir, ->(leaf) { File.symlink(target, leaf) } do
            result = provisioner.call(directory: directory(path))

            assert_equal "failed", result["status"]
            assert_match(/path .* changed while preparing; refusing/, result["message"])
            assert_match(/rerun ace-lab prepare/, result["message"])
            assert_empty chmod_calls
          end
        end

        # the planted symlink's target was not mutated
        assert_equal 0o755, File.stat(target).mode & 0o7777
        assert File.symlink?(path)
      end
    end

    # F-2: a leaf appearing in the race window between the guard lstat
    # and the leaf mkdir (EEXIST) is refused, not adopted and chmodded.
    def test_leaf_appearing_between_guard_and_mkdir_is_refused
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")

        Dir.stub :mkdir, ->(leaf) { system("mkdir", leaf) || raise("mkdir failed"); raise Errno::EEXIST } do
          result = provisioner.call(directory: directory(path))

          assert_equal "failed", result["status"]
          assert_match(/appeared or was replaced while preparing; refusing/, result["message"])
        end

        # left exactly as the concurrent creator made it — no chmod to
        # the declared 0750, no chown
        assert File.directory?(path)
        refute_equal 0o750, File.stat(path).mode & 0o7777
      end
    end

    # F-2: the mode-fix path re-lstats before chmod — a directory
    # swapped for a symlink after the owner check is refused instead of
    # chmodded through the link.
    def test_directory_swapped_after_owner_check_is_refused_before_mode_fix
      Dir.mktmpdir do |dir|
        path = File.join(dir, "labs")
        Dir.mkdir(path)
        File.chmod(0o700, path) # drift: ensure_existing takes the mode-fix path
        swapped_stat = Struct.new(:symlink?, :directory?, :uid, :mode).new(true, false, Process.uid, 0o700)
        real_lstat = File.method(:lstat)
        stat_calls = []
        chmod_called = false

        # first lstat (guard): the real drifted directory; second lstat
        # (pre-chmod re-check): the swapped symlink
        File.stub :lstat, ->(candidate) {
          next real_lstat.call(candidate) unless candidate == path

          stat_calls << candidate
          stat_calls.count > 1 ? swapped_stat : real_lstat.call(candidate)
        } do
          FileUtils.stub :chmod, ->(*_args) { chmod_called = true } do
            result = provisioner.call(directory: directory(path))

            assert_equal "failed", result["status"]
            assert_match(/changed while preparing; refusing/, result["message"])
            assert_match(/rerun ace-lab prepare/, result["message"])
            refute chmod_called
          end
        end

        assert_equal 0o700, File.stat(path).mode & 0o7777
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class AccountProvisionerTest < Minitest::Test
    FakeEntry = Struct.new(:name, :uid, :gid, :dir, keyword_init: true)

    attr_reader :calls

    def setup
      @calls = []
    end

    # Fake runner records argv arrays (ADR-031) and returns canned results
    # per command word.
    def fake_runner(responses = {})
      ->(argv) {
        @calls << argv
        response = responses.fetch(argv.first, {"status" => "ok", "out" => "", "err" => ""})
        response.is_a?(Hash) ? response : response.call(argv)
      }
    end

    def provisioner(runner: fake_runner, lookup: ->(_name) { nil }, privileged: -> { true },
      platform: "darwin", dry_run: false)
      Ace::Lab::Molecules::AccountProvisioner.new(
        runner: runner, account_lookup: lookup, privileged: privileged,
        platform: platform, dry_run: dry_run
      )
    end

    def account(overrides = {})
      {"username" => "ace-worker", "role" => "worker", "create" => false,
       "home" => "/home/ace-worker"}.merge(overrides)
    end

    def test_existing_account_reports_exists_with_uid
      provisioner = Ace::Lab::Molecules::AccountProvisioner.new(
        runner: fake_runner, account_lookup: ->(_name) { FakeEntry.new(name: "ace-worker", uid: 503, gid: 20, dir: "/home/ace-worker") },
        privileged: -> { false }, platform: "darwin"
      )

      result = provisioner.call(account: account)

      assert_equal "exists", result["status"]
      assert_equal 503, result["uid"]
      assert_nil result["message"]
      assert_empty calls
    end

    def test_missing_account_without_create_is_an_actionable_failure
      result = provisioner.call(account: account)

      assert_equal "failed", result["status"]
      assert_equal "ace-worker", result["username"]
      assert_match(/account 'ace-worker' does not exist/, result["message"])
      assert_match(/create it manually \(administrator action\) or set create: true/, result["message"])
      assert_empty calls
    end

    def test_missing_account_with_create_unprivileged_is_classified_permission_failure
      result = provisioner(privileged: -> { false }).call(account: account("create" => true))

      assert_equal "failed", result["status"]
      assert_match(/requires administrator privileges/, result["message"])
      assert_match(/rerun ace-lab prepare with sudo/, result["message"])
      assert_empty calls
    end

    def test_privileged_darwin_creation_runs_full_dscl_sequence_with_allocated_uid
      runner = fake_runner("dscl" => {"status" => "ok",
        "out" => "root 0\n_daemon 1\nnobody 4294967294\nace-other 510\n", "err" => ""})

      result = provisioner(runner: runner).call(account: account("create" => true))

      assert_equal "created", result["status"]
      assert_equal 511, result["uid"]
      assert_nil result["message"]
      # argv arrays, never shell strings (ADR-031)
      assert_equal ["dscl", ".", "-list", "/Users", "UniqueID"], calls.first
      assert_includes calls, ["dscl", ".", "-create", "/Users/ace-worker", "RealName", "ace-worker"]
      assert_includes calls, ["dscl", ".", "-create", "/Users/ace-worker", "UniqueID", "511"]
      assert_includes calls, ["dscl", ".", "-create", "/Users/ace-worker", "PrimaryGroupID", "20"]
      assert_includes calls, ["dscl", ".", "-create", "/Users/ace-worker", "UserShell", "/bin/zsh"]
      assert_includes calls, ["dscl", ".", "-create", "/Users/ace-worker", "NFSHomeDirectory", "/home/ace-worker"]
      # complete dscl account shape: GeneratedUUID + disabled Password
      guid_step = calls.find { |argv| argv[4] == "GeneratedUID" }
      assert_equal ["dscl", ".", "-create", "/Users/ace-worker", "GeneratedUID"], guid_step[0, 5]
      assert_match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/, guid_step[5])
      assert_includes calls, ["dscl", ".", "-create", "/Users/ace-worker", "Password", "*"]
      assert_equal ["createhomedir", "-c", "-u", "ace-worker"], calls.last
    end

    def test_darwin_uid_allocation_floors_at_501
      runner = fake_runner("dscl" => {"status" => "ok", "out" => "root 0\n_daemon 1\n", "err" => ""})

      result = provisioner(runner: runner).call(account: account("create" => true))

      assert_equal 501, result["uid"]
      assert_includes calls, ["dscl", ".", "-create", "/Users/ace-worker", "UniqueID", "501"]
    end

    def test_privileged_linux_creation_runs_single_useradd
      runner = fake_runner
      lookup_calls = []
      lookup = ->(name) {
        # absent before useradd, present after
        lookup_calls << name
        lookup_calls.count(name) > 1 ? FakeEntry.new(name: name, uid: 1001, gid: 1001, dir: "/home/ace-worker") : nil
      }

      result = provisioner(runner: runner, lookup: lookup, platform: "linux")
        .call(account: account("create" => true))

      assert_equal "created", result["status"]
      assert_equal 1001, result["uid"]
      assert_equal [["useradd", "-m", "-s", "/bin/zsh", "-d", "/home/ace-worker", "ace-worker"]], calls
    end

    # F-4: a created account whose uid still cannot be resolved reports
    # a message so JSON consumers can distinguish it from a normal
    # creation.
    def test_linux_created_with_unresolvable_uid_carries_message
      result = provisioner(platform: "linux").call(account: account("create" => true))

      assert_equal "created", result["status"]
      assert_nil result["uid"]
      assert_match(/was created but its uid could not be resolved yet/, result["message"])
      assert_match(/rerun ace-lab prepare to report it/, result["message"])
    end

    def test_unsupported_platform_is_reported_with_manual_remedy
      result = provisioner(platform: "freebsd").call(account: account("create" => true))

      assert_equal "failed", result["status"]
      assert_match(/unsupported platform 'freebsd' for account creation/, result["message"])
      assert_match(/set create: false/, result["message"])
      assert_empty calls
    end

    def test_command_failure_surfaces_status_and_first_stderr_line_only
      runner = fake_runner("useradd" => {"status" => 12, "out" => "",
        "err" => "first line of failure\nsecond line with secret\n"})

      result = provisioner(runner: runner, platform: "linux").call(account: account("create" => true))

      assert_equal "failed", result["status"]
      assert_match(/command failed \(useradd, exit 12\): first line of failure/, result["message"])
      refute_includes result["message"], "second line"
    end

    def test_missing_useradd_binary_is_classified_as_enoent
      runner = fake_runner("useradd" => {"status" => "enoent", "out" => "", "err" => ""})

      result = provisioner(runner: runner, platform: "linux").call(account: account("create" => true))

      assert_equal "failed", result["status"]
      assert_match(/useradd not found in PATH; install it and rerun ace-lab prepare/, result["message"])
    end

    def test_missing_dscl_binary_is_classified_as_enoent
      runner = fake_runner("dscl" => {"status" => "enoent", "out" => "", "err" => ""})

      result = provisioner(runner: runner, platform: "darwin").call(account: account("create" => true))

      assert_equal "failed", result["status"]
      assert_match(/dscl not found in PATH/, result["message"])
    end

    def test_dry_run_predicts_creation_without_invoking_the_runner
      result = provisioner(dry_run: true).call(account: account("create" => true))

      assert_equal "would_create", result["status"]
      assert_empty calls
    end

    def test_dry_run_still_reports_missing_account_without_create
      result = provisioner(dry_run: true).call(account: account)

      assert_equal "failed", result["status"]
      assert_match(/does not exist/, result["message"])
    end
  end
end

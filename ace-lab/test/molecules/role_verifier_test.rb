# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class RoleVerifierTest < Minitest::Test
    FakeEntry = Struct.new(:name, :uid, :gid, :dir, keyword_init: true)

    def self_entry
      FakeEntry.new(name: "ace-worker", uid: Process.uid, gid: Process.gid, dir: Dir.home)
    end

    def verifier(lookup: ->(_name) { self_entry }, dry_run: false)
      Ace::Lab::Molecules::RoleVerifier.new(account_lookup: lookup, dry_run: dry_run)
    end

    def role(instructions)
      {"id" => "worker", "account" => "ace-worker", "instructions" => instructions}
    end

    def test_protocol_instructions_verify_syntactically
      %w[wfi://assign/work prompt://plan tmpl://base].each do |instructions|
        result = verifier.call(role: role(instructions))

        assert_equal "verified", result["status"]
        assert_nil result["message"]
      end
    end

    def test_existing_readable_file_verifies
      Dir.mktmpdir do |dir|
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chmod(0o644, path)

        result = verifier.call(role: role(path))

        assert_equal "verified", result["status"]
      end
    end

    def test_owner_only_file_verifies_for_owning_account
      Dir.mktmpdir do |dir|
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chmod(0o400, path)

        result = verifier.call(role: role(path))

        assert_equal "verified", result["status"]
      end
    end

    def test_missing_file_fails_with_specific_message
      result = verifier.call(role: role("/nonexistent/roles/worker.md"))

      assert_equal "failed", result["status"]
      assert_match(%r{instructions file '/nonexistent/roles/worker\.md' does not exist}, result["message"])
    end

    def test_unreadable_for_account_fails
      Dir.mktmpdir do |dir|
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chmod(0o600, path)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        result = verifier(lookup: ->(_name) { other }).call(role: role(path))

        assert_equal "failed", result["status"]
        assert_match(/not readable by account 'ace-other'/, result["message"])
        assert_match(/ACLs are out of scope/, result["message"])
      end
    end

    def test_unavailable_account_fails_with_dependency_message
      result = verifier(lookup: ->(_name) { nil }).call(role: role("wfi://assign/work"))

      assert_equal "failed", result["status"]
      assert_match(/role 'worker' account 'ace-worker' is not available/, result["message"])
      assert_match(/fix the account phase first/, result["message"])
    end

    def test_directory_at_instructions_path_fails
      Dir.mktmpdir do |dir|
        result = verifier.call(role: role(dir))

        assert_equal "failed", result["status"]
        assert_match(/is not a regular file/, result["message"])
      end
    end

    def test_dry_run_with_would_create_account_predicts_verified
      Dir.mktmpdir do |dir|
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chmod(0o644, path)

        # the account phase would create the account — live passwd
        # returns nil, but the prediction must not fail the dependency
        result = verifier(lookup: ->(_name) { nil }, dry_run: true).call(role: role(path))

        assert_equal "verified", result["status"]
        assert_nil result["message"]
      end
    end

    def test_dry_run_with_would_create_account_still_fails_on_missing_file
      result = verifier(lookup: ->(_name) { nil }, dry_run: true)
        .call(role: role("/nonexistent/roles/worker.md"))

      assert_equal "failed", result["status"]
      assert_match(/does not exist/, result["message"])
    end
  end
end

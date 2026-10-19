# frozen_string_literal: true

require_relative "../test_helper"

module Molecules
  class RoleVerifierTest < Minitest::Test
    def self_entry
      FakeEntry.new(name: "ace-worker", uid: Process.uid, gid: Process.gid, dir: Dir.home)
    end

    def verifier(lookup: ->(_name) { self_entry }, group_source: nil, dry_run: false)
      Ace::Lab::Molecules::RoleVerifier.new(
        account_lookup: lookup, group_source: group_source, dry_run: dry_run
      )
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

    # PR #392 F5: read bits on the file are not enough — without the
    # search (x) bit on an ancestor directory the account cannot reach
    # the file at all, so the binding is failed, not verified.
    def test_readable_file_behind_unsearchable_directory_fails
      Dir.mktmpdir do |dir|
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chmod(0o644, path)
        File.chmod(0o700, dir)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        result = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .call(role: role(path))

        assert_equal "failed", result["status"]
        assert_match(/not reachable by account 'ace-other'/, result["message"])
        assert_match(/search permission/, result["message"])
      end
    end

    # F5 control: the same foreign account with search-permitted
    # ancestors all the way up verifies. The fixture lives under /tmp
    # because the default tmpdir (macOS per-user folder) is itself
    # 0700-owner-only for the running account.
    def test_searchable_ancestor_path_verifies_for_other_account
      Dir.mktmpdir("pr392-f5", "/tmp") do |dir|
        File.chmod(0o755, dir)
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chmod(0o644, path)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        result = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .call(role: role(path))

        assert_equal "verified", result["status"]
        assert_nil result["message"]
      end
    end

    # 8xi16mz1: the FINAL component is a symlink to a file behind an
    # unsearchable directory — the read check stats the 0644 target and
    # passes, so only resolving the symlink itself (not just the
    # ancestors of the link's own path) can catch the unreachable pair.
    def test_symlinked_instruction_behind_unsearchable_directory_fails
      Dir.mktmpdir("mz1", "/tmp") do |dir|
        File.chmod(0o755, dir)
        hidden = File.join(dir, "hidden")
        Dir.mkdir(hidden)
        target = File.join(hidden, "worker.md")
        File.write(target, "instructions")
        File.chmod(0o644, target)
        File.chmod(0o700, hidden)
        link = File.join(dir, "worker-link.md")
        File.symlink(target, link)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        result = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .call(role: role(link))

        assert_equal "failed", result["status"]
        assert_match(/not reachable by account 'ace-other'/, result["message"])
      ensure
        File.chmod(0o755, hidden) if File.directory?(hidden)
      end
    end

    # mz1 control: a symlink whose target IS reachable verifies —
    # resolving the final component does not ban symlinks.
    def test_symlinked_instruction_with_searchable_target_path_verifies
      Dir.mktmpdir("mz1", "/tmp") do |dir|
        File.chmod(0o755, dir)
        target = File.join(dir, "worker.md")
        File.write(target, "instructions")
        File.chmod(0o644, target)
        link = File.join(dir, "worker-link.md")
        File.symlink(target, link)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        result = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .call(role: role(link))

        assert_equal "verified", result["status"]
        assert_nil result["message"]
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

    # Round-4 M2: POSIX owner class short-circuits — a file owned by
    # the account with only the group bit set (0o040) is NOT readable
    # by that account; the old gid-match fallthrough false-verified it.
    def test_owner_with_group_readable_only_mode_fails_verification
      Dir.mktmpdir do |dir|
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chmod(0o040, path)

        result = verifier.call(role: role(path))

        assert_equal "failed", result["status"]
        assert_match(/not readable by account 'ace-worker'/, result["message"])
      ensure
        File.chmod(0o600, path) if File.exist?(path)
      end
    end

    # Round-4 M2 companions: each non-owner class still verifies
    # through its own bit when the higher classes do not apply.
    # The fixture lives under /tmp with 0755 ancestors: the default
    # tmpdir is 0700-owner-only, legitimately unreachable for the
    # foreign-uid account (PR #392 F5 checks ancestor search too).
    def test_group_class_verifies_when_owner_is_foreign
      Dir.mktmpdir("pr392-f5", "/tmp") do |dir|
        File.chmod(0o755, dir)
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        # /tmp fixtures inherit gid 0 — restore the account's primary
        # group so the group permission class applies to the fixture
        File.chown(nil, Process.gid, dir)
        File.chown(nil, Process.gid, path)
        File.chmod(0o040, path)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid, dir: "/x")

        result = verifier(lookup: ->(_name) { other }).call(role: role(path))

        assert_equal "verified", result["status"]
      ensure
        File.chmod(0o600, path) if File.exist?(path)
      end
    end

    def test_owner_class_with_owner_bit_clear_fails_even_when_group_bit_set_for_foreign_owner
      Dir.mktmpdir do |dir|
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        # owner bit set, group/other clear; the account matches gid but
        # not uid — only the (foreign) owner can read it
        File.chmod(0o400, path)
        in_group = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid, dir: "/x")

        result = verifier(lookup: ->(_name) { in_group }).call(role: role(path))

        assert_equal "failed", result["status"]
        assert_match(/not readable by account 'ace-other'/, result["message"])
      end
    end

    # Round-5 C3: the group permission class covers supplementary
    # groups too — a file group-readable by a group the account holds
    # beyond its primary gid genuinely is readable by the runtime.
    # Fake group source stands in for the Etc.group scan (injectable
    # seam).
    def test_supplementary_group_membership_verifies_group_readable_file
      # searchable ancestors + primary-group fixture, see the group-class test above
      Dir.mktmpdir("pr392-f5", "/tmp") do |dir|
        File.chmod(0o755, dir)
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chown(nil, Process.gid, dir)
        File.chown(nil, Process.gid, path)
        File.chmod(0o040, path)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        result = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [Process.gid] })
          .call(role: role(path))

        assert_equal "verified", result["status"]
        assert_nil result["message"]
      ensure
        File.chmod(0o600, path) if File.exist?(path)
      end
    end

    # Round-5 C3 companion: a group-readable file whose gid the
    # account does NOT hold (primary or supplementary) still fails —
    # the seam does not weaken the group-class check.
    def test_group_readable_file_outside_all_account_groups_still_fails
      Dir.mktmpdir do |dir|
        path = File.join(dir, "worker.md")
        File.write(path, "instructions")
        File.chmod(0o040, path)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        result = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .call(role: role(path))

        assert_equal "failed", result["status"]
        assert_match(/not readable by account 'ace-other'/, result["message"])
      ensure
        File.chmod(0o600, path) if File.exist?(path)
      end
    end

    # --- directory access (LAB-2) and executable access (FINAL-LAB3) --

    # A directory without the search bit on ITSELF is unusable to the
    # target executor however read/write it is (the audit's secondary
    # access-mask concern): rw alone must be denied.
    def test_rw_directory_without_search_bit_is_denied_for_the_executor
      Dir.mktmpdir("pr393", "/tmp") do |dir|
        File.chmod(0o755, dir)
        project = File.join(dir, "atlas")
        Dir.mkdir(project)
        File.chown(nil, Process.gid, project)
        File.chmod(0o666, project)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid, dir: "/x")

        reason = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .directory_access_reason(project, other)

        assert_match(/denies read\/write\/search permission to account 'ace-other'/, reason)
      ensure
        File.chmod(0o755, project) if File.directory?(project)
      end
    end

    def test_searchable_rwx_directory_passes_for_the_executor
      Dir.mktmpdir("pr393", "/tmp") do |dir|
        File.chmod(0o755, dir)
        project = File.join(dir, "atlas")
        Dir.mkdir(project)
        File.chmod(0o777, project)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        reason = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .directory_access_reason(project, other)

        assert_nil reason
      end
    end

    # FINAL-LAB3: an installer-owned 0700 executable denies the
    # different-uid executor through its governing class — exactly the
    # false-readiness the final audit reproduced.
    def test_installer_only_executable_denies_the_target_executor
      Dir.mktmpdir("pr393", "/tmp") do |dir|
        File.chmod(0o755, dir)
        tool = File.join(dir, "tool")
        File.write(tool, "#!/bin/sh\n")
        File.chmod(0o700, tool)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        reason = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .executable_access_reason(tool, other)

        assert_match(/denies execute permission to account 'ace-other'/, reason)
      end
    end

    def test_world_executable_tool_passes_for_the_target_executor
      Dir.mktmpdir("pr393", "/tmp") do |dir|
        File.chmod(0o755, dir)
        tool = File.join(dir, "tool")
        File.write(tool, "#!/bin/sh\n")
        File.chmod(0o755, tool)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        reason = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .executable_access_reason(tool, other)

        assert_nil reason
      end
    end

    def test_executable_behind_unsearchable_directory_is_denied_for_the_executor
      Dir.mktmpdir("pr393", "/tmp") do |dir|
        File.chmod(0o755, dir)
        hidden = File.join(dir, "hidden")
        Dir.mkdir(hidden)
        tool = File.join(hidden, "tool")
        File.write(tool, "#!/bin/sh\n")
        File.chmod(0o755, tool)
        File.chmod(0o700, hidden)
        other = FakeEntry.new(name: "ace-other", uid: Process.uid + 1, gid: Process.gid + 1, dir: "/x")

        reason = verifier(lookup: ->(_name) { other }, group_source: ->(_name) { [] })
          .executable_access_reason(tool, other)

        assert_match(/denies search permission to account 'ace-other'/, reason)
      ensure
        File.chmod(0o755, hidden) if File.directory?(hidden)
      end
    end
  end
end

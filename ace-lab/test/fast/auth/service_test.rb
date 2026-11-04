# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "open3"
require "timeout"

module Ace
  module Lab
    module Auth
      # Core lease lifecycle of ace-lab auth (task 8xs.t.pu0.7):
      # idempotent request, TTL refusal, principal/role gating, exec
      # with the credential REFERENCE (never a value), idempotent
      # revoke, and reconcile of interrupted states — with a fake
      # provider pinning the plugin contract.
      class ServiceTest < Minitest::Test
        class FakeProvider
          attr_reader :issued, :revoked

          def initialize(capabilities: {"expiry_mode" => "host-revoke"}, failure: nil)
            @capabilities = capabilities
            @failure = failure
            @issued = []
            @revoked = []
          end

          def capabilities
            @capabilities
          end

          # No deterministic remote identity: the reference only exists
          # after the (possibly lost) creation response.
          def token_ref_for(lease_id:)
            nil
          end

          def issue(profile:, lease:)
            raise @failure if @failure

            @issued << lease["id"]
            {"token" => "SECRET-#{lease["id"]}", "token_ref" => "tok-#{lease["id"]}",
             "provider_expiry" => nil, "via" => {"kind" => "file"}}
          end

          def revoke(profile:, token_ref:, token: nil)
            raise @failure if @failure

            @revoked << token_ref
            :revoked
          end
        end

        AUTH_YAML = <<~YAML
          auth:
            leases_dir: %s
            credentials_dir: %s
            profiles:
              developer:
                provider: fake
                roles: [developer]
                principals: [test-worker]
                repos: [ace, other]
                scopes: ["write:repository"]
              wide:
                provider: fake
                roles: [developer]
                principals: []
                repos: []
        YAML

        def setup
          @dir = Dir.mktmpdir
          leases = File.join(@dir, "leases")
          credentials = File.join(@dir, "credentials")
          @document = format(AUTH_YAML, leases, credentials)
          Providers.register("fake", @fake = FakeProvider.new)
          @peer_handle = File.open(File::NULL)
          @main_handle = File.open(File::NULL)
          @mount_namespace = File.open(File::NULL)
        end

        def test_rejects_noncallable_principal_at_construction
          error = assert_raises(ArgumentError) { Service.new(principal: "worker") }
          assert_match(/principal must be callable/, error.message)
        end

        def test_rejects_session_without_a_numeric_uid_before_initialization
          identity = session_identity.dup
          identity.uid = nil
          Process.stub(:euid, 0) do
            assert_raises(ArgumentError) { Service.new(session: identity, issuer_invocation: "a" * 32) }
          end
        end

        def test_invalid_environment_names_are_rejected_at_profile_load
          ["BAD=NAME", "BAD\0NAME"].each do |name|
            doc = {"auth" => {"profiles" => {"test" => {"provider" => "env", "env_names" => [name]}}}}
            assert_raises(Ace::Lab::InvalidConfigurationError) { ProfileSchema.normalize(doc) }
          end
        end

        def teardown
          @peer_handle.close unless @peer_handle.closed?
          @main_handle.close unless @main_handle.closed?
          @mount_namespace.close unless @mount_namespace.closed?
          FileUtils.remove_entry(@dir) if @dir
          Providers.reset!
        end

        def session_identity
          SessionPeer::Identity.new(uid: Process.uid, gid: Process.gid, role: "worker",
            invocation_id: "a" * 32, unit: "ace-auth-session-worker-0123456789abcdef.service",
            cwd: Dir.pwd, runtime_dir: "/run/ace-auth-0123456789abcdef", pidfd: @peer_handle, main_pidfd: @main_handle,
            main_pid: Process.pid, mount_namespace: @mount_namespace)
        end

        def service(document: @document)
          Molecules::GrantResolver.stub :read_verified, document do
            Service.new(
              principal: -> { "test-worker" },
              runner: ->(argv, env) { @exec_seen = [argv, env]; @exec_result || 0 }
            )
          end
        end

        def test_request_issues_a_lease_and_hands_off_the_secret_as_a_file
          lease = service.request(profile_name: "developer", role: "developer",
            task: "8xs.t.pu0.7", assignment: "assign-1", repos: %w[ace])

          assert_equal "issued", lease["state_detail"]
          assert_equal %w[ace], lease["repos"], "the scope is the profile/request intersection"
          assert_equal "test-worker", lease["principal"]
          refute_match(/SECRET/, JSON.generate(lease), "the lease record never carries the secret")

          credential = Dir.glob(File.join(@dir, "credentials", "*")).first
          assert_match(/\ASECRET-lease-/, File.read(credential))
          assert_equal 0o400, File.stat(credential).mode & 0o777
        end

        def test_provider_refusal_records_that_no_token_was_issued
          @fake.instance_variable_set(:@failure, Providers::RefusedError.new("refused before issue"))
          requester = service
          assert_raises(Refusal) do
            requester.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          end
          record = requester.store.all.fetch(0)
          assert_equal "revoked", record.fetch("state")
          assert_equal "not-issued", record.dig("cleanup", "result")
        end

        def test_another_principal_cannot_execute_a_live_lease
          owner = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" })
          end
          lease = owner.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          ran = false
          other = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "other-worker" }, runner: ->(_argv, _env) { ran = true; 0 })
          end

          error = assert_raises(Refusal) { other.exec(lease_id: lease["id"], argv: ["true"]) }
          assert_match(/principal/, error.message)
          refute ran
          assert_equal "issued", owner.status(lease_id: lease["id"])["state"]
        end

        def test_root_can_revoke_only_leases_of_a_finished_issuer_invocation
          first, second = "a" * 32, "b" * 32
          worker = service
          leases = [first, second].map.with_index do |invocation, index|
            record = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
              task: "task-#{index}", assignment: "assignment-#{index}", repos: ["ace"],
              use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil,
              token_ref: "token-#{index}", session_uid: 1234, session_id: "c" * 32,
              session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: invocation)
            worker.store.update(record["id"]) { |item| item["state"] = "issued" }
          end
          operator = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "root" })
          end
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            result = operator.revoke_issuer(invocation: first)
            assert_equal [leases.first["id"]], result.map { |row| row.fetch("lease") }
          end }
          assert_equal "revoked", worker.store.load(leases.first["id"])["state"]
          assert_equal "issued", worker.store.load(leases.last["id"])["state"]
          assert_equal ["token-0"], @fake.revoked
          Process.stub(:uid, 1234) { assert_raises(Refusal) { operator.revoke_issuer(invocation: second) } }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) { assert_raises(Refusal) { operator.revoke_issuer(invocation: "bad") } } }
        end

        def test_startup_recovery_cleans_each_issuer_under_an_exclusive_lifecycle_lock
          worker = service
          leases = %w[a b].map do |letter|
            record = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
              task: letter, assignment: letter, repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
              provider_expiry: nil, token_ref: letter, session_uid: 1234, session_id: "c" * 32,
              session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: letter * 32)
            worker.store.update(record["id"]) { |item| item["state"] = "issued" }
            record
          end
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          lock = ->(exclusive:, &block) { raise "exclusive lock required" unless exclusive; block.call }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            operator.store.stub(:with_issuer_lifecycle_lock, lock) do
              assert_equal 2, operator.recover_issuers.size
            end
          end }
          assert_equal %w[a b], @fake.revoked.sort
          leases.each { |lease| assert_equal "revoked", worker.store.load(lease["id"])["state"] }
        end

        def test_startup_recovery_requires_root
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 1234) { assert_raises(Refusal) { operator.recover_issuers } }
        end

        def test_session_cannot_be_created_without_its_issuer_invocation
          skip "requires a non-root account" if Process.uid.zero?

          Process.stub(:euid, 0) do
            assert_raises(ArgumentError) do
              Service.new(session: session_identity)
            end
          end
        end

        def test_issuer_recovery_keeps_unconfirmed_revocation_visible
          worker = service
          lease = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"],
            use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil,
            token_ref: "token", session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
          worker.store.update(lease["id"]) { |item| item["state"] = "issued" }
          @fake.instance_variable_set(:@failure, Providers::TransientError.new("offline"))
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
          end }
          assert_equal "revoke-pending", worker.store.load(lease["id"])["state"]
        end

        def test_issuer_recovery_continues_after_an_unconfirmed_revocation
          worker = service
          leases = %w[first second].map do |name|
            record = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
              task: name, assignment: name, repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
              provider_expiry: nil, token_ref: name, session_uid: 1234, session_id: "c" * 32,
              session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
            worker.store.update(record["id"]) { |item| item["state"] = "issued" }
            record
          end
          failing = Object.new
          failing.define_singleton_method(:revoke) do |profile:, token_ref:, token:|
            raise Providers::TransientError, "offline" if token_ref == "first"
            :revoked
          end
          Providers.register("fake", failing)
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
          end }
          assert_equal "revoke-pending", worker.store.load(leases.first["id"])["state"]
          assert_equal "revoked", worker.store.load(leases.last["id"])["state"]
        end

        def test_issuer_recovery_does_not_claim_a_forced_terminal_is_revoked
          worker = service
          record = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
            provider_expiry: nil, token_ref: "token", session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
          worker.store.update(record["id"]) do |item|
            item["state"] = "revoked"
            item["cleanup"] = {"result" => "forced-terminal"}
          end
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
          end }
        end

        def test_issuer_recovery_does_not_claim_a_revoked_record_without_evidence
          worker = service
          record = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
            provider_expiry: nil, token_ref: "token", session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
          worker.store.update(record["id"]) { |item| item["state"] = "revoked" }
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
          end }
        end

        def test_issuer_recovery_reports_not_issued_as_its_actual_outcome
          worker = service
          record = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
            provider_expiry: nil, session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
          worker.store.update(record["id"]) do |item|
            item["state"] = "revoked"
            item["cleanup"] = {"result" => "not-issued"}
          end
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_equal "not-issued", operator.revoke_issuer(invocation: "a" * 32).first.fetch("cleanup")
          end }
        end

        def test_issuer_recovery_refuses_unreadable_lease_inventory
          worker = service
          worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"],
            use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil, session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            File.stub(:read, ->(*) { raise Errno::EACCES }) do
              assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
            end
          end }
        end

        def test_issuer_recovery_refuses_non_object_lease_inventory
          worker = service
          lease = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"],
            use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil, session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
          File.write(File.join(@dir, "leases", "#{lease['id']}.json"), "null")
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
          end }
        end

        def test_issuer_recovery_refuses_session_lease_without_issuer_identity
          worker = service
          lease = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"], session_uid: 1234, session_id: "b" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service",
            use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil, issuer_invocation: "a" * 32)
          path = File.join(@dir, "leases", "#{lease.fetch('id')}.json")
          damaged = JSON.parse(File.read(path))
          damaged.delete("issuer_invocation")
          File.write(path, JSON.generate(damaged))
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
          end }
        end

        def test_issuer_recovery_revokes_known_leases_even_if_another_record_is_corrupt
          worker = service
          lease = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"], token_ref: "token",
            use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil, session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
          worker.store.update(lease["id"]) { |item| item["state"] = "issued" }
          File.write(File.join(@dir, "leases", "lease-damaged.json"), "null")
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
          end }
          assert_equal "revoked", worker.store.load(lease["id"])["state"]
          assert_equal ["token"], @fake.revoked
        end

        def test_issuer_recovery_rechecks_identity_after_acquiring_lock
          worker = service
          lease = worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"], token_ref: "token",
            use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil, session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "a" * 32)
          worker.store.update(lease["id"]) { |item| item["state"] = "issued" }
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          lock = lambda do |id, &block|
            worker.store.update(id) { |item| item["issuer_invocation"] = "b" * 32 }
            block.call
          end
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            operator.store.stub(:with_exec_lock, lock) do
              assert_raises(Error) { operator.revoke_issuer(invocation: "a" * 32) }
            end
          end }
          assert_empty @fake.revoked
        end

        def test_another_principal_cannot_revoke_a_live_lease
          owner = service
          lease = owner.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          other = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "other-worker" }, runner: ->(_argv, _env) { 0 })
          end

          error = assert_raises(Refusal) { other.revoke(lease_id: lease["id"]) }
          assert_match(/principal/, error.message)
          assert_empty @fake.revoked
          assert_equal "issued", owner.status(lease_id: lease["id"])["state"]
        end

        def test_runner_failure_still_revokes_and_clears_its_lease
          failing = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(_argv, _env) { raise Errno::ENOENT })
          end
          lease = failing.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          assert_raises(Error) { failing.exec(lease_id: lease["id"], argv: ["missing-command"]) }
          assert_equal "revoked", failing.status(lease_id: lease["id"])["state"]
          assert_empty Dir.children(File.join(@dir, "credentials"))
        end

        def test_privileged_session_request_rejects_an_unrestricted_principal_profile
          skip "requires a non-root account for the fake peer" if Process.uid.zero?

          Process.stub(:euid, 0) do
            isolated = Molecules::GrantResolver.stub(:read_verified, @document) do
              Service.new(session: session_identity, issuer_invocation: "b" * 32)
            end
            error = assert_raises(Refusal) do
              isolated.request(profile_name: "wide", role: "developer", task: "t", assignment: "a", repos: ["ace"])
            end
            assert_match(/explicit.*principal/i, error.message)
            assert_empty @fake.issued
          end
        end

        def test_session_does_not_issue_host_revoked_token_without_supervision
          skip "requires a non-root account for the fake peer" if Process.uid.zero?

          account = Etc.getpwuid(Process.uid)
          document = YAML.safe_load(@document)
          document["auth"]["profiles"]["developer"]["principals"] = ["session:worker"]
          document["auth"]["profiles"]["developer"]["expiry_mode"] = "host-revoke"
          Process.stub(:euid, 0) do
            isolated = Molecules::GrantResolver.stub(:read_verified, YAML.dump(document)) do
              Service.new(session: session_identity, issuer_invocation: "b" * 32)
            end
            error = assert_raises(Refusal) do
              isolated.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
            end
            assert_match(/revocation supervision/i, error.message)
            assert_empty @fake.issued
          end
        end

        def test_supervised_session_handoff_failure_requires_issuer_recovery_after_remote_issue
          skip "requires a non-root account for the fake peer" if Process.uid.zero?
          document = YAML.safe_load(@document)
          document["auth"]["profiles"]["developer"]["principals"] = ["session:worker"]
          isolated = Process.stub(:euid, 0) do
            Molecules::GrantResolver.stub(:read_verified, YAML.dump(document)) do
              Service.new(session: session_identity, issuer_invocation: "b" * 32, supervised: true)
            end
          end
          handoff = Object.new
          def handoff.prepare! = true
          def handoff.deliver(*) = raise(IOError, "disk unavailable")
          attachment = isolated.instance_variable_get(:@session_attachment)
          attachment.stub(:verify_session!, true) do
            CredentialHandoff.stub(:new, handoff) do
              assert_raises(UnresolvedIssuanceError) do
                isolated.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
              end
            end
          end
          assert_equal 1, @fake.issued.size, "failure must occur after remote issuance"
          record = isolated.store.all.fetch(0)
          assert_equal "revoke-pending", record.fetch("state")
          assert_equal "b" * 32, record.fetch("issuer_invocation")
        end

        def test_session_cannot_claim_a_different_role_in_profile
          skip "requires a non-root account for the fake peer" if Process.uid.zero?

          document = YAML.safe_load(@document)
          document["auth"]["profiles"]["developer"]["principals"] = ["session:reviewer"]
          Process.stub(:euid, 0) do
            isolated = Molecules::GrantResolver.stub(:read_verified, YAML.dump(document)) do
              Service.new(session: session_identity, issuer_invocation: "b" * 32)
            end
            error = assert_raises(Refusal) do
              isolated.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
            end
            assert_match(/principal.*not allowed/, error.message)
            assert_empty @fake.issued
          end
        end

        def test_session_uid_reuse_cannot_execute_another_invocations_lease
          skip "requires a non-root account for the fake peer" if Process.uid.zero?

          Process.stub(:euid, 0) do
            isolated = Molecules::GrantResolver.stub(:read_verified, @document) do
              Service.new(session: session_identity, issuer_invocation: "b" * 32)
            end
            account = Etc.getpwuid(Process.uid)
            lease = isolated.store.create(profile: "developer", role: "developer", principal: account.name,
              task: "t", assignment: "a", repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
              provider_expiry: nil, session_uid: account.uid, session_id: "b" * 32,
              session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "c" * 32)
            isolated.store.update(lease["id"]) { |record| record["state"] = "issued" }
            error = assert_raises(Refusal) { isolated.exec(lease_id: lease["id"], argv: ["true"]) }
            assert_match(/different principal/, error.message)
          end
        end

        def test_same_session_cannot_execute_a_lease_owned_by_another_issuer
          skip "requires a non-root account for the fake peer" if Process.uid.zero?

          Process.stub(:euid, 0) do
            isolated = Molecules::GrantResolver.stub(:read_verified, @document) do
              Service.new(session: session_identity, issuer_invocation: "b" * 32)
            end
            account = Etc.getpwuid(Process.uid)
            lease = isolated.store.create(profile: "developer", role: "developer", principal: account.name,
              task: "t", assignment: "a", repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
              provider_expiry: nil, session_uid: account.uid, session_id: "a" * 32,
              session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: "c" * 32)
            isolated.store.update(lease["id"]) { |record| record["state"] = "issued" }
            error = assert_raises(Refusal) { isolated.exec(lease_id: lease["id"], argv: ["true"]) }
            assert_match(/different issuer invocation/, error.message)
            assert_raises(Refusal) { isolated.status(lease_id: lease["id"]) }
            assert_empty isolated.status
            assert_raises(Refusal) { isolated.revoke(lease_id: lease["id"]) }
            assert_equal "issued", isolated.store.load(lease["id"])["state"]
          end
        end

        def test_root_exec_without_a_non_root_session_is_refused
          owner = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" })
          end
          lease = owner.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          error = Process.stub(:euid, 0) do
            assert_raises(Refusal) { owner.exec(lease_id: lease["id"], argv: ["true"]) }
          end
          assert_match(/authenticated non-root session/, error.message)
        end

        def test_root_request_without_a_non_root_session_does_not_issue
          owner = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" })
          end
          error = Process.stub(:euid, 0) do
            assert_raises(Refusal) do
              owner.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
            end
          end
          assert_match(/authenticated non-root session/, error.message)
          assert_empty @fake.issued
        end

        def test_request_is_idempotent_for_the_same_live_correlation
          svc = service
          first = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          second = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          assert_equal first["id"], second["id"]
          assert_equal 1, @fake.issued.size, "concurrent requests mint one token"
        end

        def test_idempotent_retry_with_unsorted_profile_repository_scope
          document = YAML.safe_load(@document)
          document["auth"]["profiles"]["developer"]["repos"] = %w[other ace]
          svc = service(document: YAML.dump(document))
          args = {profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: %w[ace other]}
          first = svc.request(**args)
          second = svc.request(**args)
          assert_equal first["id"], second["id"]
          assert_equal 1, @fake.issued.size
        end

        def test_concurrent_identical_requests_serialize_to_one_token
          svc = service
          results = 2.times.map do
            Thread.new do
              svc.request(profile_name: "developer", role: "developer",
                task: "t", assignment: "a", repos: %w[ace])
            end
          end.map(&:value)

          assert_equal 1, results.map { |lease| lease["id"] }.uniq.size,
            "the correlation lock serializes find_live + create + issue"
          assert_equal 1, @fake.issued.size, "exactly one token minted"
          assert_equal 1, svc.store.all.count { |record| svc.store.live?(record) }
        end

        def test_retry_with_a_different_scope_is_refused_not_answered_with_the_wider_grant
          svc = service
          svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace other])

          error = assert_raises(Refusal) do
            svc.request(profile_name: "developer", role: "developer",
              task: "t", assignment: "a", repos: %w[ace])
          end
          assert_match(/live lease for task 't' assignment 'a'.*scope \[ace, other\].*revoke it first/,
            error.message)
          # the wider grant still exists untouched — no second token, no narrowing
          assert_equal 1, @fake.issued.size
          live = svc.store.all.count { |record| svc.store.live?(record) }
          assert_equal 1, live
        end

        def test_role_principal_and_ttl_refusals_carry_reasons
          error = assert_raises(Refusal) do
            service.request(profile_name: "developer", role: "reviewer",
              task: "t", assignment: "a", repos: %w[ace])
          end
          assert_match(/role 'reviewer' is not allowed/, error.message)

          error = assert_raises(Refusal) do
            service.request(profile_name: "ghost", role: "developer",
              task: "t", assignment: "a", repos: %w[ace])
          end
          assert_match(/unknown auth profile/, error.message)

          error = assert_raises(Refusal) do
            svc = Molecules::GrantResolver.stub :read_verified, @document do
              Service.new(principal: -> { "someone-else" })
            end
            svc.request(profile_name: "developer", role: "developer",
              task: "t", assignment: "a", repos: %w[ace])
          end
          assert_match(/principal 'someone-else' is not allowed.*escalate to the host owner/, error.message)

          svc = service
          error = assert_raises(Refusal) do
            svc.request(profile_name: "wide", role: "developer",
              task: "t", assignment: "a", ttl_minutes: 120)
          end
          assert_match(/exceeds the profile limit 60m; refused, not clipped/, error.message)
        end

        def test_non_positive_ttl_is_refused
          svc = service
          [0, -5].each do |ttl|
            error = assert_raises(Refusal) do
              svc.request(profile_name: "developer", role: "developer",
                task: "t", assignment: "a", repos: %w[ace], ttl_minutes: ttl)
            end
            assert_match(/ttl must be a positive number of minutes, got #{ttl}/, error.message)
          end
          assert_empty svc.store.all, "no record exists for a refused ttl"
        end

        def test_empty_repository_scope_is_refused_before_issuing
          svc = service
          error = assert_raises(Refusal) do
            svc.request(profile_name: "developer", role: "developer",
              task: "t", assignment: "a", repos: %w[unrelated])
          end
          assert_match(/granted repository scope would be empty.*ALL repositories.*refused before issuing/,
            error.message)

          error = assert_raises(Refusal) do
            svc.request(profile_name: "developer", role: "developer",
              task: "t", assignment: "a", repos: [])
          end
          assert_match(/granted repository scope would be empty/, error.message)

          assert_empty svc.store.all, "no lease record and no token for an empty scope"
          assert_empty @fake.issued
        end

        def test_provider_resolution_or_capability_failure_leaves_no_lease_record
          document = format(<<~YAML, File.join(@dir, "leases"), File.join(@dir, "credentials"))
            auth:
              leases_dir: %s
              credentials_dir: %s
              profiles:
                missing:
                  provider: not-registered
                  roles: [developer]
                  principals: []
                  repos: [ace]
                native:
                  provider: fake
                  roles: [developer]
                  principals: []
                  repos: [ace]
                  expiry_mode: provider
          YAML
          svc = service(document: document)

          error = assert_raises(Refusal) do
            svc.request(profile_name: "missing", role: "developer",
              task: "t", assignment: "a", repos: %w[ace])
          end
          assert_match(/no auth provider registered/, error.message)

          error = assert_raises(Refusal) do
            svc.request(profile_name: "native", role: "developer",
              task: "t", assignment: "a", repos: %w[ace])
          end
          assert_match(/cannot guarantee the profile's native expiry/, error.message)

          assert_empty svc.store.all,
            "resolve and capability checks run BEFORE create — no orphaned records"
        end

        def test_exec_passes_the_credential_reference_and_reports_both_outcomes
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          @exec_result = 0
          report = svc.exec(lease_id: lease["id"], argv: %w[bin/ace-test atoms])

          assert_equal 0, report["exit"]
          assert_equal "revoked", report["cleanup"]
          argv, env = @exec_seen
          assert_equal %w[bin/ace-test atoms], argv
          assert_equal lease["id"], env["ACE_LAB_LEASE"]
          credential_file = env["ACE_LAB_CREDENTIAL_FILE"]
          assert_match(/#{lease["id"]}-test-worker\z/, credential_file)
          refute File.exist?(credential_file), "the handoff is cleared with the lease"
          assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
        end

        def test_exec_preserves_the_process_exit_code
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          @exec_result = 3
          report = svc.exec(lease_id: lease["id"], argv: %w[false])
          assert_equal 3, report["exit"]
          assert_equal "revoked", report["cleanup"]
        end

        def test_exec_preserves_the_selected_installed_runtime
          @fake.define_singleton_method(:with_exec_environment) do |profile:, credential:, &block|
            block.call({"ACE_TOOLCHAIN" => "auto", "GEM_PATH" => "/provider/source", "PATH" => "/provider/source/bin"})
          end
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          selected = {"ACE_TOOLCHAIN" => "installed", "GEM_HOME" => "/opt/ace/gems", "GEM_PATH" => "/opt/ace/gems",
            "PATH" => "/opt/ace/runtime/bin:/usr/bin:/bin"}
          original = selected.to_h { |key, _| [key, ENV[key]] }
          selected.each { |key, value| ENV[key] = value }
          begin
            svc.exec(lease_id: lease["id"], argv: %w[true],
              env: {"ACE_TOOLCHAIN" => "auto", "GEM_HOME" => "/workspace/source", "GEM_PATH" => "/workspace/source"})
            _argv, env = @exec_seen
            selected.each { |key, value| assert_equal value, env[key], "#{key} must survive the auth boundary" }
          ensure
            original.each { |key, value| value ? ENV[key] = value : ENV.delete(key) }
          end
        end

        def test_exec_uses_the_provider_session_environment
          @fake.define_singleton_method(:with_exec_environment) do |profile:, credential:, &block|
            raise "missing handoff" unless File.file?(credential)
            block.call({"XDG_DATA_HOME" => "/private/session"})
          end
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          svc.exec(lease_id: lease["id"], argv: %w[true])
          _argv, env = @exec_seen
          assert_equal "/private/session", env["XDG_DATA_HOME"]
          assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
        end

        def test_exec_connects_real_forgejo_projection_to_the_lease_handoff
          projection = Plugins::ForgejoProvider.new
          @fake.define_singleton_method(:with_exec_environment) do |profile:, credential:, &block|
            effective = profile.merge("issuer" => {"url" => "http://127.0.0.1:3000", "account" => "reviewer"})
            projection.stub(:linux_xdg?, true) do
              projection.with_exec_environment(profile: effective, credential: credential, &block)
            end
          end
          observed = nil
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: lambda { |_argv, env|
              data = JSON.parse(File.read(File.join(env.fetch("XDG_DATA_HOME"), "forgejo-cli", "keys.json")))
              token = data.fetch("hosts").fetch("127.0.0.1:3000").fetch("token")
              value, status = Open3.capture2(env, env.fetch("GIT_ASKPASS"), "Password for 'http://reviewer@127.0.0.1:3000': ")
              observed = [token, value, status.success?, env.fetch("XDG_DATA_HOME")]
              0
            })
          end
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          svc.exec(lease_id: lease["id"], argv: %w[true])
          assert_equal "SECRET-#{lease['id']}", observed[0]
          assert_equal observed[0], observed[1]
          assert observed[2]
          refute File.exist?(observed[3])
        end

        def test_exec_on_a_dead_or_parallel_lease_is_refused
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          svc.revoke(lease_id: lease["id"])

          error = assert_raises(Refusal) { svc.exec(lease_id: lease["id"], argv: %w[true]) }
          assert_match(/not live/, error.message)
        end

        def test_exec_refuses_when_the_registered_provider_disappears
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          Providers.reset!
          error = assert_raises(Refusal) { svc.exec(lease_id: lease["id"], argv: %w[true]) }
          assert_match(/provider execution refused/, error.message)
        end

        def test_revoke_keeps_unknown_outcome_pending_when_provider_disappears
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          Providers.reset!
          assert_match(/revoke-pending/, svc.revoke(lease_id: lease["id"]).to_s)
          record = svc.store.load(lease["id"])
          assert_equal "revoke-pending", record["state"]
          refute svc.store.live?(record)
        end

        def test_exec_without_the_delivered_credential_degrades_to_a_refusal
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          File.delete(Dir.glob(File.join(@dir, "credentials", "*")).first)

          error = assert_raises(Refusal) do
            svc.exec(lease_id: lease["id"], argv: %w[true])
          end
          assert_match(/no delivered credential/, error.message)
        end

        def test_revoke_is_idempotent_and_unknown_leases_are_refused
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          assert_equal :revoked, svc.revoke(lease_id: lease["id"])
          assert_equal :revoked, svc.revoke(lease_id: lease["id"])
          assert_equal 1, @fake.revoked.size, "the exact token id, once"

          error = assert_raises(Error) { svc.revoke(lease_id: "lease-0000000000000000") }
          assert_match(/unknown lease/, error.message)
        end

        def test_repeated_revoke_preserves_unconfirmed_forced_terminal_result
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          svc.store.update(lease["id"]) do |record|
            record["state"] = "revoked"
            record["cleanup"] = {"result" => "forced-terminal"}
          end
          assert_equal :forced_terminal, svc.revoke(lease_id: lease["id"])
          assert_empty @fake.revoked
        end

        def test_concurrent_revoke_does_not_turn_confirmed_cleanup_into_pending
          entered = Queue.new
          release = Queue.new
          def @fake.revoke(profile:, token_ref:, token: nil)
            raise Providers::OutcomeUnknownError, "token required" if token.nil?
            @revoked << token_ref
            :revoked
          end
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(_argv, _env) { entered << true; release.pop; 0 })
          end
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          execution = Thread.new do
            {result: svc.exec(lease_id: lease["id"], argv: ["dummy"])}
          rescue StandardError => e
            {error: e}
          end
          Timeout.timeout(5) { entered.pop }
          assert_equal :revoked, svc.revoke(lease_id: lease["id"])
          release << true
          outcome = execution.value
          assert_nil outcome[:error], outcome[:error]&.message
          assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
        ensure
          release << true if execution&.alive?
          execution&.join
        end

        def test_late_cleanup_failure_does_not_overwrite_confirmed_revocation
          entered = Queue.new
          release = Queue.new
          mutex = Mutex.new
          calls = 0
          @fake.define_singleton_method(:revoke) do |profile:, token_ref:, token: nil|
            ordinal = mutex.synchronize { calls += 1 }
            if ordinal == 1
              entered << true
              release.pop
              raise Providers::OutcomeUnknownError, "late failure"
            end
            :revoked
          end
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          execution = Thread.new do
            {result: svc.exec(lease_id: lease["id"], argv: ["dummy"])}
          rescue StandardError => e
            {error: e}
          end
          Timeout.timeout(5) { entered.pop }
          assert_equal :revoked, svc.revoke(lease_id: lease["id"])
          release << true
          outcome = execution.value
          assert_nil outcome[:error], outcome[:error]&.message
          assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
        ensure
          release << true if execution&.alive?
          execution&.join
        end

        def test_network_shaped_revoke_stays_visible_as_pending_never_claimed
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          pending = FakeProvider.new(failure: Providers::OutcomeUnknownError.new("network"))
          Providers.register("fake", pending)

          outcome = svc.revoke(lease_id: lease["id"])
          assert_match(/revoke-pending/, outcome.to_s)
          assert_equal "revoke-pending", svc.status(lease_id: lease["id"])["state"]
        end

        def test_revoke_and_reconcile_degrade_when_the_profile_was_removed
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          stripped = format(<<~YAML, File.join(@dir, "leases"), File.join(@dir, "credentials"))
            auth:
              leases_dir: %s
              credentials_dir: %s
              profiles: {}
          YAML
          stripped_service = service(document: stripped)

          outcome = stripped_service.revoke(lease_id: lease["id"])
          assert_match(/revoke-pending \(profile 'developer' removed/, outcome.to_s)
          assert_equal "revoke-pending",
            stripped_service.status(lease_id: lease["id"])["state"]

          entry = stripped_service.reconcile.find { |item| item["lease"] == lease["id"] }
          assert_match(/profile 'developer' removed/, entry["reconciled"])
        end

        def test_reconcile_resolves_pending_and_expired_leases
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          # force an expired deadline: the lease becomes non-live
          svc.store.update(lease["id"]) { |record| record["use_until"] = "2020-01-01T00:00:00Z" }

          report = svc.reconcile
          entry = report.find { |item| item["lease"] == lease["id"] }
          assert_equal "revoked", entry["reconciled"]
          assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
        end

        def test_reconcile_does_not_report_forced_terminal_as_confirmed_revocation
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          svc.store.update(lease["id"]) do |record|
            record["state"] = "revoked"
            record["cleanup"] = {"result" => "forced-terminal"}
          end
          result = svc.reconcile.find { |row| row["lease"] == lease["id"] }
          assert_equal "forced_terminal", result["reconciled"]
        end

        def test_exec_accepts_already_invalid_as_confirmed_cleanup
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          def @fake.revoke(**) = :already_invalid
          assert_equal "already_invalid", svc.exec(lease_id: lease["id"], argv: ["true"])["cleanup"]
          assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
        end

        def test_credential_disappearing_during_cleanup_remains_pending
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          credential = Dir.glob(File.join(@dir, "credentials", "*")).fetch(0)
          read = File.method(:read)
          raced = ->(path, *args, **kwargs) { raise Errno::ENOENT if path == credential; read.call(path, *args, **kwargs) }
          outcome = File.stub(:read, raced) { svc.revoke(lease_id: lease["id"]) }
          assert_match(/revoke-pending/, outcome.to_s)
          assert_equal "revoke-pending", svc.store.load(lease["id"])["state"]
        end

        def test_invalid_stored_deadline_is_a_typed_error
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          svc.store.update(lease["id"]) { |record| record["use_until"] = "not-a-date" }
          assert_raises(Error) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
        end

        def test_reconcile_reports_one_broken_handoff_and_continues
          svc = service
          leases = %w[first second].map do |name|
            lease = svc.request(profile_name: "developer", role: "developer", task: name, assignment: name, repos: ["ace"])
            svc.store.update(lease["id"]) { |record| record["use_until"] = "2020-01-01T00:00:00Z" }
            lease
          end
          handoff = svc.method(:handoff_for)
          poisoned = ->(lease) { raise Error, "unsafe runtime directory" if lease["id"] == leases.first["id"]; handoff.call(lease) }
          report = svc.stub(:handoff_for, poisoned) { svc.reconcile }
          assert_match(/reconcile-failed/, report.find { |row| row["lease"] == leases.first["id"] }["reconciled"])
          assert_equal "revoked", svc.status(lease_id: leases.last["id"])["state"]
        end

        def test_reconcile_reports_a_record_missing_correlation_fields
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          svc.store.update(lease["id"]) { |record| record.delete("task") }
          result = svc.reconcile.find { |row| row["lease"] == lease["id"] }
          assert_match(/reconcile-failed/, result["reconciled"])
        end

        def test_exec_reports_session_system_call_failure_as_auth_error_and_cleans_up
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(*) { raise Errno::EINVAL })
          end
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          assert_raises(Error) { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
        end

        def test_exec_rejects_invalid_runner_result_and_cleans_up
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(*) { nil })
          end
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          assert_raises(Error) { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
        end

        def test_unconfirmed_containment_blocks_recovery_and_new_issuance
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(*) { raise UncontainedSessionError, "unconfirmed" })
          end
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          assert_raises(UncontainedSessionError) { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          record = svc.status(lease_id: lease["id"])
          assert_equal "revoked", record["state"]
          assert_equal "unconfirmed", record["containment"]
          assert_equal :revoked, svc.revoke(lease_id: lease["id"])
          assert_match(/execution unresolved/, svc.reconcile.find { |row| row["lease"] == lease["id"] }["reconciled"])
          assert_raises(Refusal) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          assert_equal 1, @fake.issued.size
          assert_equal [lease["token_ref"]], @fake.revoked
        end

        def test_cleanup_error_preserves_uncontained_failure_and_marker
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(*) { raise UncontainedSessionError, "unconfirmed" })
          end
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          def @fake.revoke(**) = raise(Errno::EIO)
          error = assert_raises(UncontainedSessionError) { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          assert_kind_of Errno::EIO, error.cause
          assert_equal "unconfirmed", svc.store.load(lease["id"])["execution"]
        end

        def test_cleanup_system_error_after_success_is_a_typed_failure
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          def @fake.revoke(**) = raise(Errno::EIO)
          assert_raises(Error) { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          refute svc.store.load(lease["id"]).key?("execution")
        end

        def test_reissued_lease_waits_for_a_previously_revoked_execution_to_finish
          started, finish = Queue.new, Queue.new
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(*) { started << true; finish.pop; 0 })
          end
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          execution = Thread.new { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          Timeout.timeout(3) { started.pop }
          assert_equal :revoked, svc.revoke(lease_id: lease["id"])
          assert_raises(Refusal) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          assert_equal 1, @fake.issued.size
          finish << true
          Timeout.timeout(3) { execution.value }
        ensure
          finish << true if finish && execution&.alive?
          execution&.join(3)
        end

        def test_reconcile_revokes_expired_credential_without_claiming_command_exit
          started, finish = Queue.new, Queue.new
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(*) { started << true; finish.pop; 0 })
          end
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          execution = Thread.new { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          Timeout.timeout(3) { started.pop }
          svc.store.update(lease["id"]) { |record| record["use_until"] = "2020-01-01T00:00:00Z" }
          report = svc.reconcile.find { |row| row["lease"] == lease["id"] }
          assert_match(/execution unresolved/, report["reconciled"])
          assert_equal "revoked", svc.store.load(lease["id"])["state"]
          assert_equal [lease["token_ref"]], @fake.revoked
          assert_raises(Refusal) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          finish << true
          Timeout.timeout(3) { execution.value }
        ensure
          finish << true if finish && execution&.alive?
          execution&.join(3)
        end

        def test_concurrent_revoke_cannot_hide_unconfirmed_command_containment
          started, finish = Queue.new, Queue.new
          svc = Molecules::GrantResolver.stub(:read_verified, @document) do
            Service.new(principal: -> { "test-worker" }, runner: ->(*) { started << true; finish.pop; raise UncontainedSessionError, "unconfirmed" })
          end
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          execution = Thread.new do
            svc.exec(lease_id: lease["id"], argv: ["true"])
          rescue UncontainedSessionError
            :uncontained
          end
          Timeout.timeout(3) { started.pop }
          assert_equal :revoked, svc.revoke(lease_id: lease["id"])
          assert_raises(Refusal) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          finish << true
          assert_equal :uncontained, Timeout.timeout(3) { execution.value }
          assert_equal "unconfirmed", svc.status(lease_id: lease["id"])["containment"]
          assert_raises(Refusal) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          assert_equal 1, @fake.issued.size
        ensure
          finish << true if finish && execution&.alive?
          execution&.join(3)
        end

        def test_persisted_execution_marker_blocks_recovery_and_reissue_after_crash
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          svc.store.update(lease["id"]) do |record|
            record["state"] = "revoked"
            record["cleanup"] = {"result" => "revoked"}
            record["execution"] = "in-progress"
          end
          report = svc.reconcile.find { |row| row["lease"] == lease["id"] }
          assert_match(/execution unresolved/, report["reconciled"])
          assert_raises(Refusal) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          assert_equal 1, @fake.issued.size
        end

        def test_persisted_execution_marker_blocks_reuse_of_an_issued_lease
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          svc.store.update(lease["id"]) { |record| record["execution"] = "in-progress" }
          assert_raises(Refusal) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          assert_raises(Refusal) { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          assert_empty @fake.revoked
        end

        def test_session_runner_persists_the_exact_command_cgroup_before_launch
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          unit = "ace-auth-session-worker-0123456789abcdef.service"
          session_id = "c" * 32
          path = "/sys/fs/cgroup/ace.slice/#{unit}/ace-exec-#{'d' * 32}"
          svc.store.update(lease["id"]) do |record|
            record["execution"] = "in-progress"
            record["session_unit"] = unit
            record["session_id"] = session_id
            record["session_uid"] = 1234
            record["issuer_invocation"] = "a" * 32
          end
          runner = Object.new
          runner.define_singleton_method(:call) do |_argv, _env, before_start:, deadline:|
            raise "lease deadline not propagated" unless deadline == Time.iso8601(lease.fetch("use_until"))
            before_start.call(path)
            raise "cgroup was not recorded before launch" unless svc.store.load(lease["id"])["execution_cgroup"] == path
            0
          end
          svc.instance_variable_set(:@session_runner, runner)
          svc.instance_variable_set(:@session_unit, unit)
          svc.instance_variable_set(:@session_id, session_id)
          assert_equal 0, svc.send(:run_leased_command, ["true"], {}, lease["id"])
        end

        def test_issuer_recovery_refuses_to_claim_a_marked_execution_complete
          invocation = "a" * 32
          svc = service
          lease = svc.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "t", assignment: "a", repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
            provider_expiry: nil, token_ref: "token", session_uid: 1234, session_id: "c" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service", issuer_invocation: invocation)
          svc.store.update(lease["id"]) do |record|
            record["state"] = "issued"
            record["execution"] = "in-progress"
          end
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            assert_raises(Error) { operator.revoke_issuer(invocation: invocation) }
          end }
          assert_equal ["token"], @fake.revoked
          assert_equal "revoked", svc.store.load(lease["id"])["state"]
          assert_equal "in-progress", svc.store.load(lease["id"])["execution"]
        end

        def test_issuer_recovery_contains_exact_recorded_command_before_revocation
          invocation, session_id = "a" * 32, "c" * 32
          unit = "ace-auth-session-worker-0123456789abcdef.service"
          path = "/sys/fs/cgroup/ace.slice/#{unit}/ace-exec-#{'d' * 32}"
          svc = service
          lease = svc.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "t", assignment: "a", repos: ["ace"], use_until: (Time.now.utc + 60).iso8601,
            provider_expiry: nil, token_ref: "token", session_uid: 1234, session_id: session_id,
            session_unit: unit, issuer_invocation: invocation)
          svc.store.update(lease["id"]) do |record|
            record["state"] = "issued"
            record["execution"] = "in-progress"
            record["execution_cgroup"] = path
          end
          observed = nil
          recover = ->(**values) { observed = values; :contained }
          state_during_revoke = nil
          @fake.define_singleton_method(:revoke) do |**|
            state_during_revoke = svc.store.load(lease["id"])["state"]
            :revoked
          end
          operator = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "root" }) }
          Process.stub(:uid, 0) { Process.stub(:euid, 0) do
            SessionAttachment.stub(:recover_command!, recover) do
              assert_equal "revoked", operator.revoke_issuer(invocation: invocation).fetch(0).fetch("cleanup")
            end
          end }
          assert_equal({path: path, unit: unit, invocation_id: session_id}, observed)
          assert_equal "revoke-pending", state_during_revoke
          record = svc.store.load(lease["id"])
          refute record.key?("execution")
          refute record.key?("execution_cgroup")
          assert_equal "revoked", record["state"]
        end

        def test_exec_refuses_credential_overrides_from_caller_environment
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          assert_raises(Refusal) { svc.exec(lease_id: lease["id"], argv: ["true"], env: {"GH_TOKEN" => "override"}) }
          assert_equal "issued", svc.status(lease_id: lease["id"])["state"]
        end

        def test_exec_rejects_invalid_allowlisted_environment_values
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          [1, nil, "bad\0value"].each do |value|
            assert_raises(Refusal) { svc.exec(lease_id: lease.fetch("id"), argv: ["true"], env: {"PATH" => value}) }
          end
          assert_equal "issued", svc.status(lease_id: lease.fetch("id"))["state"]
        end

        def test_exec_refuses_invalid_argv_before_reading_credentials
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          [nil, [], [""], ["valid", "bad\0argument"], [123]].each do |argv|
            assert_raises(Refusal) { svc.exec(lease_id: lease["id"], argv: argv) }
          end
          assert_equal "issued", svc.status(lease_id: lease["id"])["state"]
          assert_empty @fake.revoked
        end

        def test_exec_rejects_malformed_env_handoff_without_exposing_or_consuming_it
          document = YAML.safe_load(@document)
          document.fetch("auth").fetch("profiles")["local"] = {
            "provider" => "env", "roles" => ["developer"], "principals" => ["test-worker"],
            "repos" => ["ace"], "env_names" => ["TEST_SECRET"]
          }
          Providers.register("env", Plugins::EnvProvider.new(issuer_env: {"TEST_SECRET" => "private-value"}))
          svc = service(document: YAML.dump(document))
          lease = svc.request(profile_name: "local", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          credential = Dir.glob(File.join(@dir, "credentials", "*")).fetch(0)
          File.chmod(0o600, credential)
          File.write(credential, '["unexpected"]')
          assert_raises(Refusal) { svc.exec(lease_id: lease["id"], argv: ["true"]) }
          assert_equal "issued", svc.status(lease_id: lease["id"])["state"]
          refute @exec_seen
        end

        def test_default_runner_executes_a_program_with_equals_in_its_path
          skip "the unprivileged direct runner is unavailable to root" if Process.euid.zero?
          svc = Molecules::GrantResolver.stub(:read_verified, @document) { Service.new(principal: -> { "test-worker" }) }
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          program = File.join(@dir, "program=literal")
          File.write(program, "#!/bin/sh\nexit 0\n")
          File.chmod(0o700, program)
          assert_equal 0, svc.exec(lease_id: lease["id"], argv: [program])["exit"]
        end

        def test_wildcard_profile_deduplicates_requested_repositories
          lease = service.request(profile_name: "wide", role: "developer", task: "t", assignment: "a", repos: %w[ace ace])
          assert_equal ["ace"], lease["repos"]
        end

        def test_reconcile_cannot_revoke_an_issue_that_is_still_in_flight
          started, finish = Queue.new, Queue.new
          provider = @fake
          original_issue = provider.method(:issue)
          provider.define_singleton_method(:issue) do |profile:, lease:|
            started << lease["id"]
            finish.pop
            original_issue.call(profile: profile, lease: lease)
          end
          svc = service
          request = Thread.new { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          id = Timeout.timeout(3) { started.pop }
          attempted = Queue.new
          lock = svc.store.method(:with_correlation_lock)
          svc.store.define_singleton_method(:with_correlation_lock) { |**args, &block| attempted << true; lock.call(**args, &block) }
          reconcile = Thread.new { svc.reconcile }
          Timeout.timeout(3) { attempted.pop }
          assert_empty @fake.revoked
          finish << true
          lease = Timeout.timeout(3) { request.value }
          report = Timeout.timeout(3) { reconcile.value }
          assert_equal "issued", svc.status(lease_id: id)["state"]
          assert_equal "live", report.find { |row| row["lease"] == id }["reconciled"]
          assert_equal id, lease["id"]
        ensure
          finish << true if finish && request&.alive?
          [request, reconcile].compact.each { |thread| thread.join(3) }
        end

        def test_revoke_waits_for_the_correlated_issue_to_finish
          started, finish = Queue.new, Queue.new
          provider = @fake
          original_issue = provider.method(:issue)
          provider.define_singleton_method(:issue) do |profile:, lease:|
            started << lease["id"]
            finish.pop
            original_issue.call(profile: profile, lease: lease)
          end
          svc = service
          request = Thread.new { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          id = Timeout.timeout(3) { started.pop }
          attempted = Queue.new
          lock = svc.store.method(:with_correlation_lock)
          svc.store.define_singleton_method(:with_correlation_lock) { |**args, &block| attempted << true; lock.call(**args, &block) }
          revoke = Thread.new { svc.revoke(lease_id: id) }
          Timeout.timeout(3) { attempted.pop }
          assert_empty @fake.revoked
          finish << true
          Timeout.timeout(3) { request.value }
          assert_equal :revoked, Timeout.timeout(3) { revoke.value }
          assert_equal "revoked", svc.status(lease_id: id)["state"]
        ensure
          finish << true if finish && request&.alive?
          [request, revoke].compact.each { |thread| thread.join(3) }
        end

        def test_reconcile_does_not_overtake_issuance_across_processes
          skip "fork unavailable" unless Process.respond_to?(:fork)
          ready_read, ready_write = IO.pipe
          release_read, release_write = IO.pipe
          attempted_read, attempted_write = IO.pipe
          revoked = File.join(@dir, "revoked-during-issue")
          provider = @fake
          original_issue = provider.method(:issue)
          provider.define_singleton_method(:issue) do |profile:, lease:|
            ready_write.write("1")
            release_read.read(1)
            original_issue.call(profile: profile, lease: lease)
          end
          provider.define_singleton_method(:revoke) do |**|
            File.write(revoked, "revoked")
            :revoked
          end
          svc = service
          issuer = fork do
            begin
              svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
              exit! 0
            rescue StandardError
              exit! 1
            end
          end
          Timeout.timeout(5) { ready_read.read(1) }
          reconciler = fork do
            lock = svc.store.method(:with_correlation_lock)
            svc.store.define_singleton_method(:with_correlation_lock) do |**args, &block|
              attempted_write.write("1")
              lock.call(**args, &block)
            end
            begin
              svc.reconcile
              exit! 0
            rescue StandardError
              exit! 1
            end
          end
          Timeout.timeout(5) { attempted_read.read(1) }
          refute File.exist?(revoked), "reconcile revoked an issue that had not finished"
          release_write.write("1")
          _, status = Timeout.timeout(5) { Process.wait2(issuer) }
          issuer = nil
          assert status.success?, "issuer process failed"
          _, status = Timeout.timeout(5) { Process.wait2(reconciler) }
          reconciler = nil
          assert status.success?, "reconciler process failed"
          assert_equal "issued", svc.store.all.fetch(0)["state"]
          refute File.exist?(revoked)
        ensure
          [issuer, reconciler].compact.each do |pid|
            begin
              unless Process.waitpid(pid, Process::WNOHANG)
                Process.kill("KILL", pid) # our own unreaped test child
                Process.waitpid(pid)
              end
            rescue Errno::ESRCH, Errno::ECHILD
              nil
            end
          end
          [ready_read, ready_write, release_read, release_write, attempted_read, attempted_write].compact.each do |io|
            io.close unless io.closed?
          end
        end

        def test_status_never_exposes_the_token_reference
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          single = svc.status(lease_id: lease["id"])
          refute_includes single.keys, "token_ref"
          refute_includes svc.status.map(&:keys).flatten.uniq, "token_ref"
        end

        def test_status_does_not_expose_internal_path_of_corrupt_record
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          File.write(File.join(@dir, "leases", "#{lease.fetch("id")}.json"), "{")

          corrupt = svc.status.find { |record| record["id"] == lease["id"] }
          assert corrupt.fetch("corrupt")
          refute_includes corrupt.keys, "_path"
        end

        def test_corrupt_lease_blocks_new_issuance_without_reminting
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          File.write(File.join(@dir, "leases", "#{lease.fetch("id")}.json"), "{")

          error = assert_raises(Refusal) do
            svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: %w[ace])
          end
          assert_match(/corrupt/, error.message)
          assert_equal 1, @fake.issued.length
        end

        def test_unattributable_lease_blocks_new_issuance
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          svc.store.update(lease.fetch("id")) { |record| record.delete("task") }

          assert_raises(Error) { svc.revoke(lease_id: lease.fetch("id")) }
          assert_raises(Refusal) do
            svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: %w[ace])
          end
          assert_equal 1, @fake.issued.length
        end

        def test_request_refuses_incomplete_correlation_before_creating_a_lease
          svc = service
          [nil, "", "  ", 1].each do |value|
            assert_raises(Refusal) do
              svc.request(profile_name: "developer", role: "developer", task: value, assignment: "a", repos: ["ace"])
            end
          end
          assert_empty svc.store.all
          assert_empty @fake.issued
        end

        def test_expired_lease_with_unconfirmed_revocation_blocks_reissue
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          svc.store.update(lease.fetch("id")) { |record| record["use_until"] = "2020-01-01T00:00:00Z" }
          @fake.instance_variable_set(:@failure, Providers::TransientError.new("offline"))

          assert_raises(Refusal) do
            svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: %w[ace])
          end
          assert_equal 1, @fake.issued.length
          assert_equal "revoke-pending", svc.store.load(lease.fetch("id"))["state"]
        end

        def test_missing_live_handoff_requires_revocation_before_replacement
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          credential = Dir.glob(File.join(@dir, "credentials", "#{lease.fetch("id")}-*")).fetch(0)
          File.unlink(credential)

          error = assert_raises(Refusal) { svc.exec(lease_id: lease.fetch("id"), argv: ["true"]) }
          assert_match(/revoke/, error.message)
          assert_raises(Refusal) { svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"]) }
          report = svc.reconcile.find { |entry| entry["lease"] == lease.fetch("id") }
          assert_match(/handoff missing/, report.fetch("reconciled"))
          assert_equal 1, @fake.issued.length
          assert_equal :revoked, svc.revoke(lease_id: lease.fetch("id"))
          replacement = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          refute_equal lease.fetch("id"), replacement.fetch("id")
        end

        def test_invalid_provider_expiry_is_pending_and_can_be_reconciled
          issue = @fake.method(:issue)
          @fake.define_singleton_method(:issue) do |**kwargs|
            issue.call(**kwargs).merge("provider_expiry" => "not-a-time")
          end
          svc = service
          error = assert_raises(Error) do
            svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          end
          assert_match(/invalid or expired expiry/, error.message)
          record = svc.store.all.fetch(0)
          assert_equal "revoke-pending", record.fetch("state")
          assert_nil record["provider_expiry"]
          assert_equal "revoked", svc.reconcile.fetch(0).fetch("reconciled")
        end

        def test_provider_managed_expiry_cannot_be_missing
          @fake.instance_variable_set(:@capabilities, {"expiry_mode" => "provider"})
          document = YAML.safe_load(@document)
          document.fetch("auth").fetch("profiles").fetch("developer")["expiry_mode"] = "provider"
          svc = service(document: document.to_yaml)
          assert_raises(Error) do
            svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          end
          record = svc.store.all.fetch(0)
          assert_equal "revoke-pending", record.fetch("state")
          assert_equal "revoked", svc.reconcile.fetch(0).fetch("reconciled")
        end

        def test_provider_managed_expiry_requires_a_declared_capability
          @fake.instance_variable_set(:@capabilities, {})
          document = YAML.safe_load(@document)
          document.fetch("auth").fetch("profiles").fetch("developer")["expiry_mode"] = "provider"
          svc = service(document: document.to_yaml)
          assert_raises(Refusal) do
            svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          end
          assert_empty svc.store.all
          assert_empty @fake.issued
        end

        def test_provider_expiry_is_normalized_to_an_absolute_time
          issue = @fake.method(:issue)
          @fake.define_singleton_method(:issue) do |**kwargs|
            issue.call(**kwargs).merge("provider_expiry" => (Time.now.utc + 3600).getlocal("+02:00").strftime("%Y-%m-%d %H:%M:%S %z"))
          end
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          assert_match(/\A\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\z/, lease.fetch("provider_expiry"))
        end

        def test_settlement_selects_handoff_from_the_previous_lease
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
          unit = "ace-auth-session-worker-0123456789abcdef.service"
          svc.store.update(lease.fetch("id")) do |record|
            record.merge!("use_until" => "2020-01-01T00:00:00Z", "session_uid" => 1234,
              "session_id" => "a" * 32, "session_unit" => unit, "issuer_invocation" => "b" * 32)
          end
          seen = []
          select_handoff = lambda do |record|
            seen << record.fetch("session_unit")
            CredentialHandoff.new(File.join(@dir, "credentials"), recipient: record.fetch("principal"))
          end

          svc.stub(:handoff_for, select_handoff) do
            replacement = svc.request(profile_name: "developer", role: "developer", task: "t", assignment: "a", repos: ["ace"])
            refute_equal lease.fetch("id"), replacement.fetch("id")
          end
          assert_equal [unit], seen
          assert_equal "revoked", svc.store.load(lease.fetch("id"))["state"]
        end

        # R6 (re-review): a REALLY spawned child must not inherit any
        # ambient credential override the lease does not contain — the
        # child environment is an allowlist, not a merge.
        def test_exec_real_child_does_not_inherit_unleased_credential_overrides
          skip "the unprivileged direct runner is not available to a root issuer" if Process.euid.zero?
          require "rbconfig"
          svc = Molecules::GrantResolver.stub :read_verified, @document do
            Service.new(principal: -> { "test-worker" }) # default runner: real spawn via env -i
          end
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          previous = ENV["GH_TOKEN"]
          ENV["GH_TOKEN"] = "SYNTHETIC-AMBIENT-OVERRIDE"
          observed = File.join(@dir, "child-observation.json")
          child = "require 'json'; File.write(ARGV.fetch(0), JSON.generate(" \
            "{'ambient_credential_present' => ENV.key?('GH_TOKEN'), " \
            "'path_present' => ENV.key?('PATH'), " \
            "'lease' => ENV['ACE_LAB_LEASE']}))"
          report = nil
          begin
            report = svc.exec(lease_id: lease["id"],
              argv: [RbConfig.ruby, "-e", child, observed])
          ensure
            previous ? ENV["GH_TOKEN"] = previous : ENV.delete("GH_TOKEN")
          end

          assert_equal 0, report["exit"]
          observed_env = JSON.parse(File.read(observed))
          refute observed_env["ambient_credential_present"],
            "the child inherited a credential outside the lease"
          assert observed_env["path_present"], "allowlisted runtime vars survive"
          assert_equal lease["id"], observed_env["lease"]
        end
      end
    end
  end
end

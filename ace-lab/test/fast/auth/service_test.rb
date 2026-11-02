# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"
require "open3"

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
        end

        def teardown
          @peer_handle.close unless @peer_handle.closed?
          FileUtils.remove_entry(@dir) if @dir
          Providers.reset!
        end

        def session_identity
          SessionPeer::Identity.new(uid: Process.uid, gid: Process.gid, role: "worker",
            invocation_id: "a" * 32, unit: "ace-auth-session-worker-0123456789abcdef.service",
            cwd: Dir.pwd, runtime_dir: "/run/ace-auth-0123456789abcdef", pidfd: @peer_handle)
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
            result = operator.revoke_issuer(invocation: "a" * 32)
            assert_match(/revoke-pending/, result.first.fetch("cleanup"))
          end }
          assert_equal "revoke-pending", worker.store.load(lease["id"])["state"]
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
          worker.store.create(profile: "developer", role: "developer", principal: "test-worker",
            task: "task", assignment: "assignment", repos: ["ace"], session_uid: 1234, session_id: "b" * 32,
            session_unit: "ace-auth-session-worker-0123456789abcdef.service",
            use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil)
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

          assert_raises(Errno::ENOENT) { failing.exec(lease_id: lease["id"], argv: ["missing-command"]) }
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

        def test_status_never_exposes_the_token_reference
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])

          single = svc.status(lease_id: lease["id"])
          refute_includes single.keys, "token_ref"
          refute_includes svc.status.map(&:keys).flatten.uniq, "token_ref"
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

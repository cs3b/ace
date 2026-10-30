# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"

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
        end

        def teardown
          FileUtils.remove_entry(@dir) if @dir
          Providers.reset!
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

          error = assert_raises(Providers::UnsupportedError) do
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

        def test_exec_on_a_dead_or_parallel_lease_is_refused
          svc = service
          lease = svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
          svc.revoke(lease_id: lease["id"])

          error = assert_raises(Refusal) { svc.exec(lease_id: lease["id"], argv: %w[true]) }
          assert_match(/not live/, error.message)
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

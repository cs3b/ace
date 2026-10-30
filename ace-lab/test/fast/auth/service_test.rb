# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"

module Auth
  # Core lease lifecycle of ace-lab auth (task 8xs.t.pu0.7): idempotent
  # request, TTL refusal, principal/role gating, exec with the credential
  # REFERENCE (never a value), idempotent revoke, and reconcile of
  # interrupted states — with a fake provider pinning the plugin contract.
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

      def issue(profile:, lease:)
        raise @failure if @failure

        @issued << lease["id"]
        {"token" => "SECRET-#{lease["id"]}", "token_ref" => "tok-#{lease["id"]}",
         "provider_expiry" => nil, "via" => {"kind" => "file"}}
      end

      def revoke(profile:, token_ref:)
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
      Ace::Lab::Auth::Providers.register("fake", @fake = FakeProvider.new)
    end

    def teardown
      FileUtils.remove_entry(@dir) if @dir
    end

    def service
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, @document do
        Ace::Lab::Auth::Service.new(
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

    def test_role_principal_and_ttl_refusals_carry_reasons
      error = assert_raises(Ace::Lab::Auth::Refusal) do
        service.request(profile_name: "developer", role: "reviewer",
          task: "t", assignment: "a", repos: %w[ace])
      end
      assert_match(/role 'reviewer' is not allowed/, error.message)

      error = assert_raises(Ace::Lab::Auth::Refusal) do
        service.request(profile_name: "ghost", role: "developer",
          task: "t", assignment: "a", repos: %w[ace])
      end
      assert_match(/unknown auth profile/, error.message)

      Ace::Lab::Auth::Providers.register("fake2", FakeProvider.new)
      error = assert_raises(Ace::Lab::Auth::Refusal) do
        svc = Ace::Lab::Molecules::GrantResolver.stub :read_verified, @document do
          Ace::Lab::Auth::Service.new(principal: -> { "someone-else" })
        end
        svc.request(profile_name: "developer", role: "developer",
          task: "t", assignment: "a", repos: %w[ace])
      end
      assert_match(/principal 'someone-else' is not allowed.*escalate to the host owner/, error.message)

      svc = service
      error = assert_raises(Ace::Lab::Auth::Refusal) do
        svc.request(profile_name: "wide", role: "developer",
          task: "t", assignment: "a", ttl_minutes: 120)
      end
      assert_match(/exceeds the profile limit 60m; refused, not clipped/, error.message)
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

      error = assert_raises(Ace::Lab::Auth::Refusal) { svc.exec(lease_id: lease["id"], argv: %w[true]) }
      assert_match(/not live/, error.message)
    end

    def test_revoke_is_idempotent_and_unknown_leases_are_refused
      svc = service
      lease = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])

      assert_equal :revoked, svc.revoke(lease_id: lease["id"])
      assert_equal :revoked, svc.revoke(lease_id: lease["id"])
      assert_equal 1, @fake.revoked.size, "the exact token id, once"

      error = assert_raises(Ace::Lab::Error) { svc.revoke(lease_id: "lease-0000000000000000") }
      assert_match(/unknown lease/, error.message)
    end

    def test_network_shaped_revoke_stays_visible_as_pending_never_claimed
      svc = service
      lease = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])
      pending = FakeProvider.new(failure: Ace::Lab::Auth::Providers::OutcomeUnknownError.new("network"))
      Ace::Lab::Auth::Providers.register("fake", pending)

      outcome = svc.revoke(lease_id: lease["id"])
      assert_match(/revoke-pending/, outcome.to_s)
      assert_equal "revoke-pending", svc.status(lease_id: lease["id"])["state"]
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
  end
end

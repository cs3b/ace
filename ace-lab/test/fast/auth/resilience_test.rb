# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth"

module Ace
  module Lab
    module Auth
      # Crash-boundary matrix for the lease lifecycle (task 8xs.t.pu0.f):
      # issue interrupted before handoff, an unknown issue outcome, a
      # SIGKILL'd executor, a network loss during revoke, an expired
      # grant reuse, and a stuck revoke-pending with a lost credential —
      # every recovery continues the right stage without a second active
      # grant, a silent success, or a blind replay.
      class ResilienceTest < Minitest::Test
    class FlakyProvider
      attr_accessor :issue_fails, :revoke_fails, :issued, :revoked

      def initialize
        @issue_fails = 0
        @revoke_fails = 0
        @issued = []
        @revoked = []
      end

      def capabilities
        {"expiry_mode" => "host-revoke"}
      end

      def issue(profile:, lease:)
        if @issue_fails.positive?
          @issue_fails -= 1
          raise Ace::Lab::Auth::Providers::OutcomeUnknownError, "connection lost mid-issue"
        end

        @issued << lease["id"]
        {"token" => "SECRET-#{lease["id"]}", "token_ref" => "tok-#{lease["id"]}",
         "provider_expiry" => nil, "via" => {"kind" => "file"}}
      end

      def revoke(profile:, token_ref:, token: nil)
        if @revoke_fails.positive?
          @revoke_fails -= 1
          raise Ace::Lab::Auth::Providers::OutcomeUnknownError, "network down"
        end

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
            provider: flaky
            roles: [developer]
            principals: [test-worker]
            repos: [ace]
    YAML

    def setup
      @dir = Dir.mktmpdir
      @document = format(AUTH_YAML, File.join(@dir, "leases"), File.join(@dir, "credentials"))
      @flaky = FlakyProvider.new
      Ace::Lab::Auth::Providers.register("flaky", @flaky)
    end

    def teardown
      FileUtils.remove_entry(@dir) if @dir
      Providers.reset!
    end

    def service
      Ace::Lab::Molecules::GrantResolver.stub :read_verified, @document do
        Ace::Lab::Auth::Service.new(principal: -> { "test-worker" },
          runner: ->(_argv, _env) { @exec_result || 0 })
      end
    end

    def test_unknown_issue_outcome_leaves_one_live_lease_after_retry
      @flaky.issue_fails = 1
      svc = service

      error = assert_raises(Ace::Lab::Error) do
        svc.request(profile_name: "developer", role: "developer",
          task: "t", assignment: "a", repos: %w[ace])
      end
      assert_match(/unknown outcome/, error.message)

      # the retry mints the working lease; the interrupted record is NOT
      # live (exactly one active grant — no double issuance)
      lease = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])
      assert_equal "issued", lease["state_detail"]
      live = svc.store.all.count { |record| svc.store.live?(record) }
      assert_equal 1, live, "exactly one live grant after an interrupted issue + retry"
      interrupted = svc.store.all.reject { |record| record["id"] == lease["id"] }
      assert(interrupted.all? { |record| record["state"] == "revoke-pending" },
        "the interrupted record stays a visible open item for reconcile")
    end

    def test_sigkilled_executors_grant_dies_at_use_until_and_never_resurrects
      svc = service
      lease = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])

      # SIGKILL shape: no cleanup ran — the lease is still live until the
      # recorded use_until passes, then dead; nothing model-side revives it.
      assert svc.store.live?(svc.store.load(lease["id"]))
      svc.store.update(lease["id"]) do |record|
        record["use_until"] = Time.at(Time.now.utc - 60).strftime("%Y-%m-%dT%H:%M:%SZ")
      end
      dead = svc.store.load(lease["id"])
      refute svc.store.live?(dead), "use after use_until is refused"

      error = assert_raises(Ace::Lab::Auth::Refusal) do
        svc.exec(lease_id: lease["id"], argv: %w[true])
      end
      assert_match(/not live/, error.message)
    end

    def test_network_loss_during_revoke_stays_pending_until_reconcile_closes_it
      svc = service
      lease = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])
      @flaky.revoke_fails = 1

      outcome = svc.revoke(lease_id: lease["id"])
      assert_match(/revoke-pending/, outcome.to_s,
        "a lost revoke response is NEVER claimed as success")
      assert_equal "revoke-pending", svc.status(lease_id: lease["id"])["state"]

      # recovery: the network returns and reconcile finishes the SAME grant
      report = svc.reconcile
      entry = report.find { |item| item["lease"] == lease["id"] }
      assert_equal "revoked", entry["reconciled"]
      assert_equal "revoked", svc.status(lease_id: lease["id"])["state"]
      assert_equal 1, @flaky.revoked.size, "the exact token, revoked once"
    end

    def test_cleanup_is_independent_of_any_model_turn
      svc = service
      lease = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])

      @exec_result = 0
      report = svc.exec(lease_id: lease["id"], argv: %w[bin/true])

      assert_equal 0, report["exit"]
      assert_equal "revoked", report["cleanup"],
        "credential cleanup follows the process, not a model decision"
      credential_files = Dir.glob(File.join(@dir, "credentials", "*"))
      assert_empty credential_files, "the handoff is cleared with the lease"
    end

    # F6 window: the provider ISSUED the token but the credential
    # handoff write fails afterwards — the record must not stay a
    # usable/live grant; reconcile finishes it and the retry mints a
    # fresh lease.
    def test_failed_handoff_delivery_leaves_no_live_lease
      Dir.mktmpdir do |dir|
        document = format(AUTH_YAML, File.join(dir, "leases"), File.join(dir, "credentials"))
        # occupy the credentials path with a FILE: mkdir_p/deliver fails
        File.write(File.join(dir, "credentials"), "occupied")
        svc = Ace::Lab::Molecules::GrantResolver.stub :read_verified, document do
          Ace::Lab::Auth::Service.new(principal: -> { "test-worker" },
            runner: ->(_argv, _env) { 0 })
        end

        error = assert_raises(Ace::Lab::Error) do
          svc.request(profile_name: "developer", role: "developer",
            task: "t", assignment: "a", repos: %w[ace])
        end
        assert_match(/credential handoff failed/, error.message)

        interrupted = svc.store.all.fetch(0)
        assert_equal "revoke-pending", interrupted["state"],
          "the interrupted handoff is a visible open item, never a live grant"
        refute svc.store.live?(interrupted)
        assert_equal 1, @flaky.issued.size, "the token WAS issued provider-side"

        # recovery: the retry mints a working lease; reconcile revokes
        # the interrupted token by its recorded reference
        FileUtils.rm(File.join(dir, "credentials"))
        lease = svc.request(profile_name: "developer", role: "developer",
          task: "t", assignment: "a", repos: %w[ace])
        assert_equal "issued", lease["state_detail"]
        refute_equal interrupted["id"], lease["id"]
        assert_equal 1, svc.store.all.count { |record| svc.store.live?(record) }

        report = svc.reconcile
        entry = report.find { |item| item["lease"] == interrupted["id"] }
        assert_equal "revoked", entry["reconciled"]
        assert_includes @flaky.revoked, interrupted["token_ref"]
      end
    end

    # 8xti21n3: an ISSUED record past its use_until must not be handed
    # back by find_live as "live" — a retry mints a fresh grant while
    # reconcile retires the expired one (never two live grants).
    def test_expired_lease_is_not_reused_by_a_retry_and_reconcile_retires_it
      svc = service
      expired = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])
      svc.store.update(expired["id"]) { |record| record["use_until"] = "2020-01-01T00:00:00Z" }

      refute svc.store.live?(svc.store.load(expired["id"]))
      assert_nil svc.store.find_live(task: "t", assignment: "a",
        profile: "developer", role: "developer"),
        "find_live is deadline-aware: the expired grant is not returned"

      fresh = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])
      refute_equal expired["id"], fresh["id"], "a fresh grant replaces the expired one"
      assert_equal "issued", fresh["state_detail"]
      assert_equal 2, @flaky.issued.size
      assert_equal 1, svc.store.all.count { |record| svc.store.live?(record) },
        "exactly one live grant after expiry + retry"

      entry = svc.reconcile.find { |item| item["lease"] == expired["id"] }
      assert_equal "revoked", entry["reconciled"], "reconcile retires the expired lease"
    end

    # 8xtiatf1: a revoke-pending lease whose credential file is gone
    # cannot present the token to the provider ever again — the
    # operator's explicit --force closes it as forced-terminal without
    # ever CLAIMING the provider confirmed the revocation.
    def test_force_revoke_closes_a_pending_lease_whose_credential_is_gone
      svc = service
      lease = svc.request(profile_name: "developer", role: "developer",
        task: "t", assignment: "a", repos: %w[ace])
      @flaky.revoke_fails = 1
      assert_match(/revoke-pending/, svc.revoke(lease_id: lease["id"]).to_s)
      File.delete(Dir.glob(File.join(@dir, "credentials", "*")).first)

      # without the operator force it stays a visible pending open item
      @flaky.revoke_fails = 1
      assert_match(/revoke-pending/, svc.revoke(lease_id: lease["id"]).to_s)
      assert_equal "revoke-pending", svc.status(lease_id: lease["id"])["state"]

      forced = svc.revoke(lease_id: lease["id"], force: true)
      assert_equal :forced_terminal, forced
      record = svc.store.load(lease["id"])
      assert_equal "revoked", record["state"]
      assert_equal "forced-terminal", record["cleanup"]["result"]
      assert_match(/outcome unconfirmed/, record["cleanup"]["note"],
        "the unconfirmed provider outcome stays recorded")
    end
  end
end
end
end

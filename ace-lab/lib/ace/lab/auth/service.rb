# frozen_string_literal: true

require "etc"
require "json"
require "open3"

module Ace
  module Lab
    module Auth
      # Explicit error base for the auth surface (the CLI rescues it).
      class Error < ::Ace::Lab::Error; end

      # The auth service core (task 8xs.t.pu0.7): request / status /
      # exec / revoke / reconcile over the trusted host configuration
      # and the plugin registry. It owns the lease lifecycle and the
      # minimal lease record — nothing else: no task progress, no
      # queues, no admission service. The calling ACCOUNT is verified
      # (the profile's principals/roles gate issuance — naming a role
      # never grants a right), TTLs refuse instead of silently
      # clipping, and the secret exists only in the ephemeral handoff.
      class Service
        DEFAULT_LEASES_DIR = "/var/lib/lab/ace-lab/auth/leases"
        DEFAULT_CREDENTIALS_DIR = "/run/lab/credentials"

        attr_reader :config, :store

        # @param authorization_path [String] trusted document location
        # @param runner [Proc] argv runner for the exec'd child
        def initialize(authorization_path: nil, runner: nil, principal: nil)
          @authorization_path = authorization_path || Ace::Lab.authorization_path
          @runner = runner || ->(argv, env) { system(env, *argv) ? 0 : 1 }
          @principal = principal || -> { Etc.getpwuid(Process.uid).name }
          @config = load_config
          @store = LeaseStore.new(@config["leases_dir"] || DEFAULT_LEASES_DIR)
          @credentials_dir = @config["credentials_dir"] || DEFAULT_CREDENTIALS_DIR
        end

        # --- request -------------------------------------------------------

        # Idempotent only per the IDENTICAL live request: the
        # task/assignment/profile/role correlation AND the requested
        # scope/principal must match; a mismatched retry (e.g. a
        # narrower repo list) is refused, never silently answered with
        # the wider existing grant. The granted scope is the
        # INTERSECTION of the host profile, the request and the task's
        # repo — a request may narrow, never widen; editing the task or
        # project config grants nothing.
        def request(profile_name:, role:, task:, assignment:, repos: [],
          ttl_minutes: nil)
          profile = profile_for(profile_name)
          unless profile["roles"].include?(role)
            raise Refusal.new("role '#{role}' is not allowed by profile '#{profile_name}'")
          end
          principal = @principal.call
          unless profile["principals"].empty? || profile["principals"].include?(principal)
            raise Refusal.new("principal '#{principal}' is not allowed by profile '#{profile_name}'; " \
              "escalate to the host owner")
          end

          ttl = ttl_minutes || profile["ttl_minutes"]
          if ttl > profile["max_ttl_minutes"]
            raise Refusal.new("ttl #{ttl}m exceeds the profile limit #{profile['max_ttl_minutes']}m; " \
              "refused, not clipped")
          end

          # The granted scope is computed BEFORE the live-lease lookup
          # so a retry is judged against what THIS request asked for.
          repos = (profile["repos"].empty? ? repos : profile["repos"] & repos).sort

          existing = @store.find_live(task: task, assignment: assignment,
            profile: profile_name, role: role)
          if existing && @store.live?(existing)
            # Idempotency holds only for the IDENTICAL request: a live
            # lease with a different granted scope or principal is a
            # mismatched retry — refusing it never silently reuses a
            # wider grant for a narrower ask.
            unless existing["repos"] == repos && existing["principal"] == principal
              raise Refusal.new("a live lease for task '#{task}' assignment '#{assignment}' " \
                "profile '#{profile_name}' role '#{role}' already exists with scope " \
                "[#{existing["repos"].join(", ")}] for principal '#{existing["principal"]}'; " \
                "revoke it first or repeat the identical request")
            end
            return existing.merge("state_detail" => "live")
          end

          lease = @store.create(profile: profile_name, role: role, principal: principal,
            task: task, assignment: assignment, repos: repos,
            use_until: Time.at(Time.now.utc + ttl * 60).strftime("%Y-%m-%dT%H:%M:%SZ"),
            provider_expiry: nil)

          issue = Providers.resolve(profile["provider"])
          # A provider unable to back the profile's NATIVE expiry must
          # be visible BEFORE handoff, never hidden behind use_until.
          if profile["expiry_mode"] == "provider" &&
            issue.capabilities.fetch("expiry_mode") != "provider"
            raise Refusal.new("provider '#{profile["provider"]}' cannot guarantee the " \
              "profile's native expiry")
          end

          begin
            granted = issue.issue(profile: profile, lease: lease)
          rescue Providers::RefusedError => e
            @store.update(lease["id"]) { |record| record["state"] = "revoked" }
            raise Refusal.new("provider refused: #{e.message}")
          rescue Providers::TransientError, Providers::OutcomeUnknownError => e
            @store.update(lease["id"]) { |record| record["state"] = "revoke-pending" }
            raise Error.new("issuance failed with unknown outcome: #{e.message}; " \
              "reconcile resolves the pending record")
          end

          @store.update(lease["id"]) do |record|
            record["token_ref"] = granted["token_ref"]
            record["provider_expiry"] = granted["provider_expiry"]&.to_s
            record["via"] = granted["via"]
          end
          # The secret goes ONLY to the ephemeral handoff; the returned
          # lease record carries references, never values. A failed
          # delivery is never a live grant: the token may exist
          # provider-side, so the record becomes revoke-pending for
          # reconcile to finish — an interrupted handoff must not be
          # reusable by a retry.
          handoff = CredentialHandoff.new(@credentials_dir, recipient: principal)
          begin
            handoff.deliver(lease["id"], granted["token"])
          rescue StandardError => e
            @store.update(lease["id"]) { |record| record["state"] = "revoke-pending" }
            raise Error.new("credential handoff failed: #{e.message}; " \
              "reconcile resolves the pending record")
          end
          @store.update(lease["id"]) { |record| record["cleanup_due_at"] = record["use_until"] }

          @store.load(lease["id"]).merge("state_detail" => "issued")
        end

        # --- status --------------------------------------------------------

        def status(lease_id: nil)
          return @store.load(lease_id) if lease_id

          @store.all.map { |lease| public_view(lease) }
        end

        # --- exec ----------------------------------------------------------

        # Runs the child under the lease: the child receives the
        # credential REFERENCE (ACE_LAB_CREDENTIAL_FILE / the profile's
        # env names), never a value in argv. The process exit code is
        # preserved; on process success a cleanup failure is itself an
        # error; the report carries both outcomes. One exec at a time
        # per lease.
        def exec(lease_id:, argv:, env: {})
          lease = @store.load(lease_id)
          raise Refusal.new("lease '#{lease_id}' is not live") unless @store.live?(lease)

          @store.with_exec_lock(lease_id) do
            profile = profile_for(lease["profile"])
            handoff = CredentialHandoff.new(@credentials_dir, recipient: lease["principal"])
            child_env = {**env,
              "ACE_LAB_LEASE" => lease_id,
              "ACE_LAB_CREDENTIAL_FILE" => handoff.path(lease_id)}
            if profile["provider"] == "env"
              child_env.merge!(JSON.parse(File.read(handoff.path(lease_id))))
            end

            exit_code = @runner.call(argv, child_env)
            cleanup = cleanup(lease, profile, handoff)
            if exit_code.zero? && cleanup != :revoked && cleanup != :cleared
              raise Error.new("process succeeded (exit 0) but cleanup failed: #{cleanup}")
            end

            {"lease" => lease_id, "exit" => exit_code, "cleanup" => cleanup.to_s}
          end
        end

        # --- revoke --------------------------------------------------------

        # Idempotent; an unknown/foreign lease id is refused; a network
        # outcome stays visible as revoke-pending — a revocation is
        # never CLAIMED before the provider confirms it.
        def revoke(lease_id:)
          lease = @store.load(lease_id)
          profile = profile_for(lease["profile"])
          handoff = CredentialHandoff.new(@credentials_dir, recipient: lease["principal"])

          # An already-revoked lease never re-dials the provider: the
          # idempotent result stands and only the handoff is re-cleared.
          if lease["state"] == "revoked"
            handoff.clear(lease_id)
            return :revoked
          end

          cleanup(lease, profile, handoff)
        end

        # --- reconcile -----------------------------------------------------

        # Resolves interrupted issue/revoke cycles and expired
        # assignments in the SAME store: revoke-pending and past-deadline
        # leases are revocation-retried, leftover handoff files are
        # cleared, and the report is explicit about what stays unknown.
        # Assignments themselves are not reconstructed here.
        def reconcile
          results = []
          @store.all.each do |lease|
            profile = profile_for(lease["profile"])
            handoff = CredentialHandoff.new(@credentials_dir, recipient: lease["principal"])
            outcome =
              if lease["state"] == "revoked"
                handoff.clear(lease["id"])
                :already_revoked
              elsif lease["state"] == "revoke-pending" || !@store.live?(lease)
                cleanup(lease, profile, handoff)
              else
                :live
              end
            results << {"lease" => lease["id"], "state" => lease["state"], "reconciled" => outcome.to_s}
          end
          results
        end

        private

        # Revocation hands the provider the ISSUED secret from the
        # ephemeral handoff when the file still exists — GitHub's
        # installation-token endpoint revokes the token that
        # authenticates the request, so the token VALUE is required
        # there; id-revoking providers ignore it.
        def cleanup(lease, profile, handoff)
          provider = Providers.resolve(profile["provider"])
          credential = handoff.path(lease["id"])
          token = File.file?(credential) ? File.read(credential) : nil
          begin
            outcome = provider.revoke(profile: profile, token_ref: lease["token_ref"],
              token: token)
          rescue Providers::TransientError, Providers::OutcomeUnknownError => e
            @store.update(lease["id"]) { |record| record["state"] = "revoke-pending" }
            return :"revoke-pending (#{e.class})"
          end

          handoff.clear(lease["id"])
          @store.update(lease["id"]) do |record|
            record["state"] = "revoked"
            record["cleanup"] = {"result" => outcome.to_s, "at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")}
          end
          outcome
        end

        def profile_for(name)
          profile = @config.dig("profiles", name)
          raise Refusal.new("unknown auth profile '#{name}'") if profile.nil?

          profile
        end

        def public_view(lease)
          lease.reject { |key, _| key == "token_ref" }
            .merge("live" => @store.live?(lease))
        end

        def load_config
          content = Molecules::GrantResolver.read_verified(@authorization_path)
          document = content ? YAML.safe_load(content, permitted_classes: [Date], aliases: true) : {}
          ProfileSchema.normalize(document.is_a?(Hash) ? document : {})
        end
      end

      class Refusal < Error; end
    end
  end
end

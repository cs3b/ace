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
        # The child environment is an ALLOWLIST: only non-secret runtime
        # variables the child needs to execute, plus the leased
        # credential reference — the issuer's whole environment (and
        # any ambient credential override like GH_TOKEN in it) is never
        # inherited past the lease's own scope.
        CHILD_ENV_ALLOWLIST = %w[PATH HOME TMPDIR LANG LC_ALL TZ USER LOGNAME SHELL].freeze

        attr_reader :config, :store

        # @param authorization_path [String] trusted document location
        # @param runner [Proc] argv runner for the exec'd child
        def initialize(authorization_path: nil, runner: nil, principal: nil)
          @authorization_path = authorization_path || Ace::Lab.authorization_path
          # The default runner spawns the child through `env -i` so the
          # allowlisted child environment is EXACTLY what the child
          # sees — Ruby's system(env, ...) MERGES the hash into the
          # inherited environment, which would leak every ambient
          # credential override past the profile's scope. The real exit
          # status is preserved (nil-status spawn failure degrades to
          # 127, signals to 128+signum).
          @runner = runner || lambda { |argv, env|
            spawned = ["env", "-i", *env.map { |key, value| "#{key}=#{value}" }, *argv]
            system(*spawned)
            status = $?
            if status.nil?
              127
            elsif status.success?
              0
            else
              status.exitstatus || 128 + status.termsig.to_i
            end
          }
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
          unless ttl.is_a?(Integer) && ttl.positive?
            raise Refusal.new("ttl must be a positive number of minutes, got #{ttl.inspect}; refused")
          end
          if ttl > profile["max_ttl_minutes"]
            raise Refusal.new("ttl #{ttl}m exceeds the profile limit #{profile['max_ttl_minutes']}m; " \
              "refused, not clipped")
          end

          # The granted scope is computed BEFORE the live-lease lookup
          # so a retry is judged against what THIS request asked for.
          requested = Array(repos).map(&:to_s).sort
          repos = (profile["repos"].empty? ? requested : profile["repos"] & requested)
          if repos.empty?
            raise Refusal.new("the granted repository scope would be empty (profile " \
              "'#{profile_name}' repos: [#{profile["repos"].join(", ")}]; requested: " \
              "[#{requested.join(", ")}]); an empty repository grant means ALL " \
              "repositories provider-side — refused before issuing")
          end

          # The provider is resolved and capability-verified BEFORE any
          # record exists: a failed resolve or an expiry the provider
          # cannot back must not orphan a lease record.
          issue = Providers.resolve(profile["provider"])
          # A provider unable to back the profile's NATIVE expiry must
          # be visible BEFORE handoff, never hidden behind use_until.
          if profile["expiry_mode"] == "provider" &&
            issue.capabilities.fetch("expiry_mode") != "provider"
            raise Refusal.new("provider '#{profile["provider"]}' cannot guarantee the " \
              "profile's native expiry")
          end

          # One request flow at a time per correlation: find_live +
          # create + issue are atomic against a concurrent identical
          # request — the second waits, then returns the first's LIVE
          # lease instead of minting a second token.
          @store.with_correlation_lock(task: task, assignment: assignment,
            profile: profile_name, role: role) do
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
              next existing.merge("state_detail" => "live")
            end

            # An unresolved predecessor (issue lost to a crash while
            # PREPARING, or a lost response after possible remote
            # issuance) is settled DETERMINISTICALLY before any re-mint
            # — the remote token, if it exists, is revoked through the
            # record's deterministic reference. A settlement that
            # cannot be confirmed refuses the retry: a local pending
            # record is never proof the remote token is gone.
            settle_unresolved(task: task, assignment: assignment,
              profile: profile_name, role: role, principal: principal)

            lease_id = "lease-#{SecureRandom.hex(8)}"
            # Duck-typed capability: bundled providers always implement
            # token_ref_for; an external plugin without one simply has no
            # deterministic identity (unsettled issues then wait for
            # reconcile/native expiry instead).
            token_ref = issue.token_ref_for(lease_id: lease_id) if issue.respond_to?(:token_ref_for)
            lease = @store.create(id: lease_id,
              profile: profile_name, role: role, principal: principal,
              task: task, assignment: assignment, repos: repos,
              use_until: Time.at(Time.now.utc + ttl * 60).strftime("%Y-%m-%dT%H:%M:%SZ"),
              provider_expiry: nil,
              token_ref: token_ref)

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
              record["token_ref"] = granted["token_ref"] || record["token_ref"]
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
            # ISSUED means a COMPLETE, usable grant: credential
            # delivered, deadlines recorded, cleanup due. Until this
            # write the record is PREPARING — never delivered, never
            # returned as live, and recoverable after a hard death.
            @store.update(lease["id"]) do |record|
              record["state"] = "issued"
              record["cleanup_due_at"] = record["use_until"]
            end

            # The REQUEST return keeps token_ref (the holder just minted
            # the lease and may need the reference for reconcile), while
            # status() strips it to the public view — intentional
            # reference-vs-value distinction, never the token itself.
            @store.load(lease["id"]).merge("state_detail" => "issued")
          end
        end

        # --- status --------------------------------------------------------

        def status(lease_id: nil)
          return public_view(@store.load(lease_id)) if lease_id

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
            credential = handoff.path(lease_id)
            # A live lease without its delivered credential is not
            # executable — degrade with a clear reason instead of an
            # unrescued ENOENT from the child env merge.
            unless File.file?(credential)
              raise Refusal.new("lease '#{lease_id}' has no delivered credential at " \
                "'#{credential}'; run reconcile or request a fresh lease")
            end

            # ALLOWLISTED child environment: required non-secret
            # runtime variables plus the leased credential reference —
            # nothing else is inherited, so an ambient credential
            # override (GH_TOKEN, GIT_* auth, ...) can never bypass the
            # profile's scope.
            child_env = CHILD_ENV_ALLOWLIST.each_with_object({}) do |key, allowlist|
              allowlist[key] = ENV[key] if ENV[key]
            end
            child_env.merge!(env,
              "ACE_LAB_LEASE" => lease_id,
              "ACE_LAB_CREDENTIAL_FILE" => credential)
            if profile["provider"] == "env"
              begin
                child_env.merge!(JSON.parse(File.read(credential)))
              rescue JSON::ParserError, Errno::ENOENT => e
                raise Refusal.new("lease '#{lease_id}' credential could not be read as " \
                  "an env handoff (#{e.class.name}); reconcile or request a fresh lease")
              end
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
        #
        # `force:` is the explicit OPERATOR decision shape for a lease
        # stuck revoke-pending with its credential already gone (the
        # token cannot be presented to the provider anymore): it closes
        # the record as forced-terminal with the unconfirmed outcome
        # recorded — never a claimed revocation.
        def revoke(lease_id:, force: false)
          lease = @store.load(lease_id)
          handoff = CredentialHandoff.new(@credentials_dir, recipient: lease["principal"])

          # An already-revoked lease never re-dials the provider: the
          # idempotent result stands and only the handoff is re-cleared.
          if lease["state"] == "revoked"
            handoff.clear(lease_id)
            return :revoked
          end

          if force && lease["state"] == "revoke-pending" &&
            !File.file?(handoff.path(lease_id))
            @store.update(lease_id) do |record|
              record["state"] = "revoked"
              record["cleanup"] = {"result" => "forced-terminal",
                "note" => "credential absent; provider outcome unconfirmed — operator-forced close",
                "at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")}
            end
            return :forced_terminal
          end

          # A removed profile cannot resolve its provider: the lease
          # stays a visible revoke-pending open item instead of
          # crashing the caller.
          begin
            profile = profile_for(lease["profile"])
          rescue Refusal
            @store.update(lease_id) { |record| record["state"] = "revoke-pending" }
            return :"revoke-pending (profile '#{lease["profile"]}' removed from the authorization document)"
          end

          cleanup(lease, profile, handoff)
        end

        # --- reconcile -----------------------------------------------------

        # Resolves interrupted issue/revoke cycles and expired
        # assignments in the SAME store: preparing (dead mid-issue),
        # revoke-pending and past-deadline leases are
        # revocation-retried, leftover handoff files are cleared, a
        # corrupt record is a VISIBLE recovery error, and the report is
        # explicit about what stays unknown. Assignments themselves are
        # not reconstructed here.
        def reconcile
          results = []
          @store.all.each do |lease|
            handoff = CredentialHandoff.new(@credentials_dir, recipient: lease["principal"])
            outcome =
              if lease["corrupt"]
                # An unparseable record is a visible recovery problem —
                # the remote token may still be live; it must never
                # silently vanish from the inventory.
                record = File.basename(lease["_path"].to_s)
                :"corrupt (unparseable lease record #{record}; manual recovery required — the remote token may still be live)"
              elsif lease["state"] == "revoked"
                handoff.clear(lease["id"])
                :already_revoked
              else
                begin
                  profile = profile_for(lease["profile"])
                rescue Refusal
                  # A removed profile cannot resolve its provider: keep
                  # the lease a visible revoke-pending open item (the
                  # operator closes it with `revoke --force` when the
                  # credential is gone) instead of crashing reconcile.
                  @store.update(lease["id"]) { |record| record["state"] = "revoke-pending" }
                  :"revoke-pending (profile '#{lease["profile"]}' removed)"
                else
                  if lease["state"] == "preparing" || lease["state"] == "revoke-pending" ||
                    !@store.live?(lease)
                    cleanup(lease, profile, handoff)
                  else
                    :live
                  end
                end
              end
            results << {"lease" => lease["id"], "state" => lease["state"], "reconciled" => outcome.to_s}
          end
          results
        end

        private

        # R5: a previous issue with an UNRESOLVED remote outcome (lost
        # response after possible issuance, or a hard death while
        # PREPARING) is settled before any re-mint. Settlement runs the
        # normal cleanup — the record's DETERMINISTIC token_ref (written
        # at creation) identifies the remote token, the handoff file
        # supplies the secret when it exists — and only a confirmed
        # :revoked/:already_invalid/:cleared lets the retry proceed. A
        # pending/unknown settlement REFUSES the retry: never a blind
        # second mint, never treating a local pending record as a
        # remote revocation.
        def settle_unresolved(task:, assignment:, profile:, role:, principal:)
          unresolved = @store.all.select do |record|
            record["task"] == task && record["assignment"] == assignment &&
              record["profile"] == profile && record["role"] == role &&
              %w[preparing revoke-pending].include?(record["state"])
          end
          return if unresolved.empty?

          record_profile = profile_for(profile)
          unresolved.each do |record|
            # An unknown ISSUE outcome (revoke-pending after a lost
            # response) without a deterministic remote identity can
            # NEVER be confirmed settled — the retry is refused until
            # reconcile or the provider's native expiry settles it. A
            # PREPARING record (issuer died mid-flight, nothing ever
            # delivered) is settled best-effort through the provider
            # below; only a confirmed outcome lets the retry proceed.
            if record["state"] == "revoke-pending" && record["token_ref"].to_s.empty?
              raise Refusal.new("a previous issue for task '#{task}' assignment '#{assignment}' " \
                "profile '#{profile}' has an unresolved remote outcome (lease '#{record["id"]}', " \
                "no deterministic remote identity); it was NOT re-minted — run reconcile, wait " \
                "for the provider's native expiry, or close it explicitly before requesting again")
            end

            handoff = CredentialHandoff.new(@credentials_dir, recipient: record["principal"] || principal)
            outcome = cleanup(record, record_profile, handoff)
            next if %i[revoked already_invalid cleared].include?(outcome)

            raise Refusal.new("a previous issue for task '#{task}' assignment '#{assignment}' " \
              "profile '#{profile}' has an unresolved remote outcome (lease '#{record["id"]}', " \
              "state #{record["state"]}); it was NOT re-minted — run reconcile, wait for the " \
              "provider's native expiry, or close it explicitly before requesting again")
          end
        end

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

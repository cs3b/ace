# frozen_string_literal: true

require "etc"
require "date"
require "json"
require "open3"
require "securerandom"
require "time"
require "yaml"
require_relative "error"
require_relative "session_runner"
require_relative "session_attachment"

module Ace
  module Lab
    module Auth
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
        CHILD_ENV_ALLOWLIST = %w[PATH HOME TMPDIR LANG LC_ALL TZ USER LOGNAME SHELL
          ACE_TOOLCHAIN GEM_HOME GEM_PATH].freeze

        attr_reader :config, :store

        # @param authorization_path [String] trusted document location
        # @param runner [Proc] argv runner for the exec'd child
        # @param principal [Proc, nil] trusted callable returning the account name
        # @param session [SessionPeer::Identity, nil] authenticated peer
        #   supplied by a trusted system entry point, never client fields
        # @param issuer_invocation [String, nil] trusted systemd issuer invocation
        def initialize(authorization_path: nil, runner: nil, principal: nil, session: nil, issuer_invocation: nil,
          supervised: false)
          raise ArgumentError, "principal must be callable" unless principal.nil? || principal.respond_to?(:call)
          @authorization_path = authorization_path || Ace::Lab.authorization_path
          @injected_runner = !runner.nil?
          @supervised = supervised == true
          if session
            raise ArgumentError, "session execution requires a root issuer" unless Process.euid.zero?
            raise ArgumentError, "session execution does not accept caller-supplied identity or runner" if principal || runner
            unless session.is_a?(SessionPeer::Identity) && session.uid.is_a?(Integer) && session.uid.positive? &&
                session.gid.is_a?(Integer) && session.gid.positive? && session.invocation_id.is_a?(String) &&
                session.invocation_id.match?(/\A[0-9a-f]{32}\z/) && session.runtime_dir.is_a?(String) &&
                session.runtime_dir.start_with?("/") && File.expand_path(session.runtime_dir) == session.runtime_dir &&
                session.main_pidfd.is_a?(IO) && !session.main_pidfd.closed? &&
                session.mount_namespace.is_a?(IO) && !session.mount_namespace.closed?
              raise ArgumentError, "session execution requires a verified systemd invocation identity"
            end
            unless issuer_invocation.is_a?(String) && issuer_invocation.match?(/\A[0-9a-f]{32}\z/)
              raise ArgumentError, "session execution requires an issuer invocation identity"
            end
            unit_match = SessionPeer::UNIT.match(session.unit.to_s)
            unless unit_match && unit_match[1] == session.role && session.runtime_dir == "/run/ace-auth-#{unit_match[2]}"
              raise ArgumentError, "session role differs from its verified unit"
            end

            attachment = SessionAttachment.new(identity: session)
            @session_attachment = attachment
            @session_runner = SessionRunner.new(uid: session.uid, cwd: session.cwd, attach: attachment,
              namespace: session.mount_namespace)
            account = Etc.getpwuid(Integer(session.uid))
            raise ArgumentError, "session account group differs" unless account.gid == session.gid
            @session_uid = account.uid
            @session_id = session.invocation_id
            @session_role = session.role
            @session_unit = session.unit
            @issuer_invocation = issuer_invocation
            @session_runtime_dir = session.runtime_dir
            @principal = -> { account.name }
          else
            raise ArgumentError, "issuer invocation requires a session" if issuer_invocation
            @principal = principal || -> { Etc.getpwuid(Process.uid).name }
          end
          # Explicit argv and unsetenv_others prevent shell interpretation
          # and inherited credentials. Preserve the real exit status.
          @runner = @session_runner || runner || lambda { |argv, env|
            system(env, [argv.first, argv.first], *argv.drop(1), unsetenv_others: true)
            status = $?
            if status.nil?
              127
            elsif status.success?
              0
            else
              status.exitstatus || 128 + status.termsig.to_i
            end
          }
          @config = load_config
          @store = LeaseStore.new(@config["leases_dir"] || DEFAULT_LEASES_DIR)
          @credentials_dir = @session_runtime_dir || @config["credentials_dir"] || DEFAULT_CREDENTIALS_DIR
        end

        # --- request -------------------------------------------------------

        # Idempotent only per the IDENTICAL live request: the
        # task/assignment/profile/role correlation AND the requested
        # scope/principal must match; a mismatched retry (e.g. a
        # narrower repo list) is refused, never silently answered with
        # the wider existing grant. The granted scope is the
        # intersection of the requested repos and the host profile, whose
        # empty repo list imposes no further restriction. A request may
        # narrow, never widen; editing the task or
        # project config grants nothing.
        def request(profile_name:, role:, task:, assignment:, repos: [],
          ttl_minutes: nil)
          arguments = {profile_name: profile_name, role: role, task: task, assignment: assignment,
                       repos: repos, ttl_minutes: ttl_minutes}
          return request_locked(**arguments) unless @session_uid

          @store.with_session_lock(unit: @session_unit, invocation: @session_id) do
            request_locked(**arguments)
          end
        end

        def request_locked(profile_name:, role:, task:, assignment:, repos:, ttl_minutes:)
          issuance_started = false
          unless [profile_name, role, task, assignment].all? { |value| value.is_a?(String) && value.valid_encoding? && !value.strip.empty? }
            raise Refusal.new("profile, role, task and assignment must be non-empty strings")
          end
          if Process.euid.zero? && !@session_uid && !@injected_runner
            raise Refusal.new("root issuance requires an authenticated non-root session identity")
          end
          profile = profile_for(profile_name)
          if @session_uid && profile["principals"].empty?
            raise Refusal.new("session auth profile '#{profile_name}' requires an explicit principal allowlist")
          end
          unless profile["roles"].include?(role)
            raise Refusal.new("role '#{role}' is not allowed by profile '#{profile_name}'")
          end
          principal = @principal.call
          subject = @session_uid ? "session:#{@session_role}" : principal
          unless profile["principals"].empty? || profile["principals"].include?(subject)
            raise Refusal.new("principal '#{subject}' is not allowed by profile '#{profile_name}'; " \
              "escalate to the host owner")
          end
          if @session_uid && !@supervised
            # Only the trusted singleton request handler opts into issuance:
            # it owns supervision through session exit, expiry and revocation.
            # Direct session-bound service callers cannot mint unattended grants.
            raise Refusal.new("session access requires revocation supervision and session-bound cleanup before issuance")
          end
          @session_attachment&.verify_session!

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
          requested = Array(repos).map(&:to_s).uniq.sort
          repos = (profile["repos"].empty? ? requested : profile["repos"] & requested).sort
          if repos.empty?
            raise Refusal.new("the granted repository scope would be empty (profile " \
              "'#{profile_name}' repos: [#{profile["repos"].join(", ")}]; requested: " \
              "[#{requested.join(", ")}]); an empty repository grant means ALL " \
              "repositories provider-side — refused before issuing")
          end

          # The provider is resolved and capability-verified BEFORE any
          # record exists: a failed resolve or an expiry the provider
          # cannot back must not orphan a lease record.
          begin
            issue = Providers.resolve(profile["provider"])
          rescue Providers::UnsupportedError => e
            raise Refusal.new("provider unavailable: #{e.message}")
          end
          # A provider unable to back the profile's NATIVE expiry must
          # be visible BEFORE handoff, never hidden behind use_until.
          capabilities = issue.capabilities if profile["expiry_mode"] == "provider"
          if profile["expiry_mode"] == "provider" &&
            (!capabilities.is_a?(Hash) || capabilities["expiry_mode"] != "provider")
            raise Refusal.new("provider '#{profile["provider"]}' cannot guarantee the " \
              "profile's native expiry")
          end

          # A privileged session must have a safe handoff destination before
          # a remote token exists. Delivery can still fail later (e.g. disk
          # full), in which case the existing revoke-pending recovery applies.
          handoff = CredentialHandoff.new(@credentials_dir, recipient: principal, owner_uid: @session_uid,
            create_root: @session_uid.nil?)
          handoff.prepare! if @session_uid

          # One request flow at a time per correlation: find_live +
          # create + issue are atomic against a concurrent identical
          # request — the second waits, then returns the first's LIVE
          # lease instead of minting a second token.
          @store.with_correlation_lock(task: task, assignment: assignment,
            profile: profile_name, role: role) do
            existing = @store.find_live(task: task, assignment: assignment,
              profile: profile_name, role: role)
            if existing && @store.live?(existing)
              if existing.key?("execution")
                raise Refusal.new("a previous command's execution is unresolved; no lease can be reused")
              end
              # Idempotency holds only for the IDENTICAL request: a live
              # lease with a different granted scope or principal is a
              # mismatched retry — refusing it never silently reuses a
              # wider grant for a narrower ask.
              same_issuer = !@session_uid || existing["issuer_invocation"] == @issuer_invocation
              unless existing["repos"] == repos && existing["principal"] == principal && session_matches?(existing) && same_issuer
                raise Refusal.new("a live lease for task '#{task}' assignment '#{assignment}' " \
                  "profile '#{profile_name}' role '#{role}' already exists with scope " \
                  "[#{existing["repos"].join(", ")}] for principal '#{existing["principal"]}'; " \
                  "revoke it first or repeat the identical request")
              end
              unless File.file?(handoff_for(existing).path(existing.fetch("id")))
                raise Refusal.new("live lease '#{existing["id"]}' has no credential handoff; revoke it before requesting a replacement")
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
              profile: profile_name, role: role)

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
              token_ref: token_ref, session_uid: @session_uid, session_id: @session_id,
              session_unit: @session_unit, issuer_invocation: @issuer_invocation)

            issuance_started = true
            begin
              granted = issue.issue(profile: profile, lease: lease)
            rescue Providers::RefusedError => e
              @store.update(lease["id"]) do |record|
                record["state"] = "revoked"
                record["cleanup"] = {"result" => "not-issued", "at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")}
              end
              issuance_started = false
              raise Refusal.new("provider refused: #{e.message}")
            rescue Providers::TransientError, Providers::OutcomeUnknownError => e
              @store.update(lease["id"]) { |record| record["state"] = "revoke-pending" }
              raise Error.new("issuance failed with unknown outcome: #{e.message}; " \
                "reconcile retries cleanup; the outcome may remain unresolved")
            end

            expiry = granted["provider_expiry"]&.to_s
            expiry_valid = begin
              if expiry
                parsed_expiry = Time.parse(expiry)
                expiry = parsed_expiry.utc.iso8601
                parsed_expiry > Time.now.utc
              else
                profile["expiry_mode"] != "provider"
              end
            rescue ArgumentError, TypeError
              false
            end
            @store.update(lease["id"]) do |record|
              record["token_ref"] = granted["token_ref"] || record["token_ref"]
              record["provider_expiry"] = expiry_valid ? expiry : nil
              record["via"] = granted["via"]
            end
            # The secret goes ONLY to the ephemeral handoff; the returned
            # lease record carries references, never values. A failed
            # delivery is never a live grant: the token may exist
            # provider-side, so the record becomes revoke-pending for
            # reconcile to finish — an interrupted handoff must not be
            # reusable by a retry.
            begin
              @session_attachment&.verify_session!
              handoff.deliver(lease["id"], granted["token"])
              @session_attachment&.verify_session!
            rescue StandardError => e
              @store.update(lease["id"]) { |record| record["state"] = "revoke-pending" }
              raise Error.new("credential handoff failed: #{e.message}; " \
                "reconcile retries cleanup; the outcome may remain unresolved")
            end
            unless expiry_valid
              @store.update(lease["id"]) { |record| record["state"] = "revoke-pending" }
              raise Error, "provider returned a missing, invalid or expired expiry; reconcile must revoke the grant"
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
        rescue StandardError
          # A failed request may already have a remote grant even though no
          # lease was returned to the handler. Stop the singleton so its
          # canonical recovery handles the preparing/revoke-pending record.
          if @session_uid && @supervised && issuance_started
            raise UnresolvedIssuanceError, "session issuance requires issuer recovery"
          end
          raise
        end

        private :request_locked

        # --- status --------------------------------------------------------

        def status(lease_id: nil)
          if lease_id
            lease = @store.load(lease_id)
            if @session_uid && !(session_matches?(lease) && issuer_matches?(lease))
              raise Refusal.new("lease belongs to a different session or issuer")
            end
            return public_view(lease)
          end

          records = @store.all
          records = records.select { |lease| session_matches?(lease) && issuer_matches?(lease) } if @session_uid
          records.map { |lease| public_view(lease) }
        end

        # --- exec ----------------------------------------------------------

        # Runs the child under the lease: the child receives the
        # credential REFERENCE (ACE_LAB_CREDENTIAL_FILE / the profile's
        # env names), never a value in argv. The process exit code is
        # preserved; on process success a cleanup failure is itself an
        # error; the report carries both outcomes. One exec at a time
        # per lease; a completed attempt triggers cleanup, making the lease
        # single-use once revocation is confirmed.
        def exec(lease_id:, argv:, env: {})
          unless argv.is_a?(Array) && !argv.empty? && argv.all? { |arg| arg.is_a?(String) && !arg.include?("\0") } && !argv.first.empty?
            raise Refusal.new("execution requires a valid command")
          end
          unless env.is_a?(Hash) && env.all? { |key, value|
            CHILD_ENV_ALLOWLIST.include?(key) && value.is_a?(String) && !value.include?("\0")
          }
            raise Refusal.new("execution environment contains invalid or disallowed variables")
          end
          lease = @store.load(lease_id)
          unless lease["principal"] == @principal.call && session_matches?(lease)
            raise Refusal.new("lease '#{lease_id}' belongs to a different principal")
          end
          unless issuer_matches?(lease)
            raise Refusal.new("lease '#{lease_id}' belongs to a different issuer invocation")
          end
          if Process.euid.zero? && !@session_uid && !@injected_runner
            raise Refusal.new("root execution requires an authenticated non-root session identity")
          end
          raise Refusal.new("lease '#{lease_id}' is not live") unless @store.live?(lease)

          @store.with_exec_lock(lease_id) do
            lease = @store.load(lease_id)
            unless lease["principal"] == @principal.call && session_matches?(lease) && issuer_matches?(lease) && @store.live?(lease) && !lease.key?("execution")
              raise Refusal.new("lease '#{lease_id}' is no longer live for this principal")
            end
            profile = profile_for(lease["profile"])
            handoff = handoff_for(lease)
            credential = handoff.path(lease_id)
            # A live lease without its delivered credential is not
            # executable — degrade with a clear reason instead of an
            # unrescued ENOENT from the child env merge.
            unless File.file?(credential)
              raise Refusal.new("lease '#{lease_id}' has no delivered credential at " \
                "'#{credential}'; revoke the lease before requesting a replacement")
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
                values = JSON.parse(File.read(credential))
                unless values.is_a?(Hash) && values.keys.sort == profile.fetch("env_names").sort &&
                    values.values.all? { |value| value.is_a?(String) && !value.empty? && !value.include?("\0") }
                  raise TypeError, "invalid env handoff"
                end
                child_env.merge!(values)
              rescue JSON::ParserError, SystemCallError, IOError, TypeError => e
                raise Refusal.new("lease '#{lease_id}' credential could not be read as " \
                  "an env handoff (#{e.class.name}); reconcile or request a fresh lease")
              end
            end

            # A process lock disappears on SIGKILL. Persist the in-flight
            # execution before starting a child so recovery cannot mistake
            # a dead issuer for proof that its descendants have stopped.
            @store.update(lease["id"]) do |record|
              unless record["principal"] == @principal.call && session_matches?(record) && issuer_matches?(record) && @store.live?(record) && !record.key?("execution")
                raise Refusal.new("lease '#{lease_id}' is no longer live for this principal")
              end
              record["execution"] = "in-progress"
            end
            uncontained = false
            begin
              provider = Providers.resolve(profile["provider"])
              exit_code = if provider.respond_to?(:with_exec_environment)
                provider.with_exec_environment(profile: profile, credential: credential) do |provider_env|
                  run_leased_command(argv, preserve_installed_runtime!(child_env.merge(provider_env)), lease["id"])
                end
              else
                run_leased_command(argv, preserve_installed_runtime!(child_env), lease["id"])
              end
              unless exit_code.is_a?(Integer) && exit_code.between?(0, 255)
                raise Error, "execution returned an invalid exit status"
              end
            rescue UncontainedSessionError
              uncontained = true
              raise
            rescue Providers::RefusedError, Providers::UnsupportedError => e
              raise Refusal.new("provider execution refused: #{e.message}")
            rescue SystemCallError, IOError, ArgumentError => e
              raise Error, "execution could not start (#{e.class})"
            ensure
              # A failed spawn, provider error or interrupted caller must not
              # leave an issued credential live merely because no exit code
              # was returned. Reconciliation retains unresolved revocations.
              primary_error = $!
              begin
                if uncontained
                  @store.update(lease["id"]) do |record|
                    record["state"] = "revoke-pending"
                    record["containment"] = "unconfirmed"
                    record["execution"] = "unconfirmed"
                  end
                  # Revoking the remote credential limits exposure, but does
                  # not establish that the command's processes have stopped.
                  cleanup = cleanup(lease, profile, handoff, allow_executing: true)
                else
                  @store.update(lease["id"]) do |record|
                    record.delete("execution")
                    record.delete("execution_cgroup")
                    record["state"] = "revoke-pending" unless record["state"] == "revoked"
                  end
                  cleanup = cleanup(lease, profile, handoff)
                end
              rescue Error, SystemCallError, IOError => error
                if primary_error.is_a?(UncontainedSessionError)
                  raise UncontainedSessionError.new(primary_error.message), cause: error
                end
                raise primary_error, cause: nil if primary_error
                raise Error, "credential cleanup failed (#{error.class})"
              end
            end
            if exit_code.zero? && !%i[revoked already_invalid cleared not-issued].include?(cleanup)
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
          unless %w[task assignment profile role].all? { |field| lease[field].is_a?(String) && !lease[field].empty? }
            raise Error, "lease correlation is incomplete; host recovery is required"
          end
          @store.with_correlation_lock(task: lease.fetch("task"), assignment: lease.fetch("assignment"),
            profile: lease.fetch("profile"), role: lease.fetch("role")) do
            revoke_locked(lease_id: lease_id, force: force)
          end
        end

        def revoke_locked(lease_id:, force:)
          lease = @store.load(lease_id)
          principal = @principal.call
          operator = @session_uid.nil? && Process.uid.zero? && principal == "root"
          unless (lease["principal"] == principal && session_matches?(lease) && issuer_matches?(lease)) || operator
            raise Refusal.new("lease '#{lease_id}' belongs to a different principal")
          end
          if force && !operator
            raise Refusal.new("forced terminal revocation requires the root operator")
          end
          handoff = handoff_for(lease)

          if force && lease.key?("execution")
            raise Refusal.new("cannot force-close a lease while command execution is unresolved")
          end

          # An already-revoked lease never re-dials the provider: the
          # idempotent result stands and only the handoff is re-cleared.
          if lease["state"] == "revoked"
            handoff.clear(lease_id)
            return :forced_terminal if lease.dig("cleanup", "result") == "forced-terminal"
            return :revoked if confirmed_revocation?(lease)
            raise Error, "lease '#{lease_id}' has an unconfirmed terminal cleanup outcome"
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
            # Keep the handoff while remote revocation is unresolved:
            # token-value providers need it if the profile is restored.
            @store.update(lease_id) { |record| record["state"] = "revoke-pending" }
            return :"revoke-pending (profile '#{lease["profile"]}' removed from the authorization document)"
          end

          # Explicit revocation is allowed during execution to cut remote
          # access immediately; the execution marker still prevents reuse.
          cleanup(lease, profile, handoff, allow_executing: true)
        end
        private :revoke_locked

        # --- reconcile -----------------------------------------------------

        # Invoked before accepting new issuer connections after host startup.
        # The exclusive lifecycle lock excludes live issuers; no separate
        # recovery registry is needed because the canonical lease records
        # already carry their issuer invocation IDs.
        def recover_issuers
          unless Process.uid.zero? && Process.euid.zero? && @session_uid.nil? && @principal.call == "root"
            raise Refusal.new("issuer recovery requires the root operator")
          end
          @store.with_issuer_lifecycle_lock(exclusive: true) do
            records = @store.all
            problems = records.any? { |record| record["corrupt"] }
            invocations = records.filter_map { |record| record["issuer_invocation"] unless record["corrupt"] }.uniq
            results = invocations.flat_map do |invocation|
              revoke_issuer(invocation: invocation)
            rescue Error, SystemCallError
              problems = true
              []
            end
            raise Error, "startup issuer recovery has unresolved leases" if problems
            results
          end
        end

        # Root-owned issuer cleanup can be called for the exact systemd
        # invocation after its worker has exited or its service stopped.
        # Corrupt records cannot be attributed safely and therefore block a
        # clean result instead of disappearing from the recovery inventory.
        def revoke_issuer(invocation:)
          unless Process.uid.zero? && Process.euid.zero? && @session_uid.nil? && @principal.call == "root"
            raise Refusal.new("issuer recovery requires the root operator")
          end
          unless invocation.is_a?(String) && invocation.match?(/\A[0-9a-f]{32}\z/)
            raise Refusal.new("issuer recovery requires an exact invocation identity")
          end
          revoke_owned_records(invocation: invocation)
        end

        # The launch owner calls this after confirming whole-unit containment.
        # A queued request rechecks its dead session inside this same lock, so
        # no late grant can appear after the cleanup inventory was inspected.
        def revoke_session(issuer_invocation:, unit:, invocation:)
          unless Process.uid.zero? && Process.euid.zero? && @session_uid.nil? && @principal.call == "root"
            raise Refusal.new("session cleanup requires the root operator")
          end
          unless issuer_invocation.is_a?(String) && issuer_invocation.match?(/\A[0-9a-f]{32}\z/) && issuer_invocation != "0" * 32
            raise Refusal.new("session cleanup requires the issuer invocation")
          end
          @store.with_issuer_lifecycle_lock(exclusive: false) do
            @store.with_session_lock(unit: unit, invocation: invocation) do
              revoke_owned_records(invocation: issuer_invocation, session_unit: unit, session_id: invocation)
            end
          end
        end

        def revoke_owned_records(invocation:, session_unit: nil, session_id: nil)
          matches = ->(record) { record["issuer_invocation"] == invocation &&
            (!session_unit || record["session_unit"] == session_unit && record["session_id"] == session_id) }
          records = @store.all
          problems = records.select { |record| record["corrupt"] }.map { |record| record["id"].to_s }
          results = records.select { |record| !record["corrupt"] && matches.call(record) }.filter_map do |record|
            begin
              outcome = @store.with_exec_lock(record.fetch("id")) do
                current = @store.load(record.fetch("id"))
                unless current["id"] == record["id"] && matches.call(current)
                  raise Error, "issuer lease identity changed during recovery"
                end
                containment_error = nil
                begin
                  recover_recorded_command!(current) if current.key?("execution")
                rescue Error, Ace::Runtime::Error, SystemCallError, IOError => e
                  containment_error = e
                end
                revoke(lease_id: record.fetch("id"))
                raise containment_error if containment_error
                after = @store.load(record.fetch("id"))
                raise Error, "issuer command execution is unresolved" if after.key?("execution")
                unless after["state"] == "revoked" && %w[revoked already_invalid cleared not-issued].include?(after.dig("cleanup", "result"))
                  raise Error, "issuer lease revocation is unconfirmed"
                end
                after.dig("cleanup", "result")
              end
              {"lease" => record.fetch("id"), "cleanup" => outcome.to_s}
            rescue StandardError
              problems << record["id"].to_s
              nil
            end
          end
          raise Error, "issuer recovery could not inspect or clean leases: #{problems.join(', ')}" unless problems.empty?
          results
        end

        private :revoke_owned_records

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
            begin
              if lease["corrupt"]
                record = File.basename(lease["_path"].to_s)
                results << {"lease" => lease["id"], "state" => lease["state"], "reconciled" =>
                  "corrupt (unreadable lease record #{record}; manual recovery required — the remote token may still be live)"}
              else
                @store.with_correlation_lock(task: lease.fetch("task"), assignment: lease.fetch("assignment"),
                  profile: lease.fetch("profile"), role: lease.fetch("role")) do
                  lease = @store.load(lease.fetch("id"))
                  results << reconcile_locked(lease)
                end
              end
            rescue Error, SystemCallError, IOError, KeyError, ArgumentError => e
              results << {"lease" => lease["id"], "state" => lease["state"],
                "reconciled" => "reconcile-failed (#{e.class}; manual recovery required)"}
            end
          end
          results
        end

        private

        def recover_recorded_command!(lease)
          path = lease["execution_cgroup"]
          unit = lease["session_unit"]
          session_id = lease["session_id"]
          unless SessionAttachment.command_cgroup_path?(path, unit) && session_id.is_a?(String) && session_id.match?(/\A[0-9a-f]{32}\z/)
            raise Error, "unresolved command has no verified cgroup identity"
          end
          SessionAttachment.recover_command!(path: path, unit: unit, invocation_id: session_id)
          @store.update(lease.fetch("id")) do |record|
            unless record["execution_cgroup"] == path && record["session_unit"] == unit && record["session_id"] == session_id &&
                record["issuer_invocation"] == lease["issuer_invocation"] && record.key?("execution")
              raise Error, "command recovery identity changed"
            end
            record.delete("execution")
            record.delete("execution_cgroup")
            record.delete("containment")
            record["state"] = "revoke-pending" unless record["state"] == "revoked"
          end
        end

        def run_leased_command(argv, environment, lease_id)
          return @runner.call(argv, environment) unless @session_runner

          before_start = lambda do |path|
            unless SessionAttachment.command_cgroup_path?(path, @session_unit)
              raise Error, "command cgroup identity is invalid"
            end
            @store.update(lease_id) do |record|
              unless record["execution"] == "in-progress" && record["session_unit"] == @session_unit &&
                  record["session_id"] == @session_id
                raise Error, "command execution identity changed before launch"
              end
              record["execution_cgroup"] = path
            end
          end
          deadline = begin
            Time.iso8601(@store.load(lease_id).fetch("use_until"))
          rescue ArgumentError, TypeError, KeyError
            raise Error, "lease execution deadline is invalid"
          end
          @session_runner.call(argv, environment, before_start: before_start, deadline: deadline)
        end

        def reconcile_locked(lease)
          if lease.key?("execution")
            expired = [lease["use_until"], lease["provider_expiry"]].compact.any? { |deadline| Time.parse(deadline) <= Time.now }
            if lease["state"] != "revoked" && (lease["state"] == "revoke-pending" || expired)
              profile = profile_for(lease["profile"])
              cleanup(lease, profile, handoff_for(lease), allow_executing: true)
            end
            return {"lease" => lease["id"], "state" => lease["state"],
              "reconciled" => "revoke-pending (command execution unresolved)"}
          end
          handoff = handoff_for(lease)
          outcome = if lease["state"] == "revoked"
            handoff.clear(lease["id"])
            if lease.dig("cleanup", "result") == "forced-terminal"
              :forced_terminal
            elsif confirmed_revocation?(lease)
              :already_revoked
            else
              raise Error, "terminal cleanup outcome is unconfirmed"
            end
          else
            begin
              profile = profile_for(lease["profile"])
            rescue Refusal
              @store.update(lease["id"]) { |record| record["state"] = "revoke-pending" }
              :"revoke-pending (profile '#{lease["profile"]}' removed)"
            else
              if lease["state"] == "preparing" || lease["state"] == "revoke-pending" || !@store.live?(lease)
                cleanup(lease, profile, handoff)
              elsif !File.file?(handoff.path(lease.fetch("id")))
                :"live (credential handoff missing; revoke required)"
              else
                :live
              end
            end
          end
          {"lease" => lease["id"], "state" => lease["state"], "reconciled" => outcome.to_s}
        end

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
        def settle_unresolved(task:, assignment:, profile:, role:)
          records = @store.all
          if records.any? { |record| record["corrupt"] ||
              %w[task assignment profile role].any? { |field| !record[field].is_a?(String) || record[field].empty? } ||
              !%w[preparing issued revoke-pending revoked].include?(record["state"]) }
            raise Refusal.new("a lease record is corrupt or incomplete and may represent an unresolved grant; " \
              "no new lease can be issued until the host owner resolves it")
          end
          matching = records.select do |record|
            record["task"] == task && record["assignment"] == assignment &&
              record["profile"] == profile && record["role"] == role
          end
          matching.each do |record|
            begin
              @store.with_exec_lock(record.fetch("id")) do
                current = @store.load(record.fetch("id"))
                if current.key?("execution") || current["containment"] == "unconfirmed"
                  raise Refusal.new("a previous command's execution or containment is unconfirmed; no new lease can be issued")
                end
                expired_issue = current["state"] == "issued" && !@store.live?(current)
                next unless expired_issue || %w[preparing revoke-pending].include?(current["state"])

                # Keep the execution lock through settlement. A record may
                # have changed since the inventory snapshot was read.
                if current["state"] == "revoke-pending" && current["token_ref"].to_s.empty?
                  raise Refusal.new("a previous issue for task '#{task}' assignment '#{assignment}' " \
                    "profile '#{profile}' has an unresolved remote outcome (lease '#{current["id"]}', " \
                    "no deterministic remote identity); it was NOT re-minted — run reconcile, wait " \
                    "for the provider's native expiry, or close it explicitly before requesting again")
                end
                record_profile = profile_for(profile)
                handoff = handoff_for(current)
                outcome = cleanup(current, record_profile, handoff)
                next if %i[revoked already_invalid cleared].include?(outcome)

                raise Refusal.new("a previous issue for task '#{task}' assignment '#{assignment}' " \
                  "profile '#{profile}' has an unresolved remote outcome (lease '#{current["id"]}', " \
                  "state #{current["state"]}); it was NOT re-minted — run reconcile, wait for the " \
                  "provider's native expiry, or close it explicitly before requesting again")
              end
            rescue Refusal
              raise
            rescue Error
              raise Refusal.new("a previous lease could not be settled; inspect its execution, store and provider state")
            end
          end
        end

        # Revocation hands the provider the ISSUED secret from the
        # ephemeral handoff when the file still exists — GitHub's
        # installation-token endpoint revokes the token that
        # authenticates the request, so the token VALUE is required
        # there; id-revoking providers ignore it.
        def handoff_for(lease)
          unit = lease["session_unit"]
          unless unit
            return CredentialHandoff.new(@credentials_dir, recipient: lease["principal"])
          end
          match = SessionPeer::UNIT.match(unit)
          raise Error, "invalid session unit in lease" unless match
          handoff = CredentialHandoff.new("/run/ace-auth-#{match[2]}", recipient: lease["principal"])
          handoff.validate_root_directory!
          handoff
        end

        def cleanup(lease, profile, handoff, allow_executing: false)
          current = @store.load(lease["id"])
          if current["containment"] == "unconfirmed" && !allow_executing
            return :"revoke-pending (command containment unconfirmed)"
          end
          return :"revoke-pending (command execution unresolved)" if current.key?("execution") && !allow_executing
          # A concurrent revoke may have already confirmed cleanup while an
          # exec was running. Never retry or downgrade that settled record.
          return :revoked if confirmed_revocation?(current)

          credential = handoff.path(lease["id"])
          begin
            token = File.file?(credential) ? File.read(credential) : nil
          rescue SystemCallError, IOError => e
            return mark_cleanup_pending(lease["id"], e.class.to_s)
          end
          begin
            provider = Providers.resolve(profile["provider"])
            outcome = provider.revoke(profile: profile, token_ref: lease["token_ref"],
              token: token)
          rescue Providers::TransientError, Providers::OutcomeUnknownError, Providers::RefusedError, Providers::UnsupportedError => e
            return mark_cleanup_pending(lease["id"], e.class.to_s)
          end

          # An interrupted issue may still be executing at the forge after
          # our HTTP client timed out or died. A 404 before that request
          # commits is not proof that its token can never appear later.
          if outcome == :already_invalid && token.nil? && %w[preparing revoke-pending].include?(current["state"])
            return mark_cleanup_pending(lease["id"], "issue outcome remains unknown")
          end

          handoff.clear(lease["id"])
          @store.update(lease["id"]) do |record|
            record["state"] = "revoked"
            record["cleanup"] = {"result" => outcome.to_s, "at" => Time.now.utc.strftime("%Y-%m-%dT%H:%M:%SZ")}
          end
          outcome
        end

        def confirmed_revocation?(record)
          record["state"] == "revoked" && %w[revoked already_invalid cleared not-issued].include?(record.dig("cleanup", "result"))
        end

        def mark_cleanup_pending(id, reason)
          confirmed = false
          @store.update(id) do |record|
            confirmed = confirmed_revocation?(record)
            # A forced terminal result is an operator decision, not proof of
            # remote revocation; preserve it but never report it confirmed.
            record["state"] = "revoke-pending" unless record["state"] == "revoked"
          end
          confirmed ? :revoked : :"revoke-pending (#{reason})"
        end

        def profile_for(name)
          profile = @config.dig("profiles", name)
          raise Refusal.new("unknown auth profile '#{name}'") if profile.nil?

          profile
        end

        def session_matches?(lease)
          if @session_uid
            lease["session_uid"] == @session_uid && lease["session_id"] == @session_id
          else
            !lease.key?("session_uid")
          end
        end

        def issuer_matches?(lease)
          !@session_uid || lease["issuer_invocation"] == @issuer_invocation
        end

        # No caller or provider projection may silently replace the selected
        # installed runtime. An absent path stays absent.
        def preserve_installed_runtime!(environment)
          if ENV["ACE_TOOLCHAIN"] == "installed"
            %w[ACE_TOOLCHAIN GEM_HOME GEM_PATH PATH].each do |key|
              ENV.key?(key) ? environment[key] = ENV[key] : environment.delete(key)
            end
          end
          environment
        end

        def public_view(lease)
          lease.reject { |key, _| key == "token_ref" || key.start_with?("_") }
            .merge("live" => @store.live?(lease))
        end

        def load_config
          content = Molecules::GrantResolver.read_verified(@authorization_path)
          document = content ? YAML.safe_load(content, permitted_classes: [Date], aliases: true) : {}
          ProfileSchema.normalize(document.is_a?(Hash) ? document : {})
        end
      end

    end
  end
end

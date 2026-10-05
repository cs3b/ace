# frozen_string_literal: true

require "digest"
require "json"
require "time"
require "securerandom"
require "openssl"
require "ace/hitl/contract"

module Ace
  module Herdr
    module Organisms
      # Durable event inbox. All transitions for one event are serialized by
      # DeliveryRecordStore; a saved submission intent is never replayed.
      class Inbox
        class IdentityDriftError < ValidationError; end

        EVENT = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        TARGET_IDENTITY = %w[session pane terminal_id agent thread thread_kind].freeze
        THREAD_ID = /\A[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\z/
        PI_PATH = /_([0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})\.jsonl\z/
        # Single validator for Pi queue event ids, shared by enqueue and
        # delivery observation so the two sites can never disagree again.
        PI_EVENT_ID = /\A(?:inb|wnk)-[a-z0-9-]{8,64}\z/
        # Agent statuses herdr reports (pane observations use busy; agent wait
        # also names working/blocked). Anything else — including an explicit
        # "unknown" — is undetermined and stays a retryable pre-submission
        # rejection.
        AGENT_STATUSES = %w[idle busy working blocked done].freeze
        WAKE_STATUSES = %w[idle done].freeze

        # One configured verifier construction for the Herdr CLI and signed
        # receipt consumers. Configuration remains supervisor-owned.
        def self.from_config(config: Ace::Herdr.config, root: Dir.pwd,
          executor: Molecules::HerdrExecutor.new, native: Molecules::NativeQueueExecutor.new)
          path = config["inbox_receipt_public_key"]
          key = begin
            candidate = OpenSSL::PKey.read(File.read(path)) if path.is_a?(String) && path.start_with?("/")
            candidate if candidate.is_a?(OpenSSL::PKey::RSA) && !candidate.private?
          rescue SystemCallError, OpenSSL::PKey::PKeyError
            nil
          end
          new(executor: executor, native: native,
            deliveries_dir: File.expand_path(config["deliveries_dir"] || ".ace-local/herdr/deliveries", root),
            receipt_public_key: key)
        end

        # Enumerate retained event identities through the same store/lock owner.
        # Unreadable unattributable records cannot be treated as another attempt.
        def self.retained_events(deliveries_dir:, attempt:)
          raise ValidationError, "invalid attempt id" unless attempt.is_a?(String) && EVENT.match?(attempt)
          ids = [deliveries_dir, Molecules::DeliveryRecordStore.archive_dir(deliveries_dir)].flat_map do |dir|
            next [] unless Dir.exist?(dir)
            Dir.children(dir).filter_map { |name| name.delete_suffix(".json") if name.end_with?(".json") }
          end.uniq
          ids.select do |event|
            raise ValidationError, "retained inbox event id is invalid" unless EVENT.match?(event)
            Molecules::DeliveryRecordStore.with_lock(deliveries_dir, event, create: false) do
              record = Molecules::DeliveryRecordStore.load(deliveries_dir, event)
              raise ValidationError, "retained inbox event is unavailable" unless record&.inbox
              record.inbox.fetch("attempt_id") == attempt
            end
          end
        rescue SystemCallError, JSON::ParserError, ArgumentError, KeyError
          raise ValidationError, "retained inbox inventory is unavailable"
        end

        def initialize(executor:, native:, deliveries_dir:, receipt_public_key: nil)
          @executor = executor
          @native = native
          @deliveries_dir = deliveries_dir
          @receipt_public_key = receipt_public_key
        end

        # Project the accepted runtime owner before consuming an answer. Native
        # observation may verify this identity, but cannot choose its replacement.
        def target_from_owner(owner)
          unless owner.is_a?(Hash) && owner["runtime"] == "herdr" &&
              owner["agent_session"].is_a?(Hash) && owner.dig("agent_session", "agent") == owner["agent"]
            raise ValidationError, "accepted native owner is unavailable"
          end
          target = owner.slice("session", "pane", "terminal_id", "agent").merge(
            "thread" => owner.dig("agent_session", "value"), "thread_kind" => owner.dig("agent_session", "kind"))
          validate_expected_target!(target)
          target.transform_values { |value| value.dup.freeze }.freeze
        end

        def enqueue(event:, attempt:, ref:, payload:, managed_envelope: nil, expected_target: nil)
          validate_id!(event, "event")
          validate_id!(attempt, "attempt")
          raise ValidationError, "trusted receipt public key is unavailable" unless @receipt_public_key
          payload = payload.to_s
          raise ValidationError, "payload is required" if payload.empty?
          raise ValidationError, "payload contains NUL" if payload.include?("\0")
          # Callers may hand over binary-tagged bytes; persistence is JSON, so
          # the payload must decode as UTF-8 regardless of its source tag.
          payload = payload.dup.force_encoding(Encoding::UTF_8)
          unless payload.valid_encoding?
            raise ValidationError, "payload is not valid UTF-8 text"
          end

          address = address_for(ref)
          digest = Digest::SHA256.hexdigest(payload)
          envelope = if managed_envelope
            Ace::Hitl::Contract::ManagedEnvelope.load(managed_envelope, expected: {
              attempt_id: attempt, payload_sha256: digest,
              reverse: {"schema" => Ace::Hitl::Providers::Ref::SCHEMA, "session" => address.session, "pane" => address.pane}
            })
          end
          if envelope && Ace::Hitl::Contract::SecretGate::PATTERN.match?(payload)
            raise ValidationError, "secret-bearing managed native answers are prohibited"
          end
          if envelope && expected_target.nil?
            raise ValidationError, "managed native delivery requires the accepted original target"
          end
          unless expected_target.nil?
            validate_expected_target!(expected_target)
            expected_target = expected_target.slice(*TARGET_IDENTITY)
            unless expected_target.values_at("session", "pane") == [address.session, address.pane]
              raise ValidationError, "accepted original target differs from reverse address"
            end
          end
          with_event(event) do |record|
            if record
              validate_match!(record, attempt, address, digest)
              unless record.inbox["managed_envelope"] == envelope
                raise ValidationError, "managed envelope conflicts with immutable inbox event"
              end
              if expected_target && record.inbox["origin_target"] != expected_target
                raise IdentityDriftError, "original native target conflicts with immutable inbox event"
              end
              next public_record(record)
            end

            target = observe_target(address.session, address.pane, target: expected_target)
            if expected_target && !TARGET_IDENTITY.all? { |key| target[key] == expected_target[key] }
              raise IdentityDriftError, "native target differs from accepted original owner"
            end
            if target["agent"] == "pi" && !PI_EVENT_ID.match?(event)
              raise ValidationError,
                "Pi queue requires an inbox (inb-) or wake (wnk-) event id with at " \
                "least 8 id characters; the id is immutable once enqueued"
            end
            payload_limit = target["agent"] == "pi" ?
              Molecules::NativeQueueExecutor::PI_PAYLOAD_LIMIT_BYTES :
              Molecules::NativeQueueExecutor::MAX_ARG_PAYLOAD_BYTES
            if payload.bytesize > payload_limit
              raise ValidationError,
                "payload exceeds the #{target['agent']} native queue limit " \
                "of #{payload_limit} bytes and could never be delivered"
            end
            record = Models::DeliveryRecord.new(
              event_id: event, session: address.session, pane: address.pane,
              answer_digest: digest, answer: payload, state: "queued",
              inbox: {"attempt_id" => attempt, "claim_generation" => 0,
                "receipt_key_sha256" => key_fingerprint,
                "managed_envelope" => envelope,
                "origin_target" => target.slice(*TARGET_IDENTITY),
                "target" => target, "binding" => target.merge("payload_sha256" => digest)}
            )
            save(record)
            public_record(record)
          end
        rescue Ace::Hitl::Contract::InvalidEnvelope => e
          raise ValidationError, e.message
        end

        def status(event:)
          validate_id!(event, "event")
          with_event(event) do |record|
            raise ValidationError, "unknown inbox event: #{event}" unless record&.inbox

            public_record(record)
          end
        end

        # Protected canonical reads only use an already registered event's lock.
        # Missing retention is unavailable evidence, never query-time repair.
        def retained_status(event:)
          validate_id!(event, "event")
          with_event(event, create_lock: false) do |record|
            raise ValidationError, "unknown inbox event: #{event}" unless record&.inbox
            public_record(record)
          end
        rescue SystemCallError
          raise ValidationError, "retained inbox lock is unavailable"
        end

        def deliver(event:)
          validate_id!(event, "event")
          with_event(event) do |record|
            raise ValidationError, "unknown inbox event: #{event}" unless record&.inbox
            next retry_wake(record) if record.state == "delivered" && wake_pending?(record)
            next public_record(record) if %w[delivered completed uncertain].include?(record.state)
            unless record.state == "queued"
              if record.inbox["submission_intent"]
                # A previous owner crashed after saving submission intent:
                # the submission boundary is unknown to a new process.
                record = transition(record, "uncertain", record.inbox,
                  "orphan-claim", "claim owner ended after submission intent")
              else
                # The claim was saved before any submission intent existed,
                # so no submission could have started: provably pre-send.
                record = transition(record, "queued", record.inbox.reject { |key, _| key == "claim_owner" },
                  "claim-recovery", "claim owner ended before submission intent")
              end
              save(record)
              next public_record(record)
            end

            claim = record.inbox.merge(
              "claim_owner" => "#{Process.pid}:#{SecureRandom.hex(8)}",
              "claim_generation" => record.inbox.fetch("claim_generation", 0) + 1
            )
            record = transition(record, "claimed", claim, "claim")
            save(record)

            begin
              binding = observe(record)
            rescue ValidationError, ExecutorError => e
              state = e.is_a?(IdentityDriftError) ? "uncertain" : "queued"
              record = transition(record, state, claim.merge("last_error" => e.message),
                state == "uncertain" ? "identity-drift" : "pre-submit-rejection", e.message)
              save(record)
              next public_record(record)
            end

            target = binding.reject { |key, _| key == "payload_sha256" }
            bound = claim.merge("binding" => binding, "target" => target)
            record = transition(record, "claimed", bound, "bind")
            save(record)
            # No later process may infer from a claimed record that submission
            # did not occur. Persist intent immediately before the native call.
            intent = bound.merge("submission_intent" => true)
            record = transition(record, "uncertain", intent, "submit-intent")
            save(record)

            result = submit(record, binding)
            if result["pre_submit"]
              # Missing executable is the only proven pre-submission error.
              record = transition(record, "queued", bound.merge("last_error" => result["error"]),
                "pre-submit-rejection", result["error"])
            elsif result["accepted"]
              receipt = {"event_id" => event, "attempt_id" => bound["attempt_id"],
                "claim_generation" => bound["claim_generation"],
                "payload_sha256" => record.answer_digest, "binding" => binding,
                "native_output" => result["stdout"]}
              # The wake is a separate effect from the accepted submission,
              # but its DECISION rides the first delivered transition: a crash
              # between saves must never leave the wake field missing (which
              # later reads as pending) for a busy target.
              wake = if WAKE_STATUSES.include?(binding["agent_status"])
                {"status" => "pending"}
              else
                {"status" => "none", "reason" => "busy target uses the native queue form"}
              end
              record = transition(record, "delivered",
                intent.merge("receipt" => receipt).merge("wake" => wake), "accepted")
              save(record)
              # A pending wake is attempted after the decision is durable, so
              # a crash or transient failure can be recovered by a later
              # deliver call without ever resubmitting the message.
              record = attempt_wake(record, binding) if wake["status"] == "pending"
            else
              record = transition(record, "uncertain", intent.merge("last_error" => result["error"]),
                "submission-uncertain", result["error"])
            end
            save(record)
            public_record(record)
          end
        end

        def reconcile(event:, receipt:, signed_bytes: nil, signature: nil, expected_registration: nil)
          reconcile_record(event: event, receipt: receipt, signed_bytes: signed_bytes,
            signature: signature, expected_registration: expected_registration, settle: true)
        end

        # Canonical consumers reverify retained signed settlement without creating
        # a new local transition. The same event lock and proof owner are used.
        def verify_reconciliation(event:, receipt:, signed_bytes:, signature:, expected_registration:)
          unless expected_registration.is_a?(Hash) && expected_registration.keys.sort ==
              %w[event_id attempt_id payload_sha256 receipt_key_sha256].sort &&
              %w[event_id attempt_id].all? { |key| expected_registration[key].is_a?(String) && EVENT.match?(expected_registration[key]) } &&
              %w[payload_sha256 receipt_key_sha256].all? { |key| expected_registration[key].is_a?(String) && expected_registration[key].match?(/\A[0-9a-f]{64}\z/) }
            raise ValidationError, "canonical reconciliation requires exact registration"
          end
          reconcile_record(event: event, receipt: receipt, signed_bytes: signed_bytes,
            signature: signature, expected_registration: expected_registration, settle: false)
        rescue SystemCallError
          raise ValidationError, "retained inbox lock is unavailable"
        end

        private

        def reconcile_record(event:, receipt:, signed_bytes:, signature:, expected_registration:, settle:)
          validate_id!(event, "event")
          with_event(event, create_lock: settle) do |record|
            raise ValidationError, "unknown inbox event: #{event}" unless record&.inbox
            # The consumer's accepted registration must match under the same
            # event lock that verifies and settles the signed observation.
            unless expected_registration.nil?
              registration = public_record(record).slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
              unless expected_registration == registration
                raise ValidationError, "inbox event differs from expected registration"
              end
            end
            # `delivered` only proves native queue acceptance: the message may
            # still be consumed or evicted afterwards, so a signed observation
            # can reconcile it exactly like an uncertain outcome.
            replay = %w[completed queued].include?(record.state) && receipt.is_a?(Hash) &&
              receipt == record.inbox["reconciliation"]
            unless replay || (settle && %w[uncertain delivered].include?(record.state))
              raise ValidationError, "event is not reconcilable from state #{record.state}"
            end
            binding = record.inbox["binding"]
            matches = receipt.is_a?(Hash) && receipt["event_id"] == event &&
              receipt["attempt_id"] == record.inbox["attempt_id"] &&
              receipt["claim_generation"] == record.inbox["claim_generation"] &&
              receipt["payload_sha256"] == record.answer_digest &&
              receipt["binding"] == binding
            refusal = if !binding
              "event has no verified binding"
            elsif !matches
              "reconciliation receipt does not match bound event"
            end
            refusal ||= proof_refusal(receipt) if receipt.is_a?(Hash)
            refusal ||= signature_refusal(record, receipt, signed_bytes, signature)
            replacement = nil
            if !refusal && receipt["outcome"] == "superseded" && receipt.key?("replacement_target")
              replacement = receipt["replacement_target"]
              observed = begin
                raise ValidationError, "replacement target must be an object" unless replacement.is_a?(Hash)

                address = address_for(replacement)
                observe_target(address.session, address.pane)
              rescue ValidationError, ExecutorError, Ace::Hitl::Providers::InvalidRefError => e
                refusal = "replacement target cannot be verified: #{e.message}"
                nil
              end
              stable = TARGET_IDENTITY
              unless replacement.is_a?(Hash) && observed &&
                  stable.all? { |key| replacement[key] == observed[key] }
                refusal ||= "replacement target does not match the live native session"
              end
              # The replacement agent's own delivery rules must admit this
              # event: its immutable-id requirement and payload bound.
              if observed
                if observed["agent"] == "pi" && !PI_EVENT_ID.match?(event)
                  refusal ||= "replacement pi target requires an inbox (inb-) or wake (wnk-) event id"
                end
                payload_limit = observed["agent"] == "pi" ?
                  Molecules::NativeQueueExecutor::PI_PAYLOAD_LIMIT_BYTES :
                  Molecules::NativeQueueExecutor::MAX_ARG_PAYLOAD_BYTES
                if record.answer.to_s.bytesize > payload_limit
                  refusal ||= "payload exceeds the replacement agent's native queue limit"
                end
              end
            end
            next public_record(record).merge("reconciliation_refusal" => refusal) if refusal
            # The consumer may crash after Herdr settles but before recording
            # its observation reference. Re-verify the identical signed proof
            # without another transition. A later claim has a new generation
            # and fails the binding checks above.
            next public_record(record) if replay

            outcome = receipt["outcome"]
            state = outcome == "consumed" ? "completed" : "queued"
            inbox = record.inbox.merge("reconciliation" => receipt)
            if state == "queued"
              inbox = inbox.reject do |key, _|
                %w[submission_intent claim_owner receipt].include?(key)
              end
              inbox = inbox.merge("target" => replacement) if replacement
            end
            record = transition(record, state, inbox, "reconcile-#{outcome}")
            save(record)
            public_record(record)
          end
        end

        private

        def key_fingerprint
          Digest::SHA256.hexdigest(@receipt_public_key.public_to_der)
        end

        def signature_refusal(record, receipt, signed_bytes, signature)
          return "trusted receipt public key is unavailable" unless @receipt_public_key
          unless record.inbox["receipt_key_sha256"] == key_fingerprint
            return "trusted receipt public key differs from the enqueued event"
          end
          return "receipt signature is missing" unless signed_bytes.is_a?(String) && signature.is_a?(String)
          return "signed receipt content differs from parsed receipt" unless JSON.parse(signed_bytes) == receipt
          return "receipt signature is invalid" unless @receipt_public_key.verify(
            OpenSSL::Digest::SHA256.new, signature, signed_bytes)

          nil
        rescue JSON::ParserError, OpenSSL::PKey::PKeyError
          "receipt signature is invalid"
        end

        # The receipt is an explicit operator or supervisor attestation of a
        # native outcome. Native queue submission alone cannot prove consumption
        # or nonconsumption; an absent or incomplete attestation is never retried.
        def proof_refusal(receipt)
          return "invalid reconciliation outcome" unless %w[consumed superseded].include?(receipt["outcome"])
          observer = receipt["observer"]
          unless observer.is_a?(Hash) && %w[operator supervisor].include?(observer["role"]) &&
              observer["id"].is_a?(String) && !observer["id"].strip.empty?
            return "receipt requires an identified operator or supervisor"
          end
          evidence = receipt["evidence"]
          kinds = receipt["outcome"] == "consumed" ? %w[consumed_acknowledged] :
            %w[queue_evicted queue_expired thread_replaced]
          unless evidence.is_a?(Hash) && kinds.include?(evidence["kind"]) &&
              evidence["native_reference"].is_a?(String) && !evidence["native_reference"].strip.empty? &&
              evidence["observation"].is_a?(String) && !evidence["observation"].strip.empty?
            return "receipt requires a native outcome observation and reference"
          end
          nil
        end

        def with_event(event, create_lock: true)
          Molecules::DeliveryRecordStore.with_lock(@deliveries_dir, event, create: create_lock) do
            record = Molecules::DeliveryRecordStore.load(@deliveries_dir, event)
            if record
              Ace::Hitl::Providers::Ref.new(session: record.session, pane: record.pane, canonical: true)
            end
            yield record
          end
        end

        def save(record)
          Molecules::DeliveryRecordStore.save(record, @deliveries_dir)
        end

        def transition(record, state, inbox, action, error = nil)
          detail = {"action" => action}
          detail["error"] = error if error && !error.empty?
          record.advance_inbox(state: state, inbox: inbox, detail: detail, timestamp: Time.now.utc.iso8601)
        end

        def validate_id!(value, name)
          raise ValidationError, "invalid #{name} id" unless value.is_a?(String) && EVENT.match?(value)
        end

        def address_for(ref)
          hash = ref.is_a?(Hash) ? ref : JSON.parse(File.read(ref))
          raise ValidationError, "invalid ref: expected a JSON object" unless hash.is_a?(Hash)
          Ace::Hitl::Providers::Ref.new(
            session: hash.fetch("session"), pane: hash.fetch("pane"), canonical: !ref.is_a?(Hash)
          )
        rescue Errno::ENOENT, JSON::ParserError, KeyError, TypeError => e
          raise ValidationError, "invalid ref: #{e.message}"
        end

        def validate_expected_target!(target)
          unless target.is_a?(Hash) && TARGET_IDENTITY.all? { |key| target[key].is_a?(String) && !target[key].empty? } &&
              %w[codex pi].include?(target["agent"]) && target["thread_kind"] == "id" &&
              THREAD_ID.match?(target["thread"]) && target["terminal_id"].bytesize <= 64
            raise ValidationError, "accepted original native target is incomplete or invalid"
          end
        end

        def validate_match!(record, attempt, address, digest)
          unless record.inbox && record.inbox["attempt_id"] == attempt &&
              record.session == address.session && record.pane == address.pane &&
              record.answer_digest == digest
            raise ValidationError, "event identity, attempt, target, or payload digest conflicts"
          end
        end

        def observe(record)
          target = record.inbox["target"]
          binding = observe_target(target ? target["session"] : record.session,
            target ? target["pane"] : record.pane, target: target)
          # Target drift is classified BEFORE agent-specific event id rules:
          # a bound event whose pane changed agent (e.g. codex -> pi) must
          # reconcile, not loop on a pre-send validation error.
          stable = TARGET_IDENTITY
          if target && !stable.all? { |key| target[key] == binding[key] }
            raise IdentityDriftError, "target identity changed since enqueue; reconciliation is required"
          end
          if binding["agent"] == "pi" && !PI_EVENT_ID.match?(record.event_id)
            raise ValidationError, "Pi queue requires an inbox or wake event ID"
          end
          binding.merge("payload_sha256" => record.answer_digest)
        end

        def observe_target(expected_session, expected_pane, target: nil)
          payload = @executor.pane_get_bounded(expected_pane).parsed_json
          # Shape-check each level: parseable but malformed probe JSON must
          # fail as a validation error, never as a TypeError that would
          # strand the event in claimed.
          result = payload.is_a?(Hash) ? payload["result"] : nil
          pane = result.is_a?(Hash) ? result["pane"] : nil
          raise ValidationError, "pane observation is unavailable" unless pane.is_a?(Hash)
          raise IdentityDriftError, "pane identity changed" unless pane["pane_id"] == expected_pane
          observed_session = pane["workspace_id"] || pane["session_id"]
          raise IdentityDriftError, "runtime session identity changed" unless observed_session == expected_session
          agent = pane["agent"]
          # An agent change is target drift: classify it as reconciliation-
          # worthy before any agent-specific validation can mask it.
          if target && target["agent"] != agent
            raise IdentityDriftError, "target identity changed since enqueue; reconciliation is required"
          end
          raise ValidationError, "unsupported native agent" unless %w[codex pi].include?(agent)
          session = pane["agent_session"]
          raise IdentityDriftError, "native session identity is unavailable" unless session.is_a?(Hash) && session["agent"] == agent
          thread = session["value"].to_s
          kind = session["kind"]
          if agent == "pi" && kind == "path"
            thread = PI_PATH.match(thread)&.captures&.first.to_s
            kind = "id"
          end
          # Only an immutable session UUID may carry a binding: a name
          # survives an agent restart in the same pane/terminal, so a reused
          # session could inherit an old event.
          unless kind == "id" && THREAD_ID.match?(thread)
            raise ValidationError,
              "native queue binding requires an immutable session id " \
              "(got #{kind.inspect})"
          end
          raise ValidationError, "Pi queue requires a session ID" if agent == "pi" && kind != "id"
          raw_terminal = pane["terminal_id"]
          terminal = raw_terminal.to_s.strip if raw_terminal.is_a?(String) || raw_terminal.is_a?(Integer)
          if terminal.nil? || terminal.empty? || terminal.bytesize > 64
            raise ValidationError, "durable terminal identity is unavailable"
          end
          if agent == "pi" && @native.pi_identity != thread
            raise IdentityDriftError, "live Pi session identity differs"
          end
          status = pane["agent_status"].to_s
          unless AGENT_STATUSES.include?(status)
            # An undetermined status cannot decide the wake form; fail the
            # submission provably before the submission boundary (retryable).
            raise ValidationError, "native agent status is unrecognized: #{status.inspect}"
          end
          {"session" => expected_session, "pane" => expected_pane, "terminal_id" => terminal,
           "agent" => agent, "thread" => thread, "thread_kind" => kind,
           "agent_status" => status}
        end

        def submit(record, binding)
          @native.submit(agent: binding["agent"], thread: binding["thread"],
            event_id: record.event_id, digest: record.answer_digest, payload: record.answer)
        rescue ExecutorError => e
          {"accepted" => false, "error" => e.message}
        end

        # A delivered record still owes its idle wake after a crash (no wake
        # entry) or a transient failure (status pending). Re-verify the live
        # target first — identity drift demotes the event to uncertain — then
        # retry the payload-free wake. The native payload is never resubmitted.
        def retry_wake(record)
          begin
            binding = observe(record)
          rescue IdentityDriftError => e
            record = transition(record, "uncertain", record.inbox.merge("last_error" => e.message),
              "identity-drift", e.message)
            save(record)
            return public_record(record)
          rescue ExecutorError, ValidationError => e
            record = transition(record, "delivered",
              record.inbox.merge("wake" => record.inbox.fetch("wake", {"status" => "pending"})
                .merge("status" => "pending", "error" => e.message)),
              "wake-retry-blocked", e.message)
            save(record)
            return public_record(record)
          end
          unless WAKE_STATUSES.include?(binding["agent_status"])
            # The live target works on its native queue; no prompt is owed.
            record = transition(record, "delivered",
              record.inbox.merge("wake" => {"status" => "none",
                "reason" => "busy target uses the native queue form"}), "wake-none")
            save(record)
            return public_record(record)
          end
          public_record(attempt_wake(record, binding))
        end

        def wake_pending?(record)
          wake = record.inbox["wake"]
          wake.nil? || wake["status"] == "pending"
        end

        def attempt_wake(record, binding)
          wake_error = wake_idle(binding)
          wake = if wake_error
            {"status" => "pending", "error" => wake_error}
          else
            {"status" => "sent"}
          end
          detail = wake_error ? "wake-failed" : "wake-sent"
          saved = transition(record, "delivered",
            record.inbox.merge("wake" => wake).compact, detail, wake_error)
          save(saved)
          saved
        end

        def wake_idle(binding)
          @executor.agent_prompt_bounded(pane: binding["pane"],
            text: "Check your native queued messages.", timeout_ms: 10_000)
          nil
        rescue StandardError => e
          e.message
        end

        def public_record(record)
          {"event_id" => record.event_id, "attempt_id" => record.inbox["attempt_id"],
           "session" => record.session, "pane" => record.pane,
           "payload_sha256" => record.answer_digest, "state" => record.state,
           "managed_envelope" => record.inbox["managed_envelope"],
           "receipt_key_sha256" => record.inbox["receipt_key_sha256"],
           "claim_generation" => record.inbox["claim_generation"],
           "claim_owner" => record.inbox["claim_owner"],
           "submission_intent" => !!record.inbox["submission_intent"],
           "origin_target" => record.inbox["origin_target"],
           "target" => record.inbox["target"],
           "binding" => record.inbox["binding"], "receipt" => record.inbox["receipt"],
           "reconciliation" => record.inbox["reconciliation"],
           "wake" => record.inbox["wake"],
           "last_error" => record.inbox["last_error"]}
        end
      end
    end
  end
end

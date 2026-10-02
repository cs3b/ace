# frozen_string_literal: true

require "digest"
require "json"
require "time"
require "securerandom"
require "openssl"
require "ace/hitl"

module Ace
  module Herdr
    module Organisms
      # Durable event inbox. All transitions for one event are serialized by
      # DeliveryRecordStore; a saved submission intent is never replayed.
      class Inbox
        class IdentityDriftError < ValidationError; end

        EVENT = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        THREAD_ID = /\A[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}\z/
        THREAD_NAME = /\A[A-Za-z0-9][A-Za-z0-9._-]{3,127}\z/
        PI_PATH = /_([0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12})\.jsonl\z/

        def initialize(executor:, native:, deliveries_dir:, receipt_public_key: nil)
          @executor = executor
          @native = native
          @deliveries_dir = deliveries_dir
          @receipt_public_key = receipt_public_key
        end

        def enqueue(event:, attempt:, ref:, payload:)
          validate_id!(event, "event")
          validate_id!(attempt, "attempt")
          raise ValidationError, "trusted receipt public key is unavailable" unless @receipt_public_key
          raise ValidationError, "payload is required" if payload.to_s.empty?
          raise ValidationError, "payload contains NUL" if payload.include?("\0")

          address = address_for(ref)
          digest = Digest::SHA256.hexdigest(payload)
          with_event(event) do |record|
            if record
              validate_match!(record, attempt, address, digest)
              next public_record(record)
            end

            target = observe_target(address.session, address.pane)
            record = Models::DeliveryRecord.new(
              event_id: event, session: address.session, pane: address.pane,
              answer_digest: digest, answer: payload, state: "queued",
              inbox: {"attempt_id" => attempt, "claim_generation" => 0,
                "receipt_key_sha256" => key_fingerprint,
                "target" => target, "binding" => target.merge("payload_sha256" => digest)}
            )
            save(record)
            public_record(record)
          end
        end

        def status(event:)
          validate_id!(event, "event")
          with_event(event) do |record|
            raise ValidationError, "unknown inbox event: #{event}" unless record&.inbox

            public_record(record)
          end
        end

        def deliver(event:)
          validate_id!(event, "event")
          with_event(event) do |record|
            raise ValidationError, "unknown inbox event: #{event}" unless record&.inbox
            next public_record(record) if %w[delivered completed uncertain].include?(record.state)
            unless record.state == "queued"
              # A previous owner may have crashed after its claim. The
              # submission boundary is unknown to a new process.
              record = transition(record, "uncertain", record.inbox,
                "orphan-claim", "claim owner ended before a receipt")
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
              record = transition(record, "delivered", intent.merge("receipt" => receipt), "accepted")
              save(record)
              if %w[idle done].include?(binding["agent_status"])
                wake_error = wake_idle(binding)
                if wake_error
                  record = transition(record, "delivered", record.inbox.merge("wake_error" => wake_error),
                    "wake-failed", wake_error)
                end
              end
            else
              record = transition(record, "uncertain", intent.merge("last_error" => result["error"]),
                "submission-uncertain", result["error"])
            end
            save(record)
            public_record(record)
          end
        end

        def reconcile(event:, receipt:, signed_bytes: nil, signature: nil)
          validate_id!(event, "event")
          with_event(event) do |record|
            raise ValidationError, "unknown inbox event: #{event}" unless record&.inbox
            raise ValidationError, "event is not uncertain" unless record.state == "uncertain"
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
              stable = %w[session pane terminal_id agent thread thread_kind]
              unless replacement.is_a?(Hash) && observed &&
                  stable.all? { |key| replacement[key] == observed[key] }
                refusal ||= "replacement target does not match the live native session"
              end
            end
            next public_record(record).merge("reconciliation_refusal" => refusal) if refusal

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

        def with_event(event)
          Molecules::DeliveryRecordStore.with_lock(@deliveries_dir, event) do
            yield Molecules::DeliveryRecordStore.load(@deliveries_dir, event)
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
          Ace::Hitl::Providers::Ref.new(
            session: Ace::Hitl::Providers::Ref.validate!(hash.fetch("session"), "session"),
            pane: Ace::Hitl::Providers::Ref.validate!(hash.fetch("pane"), "pane")
          )
        rescue Errno::ENOENT, JSON::ParserError, KeyError => e
          raise ValidationError, "invalid ref: #{e.message}"
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
            target ? target["pane"] : record.pane)
          if binding["agent"] == "pi" && !/\A(?:inb|wnk)-[a-z0-9-]{8,64}\z/.match?(record.event_id)
            raise ValidationError, "Pi queue requires an inbox or wake event ID"
          end
          stable = %w[session pane terminal_id agent thread thread_kind]
          if target && !stable.all? { |key| target[key] == binding[key] }
            raise IdentityDriftError, "target identity changed since enqueue; reconciliation is required"
          end
          binding.merge("payload_sha256" => record.answer_digest)
        end

        def observe_target(expected_session, expected_pane)
          payload = @executor.pane_get(expected_pane).parsed_json
          pane = payload.is_a?(Hash) && payload.dig("result", "pane")
          raise ValidationError, "pane observation is unavailable" unless pane.is_a?(Hash)
          raise IdentityDriftError, "pane identity changed" unless pane["pane_id"] == expected_pane
          observed_session = pane["workspace_id"] || pane["session_id"]
          raise IdentityDriftError, "runtime session identity changed" unless observed_session == expected_session
          agent = pane["agent"]
          raise ValidationError, "unsupported native agent" unless %w[codex pi].include?(agent)
          session = pane["agent_session"]
          raise IdentityDriftError, "native session identity is unavailable" unless session.is_a?(Hash) && session["agent"] == agent
          thread = session["value"].to_s
          kind = session["kind"]
          if agent == "pi" && kind == "path"
            thread = PI_PATH.match(thread)&.captures&.first.to_s
            kind = "id"
          end
          valid = kind == "id" ? THREAD_ID.match?(thread) : (kind == "name" && THREAD_NAME.match?(thread))
          raise ValidationError, "native thread identity is invalid" unless valid
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
          raise ValidationError, "native agent status is unavailable" if status.empty?
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
           "receipt_key_sha256" => record.inbox["receipt_key_sha256"],
           "claim_generation" => record.inbox["claim_generation"],
           "claim_owner" => record.inbox["claim_owner"],
           "submission_intent" => !!record.inbox["submission_intent"],
           "target" => record.inbox["target"],
           "binding" => record.inbox["binding"], "receipt" => record.inbox["receipt"],
           "reconciliation" => record.inbox["reconciliation"],
           "last_error" => record.inbox["last_error"],
           "wake_error" => record.inbox["wake_error"]}
        end
      end
    end
  end
end

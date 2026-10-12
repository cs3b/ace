# frozen_string_literal: true

require "tempfile"
require_relative "../errors"
require_relative "../molecules/ordinary_merge_contract"
require_relative "../molecules/ordinary_merge_cli"

module Ace
  module Assign
    module Organisms
      # Ordinary project-overseer merge consumer (qkb.1).
      #
      # Records the exact immutable integration request as attempt evidence
      # before dispatch, invokes the fixed producer through `ace-lab service
      # request/status --mode ordinary-merge` with the closed selectors,
      # persists the receiver-owned opaque reference, restores it after a
      # queue-owner restart, and accepts only the exact terminal receipt.
      #
      # ace-assign attempt/evidence state is the sole queue/effect record:
      # no caller-local journal, receipt ledger or second engine exists here.
      # Lost acknowledgments, requester/receiver restarts, unavailable
      # receivers and uncertain original results reconcile only by the
      # recorded binding and reference, performing at most one merge. An
      # uncertain original result is never resubmitted; only a proven
      # pre-effect refusal closes an intent for a new reviewed request.
      # Read-only status polls never dispatch, repair or refresh anything,
      # and no `refused` state exists as status — refusal is request-time
      # only.
      class OrdinaryMergeConsumer
        INTENT_STAGE = "ordinary-merge-intent"
        ACK_STAGE = "ordinary-merge-ack"
        RESULT_STAGE = "ordinary-merge-result"

        def initialize(repo_root:, journal: nil, coordinator: nil, identity_resolver: nil, producer: nil)
          @repo_root = repo_root
          @journal = journal || Molecules::EvidenceJournal.new(repo_root: repo_root)
          @coordinator = coordinator || AttemptCoordinator.new(repo_root: repo_root, journal: @journal)
          @identity_resolver = identity_resolver || Molecules::ExecutionIdentityResolver.new
          @producer = producer || Molecules::OrdinaryMergeCli.new
        end

        # Records the immutable binding and dispatches one admission request.
        # Re-invocation with the identical recorded binding reconciles by the
        # same request ID (an identical digest returns the original
        # acknowledgment); any different binding while an effect is unresolved
        # is forbidden resubmission.
        def dispatch(assignment_id:, attempt_id:, project:, queue_entry:, input:, authorization:, request_id:)
          identity = trusted_identity!
          binding = identity_binding!(assignment_id, attempt_id)
          attempt = authoritative_attempt!(binding)
          raise AttemptErrors::ReceiptRejected, "Ordinary merge attempt is no longer active" unless attempt.active?
          input_document = validate_input!(input)
          digest = Atoms::EvidenceDigest.digest(input_document)
          selectors = validated_selectors(project: project, queue_entry: queue_entry,
            authorization: authorization, request_id: request_id)
          recorded = merge_effects(binding)
          if (intent = recorded[:intent])
            unless identical_binding?(intent.fetch("payload"), selectors, digest)
              raise AttemptErrors::Conflict,
                "Unresolved ordinary merge binding requires read-only status reconciliation; resubmission is forbidden"
            end
            return admit(binding, identity, selectors, input_document, digest, record_intent: false)
          end
          raise AttemptErrors::InvalidState, "Ordinary merge is already terminal for this attempt" if recorded[:receipt]
          admit(binding, identity, selectors, input_document, digest, record_intent: true)
        rescue Molecules::OrdinaryMergeCli::UnavailableError
          raise AttemptErrors::EvidenceUnavailable,
            "ordinary merge receiver is unavailable before admission; reconciliation by the recorded binding is required, resubmission is forbidden"
        rescue ArgumentError
          raise AttemptErrors::ReceiptRejected, "ordinary merge request violates the closed contract"
        end

        # Read-only observation. Recovers the binding and opaque reference
        # from canonical attempt evidence, polls the producer status command,
        # and accepts only the exact terminal receipt. Once a terminal
        # receipt is accepted it is returned without further producer calls.
        def poll(assignment_id:, attempt_id:)
          trusted_identity!
          binding = identity_binding!(assignment_id, attempt_id)
          authoritative_attempt!(binding)
          recorded = merge_effects(binding)
          return terminal_result(recorded[:receipt].fetch("payload")) if recorded[:receipt]
          unless recorded[:intent]
            raise AttemptErrors::NotFound,
              "No ordinary merge request is recorded or unresolved for this attempt"
          end
          intent = recorded[:intent].fetch("payload")
          selectors = intent_selectors(intent)
          input_document = intent.fetch("input")
          digest = intent.fetch("input_digest")
          reference = recorded[:ack]&.fetch("payload")&.fetch("reference")
          return recover_admission(binding, selectors, input_document, digest) unless reference
          observe(binding, selectors, reference, input_document, digest)
        rescue Molecules::OrdinaryMergeCli::UnavailableError
          raise AttemptErrors::EvidenceUnavailable,
            "ordinary merge status is unavailable; read-only reconciliation by the recorded reference is required"
        end

        private

        def trusted_identity!
          identity = @identity_resolver.resolve
          raise AttemptErrors::UnauthorizedIdentity, "Only a trusted coordinator may consume ordinary merge" unless
            @identity_resolver.trusted?(identity)
          identity
        end

        def identity_binding!(assignment_id, attempt_id)
          [assignment_id, attempt_id].each do |value|
            raise ArgumentError, "ordinary merge assignment/attempt must match the closed token grammar" unless
              value.is_a?(String) && value.match?(Molecules::JournalMutation::ID)
          end
          {"assignment_id" => assignment_id, "attempt_id" => attempt_id}
        end

        def authoritative_attempt!(binding)
          attempt = @coordinator.authoritative_attempt(binding)
          raise AttemptErrors::NotFound, "Ordinary merge attempt not found" unless attempt
          raise AttemptErrors::ReceiptRejected, "Ordinary merge requires a managed attempt" unless attempt.managed?
          attempt
        end

        def validate_input!(input)
          Molecules::OrdinaryMergeContract.validate_request_input!(input)
        end

        def validated_selectors(project:, queue_entry:, authorization:, request_id:)
          {"project" => project, "queue_entry" => queue_entry, "request_id" => request_id}.each do |label, value|
            raise ArgumentError, "ordinary merge #{label} must match the closed token grammar" unless
              value.is_a?(String) && value.match?(Molecules::JournalMutation::ID)
          end
          unless authorization.is_a?(String) && authorization.length.between?(1, 256)
            raise ArgumentError, "ordinary merge authorization reference must be a non-empty string of at most 256 characters"
          end
          {project: project, queue_entry: queue_entry, authorization: authorization, request_id: request_id}
        end

        def intent_selectors(intent)
          {project: intent.fetch("project"), queue_entry: intent.fetch("queue_entry"),
           authorization: intent.fetch("authorization"), request_id: intent.fetch("request_id")}
        end

        def identical_binding?(intent, selectors, digest)
          intent_selectors(intent) == selectors && intent.fetch("input_digest") == digest
        end

        # The recorded ordinary-merge effects for one attempt: the open
        # intent (if any), its acknowledgment reference and an accepted
        # terminal receipt. Intents settle only through a result event for
        # the same request ID.
        def merge_effects(binding)
          events = @journal.read_events(binding.fetch("assignment_id")).select do |event|
            event["type"] == "delivery" && event["attempt_id"] == binding.fetch("attempt_id") &&
              event.dig("payload", "stage").to_s.start_with?("ordinary-merge-")
          end
          intents = events.select { |event| event.dig("payload", "stage") == INTENT_STAGE }
          settled = events.select { |event| event.dig("payload", "stage") == RESULT_STAGE }
            .map { |event| event.dig("payload", "request_id") }
          open = intents.reject { |event| settled.include?(event.dig("payload", "request_id")) }
          raise AttemptErrors::Conflict, "Multiple unresolved ordinary merge bindings require reconciliation" if open.length > 1
          intent = open.last
          ack = intent && events.reverse.find do |event|
            event.dig("payload", "stage") == ACK_STAGE &&
              event.dig("payload", "request_id") == intent.dig("payload", "request_id")
          end
          receipt = events.reverse.find do |event|
            event.dig("payload", "stage") == RESULT_STAGE &&
              %w[succeeded failed].include?(event.dig("payload", "terminal_status"))
          end
          {intent: intent, ack: ack, receipt: receipt}
        end

        def admit(binding, identity, selectors, input_document, digest, record_intent:)
          record_event(binding, identity, intent_payload(selectors, input_document, digest)) if record_intent
          branch = admission_branch(request_admission(binding, selectors, input_document))
          if branch[:status] == "ok"
            ack = begin
              Molecules::OrdinaryMergeContract.validate_ack!(branch[:payload],
                request_id: selectors[:request_id], input_digest: digest)
            rescue ArgumentError
              raise AttemptErrors::EvidenceUnavailable,
                "ordinary merge acknowledgment is not the maintained contract; admission stays unconfirmed"
            end
            record_event(binding, identity, {"stage" => ACK_STAGE, "reference" => ack.fetch("reference"),
              "request_id" => ack.fetch("request_id"), "input_digest" => ack.fetch("input_digest")})
            return {state: "accepted", reference: ack.fetch("reference"),
                    request_id: ack.fetch("request_id"), input_digest: ack.fetch("input_digest")}
          end
          handle_refusal(binding, identity, branch[:payload])
        end

        # Closed outer envelope for admission responses: exactly {status,
        # data} for ok and exactly {status, error} for error, both objects
        # rejecting unknown fields. Any other outer status or shape —
        # including a refusal attached to a non-error envelope such as
        # pending — is malformed, leaves admission unconfirmed, and is never
        # persisted as a proven refusal.
        def admission_branch(envelope)
          Molecules::OrdinaryMergeContract.validate_envelope_branch!(envelope)
        rescue ArgumentError
          raise AttemptErrors::EvidenceUnavailable,
            "ordinary merge response is not the maintained envelope; admission stays unconfirmed"
        end

        def request_admission(binding, selectors, input_document)
          input_path = nil
          Tempfile.create("ace-assign-ordinary-merge-input") do |file|
            file.write(Atoms::EvidenceDigest.canonical_json(input_document))
            file.flush
            input_path = file.path
            return @producer.request(project: selectors[:project], assignment: binding.fetch("assignment_id"),
              attempt: binding.fetch("attempt_id"), queue_entry: selectors[:queue_entry],
              input_path: input_path, authorization: selectors[:authorization],
              request_id: selectors[:request_id])
          end
        end

        def handle_refusal(binding, identity, error)
          refusal = begin
            Molecules::OrdinaryMergeContract.validate_refusal!(error)
          rescue ArgumentError
            raise AttemptErrors::EvidenceUnavailable,
              "ordinary merge refusal is not the maintained contract; admission stays unconfirmed"
          end
          if refusal.fetch("code") == Molecules::OrdinaryMergeContract::UNAVAILABLE_CODE
            raise AttemptErrors::EvidenceUnavailable,
              "ordinary merge receiver refused as unavailable before admission; this is a blocker, never a proven refusal"
          end
          record_event(binding, identity, {"stage" => RESULT_STAGE, "outcome" => "refused_no_effect",
            "code" => refusal.fetch("code"), "message" => refusal.fetch("message"),
            "request_id" => refusal.fetch("request_id"), "input_digest" => refusal.fetch("input_digest")})
          {state: "refused", code: refusal.fetch("code"), message: refusal.fetch("message")}
        end

        # Lost acknowledgment after durable admission: reconcile by the
        # identical recorded binding. A request ID bound to the identical
        # digest returns the original acknowledgment and reference.
        def recover_admission(binding, selectors, input_document, digest)
          identity = trusted_identity!
          result = admit(binding, identity, selectors, input_document, digest, record_intent: false)
          return result if result.is_a?(Hash) && result[:state] == "refused"
          unless result.is_a?(Hash) && result[:state] == "accepted"
            raise AttemptErrors::EvidenceUnavailable, "ordinary merge acknowledgment is still unavailable"
          end
          observe(binding, selectors, result.fetch(:reference), input_document, digest)
        end

        def observe(binding, selectors, reference, input_document, digest)
          envelope = @producer.status(reference: reference, request_id: selectors[:request_id],
            project: selectors[:project], assignment: binding.fetch("assignment_id"),
            attempt: binding.fetch("attempt_id"), queue_entry: selectors[:queue_entry],
            input_digest: digest)
          branch = status_branch(envelope)
          if branch[:status] == "error"
            begin
              validated = Molecules::OrdinaryMergeContract.validate_refusal!(branch[:payload],
                schema: Molecules::OrdinaryMergeContract::STATUS_ERROR_SCHEMA)
            rescue ArgumentError
              raise AttemptErrors::EvidenceUnavailable, "ordinary merge status error is not the maintained contract"
            end
            raise AttemptErrors::EvidenceUnavailable,
              "ordinary merge status command error (#{validated.fetch("code")}); a command error is never a durable state or a refusal"
          end
          observed = begin
            Molecules::OrdinaryMergeContract.validate_status!(envelope, reference: reference,
              request_id: selectors[:request_id], input_digest: digest)
          rescue ArgumentError
            raise AttemptErrors::ReceiptRejected, "ordinary merge status or receipt differs from the closed contract"
          end
          return {state: observed[:state]} unless observed[:receipt]
          accept_receipt(binding, selectors, reference, input_document, digest, observed[:receipt])
        end

        # Closed outer envelope for read-only status responses. A malformed
        # shape — including a missing branch object — is a classified caller-
        # side blocker, never a raw internal error and never a durable state.
        def status_branch(envelope)
          Molecules::OrdinaryMergeContract.validate_envelope_branch!(envelope)
        rescue ArgumentError
          raise AttemptErrors::EvidenceUnavailable,
            "ordinary merge status response is not the maintained envelope"
        end

        def accept_receipt(binding, selectors, reference, input_document, digest, receipt)
          receipt_binding = {reference: reference, request_id: selectors[:request_id], input_digest: digest,
                             request: {project: selectors[:project], assignment: binding.fetch("assignment_id"),
                                       attempt: binding.fetch("attempt_id"), queue_entry: selectors[:queue_entry],
                                       authorization: selectors[:authorization], input: input_document}}
          accepted = begin
            Molecules::OrdinaryMergeContract.validate_receipt!(receipt, binding: receipt_binding)
          rescue ArgumentError
            raise AttemptErrors::ReceiptRejected, "terminal receipt differs from the recorded binding or the closed schema"
          end
          payload = {"stage" => RESULT_STAGE, "terminal_status" => accepted.fetch("terminal_status"),
                     "outcome" => accepted.fetch("effect").fetch("outcome"), "reference" => reference,
                     "request_id" => selectors[:request_id], "input_digest" => digest, "receipt" => accepted,
                     "synchronization_required" => accepted.fetch("effect").fetch("outcome") == "already_merged"}
          record_event(binding, trusted_identity!, payload)
          terminal_result(payload)
        end

        def terminal_result(payload)
          {state: payload.fetch("terminal_status"), receipt: payload.fetch("receipt"),
           synchronization_required: payload.fetch("synchronization_required")}
        end

        def intent_payload(selectors, input_document, digest)
          {"stage" => INTENT_STAGE, "project" => selectors[:project], "queue_entry" => selectors[:queue_entry],
           "operation" => "merge", "authorization" => selectors[:authorization],
           "request_id" => selectors[:request_id], "input" => input_document, "input_digest" => digest}
        end

        def record_event(binding, identity, payload)
          producer = {"actor" => identity.actor, "role" => identity.role, "runtime" => identity.runtime}
          @journal.record(**binding.transform_keys(&:to_sym), type: "delivery",
            payload: payload.merge("producer" => producer),
            guard: -> {
              live = @coordinator.authoritative_attempt(binding)
              raise AttemptErrors::ReceiptRejected, "Ordinary merge attempt is no longer active" unless
                live&.active? && live.managed?
            })
        rescue SystemCallError
          raise AttemptErrors::EvidenceUnavailable,
            "ordinary merge evidence record is unavailable; reconcile by the recorded binding"
        end
      end
    end
  end
end

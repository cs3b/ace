# frozen_string_literal: true
require "ace/herdr/molecules/guarded_native_origin"

module Ace
  module Assign
    module Molecules
      # Durable N2 phases in the existing canonical journal, never an effect ledger.
      module JournalPromptMutation
        # Source-only phase: commit intent before the caller obtains any
        # native dispatch permit. The scope owner reauthenticates inside this
        # side-effect-free callback on EVERY journal CAS attempt.
        def issue_prompt(binding:, issued_by:, &admission)
          validate_prompt_binding!(binding)
          unless issued_by.is_a?(Hash) && issued_by.keys.all? { |key| key.is_a?(String) } &&
              issued_by.keys.sort == %w[gid groups host parent_pid pid started_at uid] &&
              %w[uid gid groups].all? { |key| issued_by[key] == binding.fetch("caller").fetch(key) } &&
              %w[pid parent_pid].all? { |key| issued_by[key].is_a?(Integer) && issued_by[key].positive? } &&
              %w[host started_at].all? { |key| issued_by[key].is_a?(String) && issued_by[key].bytesize.between?(1, 255) }
            raise ArgumentError, "invalid original prompt issuer evidence"
          end
          binding = JSON.parse(JSON.generate(binding))
          issued_by = JSON.parse(JSON.generate(issued_by))
          raise ArgumentError, "prompt admission callback is required" unless admission
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical_prompt_value(binding)))
          internal_id = "prompt-issue.#{digest}"
          response = mutate(assignment_id: binding.fetch("assignment_id"), attempt_id: binding.fetch("attempt_id"),
            mutation_id: internal_id, operation: "prompt_issue", parameters_digest: digest,
            expected_generation: binding.fetch("expected_generation"), with_replay: true, prompt_binding: binding) do |events, commit, generation|
            admission.call(events, commit, generation)
            {events: [{type: "prompt_issued", payload: {"external_mutation_id" => binding.fetch("mutation_id"),
              "binding_digest" => digest, "binding" => binding, "issued_by" => issued_by}}],
              data: {"mutation_id" => binding.fetch("mutation_id"), "binding_digest" => digest, "intent_mutation_id" => internal_id}}
          end
          response
        end

        # Fixed source-owned completion. Its selector authenticates the actual
        # accepted issue on every CAS; the callback rejoins the original scope
        # and guard without performing an effect. Replay keeps the FIRST public
        # reply even if a later observation has a different outcome.
        def finalize_prompt(mutation_id:, intent_event_id:, binding_digest:, evidence:, &authentication)
          raise ArgumentError, "prompt completion authentication is required" unless authentication
          intent = prompt_intent(mutation_id)
          raise AttemptErrors::EvidenceUnavailable, "Prompt issue is unavailable" unless intent
          binding = intent.fetch("payload").fetch("binding")
          selector = {"intent_event_id" => intent_event_id, "binding_digest" => binding_digest}
          mutate(assignment_id: binding.fetch("assignment_id"), attempt_id: binding.fetch("attempt_id"),
            mutation_id: mutation_id, operation: "prompt_attempt", parameters_digest: binding_digest,
            expected_generation: nil, generation_mode: :prompt_completion, prompt_completion: selector, with_replay: true) do |events, commit, generation|
            if events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
              raise AttemptErrors::EvidenceUnavailable, "Released prompt scope cannot accept new outcome"
            end
            original = authentication.call(events, commit, generation)
            unless original.is_a?(Hash) && original.keys.sort == %w[binding_digest origin] &&
                original["binding_digest"] == binding.fetch("original_binding_digest")
              raise AttemptErrors::EvidenceUnavailable, "Original prompt scope binding differs"
            end
            validate_prompt_evidence!(evidence, original.fetch("origin"))
            {events: [{type: "prompt_outcome", payload: {"external_mutation_id" => mutation_id,
              "intent_event_id" => intent_event_id, "binding_digest" => binding_digest, "evidence" => evidence}}],
              data: {"mutation_id" => mutation_id, "attempt_id" => binding.fetch("attempt_id"),
                "intent_event_id" => intent_event_id, "outcome" => evidence.fetch("outcome"), "guarded_evidence" => evidence}}
          end
        end

        def verify_prompt_completion!(selector, mutation_id:, digest:, assignment_id:, attempt_id:, commit:)
          unless selector.is_a?(Hash) && selector.keys.all? { |key| key.is_a?(String) } && selector.keys.sort == %w[binding_digest intent_event_id] &&
              selector.values.all? { |value| value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/) }
            raise ArgumentError, "invalid fixed prompt completion selector"
          end
          intent = prompt_intent(mutation_id, commit: commit)
          unless intent && intent["digest"] == selector.fetch("intent_event_id") &&
              intent.dig("payload", "binding_digest") == digest && selector.fetch("binding_digest") == digest &&
              intent.dig("payload", "binding", "assignment_id") == assignment_id && intent["attempt_id"] == attempt_id
            raise AttemptErrors::EvidenceUnavailable, "Prompt completion does not join accepted issue"
          end
          true
        end
        private :verify_prompt_completion!

        # Later authenticated native completion is a separate canonical fact.
        # It never replaces the first immutable public prompt reply.
        def observe_prompt_completion(mutation_id:, intent_event_id:, binding_digest:, evidence:, &authentication)
          raise ArgumentError, "prompt observation authentication is required" unless authentication
          intent = prompt_intent(mutation_id)
          raise AttemptErrors::EvidenceUnavailable, "Prompt issue is unavailable" unless intent
          binding = intent.fetch("payload").fetch("binding")
          selector = {"external_mutation_id" => mutation_id, "intent_event_id" => intent_event_id, "binding_digest" => binding_digest}
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical_prompt_value(selector.merge("evidence" => evidence))))
          mutate(assignment_id: binding.fetch("assignment_id"), attempt_id: binding.fetch("attempt_id"),
            mutation_id: "prompt-observe.#{intent_event_id}", operation: "prompt_observation", parameters_digest: digest,
            expected_generation: nil, generation_mode: :prompt_observation, prompt_observation: selector, with_replay: true) do |events, commit, generation|
            if events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
              raise AttemptErrors::EvidenceUnavailable, "Released prompt scope cannot accept new observation"
            end
            original = authentication.call(events, commit, generation)
            unless original.is_a?(Hash) && original.keys.sort == %w[binding_digest origin] && original["binding_digest"] == binding.fetch("original_binding_digest")
              raise AttemptErrors::EvidenceUnavailable, "Original prompt scope binding differs"
            end
            validate_prompt_evidence!(evidence, original.fetch("origin"))
            unless %w[submitted not_issued].include?(evidence.fetch("outcome"))
              raise AttemptErrors::EvidenceUnavailable, "Unknown native outcome is not completed evidence"
            end
            {events: [{type: "prompt_completion_observed", payload: selector.merge("evidence" => evidence)}],
              data: selector.merge("outcome" => evidence.fetch("outcome"), "guarded_evidence" => evidence)}
          end
        end

        def verify_prompt_observation!(selector, mutation_id:, assignment_id:, attempt_id:, commit:)
          unless selector.is_a?(Hash) && selector.keys.sort == %w[binding_digest external_mutation_id intent_event_id] &&
              mutation_id == "prompt-observe.#{selector["intent_event_id"]}"
            raise ArgumentError, "invalid fixed prompt observation selector"
          end
          verify_prompt_completion!(selector.slice("intent_event_id", "binding_digest"),
            mutation_id: selector.fetch("external_mutation_id"), digest: selector.fetch("binding_digest"),
            assignment_id: assignment_id, attempt_id: attempt_id, commit: commit)
        end
        private :verify_prompt_observation!

        def validate_prompt_evidence!(evidence, original)
          unless original.is_a?(Hash) && evidence.is_a?(Hash) && evidence.keys.all? { |key| key.is_a?(String) } && evidence["origin"] == original
            raise AttemptErrors::EvidenceUnavailable, "Prompt outcome original guard differs"
          end
          Ace::Herdr::Molecules::GuardedNativeOrigin.verify!(original, terminal_id: original.fetch("terminal_id"), child: original.fetch("child"))
          Ace::Herdr::Molecules::GuardedNativeOrigin.verify!(evidence.fetch("origin"), terminal_id: original.fetch("terminal_id"), child: original.fetch("child"))
          case evidence["outcome"]
          when "submitted"
            valid = evidence.keys.sort == %w[origin outcome submission] && evidence["submission"] == "submitted"
          when "not_issued"
            valid = evidence.keys.sort == %w[code origin outcome phase] && evidence["phase"] == "not_issued" &&
              %w[guard_mismatch origin_unavailable origin_exited agent_blocked agent_not_ready target_missing submission_busy].include?(evidence["code"])
          when "uncertain"
            valid = evidence.keys.sort == %w[origin outcome]
          end
          raise AttemptErrors::EvidenceUnavailable, "Prompt outcome is malformed" unless valid
          true
        rescue KeyError, TypeError, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "Prompt outcome original guard is malformed"
        end
        private :validate_prompt_evidence!

        # Private driver selection must be an actual retained canonical prefix,
        # never an abandoned CAS candidate that merely contains valid events.
        def verify_prompt_prefix!(commit:, canonical_commit: ref_value)
          verify_commit!(commit)
          verify_commit!(canonical_commit)
          text, error, status = git("rev-list", "--first-parent", "--parents", "--max-count=#{self.class::HISTORY_LIMIT + 1}", canonical_commit)
          nodes = text.lines.map(&:split)
          unless status.success? && nodes.size <= self.class::HISTORY_LIMIT && !nodes.empty? &&
              nodes.all? { |node| node.size.between?(1, 2) && node.all? { |sha| sha.match?(/\A[0-9a-f]{40}\z/) } } &&
              nodes.each_cons(2).all? { |left, right| left[1] == right[0] } && nodes.last.size == 1 && nodes.any? { |node| node.first == commit }
            raise AttemptErrors::EvidenceUnavailable, "Prompt prefix is not retained canonical first-parent history"
          end
          true
        end

        # A read-only selected canonical chain lookup, never a dispatch permit.
        def prompt_intent(mutation_id, commit: ref_value)
          validate_mutation_id!(mutation_id)
          found = nil
          assignment_ids(commit: commit).each do |assignment_id|
            events = read_events(assignment_id, commit: commit)
            events.group_by { |event| event.fetch("attempt_id") }.each_value do |chain|
              unless Models::EvidenceEvent.chain_valid?(chain)
                raise AttemptErrors::EvidenceUnavailable, "Prompt intent event chain is corrupt"
              end
            end
            events.each do |event|
              next unless event["type"] == "prompt_issued" && event.dig("payload", "external_mutation_id") == mutation_id
              raise AttemptErrors::EvidenceUnavailable, "Prompt intent is ambiguous" if found
              payload = event.fetch("payload")
              validate_prompt_binding!(payload.fetch("binding"))
              digest = Digest::SHA256.hexdigest(JSON.generate(canonical_prompt_value(payload.fetch("binding"))))
              binding = payload.fetch("binding")
              acceptance = events.find { |entry| entry["type"] == "authority_mutation" &&
                entry.dig("payload", "mutation_id") == "prompt-issue.#{digest}" &&
                entry.dig("payload", "operation") == "prompt_issue" &&
                entry.dig("payload", "parameters_digest") == digest && entry["previous_digest"] == event["digest"] }
              unless acceptance && payload["binding_digest"] == digest && binding["mutation_id"] == mutation_id &&
                  binding["assignment_id"] == assignment_id && binding["attempt_id"] == event["attempt_id"]
                raise AttemptErrors::EvidenceUnavailable, "Prompt intent acceptance binding differs"
              end
              found = event
            end
          end
          found
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "Prompt intent is malformed"
        end

        def validate_prompt_binding!(binding)
          fields = %w[action assignment_id attempt_id caller expected_generation mapping_id mutation_id original_binding_digest project_id text_bytes text_sha256]
          unless binding.is_a?(Hash) && binding.keys.all? { |key| key.is_a?(String) } && binding.keys.sort == fields &&
              binding["action"] == "prompt_attempt" && binding["expected_generation"].is_a?(Integer) && binding["expected_generation"] >= 0 &&
              binding["text_bytes"].is_a?(Integer) && binding["text_bytes"].between?(1, 16_384) &&
              %w[text_sha256 original_binding_digest].all? { |key| binding[key].is_a?(String) && binding[key].match?(/\A[0-9a-f]{64}\z/) }
            raise ArgumentError, "invalid fixed prompt binding"
          end
          %w[assignment_id attempt_id mapping_id mutation_id project_id].each { |key| validate_mutation_id!(binding.fetch(key)) }
          if binding.fetch("mutation_id").start_with?("prompt-issue.", "prompt-observe.")
            raise ArgumentError, "public mutation ID uses reserved prompt namespace"
          end
          caller = binding.fetch("caller")
          unless caller.is_a?(Hash) && caller.keys.all? { |key| key.is_a?(String) } && caller.keys.sort == %w[gid groups role uid] &&
              %w[launcher supervisor].include?(caller["role"]) &&
              %w[uid gid].all? { |key| caller[key].is_a?(Integer) && caller[key].between?(0, 0xffff_ffff) } &&
              caller["groups"].is_a?(Array) && caller["groups"].size <= 256 &&
              caller["groups"].all? { |group| group.is_a?(Integer) && group.between?(0, 0xffff_ffff) } &&
              caller["groups"] == caller["groups"].sort.uniq
            raise ArgumentError, "invalid authenticated stable prompt principal"
          end
          true
        end
        private :validate_prompt_binding!

        def canonical_prompt_value(value)
          case value
          when Hash then value.keys.sort.to_h { |key| [key, canonical_prompt_value(value.fetch(key))] }
          when Array then value.map { |item| canonical_prompt_value(item) }
          else value
          end
        end
        private :canonical_prompt_value

        def verify_prompt_external_namespace!(external_id, digest, assignment_id:, attempt_id:, commit:)
          intent = prompt_intent(external_id, commit: commit)
          accepted = mutation_result(external_id, commit: commit)
          if accepted || (intent && (intent.dig("payload", "binding_digest") != digest ||
              intent.dig("payload", "binding", "assignment_id") != assignment_id || intent["attempt_id"] != attempt_id))
            raise AttemptErrors::Conflict, "Mutation ID is already bound to different input"
          end
        end
        private :verify_prompt_external_namespace!

        def verify_prompt_mutation_namespace!(mutation_id:, operation:, parameters_digest:, assignment_id:, attempt_id:, prompt_completion:, prompt_observation: nil, commit:)
          # Ordinary mutations cannot steal an external ID while its accepted
          # prompt issue has no finalized public reply yet.
          if mutation_id.start_with?("prompt-issue.")
            raise ArgumentError, "reserved internal prompt namespace" unless operation == "prompt_issue"
            return
          end
          if mutation_id.start_with?("prompt-observe.")
            raise ArgumentError, "reserved internal prompt observation namespace" unless operation == "prompt_observation" && prompt_observation
            return
          end
          return if operation == "prompt_attempt" && prompt_completion
          if prompt_intent(mutation_id, commit: commit)
            raise AttemptErrors::Conflict, "Mutation ID is reserved by accepted prompt intent"
          end
        end
        private :verify_prompt_mutation_namespace!

      end
    end
  end
end

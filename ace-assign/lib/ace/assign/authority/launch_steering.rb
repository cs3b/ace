# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        def transfer_binding(operation) = TRANSFER_OPERATIONS[operation]

        def authorize_transfer!(request:, peer:, role:)
          raise ArgumentError, "unsupported launch transfer" unless request["operation"] == "prompt_attempt"
          steering_principal!(request.fetch("params"), peer, role)
        end

        def prompt_attempt!(request:, peer:, role:, transfer:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id expected_generation transfer])
          token!(request.fetch("mutation_id"))
          generation!(params.fetch("expected_generation"))
          map = steering_principal!(params, peer, role)
          raise AttemptErrors::MalformedTransfer, "Prompt transfer unavailable" unless transfer
          text = transfer.bytes
          unless text.is_a?(String) && text.force_encoding(Encoding::UTF_8).valid_encoding? && text.bytesize.between?(1, 16_384) && !text.match?(/\A[[:space:]]*\z/)
            raise AttemptErrors::MalformedTransfer, "Prompt text is malformed"
          end
          journal = journal_for(map)
          binding = intent = channel = reservation = nil
          prepared = with_exclusion(params, map, journal) do
            @mutex.synchronize do
              commit = journal.ref_value
              events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              state = origin(events, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
              original = original_prompt_record!(events, state, params: params)
              binding = {"action" => "prompt_attempt", "project_id" => map.fetch("project_id"),
                "mapping_id" => params.fetch("mapping_id"), "assignment_id" => params.fetch("assignment_id"), "attempt_id" => params.fetch("attempt_id"),
                "mutation_id" => request.fetch("mutation_id"), "expected_generation" => params.fetch("expected_generation"),
                "caller" => peer.slice("uid", "gid", "groups").merge("role" => role.to_s),
                "original_binding_digest" => original.fetch("binding_digest"), "text_bytes" => text.bytesize, "text_sha256" => Digest::SHA256.hexdigest(text)}
              digest = Digest::SHA256.hexdigest(JSON.generate(canonical(binding)))
              replay = journal.mutation_result(request.fetch("mutation_id"), commit: commit)
              if replay
                unless replay["operation"] == "prompt_attempt" && replay["parameters_digest"] == digest && replay["assignment_id"] == params["assignment_id"] && replay["attempt_id"] == params["attempt_id"]
                  raise AttemptErrors::Conflict, "Mutation ID is already bound to different input"
                end
                next({data: replay.fetch("data").merge("journal_commit" => replay.fetch("journal_commit")), replayed: true})
              end
              unless journal.prompt_intent(request.fetch("mutation_id"), commit: commit)
                channel = @control_channels[steering_key(params, map)]
                raise AttemptErrors::EvidenceUnavailable, "Original launcher channel is unavailable" unless channel
                reservation = channel.reserve_dispatch!
              end
              issue = journal.issue_prompt(binding: binding, issued_by: peer) do |current, _old, _generation|
                unless channel && reservation && channel.dispatch_reserved?(reservation)
                  raise AttemptErrors::EvidenceUnavailable, "Original launcher channel is unavailable"
                end
                fresh = origin(current, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
                authenticate = original_prompt_record!(current, fresh, params: params)
                raise AttemptErrors::EvidenceUnavailable, "Original guarded record changed" unless authenticate == original
                raise AttemptErrors::Conflict, "Attempt is not available for prompt input" unless fresh["phase"] == "issued" && !terminal_events?(current)
                scope_open_for_effect!(events: current, params: params, map: map)
                @kernel.live!(fresh.fetch("process_binding").fetch("process_identity"))
              end
              intent = journal.prompt_intent(request.fetch("mutation_id"), commit: issue.dig(:data, "journal_commit"))
              {issue: issue, original: original}
            end
          end
          return prepared if prepared.key?(:data)
          evidence = {"outcome" => "uncertain", "origin" => prepared.fetch(:original).fetch("origin")}
          if channel && !channel.closed? && !prepared.fetch(:issue).fetch(:replayed)
            frame = {"version" => 1, "type" => "prompt_dispatch", "mutation_id" => request.fetch("mutation_id"),
              "attempt_id" => params.fetch("attempt_id"), "intent_event_id" => intent.fetch("digest"),
              "journal_commit" => prepared.dig(:issue, :data, "journal_commit"), "original_binding_digest" => binding.fetch("original_binding_digest"),
              "text_descriptor" => TransferCodec.new.descriptor([text], purpose: :prompt_text), "transfer_id" => SecureRandom.hex(16)}
            begin
              outcome = channel.dispatch_prompt(frame: frame, bytes: text, deadline: wire.deadline(30), reservation: reservation)
              evidence = outcome.fetch("guarded_evidence")
            rescue Ace::Runtime::RuntimeUnavailableError, AttemptErrors::EvidenceUnavailable, IOError, SystemCallError
              # Accepted intent never yields another send permit after uncertainty.
            end
          end
          finish_prompt_outcome!(params, map, intent, evidence)
        ensure
          channel&.release_dispatch!(reservation) if reservation
          text = nil
        end

        def serve_launch_control!(request:, peer:, socket:, codec:, deadline:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id])
          raise ArgumentError, "Private control requires null mutation ID" unless request.fetch("mutation_id").nil?
          map = steering_principal!(params, peer, :launcher)
          journal = journal_for(map)
          channel = ready = nil
          with_containment_exclusion(params, map, journal) do
            @mutex.synchronize do
              commit = journal.ref_value
              events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              state = origin(events, **params.transform_keys(&:to_sym))
              raise AttemptErrors::UnauthorizedIdentity, "Private channel belongs to another launcher incarnation" unless @kernel.same?(state.fetch("launcher_identity"), peer)
              raise AttemptErrors::Conflict, "Original launcher is not issued" unless state["phase"] == "issued"
              if events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
                raise AttemptErrors::EvidenceUnavailable, "Released scope cannot retain launcher control"
              end
              original = original_prompt_record!(events, state, params: params)
              key = steering_key(params, map)
              prior = @control_channels[key]
              raise AttemptErrors::Conflict, "Original launcher channel already exists" if prior && !prior.closed?
              channel = LaunchControlChannel.new(socket: socket, codec: codec,
                outcome: ->(result) { ingest_original_prompt_outcome!(params, map, result) },
                input_inhibition: ->(result) { record_original_input_inhibition!(params.merge(result.slice("original_binding_digest", "seal_event_id")), map,
                  result.fetch("guarded_evidence"), peer: peer) })
              @control_channels[key] = channel
              ready = {"version" => 1, "type" => "launch_control_ready", "attempt_id" => params.fetch("attempt_id"),
                "original_binding_digest" => original.fetch("binding_digest"), "journal_commit" => commit, "generation" => journal.authority_generation(events)}
            end
          end
          wire.write(socket, ready, deadline: deadline, limit: 16_384)
          channel.serve
        ensure
          channel&.close
        end

        # This immutable-prefix query holds no slot/assignment exclusion. The
        # original waiter dropped all locks before dispatch/ACK handling.
        def launch_prompt_intent!(request:, peer:, role:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id mutation_id intent_event_id journal_commit])
          raise ArgumentError, "Intent lookup is read-only" unless request.fetch("mutation_id").nil?
          map = steering_principal!(params, peer, role)
          raise AttemptErrors::UnauthorizedIdentity, "Intent lookup requires original launcher" unless role == :launcher
          unless params.fetch("journal_commit").is_a?(String) && params.fetch("journal_commit").match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise ArgumentError, "Invalid immutable intent commit"
          end
          journal = journal_for(map)
          journal.verify_canonical_prefix!(commit: params.fetch("journal_commit"))
          intent = journal.prompt_intent(params.fetch("mutation_id"), commit: params.fetch("journal_commit"))
          raise AttemptErrors::EvidenceUnavailable, "Accepted prompt intent differs" unless intent && intent["digest"] == params.fetch("intent_event_id")
          events = journal.read_events(params.fetch("assignment_id"), commit: params.fetch("journal_commit")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          state = origin(events, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
          raise AttemptErrors::UnauthorizedIdentity, "Intent lookup requires exact launcher incarnation" unless @kernel.same?(state.fetch("launcher_identity"), peer)
          original = original_prompt_record!(events, state, params: params)
          binding = intent.fetch("payload").fetch("binding")
          unless binding["original_binding_digest"] == original.fetch("binding_digest") && binding["mapping_id"] == params["mapping_id"] && binding["assignment_id"] == params["assignment_id"] && binding["attempt_id"] == params["attempt_id"]
            raise AttemptErrors::EvidenceUnavailable, "Prompt intent does not join original accepted record"
          end
          {data: {"intent_event_id" => intent.fetch("digest"), "binding" => binding, "origin" => original.fetch("origin")}, replayed: false}
        end

        # Only the still-authenticated original launcher may recover its own
        # already-known native ACK after a private connection disappears.
        # This grants no input permit and never changes the first public reply.
        def launch_prompt_completion!(request:, peer:, role:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id mutation_id intent_event_id original_binding_digest guarded_evidence])
          raise ArgumentError, "Original completion requires null public mutation ID" unless request.fetch("mutation_id").nil?
          map = steering_principal!(params, peer, role)
          raise AttemptErrors::UnauthorizedIdentity, "Completion reporting requires original launcher" unless role == :launcher
          journal = journal_for(map)
          intent = journal.prompt_intent(params.fetch("mutation_id"))
          binding = intent&.dig("payload", "binding")
          unless intent && intent["digest"] == params["intent_event_id"] && binding.is_a?(Hash) &&
              %w[mapping_id assignment_id attempt_id original_binding_digest].all? { |key| binding[key] == params[key] } &&
              params.fetch("guarded_evidence").is_a?(Hash) && %w[submitted not_issued].include?(params.dig("guarded_evidence", "outcome"))
            raise AttemptErrors::EvidenceUnavailable, "Retained native completion does not join accepted issue"
          end
          accepted = finish_prompt_outcome!(params.slice("mapping_id", "assignment_id", "attempt_id"), map, intent,
            params.fetch("guarded_evidence"), peer: peer, completion_ack: true)
          {data: accepted.merge("intent_event_id" => intent.fetch("digest")), replayed: false}
        end

        def prompt_status!(request:, peer:, role:)
          params = request.fetch("params")
          strict!(params, %w[mapping_id assignment_id attempt_id mutation_id])
          %w[assignment_id attempt_id mutation_id].each { |key| token!(params.fetch(key)) }
          raise ArgumentError, "Prompt status requires null public mutation ID" unless request.fetch("mutation_id").nil?
          map = steering_principal!(params, peer, role)
          journal = journal_for(map)
          @mutex.synchronize do
            commit = journal.ref_value
            intent = journal.prompt_intent(params.fetch("mutation_id"), commit: commit)
            raise AttemptErrors::NotFound, "Prompt mutation is missing" unless intent
            binding = intent.fetch("payload").fetch("binding")
            unless binding.slice("mapping_id", "assignment_id", "attempt_id") == params.slice("mapping_id", "assignment_id", "attempt_id") &&
                binding.fetch("project_id") == map.fetch("project_id")
              raise AttemptErrors::Conflict, "Prompt mutation belongs to another attempt"
            end
            unless binding.fetch("caller") == peer.slice("uid", "gid", "groups").merge("role" => role.to_s)
              raise AttemptErrors::UnauthorizedIdentity, "Prompt mutation belongs to another principal"
            end
            events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            state = origin(events, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
            original = original_prompt_record!(events, state, params: params)
            unless binding.fetch("original_binding_digest") == original.fetch("binding_digest")
              raise AttemptErrors::EvidenceUnavailable, "Prompt original guarded record differs"
            end
            reply = journal.mutation_result(params.fetch("mutation_id"), commit: commit)
            if reply && (reply["operation"] != "prompt_attempt" || reply["parameters_digest"] != intent.dig("payload", "binding_digest") ||
                reply["assignment_id"] != params["assignment_id"] || reply["attempt_id"] != params["attempt_id"])
              raise AttemptErrors::EvidenceUnavailable, "Prompt immutable reply differs"
            end
            completed = authenticated_prompt_completions!(events, intent, original, journal).last
            {data: {"attempt_id" => params.fetch("attempt_id"), "mutation_id" => params.fetch("mutation_id"),
              "outcome" => completed ? completed.dig("payload", "evidence", "outcome") : "uncertain",
              "intent_event_id" => intent.fetch("digest"), "outcome_event_id" => completed&.fetch("digest"),
              "generation" => journal.authority_generation(events), "journal_commit" => commit}, replayed: false}
          end
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "Prompt status evidence is malformed"
        end

        private

        def steering_key(params, map)
          [map.fetch("project_id"), params.fetch("mapping_id"), params.fetch("assignment_id"), params.fetch("attempt_id")]
        end

        def steering_principal!(params, peer, role)
          @kernel.live!(peer)
          map = @deployment.verify!(params.fetch("mapping_id"), kernel: @kernel, authority_state: true)
          allowed = if role == :launcher
            peer.values_at("uid", "gid", "groups") == map.values_at("launcher_uid", "launcher_gid", "launcher_groups")
          elsif role == :supervisor
            project = @deployment.project(map.fetch("project_id"))
            credentials = project.fetch("peer_credentials")[peer.fetch("uid").to_s]
            project.fetch("supervisor_uids").include?(peer.fetch("uid")) && credentials &&
              peer.values_at("gid", "groups") == credentials.values_at("gid", "groups")
          end
          raise AttemptErrors::UnauthorizedIdentity, "Prompt requires installed launcher or supervisor" unless allowed
          map
        end

        def finish_prompt_outcome!(params, map, intent, evidence, peer: nil, completion_ack: false)
          journal = journal_for(map)
          with_containment_exclusion(params, map, journal) do
            @mutex.synchronize do
              authentication = lambda do |events, _commit, _generation|
                state = origin(events, **params.slice("assignment_id", "attempt_id", "mapping_id").transform_keys(&:to_sym))
                if peer
                  @kernel.live!(peer)
                  unless @kernel.same?(state.fetch("launcher_identity"), peer)
                    raise AttemptErrors::UnauthorizedIdentity, "Completion reporting requires exact original launcher incarnation"
                  end
                end
                original_prompt_record!(events, state, params: params)
              end
              if peer
                selected = journal.ref_value
                current = journal.read_events(params.fetch("assignment_id"), commit: selected).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
                authenticated = authentication.call(current, selected, journal.authority_generation(current))
                journal.send(:validate_prompt_evidence!, evidence, authenticated.fetch("origin"))
              end
              result = journal.finalize_prompt(mutation_id: intent.dig("payload", "external_mutation_id"), intent_event_id: intent.fetch("digest"),
                binding_digest: intent.dig("payload", "binding_digest"), evidence: evidence, &authentication)
              accepted = result
              if %w[submitted not_issued].include?(evidence["outcome"]) && %w[submitted not_issued].include?(result.dig(:data, "outcome")) &&
                  result.dig(:data, "guarded_evidence") != evidence
                raise AttemptErrors::Conflict, "Native completion differs from accepted outcome"
              end
              if result.dig(:data, "outcome") == "uncertain" && %w[submitted not_issued].include?(evidence["outcome"])
                accepted = journal.observe_prompt_completion(mutation_id: intent.dig("payload", "external_mutation_id"), intent_event_id: intent.fetch("digest"),
                  binding_digest: intent.dig("payload", "binding_digest"), evidence: evidence, &authentication)
              end
              completion_ack ? accepted.fetch(:data).slice("outcome", "journal_commit") : result
            end
          end
        end

        def ingest_original_prompt_outcome!(params, map, result)
          journal = journal_for(map)
          intent = journal.prompt_intent(result.fetch("mutation_id"))
          unless intent && intent["digest"] == result.fetch("intent_event_id") &&
              intent.dig("payload", "binding", "original_binding_digest") == result.fetch("original_binding_digest")
            raise AttemptErrors::EvidenceUnavailable, "Original driver outcome differs from accepted issue"
          end
          finish_prompt_outcome!(params, map, intent, result.fetch("guarded_evidence"), completion_ack: true)
        end

        # An issued actor lives outside the worker unit and must be inhibited
        # for its full lifetime, even with no prompt rows or only known ACKs.
        # Accepted original actor input drainage removes the writer blocker. It never
        # changes an unknown prompt outcome. Channel absence, caller exit and
        # an empty worker cgroup cannot remove this blocker.
        def pending_prompt_issuers?(events, journal, commit)
          return false if accepted_input_inhibition?(events, journal, commit)
          return true if issued_input_actor?(events)
          events.select { |event| event["type"] == "prompt_issued" }.any? do |issued|
            external_id = issued.fetch("payload").fetch("external_mutation_id")
            intent = journal.prompt_intent(external_id, commit: commit)
            raise AttemptErrors::EvidenceUnavailable, "Prompt issuer is not canonically accepted" unless intent && intent["digest"] == issued["digest"]
            binding = intent.fetch("payload").fetch("binding")
            params = binding.slice("mapping_id", "assignment_id", "attempt_id")
            state = origin(events, **params.transform_keys(&:to_sym))
            original = original_prompt_record!(events, state, params: params)
            unless binding.fetch("original_binding_digest") == original.fetch("binding_digest")
              raise AttemptErrors::EvidenceUnavailable, "Prompt issuer original binding differs"
            end
            authenticated_prompt_completions!(events, intent, original, journal).empty?
          end
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "Prompt issuer history is malformed"
        end

        def issued_input_actor?(events)
          releases = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "release_launch" }
          return false if releases.empty?
          unless Models::EvidenceEvent.chain_valid?(events) && releases.one? &&
              releases.first.dig("payload", "data").is_a?(Hash) && releases.first.dig("payload", "data", "phase") == "issued"
            raise AttemptErrors::EvidenceUnavailable, "Original outside-unit actor issuance differs"
          end
          true
        end

        def authenticated_prompt_completions!(events, intent, original, journal)
          external_id = intent.fetch("payload").fetch("external_mutation_id")
          events.select { |event| %w[prompt_outcome prompt_completion_observed].include?(event["type"]) &&
            event.dig("payload", "intent_event_id") == intent.fetch("digest") }.select do |event|
              payload = event.fetch("payload")
              evidence = payload.fetch("evidence")
              journal.send(:validate_prompt_evidence!, evidence, original.fetch("origin"))
              expected_operation = event["type"] == "prompt_outcome" ? "prompt_attempt" : "prompt_observation"
              expected_id = expected_operation == "prompt_attempt" ? external_id : "prompt-observe.#{intent.fetch('digest')}"
              acceptance = events.find { |entry| entry["type"] == "authority_mutation" && entry["previous_digest"] == event["digest"] &&
                entry.dig("payload", "operation") == expected_operation && entry.dig("payload", "mutation_id") == expected_id }
              unless payload["external_mutation_id"] == external_id && payload["binding_digest"] == intent.dig("payload", "binding_digest") &&
                  acceptance && acceptance.dig("payload", "data", "outcome") == evidence.fetch("outcome") &&
                  acceptance.dig("payload", "data", "guarded_evidence") == evidence
                raise AttemptErrors::EvidenceUnavailable, "Prompt native completion acceptance differs"
              end
              %w[submitted not_issued].include?(evidence.fetch("outcome"))
          end
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "Prompt completion history is malformed"
        end

        # Authentication binds the whole accepted original record, including
        # its native guard. A plain process-binding digest cannot substitute.
        def original_prompt_record!(events, state, params:)
          unless state.is_a?(Hash) && state["guarded_origin"].is_a?(Hash) && state["process_binding"].is_a?(Hash)
            raise AttemptErrors::EvidenceUnavailable, "Original guarded record is unavailable"
          end
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "Original guarded record chain is corrupt"
          end
          records = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "record_launch" }
          raise AttemptErrors::EvidenceUnavailable, "Original guarded record is ambiguous or absent" unless records.size == 1
          record = records.first
          data = record.fetch("payload").fetch("data")
          unless data.is_a?(Hash) && record["attempt_id"] == params.fetch("attempt_id") &&
              %w[mapping_id assignment_id attempt_id].all? { |key| data[key] == params.fetch(key) } &&
              data["process_binding"] == state.fetch("process_binding") && data["guarded_origin"] == state.fetch("guarded_origin")
            raise AttemptErrors::EvidenceUnavailable, "Original guarded record differs from accepted launch"
          end
          binding = data.fetch("process_binding")
          origin = Ace::Herdr::Molecules::GuardedNativeOrigin.verify!(data.fetch("guarded_origin"),
            terminal_id: binding.fetch("terminal_id"), child: binding.fetch("process_identity"))
          {"binding_digest" => record.fetch("digest").dup.freeze, "origin" => origin}.freeze
        rescue KeyError, TypeError, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "Original guarded record is malformed"
        end
      end
    end
  end
end

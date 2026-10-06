# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # Internal owner call, deliberately absent from the public operation
        # allowlist. The durable winner alone may call the fixed manager. A
        # lost StartUnit reply retains admission uncertainty; replay never starts.
        def admit_native_service!(params:, peer:, role:)
          strict!(params, %w[mapping_id assignment_id attempt_id launch_ticket mutation_id expected_generation])
          unless %i[launcher supervisor].include?(role)
            raise AttemptErrors::UnauthorizedIdentity, "native admission requires an exact launch owner"
          end
          %w[assignment_id attempt_id launch_ticket mutation_id].each { |key| token!(params.fetch(key)) }
          generation!(params.fetch("expected_generation"))
          @kernel.live!(peer)
          map = @deployment.mapping(params.fetch("mapping_id"))
          journal = journal_for(map)
          input = params.reject { |key, _| key == "mutation_id" }
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical(input)))
          result = with_exclusion(params, map, journal) do
            admit_native_service_held!(params, map, journal, peer, role, digest)
          end
          complete_native_start!(params, map, journal, peer, role, result) unless result.fetch(:replayed)
          result
        ensure
          settle_native_issuer!(params, map) if map
        end

        # Private transport owner. Exact manager hook attribution precedes
        # challenge issuance; this never enters the ordinary worker dispatcher.
        def native_readiness!(mapping_id:, peer:, socket:, codec:, deadline:)
          map = @deployment.mapping(mapping_id)
          journal = journal_for(map)
          pending, key = @mutex.synchronize do
            selected = @native_issuers.select { |identity, _| identity[0] == map.fetch("project_id") && identity[1] == mapping_id }
            raise AttemptErrors::EvidenceUnavailable, "no unique live admitted issuer" unless selected.size == 1
            identity, entry = selected.first
            raise AttemptErrors::Conflict, "readiness already supplied" if entry[:report] || entry[:challenge]
            entry[:challenge] = SecureRandom.hex(32)
            [entry, identity]
          end
          params = pending.fetch(:params)
          observer = scope_observer_for(mapping_id)
          challenge = with_exclusion(params, map, journal) do
            @mutex.synchronize do
              events = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
                assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: mapping_id)
              lineage.require_open!
              server = observer.readiness_peer!(lineage, peer)
              {"version" => 1, "challenge_id" => pending.fetch(:challenge), "server_identity" => server}
            end
          end
          wire.write(socket, challenge, deadline: deadline, limit: 16_384)
          envelope = wire.read(socket, deadline: deadline, limit: 16_384)
          unless envelope.is_a?(Hash) && envelope.keys.sort == %w[challenge_id transfer version] &&
              envelope["version"] == 1 && envelope["challenge_id"] == challenge.fetch("challenge_id")
            raise ArgumentError, "private readiness upload envelope differs"
          end
          codec.receive(socket, descriptor: envelope.fetch("transfer"), purpose: :scope_boundary_observation,
            deadline: deadline) do |input|
            bytes = input.bytes.force_encoding(Encoding::UTF_8)
            raise ArgumentError, "readiness observation is not UTF-8" unless bytes.valid_encoding?
            report = JSON.parse(bytes, create_additions: false, max_nesting: 12, allow_duplicate_key: false, allow_comments: false)
            with_exclusion(params, map, journal) do
              @mutex.synchronize do
                unless @native_issuers[key].equal?(pending) && !pending[:report]
                  raise AttemptErrors::EvidenceUnavailable, "readiness issuer lifetime ended"
                end
                events = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
                lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
                  assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: mapping_id)
                lineage.require_open!
                pending[:report] = observer.verify_readiness_report!(lineage, peer, report, challenge: challenge)
              end
            end
          end
          wire.write(socket, {"version" => 1, "challenge_id" => challenge.fetch("challenge_id"), "status" => "ready"},
            deadline: deadline, limit: 16_384)
        end

        private

        def admit_native_service_held!(params, map, journal, peer, role, digest)
            result = @mutex.synchronize do
              # Visibility is current even on a historical mutation replay.
              current = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              scope_admission_owner!(params, map, current, peer, role)
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: params.fetch("mutation_id"), operation: "scope_service_admission", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |events, _commit, generation|
                state, lineage = scope_admission_owner!(params, map, events, peer, role)
                lineage.require_open!
                unless state["phase"] == "reserved" && !lineage.native_event && !lineage.child_event &&
                    events.none? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_service_admission" }
                  raise AttemptErrors::Conflict, "native activation was already admitted or launch advanced"
                end
                observer = scope_observer_for(params.fetch("mapping_id"))
                installation = observer.native_admission_ready!(lineage)
                binding = lineage.binding
                data = state.merge("scope_generation" => binding.fetch("scope_generation"),
                  "scope_binding_event_id" => lineage.binding_event.fetch("digest"),
                  "service_unit" => map.fetch("execution_scope").fetch("service_unit"), "native_admission" => "issued_uncertain",
                  "network_installation" => installation)
                unless installation.is_a?(Hash) && installation["namespace_path"] == map.fetch("execution_scope").fetch("network_namespace_path")
                  raise AttemptErrors::EvidenceUnavailable, "network verifier output names another fixed namespace path"
                end
                candidate = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: params.fetch("attempt_id"),
                  payload: {"operation" => "scope_service_admission", "data" => data.merge("generation" => generation + 1)},
                  previous_digest: events.last&.fetch("digest"))
                Molecules::ExecutionScopeLineage.new(events: events + [candidate], project_id: map.fetch("project_id"),
                  assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
                {events: [], blobs: {}, data: data}
              end
            end
            unless result.fetch(:replayed)
              @mutex.synchronize do
                raise AttemptErrors::Conflict, "native issuer already active" if @native_issuers.key?(native_issuer_key(params, map))
                @native_issuers[native_issuer_key(params, map)] = {params: params.dup.freeze, report: nil, owner: Thread.current}
              end
            end
            result
        end

        def complete_native_start!(params, map, journal, peer, role, result)
          attempt_id = params.fetch("attempt_id")
          observer = scope_observer_for(params.fetch("mapping_id"))
          issue = with_exclusion(params, map, journal) do
            @mutex.synchronize do
              events = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == attempt_id }
              _, lineage = scope_admission_owner!(params, map, events, peer, role)
              !lineage.sealed?
            end
          end
          observer.start_admitted_service! if issue
          # The pending issuer lifetime remains live through this final check
          # and cleanup. A seal cannot publish proof then permit a late start.
          with_exclusion(params, map, journal) do
            events, lineage = @mutex.synchronize do
              current = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == attempt_id }
              _, retained = scope_admission_owner!(params, map, current, peer, role)
              [current, retained]
            end
            if lineage.sealed?
              observer.stop_sealed_service!
            elsif issue
              payload = observer.complete_native_readiness!(lineage,
                @mutex.synchronize { @native_issuers.fetch(native_issuer_key(params, map)).fetch(:report) })
              @mutex.synchronize { commit_ready_native!(params, map, journal, events, lineage, payload) }
            end
          end
        rescue StandardError
          # Lost command completion is uncertain. Cleanup of the fixed service
          # must finish before the live issuer can retire its pending lifetime.
          observer.stop_sealed_service! if issue
          raise
        ensure
          settle_native_issuer!(params, map) if attempt_id
        end

        def commit_ready_native!(params, map, journal, events, lineage, payload)
          context = params.slice("mapping_id", "assignment_id", "attempt_id").merge(
            "scope_binding_event_id" => lineage.binding_event.fetch("digest"))
          journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
            mutation_id: "scope-native-#{Digest::SHA256.hexdigest(lineage.binding_event.fetch('digest'))[0, 48]}",
            operation: "scope_native_binding", parameters_digest: Digest::SHA256.hexdigest(JSON.generate(canonical(context))),
            expected_generation: journal.authority_generation(events), with_replay: true) do |current, _commit, _generation|
            fresh = Molecules::ExecutionScopeLineage.new(events: current, project_id: map.fetch("project_id"),
              assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
            fresh.require_open!
            raise AttemptErrors::Conflict, "native binding already exists" if fresh.native_event
            at = Time.now.utc
            event = Models::EvidenceEvent.build(type: "scope_native_bound", attempt_id: params.fetch("attempt_id"),
              payload: payload, previous_digest: current.last&.fetch("digest"), recorded_at: at)
            Molecules::ExecutionScopeLineage.new(events: current + [event], project_id: map.fetch("project_id"),
              assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
            {events: [{type: "scope_native_bound", payload: payload, recorded_at: at}], blobs: {}, data: context}
          end
        end

        def native_issuer_key(params, map)
          [map.fetch("project_id"), params.fetch("mapping_id"), params.fetch("assignment_id"), params.fetch("attempt_id")].freeze
        end

        def settle_native_issuer!(params, map)
          @mutex.synchronize do
            key = native_issuer_key(params, map)
            pending = @native_issuers[key]
            @native_issuers.delete(key) if pending && pending[:owner].equal?(Thread.current)
          end
        end

        def native_issuer_pending!(params, map)
          if @native_issuers.key?(native_issuer_key(params, map))
            raise AttemptErrors::EvidenceUnavailable, "native issuance is still pending"
          end
        end

        def scope_admission_owner!(params, map, events, peer, role)
          state = states(events)[params.fetch("attempt_id")]
          unless state && state["mapping_id"] == params.fetch("mapping_id") &&
              state["launch_ticket"] == params.fetch("launch_ticket") &&
              (role == :supervisor || @kernel.same?(state.fetch("launcher_identity"), peer))
            raise AttemptErrors::UnauthorizedIdentity, "native admission launch origin differs"
          end
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
          [state, lineage]
        end
      end
    end
  end
end

# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      module OrdinaryAttemptStart
        START_KEYS = %w[assignment_id attempt_id expected_generation head pane].freeze

        private

        def start_attempt(request, peer, role, deadline)
          params = request.fetch("params")
          strict!(params, START_KEYS)
          %w[assignment_id attempt_id].each { |key| token!(params.fetch(key)) }
          token!(request.fetch("mutation_id"))
          unless params.fetch("head").is_a?(String) && params.fetch("head").match?(/\A[0-9a-f]{40}\z/)
            raise ArgumentError, "ordinary start HEAD is invalid"
          end
          unless %i[supervisor worker].include?(role) && params.fetch("expected_generation").is_a?(Integer) && params.fetch("expected_generation") == 0
            raise AttemptErrors::UnauthorizedIdentity, "ordinary start requires an installed worker and a new attempt"
          end
          commit = @journal.ref_value
          registered = registration(params.fetch("assignment_id"), commit: commit)
          raise AttemptErrors::NotFound, "ordinary work is not registered" unless registered
          work = registered_work(registered, commit, deadline)
          scope = work.manifest.fetch("scope")
          keys = [@exclusion.task_key(registered.fetch("task_id")), @exclusion.assignment_key(params.fetch("assignment_id"))]
          @exclusion.with_shared_multi(keys, deadline: deadline) do
            if @journal.mutation_result(request.fetch("mutation_id"))
              # Work may legitimately have advanced since an acknowledged or
              # lost start reply. Recover its original head, never recapture it.
              identity = @admission.identity!(peer: peer, pane: params.fetch("pane"), deadline: deadline)
              return @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: request.fetch("mutation_id"), operation: "start_attempt", parameters_digest: start_digest(params, peer, identity),
                expected_generation: 0, with_replay: true, deadline: deadline,
                replay_authorizer: -> { authorize_start_replay!(request, peer, role, deadline) }) do
                  raise AttemptErrors::EvidenceUnavailable, "accepted ordinary start disappeared"
                end
            end
            # Only the installed admission can observe the actual native owner
            # and worker checkout. It performs no launch or delivery effect.
            observed = @admission.execution!(peer: peer, pane: params.fetch("pane"), head: params.fetch("head"), deadline: deadline)
            identity = observed.fetch(:identity)
            principal = {"uid" => peer.fetch("uid"), "actor" => identity.actor}
            digest = start_digest(params, peer, identity)
            queue = OrdinaryQueue.new(work: work, root: @input_root).transition(operation: :activate)
            queue_sha = Digest::SHA256.hexdigest(queue.bytes)
            queue_path = "execution/definitions/#{params.fetch('assignment_id')}-queue-#{queue_sha}.json"
            authorize!(request, peer, role, deadline)
            @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "start_attempt", parameters_digest: digest,
              expected_generation: 0, with_replay: true, deadline: deadline,
              replay_authorizer: -> { authorize_start_replay!(request, peer, role, deadline) }) do |events, prefix, _generation|
              authorize!(request, peer, role, deadline)
              unless @admission.identity!(peer: peer, pane: params.fetch("pane"), deadline: deadline) == identity
                raise AttemptErrors::UnauthorizedIdentity, "ordinary native worker changed before start acceptance"
              end
              unless events.empty? && registration(params.fetch("assignment_id"), commit: prefix) == registered
                raise AttemptErrors::Conflict, "ordinary start registration or attempt changed"
              end
              # A different request ID is not permission to repeat accepted
              # work, including after a terminal result. Recovery retains the
              # original attempt; new work needs a new accepted definition.
              if @journal.derived_attempts(params.fetch("assignment_id"), commit: prefix).any?
                raise AttemptErrors::Conflict, "ordinary scope already has an attempt; reconcile its original execution"
              end
              {events: [
                {type: "intent", payload: {"assignment_id" => params.fetch("assignment_id"), "scope" => scope,
                  "project_id" => @project, "task_id" => registered.fetch("task_id"), "base_head" => observed.fetch(:checkout).fetch("head")}},
                {type: "process_start", payload: {"actor" => identity.actor, "role" => identity.role, "runtime" => identity.runtime,
                  "pid" => identity.process_pid, "process_identity" => identity.runtime_binding.fetch("process_identity"),
                  "runtime_binding" => identity.runtime_binding, "checkout" => observed.fetch(:checkout)}}
              ], blobs: {queue_path => queue.bytes}, data: {
                "authority" => "ordinary", "assignment_id" => params.fetch("assignment_id"), "attempt_id" => params.fetch("attempt_id"),
                "project_id" => @project, "scope" => scope, "state" => "running", "started_by" => principal,
                "base_head" => observed.fetch(:checkout).fetch("head"), "runtime_binding" => identity.runtime_binding,
                "queue_ref" => queue_path, "queue_sha256" => queue_sha}}
            end
          end
        end

        def start_digest(params, peer, identity)
          Atoms::EvidenceDigest.digest({"params" => params, "project_id" => @project,
            "principal" => {"uid" => peer.fetch("uid"), "actor" => identity.actor}})
        end

        def authorize_start_replay!(request, peer, role, deadline)
          authorize!(request, peer, role, deadline)
          params = request.fetch("params")
          identity = @admission.identity!(peer: peer, pane: params.fetch("pane"), deadline: deadline)
          start_replay_owner!(params, identity)
        end

        def registered_work(registered, commit, deadline)
          reference = registered.fetch("prepared_work")
          bytes = @journal.bounded_blob(registered.fetch("prepared_bundle_ref"), commit: commit,
            max_bytes: registered.fetch("prepared_bundle_bytes"))
          work = PreparedWork.admit(bytes: bytes, head: reference.fetch("prepared_head"), tree: reference.fetch("prepared_tree"),
            sha256: registered.fetch("prepared_bundle_sha256"), size: registered.fetch("prepared_bundle_bytes"),
            root: @input_root, deadline: deadline)
          unless work.reference(head: reference.fetch("prepared_head"), tree: reference.fetch("prepared_tree")) == reference &&
              work.manifest.values_at("assignment_id", "project_id", "task_id") == registered.values_at("assignment_id", "project_id", "task_id") &&
              Digest::SHA256.hexdigest(work.definition_bytes(head: reference.fetch("prepared_head"), tree: reference.fetch("prepared_tree"))) == registered.fetch("definition_digest")
            raise AttemptErrors::EvidenceUnavailable, "ordinary prepared registration bytes differ"
          end
          work
        end

        def start_replay_owner!(params, identity)
          events = @journal.read_events(params.fetch("assignment_id"))
            .select { |event| event.fetch("attempt_id") == params.fetch("attempt_id") }
          unless Models::EvidenceEvent.chain_valid?(events) && events.count { |event| event["type"] == "process_start" } == 1
            raise AttemptErrors::EvidenceUnavailable, "ordinary start evidence is unavailable"
          end
          owner = events.find { |event| event["type"] == "process_start" }.fetch("payload")
          unless owner.values_at("actor", "role", "runtime", "runtime_binding") ==
              [identity.actor, identity.role, identity.runtime, identity.runtime_binding]
            raise AttemptErrors::UnauthorizedIdentity, "ordinary replay belongs to its original native worker"
          end
        end
      end
    end
  end
end

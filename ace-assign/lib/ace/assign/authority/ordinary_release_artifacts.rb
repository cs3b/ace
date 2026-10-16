# frozen_string_literal: true

require_relative "release_artifact_manifest"
require_relative "candidate_transfer"

module Ace
  module Assign
    module Authority
      # Retention is a canonical input, never a publication permit or result.
      # Native/candidate/review and release policy are rechecked at every CAS.
      module OrdinaryReleaseArtifacts
        RELEASE_OPERATIONS = %w[retain_release_artifact].freeze
        RELEASE_TRANSFERS = {"retain_release_artifact" =>
          {direction: :upload, purpose: :release_artifact, roles: %i[worker supervisor]}}.freeze
        RELEASE_PARAMETERS = %w[assignment_id attempt_id head candidate_generation pane expected_generation
          authorization manifest transfer].freeze

        # Read an accepted import at the current immutable canonical prefix only.
        # Historical commit selection is not supported by the native origin reader.
        # The later effect consumer must independently admit its fresh scope,
        # candidate, review, authorization and fixed executor before dispatch.
        def release_artifact_at!(events:, commit:, artifact_id:)
          token!(artifact_id)
          unless commit && Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "release artifact history is unavailable"
          end
          accepted = events.select { |event| event["type"] == "authority_mutation" &&
            event.dig("payload", "operation") == "retain_release_artifact" && event.dig("payload", "mutation_id") == artifact_id }
          data = accepted.one? && accepted.first.dig("payload", "data")
          unless data && data["artifact_id"] == artifact_id && data["input_digest"] == Atoms::EvidenceDigest.digest(data.fetch("input"))
            raise AttemptErrors::EvidenceUnavailable, "release artifact acceptance is unavailable"
          end
          origin = data.fetch("producer_origin")
          retained = @journal.read_events(origin.fetch("assignment_id"), commit: commit)
            .select { |event| event["attempt_id"] == origin.fetch("attempt_id") }
          unless retained == events && ordinary_origin_at!(events, commit, running: false) == origin
            raise AttemptErrors::EvidenceUnavailable, "release artifact original scope differs"
          end
          context = release_evidence_context(data.fetch("input"), origin, data.fetch("authorization"), artifact_id)
          bytes = Molecules::CanonicalEvidence.new(journal: @journal).read(data.fetch("artifact"), **context, commit: commit)
          unless bytes.bytesize == data.dig("input", "publication", "artifact_bytes") &&
              Digest::SHA256.hexdigest(bytes) == data.dig("input", "target", "artifact_digest")
            raise AttemptErrors::EvidenceUnavailable, "release artifact retained bytes differ"
          end
          data.merge("bytes" => bytes)
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "release artifact acceptance is incomplete"
        end

        private

        def validate_ordinary_release!(request)
          params = request.fetch("params")
          strict!(params, RELEASE_PARAMETERS)
          %w[assignment_id attempt_id authorization].each { |key| token!(params.fetch(key)) }
          token!(request.fetch("mutation_id"))
          unless params["head"].is_a?(String) && CandidateTransfer::SHA.match?(params["head"]) &&
              %w[candidate_generation expected_generation].all? { |key| params[key].is_a?(Integer) && params[key].positive? }
            raise ArgumentError, "invalid release artifact candidate selection"
          end
          ReleaseArtifactManifest.validate!(params.fetch("manifest"))
        end

        def authorize_ordinary_release!(request, peer, role, deadline)
          validate_ordinary_release!(request)
          params = request.fetch("params")
          with_scope(assignment: params.fetch("assignment_id"), attempt: params.fetch("attempt_id"), deadline: deadline) do
            prefix = @journal.ref_value
            release_context_at!(request, peer, role, deadline, result_events(params, prefix), prefix)
          end
        end

        # Caller holds lifecycle exclusion before entering the journal writer.
        # This method never acquires another lifecycle lock or trusts a path.
        def release_context_at!(request, peer, role, deadline, events, commit)
          authorize!(request, peer, role, deadline)
          unless %i[worker supervisor].include?(role) && @release_authorizer
            raise AttemptErrors::UnauthorizedIdentity, "installed release artifact authorization is unavailable"
          end
          params = request.fetch("params")
          origin = origin_at!(events: events, commit: commit)
          current = candidate_at!(events: events, commit: commit, head: params.fetch("head"), generation: params.fetch("candidate_generation"))
          reference = candidate_reference_at!(events: events, commit: commit, head: params.fetch("head"), generation: params.fetch("candidate_generation"))
          observed = @admission.execution!(peer: peer, pane: params.fetch("pane"), head: current.fetch("head"), deadline: deadline)
          unless observed.fetch(:identity).runtime_binding == origin.fetch("runtime_binding")
            raise AttemptErrors::UnauthorizedIdentity, "release artifact producer native identity changed"
          end
          review_at!(events: events, commit: commit, head: current.fetch("head"), generation: current.fetch("candidate_generation"))
          input = ReleaseArtifactManifest.publication_input(manifest: params.fetch("manifest"), candidate: current, reference: reference)
          binding = params.slice("assignment_id", "attempt_id", "authorization").merge(
            "operation" => "publish", "project_id" => @project, "candidate_head" => current.fetch("head"),
            "caller_uid" => origin.dig("runtime_binding", "process_identity", "uid"),
            "input_digest" => Atoms::EvidenceDigest.digest(input), "target" => input.fetch("target"))
          unless @release_authorizer.call(binding)
            raise AttemptErrors::UnauthorizedIdentity, "release artifact manifest is not authorized"
          end
          {input: input, binding: binding, origin: origin}
        rescue SecurityError
          raise AttemptErrors::UnauthorizedIdentity, "release artifact manifest authorization is unavailable"
        end

        def retain_release_artifact(request, peer, role, deadline, transfer)
          validate_ordinary_release!(request)
          unless transfer && transfer.count == 1
            raise AttemptErrors::MalformedTransfer, "release artifact requires its one bounded binary transfer"
          end
          params = request.fetch("params")
          with_scope(assignment: params.fetch("assignment_id"), attempt: params.fetch("attempt_id"), deadline: deadline) do
            prefix = @journal.ref_value
            release_context_at!(request, peer, role, deadline, result_events(params, prefix), prefix)
            bytes = transfer.bytes.dup.freeze
            ReleaseArtifactManifest.verify!(bytes, params.fetch("manifest"))
            digest = Atoms::EvidenceDigest.digest("project_id" => @project, "params" => params)
            recheck = lambda do
              current = @journal.ref_value
              release_context_at!(request, peer, role, deadline, result_events(params, current), current)
            end
            @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: "retain_release_artifact", parameters_digest: digest,
              expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
              replay_authorizer: recheck) do |events, commit, _generation|
              selected = release_context_at!(request, peer, role, deadline, events, commit)
              artifact_id = request.fetch("mutation_id")
              context = release_evidence_context(selected.fetch(:input), selected.fetch(:origin), params.fetch("authorization"), artifact_id)
              plan = Molecules::CanonicalEvidence.new(journal: @journal).import_plan(**context,
                artifacts: [bytes], admitted_after_event_digest: events.last.fetch("digest"))
              plan.merge(data: {"artifact_id" => artifact_id, "input" => selected.fetch(:input),
                "input_digest" => selected.fetch(:binding).fetch("input_digest"), "artifact" => plan.fetch(:references).first,
                "authorization" => params.fetch("authorization"), "producer_origin" => selected.fetch(:origin)})
            end
          end
        end

        def release_evidence_context(input, origin, authorization, artifact_id)
          {kind: "release-artifact", project_id: @project, assignment_id: origin.fetch("assignment_id"),
            attempt_id: origin.fetch("attempt_id"), peer_uid: origin.dig("runtime_binding", "process_identity", "uid"),
            binding: {"input" => input, "producer_origin" => origin, "authorization" => authorization},
            request_id_or_event_id: artifact_id, generation: input.fetch("publication").fetch("candidate_reference").fetch("candidate_generation")}
        end
      end
    end
  end
end

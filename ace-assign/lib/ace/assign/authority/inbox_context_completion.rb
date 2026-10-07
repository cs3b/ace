# frozen_string_literal: true

require "ace/herdr/molecules/inbox_context_effect_binding"
require_relative "historical_inbox_evidence"
require_relative "original_inbox_selection"

module Ace
  module Assign
    module Authority
      # A read-only view of the existing qjl. It never enters context admission,
      # lifecycle exclusion, retained Inbox inventory or the current native actor.
      class InboxContextCompletion
        OPERATIONS = ["inbox_context_completion"].freeze
        PARAMETERS = %w[assignment_id attempt_id effect_binding event_id inbox_context_id mapping_id reconciliation_digest].freeze

        def initialize(deployment:, history:, authority_id:, journals:,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @deployment, @history, @authority_id, @journals, @kernel = deployment, history, authority_id, journals, kernel
        end

        def dispatch(request:, peer:, role:)
          unless request.keys.sort == %w[mutation_id operation params project_id version] &&
              request["version"].is_a?(Integer) && request["version"] == 1 && request["operation"] == OPERATIONS.first && request["mutation_id"].nil? &&
              request["params"].is_a?(Hash) && request["params"].keys.sort == PARAMETERS && role == :context_owner
            raise AttemptErrors::UnauthorizedIdentity, "context completion query differs"
          end
          params = request.fetch("params")
          binding = Ace::Herdr::Molecules::InboxContextEffectBinding.verify!(params.fetch("effect_binding"))
          map = @deployment.mapping(params.fetch("mapping_id"))
          unless map.fetch("authority_id") == @authority_id && map.fetch("project_id") == request.fetch("project_id") &&
              binding.slice(*%w[assignment_id attempt_id event_id inbox_context_id mapping_id]) == params.slice(*%w[assignment_id attempt_id event_id inbox_context_id mapping_id]) &&
              binding.fetch("project_id") == map.fetch("project_id")
            raise AttemptErrors::UnauthorizedIdentity, "context completion mapping differs"
          end
          context = @deployment.inbox_context(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          unless context.fetch("owner_credentials").values_at("uid", "gid", "groups") == peer.values_at("uid", "gid", "groups")
            raise AttemptErrors::UnauthorizedIdentity, "context completion requires its fixed owner"
          end
          @kernel.live!(peer)
          journal = @journals.fetch(map.fetch("project_id"))
          project = @deployment.project(map.fetch("project_id"))
          unless journal.evidence_mode == :protected && project.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root") ==
              [journal.repo_root, journal.ref, journal.checkout_root]
            raise AttemptErrors::EvidenceUnavailable, "context completion journal association differs"
          end
          commit = journal.ref_value
          journal.verify_commit!(commit)
          events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          original, original_map = original_selection!(events, params, map, journal, commit)
          result = HistoricalInboxEvidence.new(journal: journal, deployment: original, history: @history)
            .verify_selected!(events: events, params: params, map: original_map, commit: commit,
              reconciliation_digest: params.fetch("reconciliation_digest"), mutation_id: binding.fetch("mutation_id"))
          reply = result.fetch("reply").fetch("payload")
          unless reply["mutation_id"] == binding.fetch("mutation_id") && reply.dig("data", "context_operation") == binding
            raise AttemptErrors::EvidenceUnavailable, "canonical context operation completion differs"
          end
          @kernel.live!(peer)
          proof = result.fetch("reconciliation").fetch("payload")
          data = {"schema" => "ace.assign.inbox-context-completion/v1", "effect_binding" => binding,
            "effect_binding_digest" => Ace::Herdr::Molecules::InboxContextEffectBinding.digest(binding),
            "commit" => commit, "reconciliation_digest" => result.fetch("reconciliation").fetch("digest"),
            "reply_digest" => result.fetch("reply").fetch("digest"), "state" => proof.fetch("state"),
            "claim_generation" => proof.fetch("claim_generation"), "registration" => proof.fetch("registration"),
            "binding" => proof.fetch("binding"), "receipt_ref" => proof.fetch("receipt_ref"), "signature_ref" => proof.fetch("signature_ref")}
          raise AttemptErrors::EvidenceUnavailable, "context completion exceeds frame bound" if JSON.generate(data).bytesize > 15_360
          {data: immutable(data), replayed: false}
        rescue KeyError, TypeError, ArgumentError, NoMethodError, Ace::Herdr::Error, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "context completion evidence is unavailable"
        end

        private

        def original_selection!(events, params, map, journal, commit)
          OriginalInboxSelection.new(history: @history, authority_id: @authority_id)
            .load!(events: events, params: params, map: map, journal: journal, commit: commit)
        end

        def immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
      end
    end
  end
end

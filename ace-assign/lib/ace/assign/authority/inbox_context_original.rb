# frozen_string_literal: true

require_relative "original_inbox_selection"
require_relative "../molecules/original_launch_binding"
require_relative "../molecules/execution_scope_lineage"

module Ace
  module Assign
    module Authority
      # Canonical original identity only. No native thread, effect permission,
      # live process observation, context lock or journal mutation is returned.
      class InboxContextOriginal
        OPERATIONS = ["inbox_context_original"].freeze
        PARAMETERS = %w[assignment_id attempt_id event_id inbox_context_id mapping_id payload_sha256 purpose receipt_key_sha256].freeze
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        SHA = /\A[0-9a-f]{64}\z/

        def initialize(deployment:, history:, authority_id:, journals:,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          @deployment, @history, @authority_id, @journals, @kernel = deployment, history, authority_id, journals, kernel
        end

        def dispatch(request:, peer:, role:)
          unless request.is_a?(Hash) && request.keys.sort == %w[mutation_id operation params project_id version] &&
              request["version"].is_a?(Integer) && request["version"] == 1 && request["operation"] == OPERATIONS.first &&
              request["mutation_id"].nil? && role == :context_owner && request["params"].is_a?(Hash) &&
              request["params"].keys.sort == PARAMETERS
            raise AttemptErrors::UnauthorizedIdentity, "original inbox query differs"
          end
          params = request.fetch("params")
          unless %w[assignment_id attempt_id event_id inbox_context_id mapping_id].all? { |key| params[key].is_a?(String) && TOKEN.match?(params[key]) } &&
              %w[payload_sha256 receipt_key_sha256].all? { |key| params[key].is_a?(String) && SHA.match?(params[key]) } &&
              %w[enqueue deliver].include?(params["purpose"])
            raise AttemptErrors::UnauthorizedIdentity, "original inbox selectors differ"
          end
          map = @deployment.mapping(params.fetch("mapping_id"))
          context = @deployment.inbox_context(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          unless map.values_at("authority_id", "project_id") == [@authority_id, request.fetch("project_id")] &&
              context.fetch("owner_credentials").values_at("uid", "gid", "groups") == peer.values_at("uid", "gid", "groups")
            raise AttemptErrors::UnauthorizedIdentity, "original inbox query requires its fixed owner"
          end
          @kernel.live!(peer)
          journal = @journals.fetch(map.fetch("project_id"))
          project = @deployment.project(map.fetch("project_id"))
          unless journal.evidence_mode == :protected && project.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root") ==
              [journal.repo_root, journal.ref, journal.checkout_root]
            raise AttemptErrors::EvidenceUnavailable, "original inbox journal association differs"
          end
          commit = journal.ref_value
          journal.verify_commit!(commit)
          events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
          original, original_map = OriginalInboxSelection.new(history: @history, authority_id: @authority_id)
            .load!(events: events, params: params, map: map, journal: journal, commit: commit)
          original_context = original.inbox_context(params.fetch("mapping_id"), params.fetch("inbox_context_id"))
          unless original_context.fetch("native_mapping_id") == params.fetch("mapping_id")
            raise AttemptErrors::EvidenceUnavailable, "original inbox native mapping differs"
          end
          key = @history.public_key!(sha256: params.fetch("receipt_key_sha256"))
          unless Digest::SHA256.hexdigest(key.public_to_der) == params.fetch("receipt_key_sha256")
            raise AttemptErrors::EvidenceUnavailable, "original inbox key differs"
          end
          lineage = Molecules::ExecutionScopeLineage.new(events: events, project_id: original_map.fetch("project_id"),
            assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"), mapping_id: params.fetch("mapping_id"))
          child = lineage.child_event&.dig("payload", "original_process_binding")
          records = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "record_launch" }
          raise AttemptErrors::EvidenceUnavailable, "original inbox launch missing" unless records.one? && child
          state = records.first.fetch("payload").fetch("data")
          raise AttemptErrors::EvidenceUnavailable, "original inbox child differs" unless state.fetch("process_binding") == child
          guarded = Molecules::OriginalLaunchBinding.verify!(events: events, state: state, params: params)
          registration = {"event_id" => params.fetch("event_id"), "attempt_id" => params.fetch("attempt_id"),
            "payload_sha256" => params.fetch("payload_sha256"), "receipt_key_sha256" => params.fetch("receipt_key_sha256")}
          bindings = events.select { |event| event["type"] == "inbox_binding" && event.dig("payload", "event_id") == params.fetch("event_id") }
          unless bindings.size <= 1 && (params.fetch("purpose") == "enqueue" || bindings.one?) && bindings.all? { |event|
            event.fetch("payload") == {"attempt_id" => params.fetch("attempt_id"), "event_id" => params.fetch("event_id"),
              "inbox_context_id" => params.fetch("inbox_context_id"), "registration" => registration} }
            raise AttemptErrors::EvidenceUnavailable, "original inbox registration differs"
          end
          digests = [guarded.fetch("binding_digest"), lineage.native_event.fetch("digest"), lineage.child_event.fetch("digest")] + bindings.map { |event| event.fetch("digest") }
          journal.event_commits!(assignment_id: params.fetch("assignment_id"), event_digests: digests, commit: commit)
          @kernel.live!(peer)
          data = params.slice("assignment_id", "attempt_id", "event_id", "inbox_context_id", "mapping_id", "purpose")
            .merge("schema" => "ace.assign.inbox-context-original/v1", "project_id" => map.fetch("project_id"),
              "commit" => commit, "registration" => registration, "registered" => bindings.one?,
              "original_binding_digest" => guarded.fetch("binding_digest"), "process_binding" => child,
              "guarded_origin" => guarded.fetch("origin"), "native_binding" => lineage.native_event.fetch("payload"))
          raise AttemptErrors::EvidenceUnavailable, "original inbox projection exceeds bound" if JSON.generate(data).bytesize > 15_360
          {data: immutable(data), replayed: false}
        rescue KeyError, TypeError, ArgumentError, NoMethodError, Ace::Herdr::Error, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "original inbox evidence is unavailable"
        end

        private

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

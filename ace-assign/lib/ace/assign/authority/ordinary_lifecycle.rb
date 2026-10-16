# frozen_string_literal: true

require "ace/herdr"
require_relative "prepared_work"
require_relative "assignment_definition"
require_relative "ordinary_queue"
require_relative "ordinary_attempt_start"
require_relative "ordinary_progress"
require_relative "ordinary_results"
require_relative "ordinary_completion"
require_relative "ordinary_supervisor"
require_relative "ordinary_reviews"
require_relative "ordinary_merge_evidence"
require_relative "ordinary_release_artifacts"
require_relative "../molecules/lifecycle_exclusion"

module Ace
  module Assign
    module Authority
      # Ordinary lifecycle uses the existing canonical execution ref and CAS.
      # The installed Lab composition supplies one journal and exclusion owner
      # shared with HITL and merge. No requester cache supplies accepted state.
      class OrdinaryLifecycle
        include OrdinaryAttemptStart
        include OrdinaryProgress
        include OrdinaryResults
        include OrdinaryCompletion
        include OrdinarySupervisor
        include OrdinaryReviews
        include OrdinaryMergeEvidence
        include OrdinaryReleaseArtifacts
        OPERATIONS = (%w[register_assignment registration_status start_attempt finish merge_evidence candidate_reference] + OrdinaryProgress::PROGRESS_OPERATIONS + OrdinaryResults::RESULT_OPERATIONS + OrdinarySupervisor::SUPERVISOR_OPERATIONS + OrdinaryReviews::REVIEW_OPERATIONS + OrdinaryReleaseArtifacts::RELEASE_OPERATIONS).freeze
        TRANSFER_OPERATIONS = {"register_assignment" => {direction: :upload, purpose: :candidate, roles: [:supervisor]}}
          .merge(OrdinaryProgress::PROGRESS_TRANSFERS).merge(OrdinaryResults::RESULT_TRANSFERS).merge(OrdinaryReviews::REVIEW_TRANSFERS).merge(OrdinaryReleaseArtifacts::RELEASE_TRANSFERS).freeze
        REGISTER_KEYS = %w[assignment_id definition_digest prepared_head prepared_tree manifest_sha256 expected_generation pane transfer].freeze

        def initialize(project:, admission:, journal:, exclusion:, input_root:, inbox: nil, command_evidence: nil, release_authorizer: nil)
          @project, @admission, @journal, @exclusion = project, admission, journal, exclusion
          @ordinary_scope_mutex, @ordinary_scopes = Mutex.new, {}
          @input_root = PrivateDirectory.verify!(input_root)
          unless inbox.nil? || inbox.is_a?(Ace::Herdr::Organisms::Inbox)
            raise ArgumentError, "ordinary completion requires the installed Inbox owner"
          end
          unless release_authorizer.nil? || release_authorizer.respond_to?(:call)
            raise ArgumentError, "release artifact authorization requires its installed policy owner"
          end
          @inbox, @command_evidence, @release_authorizer = inbox, command_evidence, release_authorizer
        end

        def authorize_transfer!(request:, peer:, role:, deadline:)
          authorize!(request, peer, role, deadline)
          if OrdinaryReleaseArtifacts::RELEASE_TRANSFERS.key?(request.fetch("operation"))
            authorize_ordinary_release!(request, peer, role, deadline)
            return
          end
          if OrdinaryReviews::REVIEW_TRANSFERS.key?(request.fetch("operation"))
            authorize_ordinary_review!(request, peer, role, deadline)
            return
          end
          if OrdinaryResults::RESULT_TRANSFERS.key?(request.fetch("operation"))
            validate_result!(request)
            authorize_start_replay!(request, peer, role, deadline) if request.fetch("operation") == "submit_result"
            return
          end
          if OrdinaryProgress::PROGRESS_TRANSFERS.key?(request.fetch("operation"))
            validate_progress!(request)
            return
          end
          unless request.fetch("operation") == "register_assignment" && role == :supervisor
            raise AttemptErrors::UnauthorizedIdentity, "ordinary registration requires the installed supervisor"
          end
          validate_registration!(request)
        end

        def dispatch(request:, peer:, role:, deadline:, transfer: nil)
          authorize!(request, peer, role, deadline)
          return ordinary_review_operation(request, peer, role, deadline, transfer) if OrdinaryReviews::REVIEW_OPERATIONS.include?(request.fetch("operation"))
          case request.fetch("operation")
          when "retain_release_artifact"
            retain_release_artifact(request, peer, role, deadline, transfer)
          when "candidate_reference"
            raise ArgumentError, "candidate reference read forbids transfer" if transfer
            ordinary_candidate_reference(request, peer, role, deadline)
          when "merge_evidence"
            raise ArgumentError, "merge evidence read forbids transfer" if transfer
            ordinary_merge_evidence(request, peer, role, deadline)
          when "supervisor_status", "adopt_supervisor"
            raise ArgumentError, "ordinary supervisor operation forbids transfer" if transfer
            supervisor_operation(request, peer, role, deadline)
          when "registration_status"
            strict!(request.fetch("params"), %w[assignment_id])
            raise ArgumentError, "status mutation must be null" unless request.fetch("mutation_id").nil?
            assignment = request.fetch("params").fetch("assignment_id")
            token!(assignment)
            commit = @journal.ref_value
            data = registration(assignment, commit: commit) || {"assignment_id" => assignment, "generation" => 0}
            {data: data.merge("journal_commit" => commit), replayed: false}
          when "register_assignment"
            authorize_transfer!(request: request, peer: peer, role: role, deadline: deadline)
            register(request, peer, deadline, transfer)
          when "start_attempt"
            raise ArgumentError, "ordinary start forbids transfer" if transfer
            start_attempt(request, peer, role, deadline)
          when "assignment_snapshot"
            raise ArgumentError, "ordinary snapshot forbids upload" if transfer
            assignment_snapshot(request, peer, role, deadline)
          when "queue_start", "queue_finish", "queue_fail"
            progress(request, peer, role, deadline, transfer)
          when "submit_result", "result_status", "result_snapshot"
            ordinary_result(request, peer, role, deadline, transfer)
          when "finish"
            raise ArgumentError, "ordinary completion forbids transfer" if transfer
            finish_result(request, peer, role, deadline)
          else
            raise ArgumentError, "unknown ordinary lifecycle operation"
          end
        end

        private

        def register(request, peer, deadline, transfer)
          params = request.fetch("params")
          # Native observation and candidate subprocesses happen before CAS.
          identity = @admission.identity!(peer: peer, pane: params.fetch("pane"), deadline: deadline)
          unless identity.role == "coordinator"
            raise AttemptErrors::UnauthorizedIdentity, "ordinary registration native owner differs"
          end
          raise AttemptErrors::MalformedTransfer, "prepared input requires one bundle" unless transfer && transfer.count == 1
          bytes = transfer.bytes.freeze
          descriptor = params.fetch("transfer")
          work = PreparedWork.admit(bytes: bytes, head: params.fetch("prepared_head"), tree: params.fetch("prepared_tree"),
            sha256: descriptor.fetch("sha256"), size: descriptor.fetch("bytes"), root: @input_root, deadline: deadline)
          unless work.manifest.values_at("assignment_id", "project_id") == [params.fetch("assignment_id"), @project] &&
              work.manifest_sha256 == params.fetch("manifest_sha256")
            raise ArgumentError, "ordinary prepared assignment association differs"
          end
          definition = work.definition_bytes(head: params.fetch("prepared_head"), tree: params.fetch("prepared_tree"))
          assignment = AssignmentDefinition.parse(bytes: definition, digest: params.fetch("definition_digest"),
            assignment_id: params.fetch("assignment_id"), project_id: @project)
          # Campaign registration needs its existing canonical campaign owner;
          # it cannot be manufactured by attaching unchecked parent metadata.
          if assignment.review_campaign || assignment.campaign_execution
            raise AttemptErrors::EvidenceUnavailable, "ordinary campaign registration requires its campaign owner"
          end
          principal = {"uid" => peer.fetch("uid"), "actor" => identity.actor}
          queue = OrdinaryQueue.new(work: work, root: @input_root)
          queue_sha = Digest::SHA256.hexdigest(queue.bytes)
          digest = Atoms::EvidenceDigest.digest({"params" => params, "project_id" => @project, "principal" => principal})
          keys = [@exclusion.task_key(assignment.task_id), @exclusion.assignment_key(assignment.id)]
          @exclusion.with_shared_multi(keys, deadline: deadline) do
            # Replay bypasses the CAS callback; current authority is mandatory
            # before that lookup as well as on every fresh CAS attempt.
            authorize!(request, peer, :supervisor, deadline)
            @journal.mutate(assignment_id: assignment.id, attempt_id: "definition-#{assignment.id}",
              mutation_id: request.fetch("mutation_id"), operation: "register_assignment", parameters_digest: digest,
              expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
              replay_authorizer: -> { authorize!(request, peer, :supervisor, deadline) }) do |events, commit, _generation|
              authorize!(request, peer, :supervisor, deadline)
              unless events.empty? && registration(assignment.id, commit: commit).nil?
                raise AttemptErrors::Conflict, "ordinary assignment is already registered; retain its original definition"
              end
              bundle_sha = Digest::SHA256.hexdigest(bytes)
              definition_path = "execution/definitions/#{assignment.id}-#{params.fetch('definition_digest')}.json"
              bundle_path = "execution/prepared/#{assignment.id}-#{bundle_sha}.bundle"
              queue_path = "execution/definitions/#{assignment.id}-queue-#{queue_sha}.json"
              {events: [], blobs: {definition_path => definition, bundle_path => bytes, queue_path => queue.bytes}, data: {
                "authority" => "ordinary", "assignment_id" => assignment.id, "project_id" => @project,
                "task_id" => assignment.task_id, "registered_by" => principal, "phase" => "registered",
                "supervisor_binding" => identity.runtime_binding,
                "definition_ref" => definition_path, "definition_digest" => params.fetch("definition_digest"),
                "queue_ref" => queue_path, "queue_sha256" => queue_sha,
                "prepared_work" => work.reference(head: params.fetch("prepared_head"), tree: params.fetch("prepared_tree")),
                "prepared_bundle_ref" => bundle_path, "prepared_bundle_sha256" => bundle_sha,
                "prepared_bundle_bytes" => bytes.bytesize}}
            end
          end
        end

        def registration(assignment, commit:)
          return nil unless commit
          events = @journal.read_events(assignment, commit: commit)
          events.group_by { |event| event.fetch("attempt_id") }.each_value do |chain|
            raise AttemptErrors::EvidenceUnavailable, "ordinary assignment evidence is corrupt" unless Models::EvidenceEvent.chain_valid?(chain)
          end
          registrations = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "register_assignment" }
          return nil if registrations.empty?
          data = registrations.one? && registrations.first.dig("payload", "data")
          unless data && data.values_at("authority", "assignment_id", "project_id") == ["ordinary", assignment, @project]
            raise AttemptErrors::EvidenceUnavailable, "ordinary assignment registration owner differs"
          end
          data
        end

        def authorize!(request, peer, role, deadline)
          unless deadline.is_a?(Numeric) && deadline.finite? && deadline > Process.clock_gettime(Process::CLOCK_MONOTONIC)
            raise AttemptErrors::EvidenceUnavailable, "ordinary lifecycle deadline elapsed"
          end
          unless request.fetch("project_id") == @project && @admission.authorize!(request: request, peer: peer, deadline: deadline) == role
            raise AttemptErrors::UnauthorizedIdentity, "ordinary lifecycle principal differs"
          end
          # Project commands share the canonical journal but never the managed
          # assignment namespace. Reserve their prefix on every ordinary route,
          # including transfer admission, status and registration replay.
          assignment = request.fetch("params")["assignment_id"]
          if assignment.is_a?(String) && assignment.start_with?("command-")
            raise ArgumentError, "ordinary assignment uses the reserved project-command namespace"
          end
        end

        def validate_registration!(request)
          params = request.fetch("params")
          strict!(params, REGISTER_KEYS)
          token!(request.fetch("mutation_id"))
          token!(params.fetch("assignment_id"))
          token!("definition-#{params.fetch('assignment_id')}")
          unless params.fetch("expected_generation").is_a?(Integer) && params.fetch("expected_generation") >= 0
            raise ArgumentError, "ordinary generation is invalid"
          end
        end

        def strict!(value, keys)
          raise ArgumentError, "ordinary authority fields differ" unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end

        def token!(value)
          raise ArgumentError, "ordinary identity is invalid" unless value.is_a?(String) && Molecules::JournalMutation::ID.match?(value)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      # Source-owned progress for the already accepted work. Queue completion
      # remains a worker report, never a successful execution result or merge.
      module OrdinaryProgress
        PROGRESS_OPERATIONS = %w[queue_start queue_finish queue_fail assignment_snapshot].freeze
        PROGRESS_TRANSFERS = {
          "queue_finish" => {direction: :upload, purpose: :artifacts, roles: %i[worker supervisor]},
          "assignment_snapshot" => {direction: :download, purpose: :assignment_snapshot, roles: %i[worker supervisor reviewer]}
        }.freeze
        PROGRESS_COMMON = %w[assignment_id attempt_id expected_generation pane].freeze

        private

        def validate_progress!(request)
          params = request.fetch("params")
          operation = request.fetch("operation")
          if operation == "assignment_snapshot"
            strict!(params, %w[assignment_id kind])
            unless request.fetch("mutation_id").nil? && %w[prepared_work queue].include?(params.fetch("kind"))
              raise ArgumentError, "ordinary snapshot must be a read of accepted work or queue"
            end
          else
            fields = case operation
            when "queue_start" then %w[step]
            when "queue_finish" then %w[step transfer]
            when "queue_fail" then %w[message]
            else raise ArgumentError, "unknown ordinary progress operation"
            end
            strict!(params, PROGRESS_COMMON + fields)
            token!(params.fetch("attempt_id")); token!(request.fetch("mutation_id"))
            unless params.fetch("expected_generation").is_a?(Integer) && params.fetch("expected_generation").positive?
              raise ArgumentError, "ordinary progress generation is invalid"
            end
            if params.key?("step") && !params["step"].nil? &&
                !(params["step"].is_a?(String) && params["step"].bytesize.between?(1, 128) && PreparedWork::SCOPE.match?(params["step"]))
              raise ArgumentError, "ordinary progress step is invalid"
            end
            if params.key?("message") && !(params["message"].is_a?(String) && params["message"].bytesize.between?(1, 1024) && !params["message"].include?("\0"))
              raise ArgumentError, "ordinary failure message is invalid"
            end
          end
          token!(params.fetch("assignment_id"))
        end

        def assignment_snapshot(request, peer, role, deadline)
          validate_progress!(request)
          params = request.fetch("params")
          commit = @journal.ref_value
          registered = registration(params.fetch("assignment_id"), commit: commit)
          raise AttemptErrors::NotFound, "ordinary assignment is not registered" unless registered
          queue_record = current_queue_record(registered, commit)
          kind = params.fetch("kind")
          source = kind == "prepared_work" ? registered : queue_record
          path_key, digest_key, size = if kind == "prepared_work"
            ["prepared_bundle_ref", "prepared_bundle_sha256", registered.fetch("prepared_bundle_bytes")]
          else
            ["queue_ref", "queue_sha256", PreparedWork::MAX_TOTAL]
          end
          bytes = @journal.bounded_blob(source.fetch(path_key), commit: commit, max_bytes: size)
          unless Digest::SHA256.hexdigest(bytes) == source.fetch(digest_key)
            raise AttemptErrors::EvidenceUnavailable, "ordinary snapshot bytes differ from accepted selection"
          end
          authorize!(request, peer, role, deadline)
          {data: {"project_id" => @project, "assignment_id" => params.fetch("assignment_id"), "kind" => kind,
            "attempt_id" => queue_record["attempt_id"], "generation" => queue_record.fetch("generation"),
            "journal_commit" => commit, "sha256" => source.fetch(digest_key), "bytes" => bytes.bytesize,
            "prepared_work" => registered.fetch("prepared_work"), "definition_digest" => registered.fetch("definition_digest")},
            transfer_parts: [bytes], replayed: false}
        end

        def progress(request, peer, role, deadline, transfer)
          validate_progress!(request)
          unless %i[supervisor worker].include?(role)
            raise AttemptErrors::UnauthorizedIdentity, "ordinary progress requires its original worker"
          end
          params, operation = request.fetch("params"), request.fetch("operation")
          report = if operation == "queue_finish"
            raise ArgumentError, "ordinary progress report needs one bounded part" unless transfer && transfer.count == 1
            bytes = transfer.bytes.dup.force_encoding(Encoding::UTF_8)
            unless bytes.bytesize.between?(1, 65_536) && bytes.valid_encoding? && !bytes.include?("\0")
              raise ArgumentError, "ordinary progress report must be bounded UTF-8"
            end
            bytes
          elsif transfer
            raise ArgumentError, "ordinary progress operation forbids transfer"
          end
          commit = @journal.ref_value
          registered = registration(params.fetch("assignment_id"), commit: commit)
          raise AttemptErrors::NotFound, "ordinary work is not registered" unless registered
          work = registered_work(registered, commit, deadline)
          digest = Atoms::EvidenceDigest.digest({"params" => params, "project_id" => @project, "peer_uid" => peer.fetch("uid")})
          keys = [@exclusion.task_key(registered.fetch("task_id")), @exclusion.assignment_key(params.fetch("assignment_id"))]
          @exclusion.with_shared_multi(keys, deadline: deadline) do
            authorize!(request, peer, role, deadline)
            @journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
              mutation_id: request.fetch("mutation_id"), operation: operation, parameters_digest: digest,
              expected_generation: params.fetch("expected_generation"), with_replay: true, deadline: deadline,
              replay_authorizer: -> { authorize_start_replay!(request, peer, role, deadline) }) do |events, prefix, _generation|
              authorize_start_replay!(request, peer, role, deadline)
              unless Molecules::CanonicalAttemptState.derive(events) == "running"
                raise AttemptErrors::Conflict, "ordinary progress requires the original running attempt"
              end
              record = current_queue_record(registered, prefix)
              unless record["attempt_id"] == params.fetch("attempt_id")
                raise AttemptErrors::UnauthorizedIdentity, "ordinary queue owner differs"
              end
              bytes = @journal.bounded_blob(record.fetch("queue_ref"), commit: prefix, max_bytes: PreparedWork::MAX_TOTAL)
              unless Digest::SHA256.hexdigest(bytes) == record.fetch("queue_sha256")
                raise AttemptErrors::EvidenceUnavailable, "ordinary progress snapshot differs"
              end
              queue = OrdinaryQueue.new(work: work, root: @input_root, bytes: bytes)
              next_queue = case operation
              when "queue_start" then queue.transition(operation: :start, step: params.fetch("step"))
              when "queue_finish" then queue.transition(operation: :finish, step: params.fetch("step"), report: report)
              when "queue_fail" then queue.transition(operation: :fail, message: params.fetch("message"))
              end
              sha = Digest::SHA256.hexdigest(next_queue.bytes)
              path = "execution/definitions/#{params.fetch('assignment_id')}-queue-#{sha}.json"
              {events: [], blobs: {path => next_queue.bytes}, data: {
                "authority" => "ordinary", "assignment_id" => params.fetch("assignment_id"), "attempt_id" => params.fetch("attempt_id"),
                "project_id" => @project, "queue_ref" => path, "queue_sha256" => sha, "state" => "running",
                "queue_complete" => next_queue.status.subtree_complete?(work.manifest.fetch("scope"))}}
            end
          end
        end

        def current_queue_record(registered, commit)
          assignment = registered.fetch("assignment_id")
          attempts = @journal.derived_attempts(assignment, commit: commit)
          return registered if attempts.empty?
          raise AttemptErrors::EvidenceUnavailable, "ordinary queue has ambiguous execution owners" unless attempts.one?
          events = @journal.read_events(assignment, commit: commit).select { |event| event["attempt_id"] == attempts.first.attempt_id }
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "ordinary queue history is corrupt"
          end
          event = events.reverse.find do |entry|
            entry["type"] == "authority_mutation" &&
              %w[start_attempt queue_start queue_finish queue_fail].include?(entry.dig("payload", "operation"))
          end
          record = event&.dig("payload", "data")
          unless record && record.values_at("authority", "assignment_id", "attempt_id", "project_id") ==
              ["ordinary", assignment, attempts.first.attempt_id, @project]
            raise AttemptErrors::EvidenceUnavailable, "ordinary canonical queue is unavailable"
          end
          record.merge("generation" => @journal.authority_generation(events))
        end
      end
    end
  end
end

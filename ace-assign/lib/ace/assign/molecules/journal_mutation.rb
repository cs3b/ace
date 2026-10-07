# frozen_string_literal: true

require "json"
require "digest"
require "ace/herdr/molecules/bounded_process"
require_relative "journal_prompt_mutation"
require_relative "journal_input_inhibition"

module Ace
  module Assign
    module Molecules
      # Protected authority mutations share the execution ref's lock and CAS.
      # Replies live in chained attempt events, rather than an RPC ledger.
      module JournalMutation
        include JournalPromptMutation
        include JournalInputInhibition
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/

        # Shared canonical projection used by admission and protected status.
        # Callers hold the same owner exclusion when projecting current events.
        def authority_generation(events)
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "Attempt event chain is corrupt"
          end
          events.count { |event| event["type"] == "authority_mutation" }
        end

        def canonical_attempt_state(events)
          authority_generation(events)
          derive_state(events)
        end

        # The block runs against the current ref on every CAS attempt. It
        # returns events [{type:, payload:}], immutable blobs, and public data.
        # Only the authority calls this internal journal API; wire requests
        # cannot select blob paths, event types, or accepted response data.
        def mutate(assignment_id:, attempt_id:, mutation_id:, operation:, parameters_digest:, expected_generation:, with_replay: false, generation_mode: :expected, prompt_binding: nil, prompt_completion: nil, prompt_observation: nil, input_inhibition: nil)
          unless (generation_mode == :expected && expected_generation.is_a?(Integer) && expected_generation >= 0) ||
              (generation_mode == :recorded_completion && %w[complete_service complete_no_effect].include?(operation) && expected_generation.nil?) ||
              (generation_mode == :prompt_completion && operation == "prompt_attempt" && expected_generation.nil? && prompt_completion.is_a?(Hash)) ||
              (generation_mode == :prompt_observation && operation == "prompt_observation" && expected_generation.nil? && prompt_observation.is_a?(Hash)) ||
              (generation_mode == :input_inhibition && operation == "input_inhibition_observation" && expected_generation.nil? && input_inhibition.is_a?(Hash))
            raise ArgumentError, "invalid fixed mutation generation mode"
          end
          if input_inhibition && generation_mode != :input_inhibition
            raise ArgumentError, "Input inhibition requires its fixed mode"
          end
          if operation == "input_inhibition_observation" && !(generation_mode == :input_inhibition && input_inhibition)
            raise ArgumentError, "Input inhibition observation requires its accepted original selector"
          end
          if mutation_id.is_a?(String) && mutation_id.start_with?("input-inhibit.") && !(operation == "input_inhibition_observation" && input_inhibition)
            raise ArgumentError, "Reserved input inhibition namespace"
          end
          if prompt_completion && generation_mode != :prompt_completion
            raise ArgumentError, "prompt completion selector requires its fixed mode"
          end
          if prompt_observation && generation_mode != :prompt_observation
            raise ArgumentError, "prompt observation selector requires its fixed mode"
          end
          if operation == "prompt_issue"
            validate_prompt_binding!(prompt_binding)
            digest = Digest::SHA256.hexdigest(JSON.generate(canonical_prompt_value(prompt_binding)))
            unless parameters_digest == digest && mutation_id == "prompt-issue.#{digest}" &&
                assignment_id == prompt_binding.fetch("assignment_id") && attempt_id == prompt_binding.fetch("attempt_id")
              raise ArgumentError, "prompt phase does not match source binding"
            end
          elsif prompt_binding
            raise ArgumentError, "prompt binding is only accepted by its fixed issue phase"
          end
          [assignment_id, attempt_id, mutation_id].each { |id| validate_mutation_id!(id) }
          unless parameters_digest.is_a?(String) && parameters_digest.match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "invalid mutation parameter digest"
          end
          with_lock do
            self.class::CAS_ATTEMPTS.times do
              old = ref_value
              ensure_checkout!
              old = ref_value if old.nil?
              sync_checkout(old)
              if prompt_binding
                verify_prompt_external_namespace!(prompt_binding.fetch("mutation_id"), parameters_digest,
                  assignment_id: assignment_id, attempt_id: attempt_id, commit: old)
              end
              verify_prompt_completion!(prompt_completion, mutation_id: mutation_id, digest: parameters_digest,
                assignment_id: assignment_id, attempt_id: attempt_id, commit: old) if prompt_completion
              verify_prompt_observation!(prompt_observation, mutation_id: mutation_id,
                assignment_id: assignment_id, attempt_id: attempt_id, commit: old) if prompt_observation
              verify_input_inhibition!(input_inhibition, mutation_id: mutation_id, digest: parameters_digest,
                assignment_id: assignment_id, attempt_id: attempt_id, commit: old) if input_inhibition
              verify_prompt_mutation_namespace!(mutation_id: mutation_id, operation: operation, parameters_digest: parameters_digest,
                assignment_id: assignment_id, attempt_id: attempt_id, prompt_completion: prompt_completion, prompt_observation: prompt_observation, commit: old)
              replay = mutation_result(mutation_id, commit: old)
              if replay
                unless replay["operation"] == operation && replay["parameters_digest"] == parameters_digest &&
                    replay["assignment_id"] == assignment_id && replay["attempt_id"] == attempt_id
                  raise AttemptErrors::Conflict, "Mutation ID is already bound to different input"
                end
                result = replay.fetch("data").merge("journal_commit" => replay.fetch("journal_commit"))
                return with_replay ? {data: result, replayed: true} : result
              end
              current = read_events(assignment_id, commit: old).select { |event| event["attempt_id"] == attempt_id }
              generation = authority_generation(current)
              unless %i[recorded_completion prompt_completion prompt_observation input_inhibition].include?(generation_mode) || expected_generation == generation
                raise AttemptErrors::Conflict, "Authority registration generation changed"
              end
              plan = yield(current, old, generation)
              blobs = plan.fetch(:blobs, {})
              events = chain_mutation_events(attempt_id, current.last&.fetch("digest"), plan.fetch(:events, []))
              updates = prepare_service_updates(plan.fetch(:service_updates, []), assignment_id: assignment_id,
                attempt_id: attempt_id, pending: {current_events: current, pending_events: events, blobs: blobs, commit: old, operation: operation,
                  service_inputs: service_input_context(plan)})
              events.concat(chain_mutation_events(attempt_id, events.last&.fetch("digest") || current.last&.fetch("digest"),
                updates.map { |prepared| prepared.fetch(:event) }))
              data = plan.fetch(:data).merge("generation" => generation + 1)
              receipt = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: attempt_id,
                previous_digest: events.last&.fetch("digest") || current.last&.fetch("digest"),
                payload: {"mutation_id" => mutation_id, "operation" => operation,
                          "parameters_digest" => parameters_digest, "assignment_id" => assignment_id,
                          "attempt_id" => attempt_id, "data" => data})
              events << receipt
              write_mutation_blobs(blobs, commit: old)
              write_service_records(updates)
              write_event_files(assignment_id, events)
              git!("-C", checkout_dir, "add", "--", "execution/#{assignment_id}")
              stage_mutation_blobs(blobs)
              stage_service_records(updates)
              git!("-C", checkout_dir, "-c", "user.name=ace-assign", "-c", "user.email=ace-assign@localhost",
                "-c", "core.hooksPath=/dev/null", "commit", "-m", "evidence: authority #{operation} #{mutation_id}")
              commit = git!("-C", checkout_dir, "rev-parse", "HEAD").first
              if update_ref_cas(commit, old)
                result = data.merge("journal_commit" => commit)
                return with_replay ? {data: result, replayed: false} : result
              end
            end
            raise AttemptErrors::EvidenceUnavailable, "Authority mutation ref stayed conflicting"
          end
        end

        def mutation_result(mutation_id, commit: ref_value)
          validate_mutation_id!(mutation_id)
          assignment_ids(commit: commit).each do |assignment_id|
            events = read_events(assignment_id, commit: commit)
            events.group_by { |event| event["attempt_id"] }.each_value do |chain|
              unless Models::EvidenceEvent.chain_valid?(chain)
                raise AttemptErrors::EvidenceUnavailable, "Authority mutation event chain is corrupt"
              end
            end
            event = events.find do |entry|
              entry["type"] == "authority_mutation" && entry.dig("payload", "mutation_id") == mutation_id
            end
            next unless event

            path = "execution/#{assignment_id}/events/#{event_filename(event)}"
            acceptance_commit = git!("log", "--diff-filter=A", "-1", "--format=%H", commit, "--", path).first
            raise AttemptErrors::EvidenceUnavailable, "Mutation acceptance commit is missing" if acceptance_commit.empty?
            return event.fetch("payload").merge("journal_commit" => acceptance_commit)
          end
          nil
        end

        # Source composition supplies original body bytes only for the current
        # service CAS callback. They are never part of persisted mutation data.
        def service_input_context(plan)
          inputs = plan.fetch(:service_inputs, {})
          raise ArgumentError, "invalid ephemeral service input context" unless inputs.is_a?(Hash)
          return {}.freeze if inputs.empty?
          updates = plan.fetch(:service_updates, [])
          unless inputs.size == 1 && updates.size == 1 && inputs.keys == [updates.first.fetch(:request_id)] &&
              inputs.values.first.is_a?(String) && inputs.values.first.bytesize.between?(1, 64 * 1024)
            raise ArgumentError, "invalid ephemeral service input context"
          end
          inputs.to_h { |key, bytes| [key.dup.freeze, bytes.dup.freeze] }.freeze
        end
        private :service_input_context

        # Read immutable bytes directly from a selected canonical ref commit.
        # Worktree projections are never consulted for protected evidence.
        def blob(path, commit: ref_value)
          validate_blob_path!(path)
          raise AttemptErrors::EvidenceUnavailable, "Canonical evidence ref is missing" unless commit
          out, _error, status = Open3.capture3("git", "show", "#{commit}:#{path}",
            chdir: repo_root, stdin_data: "")
          raise AttemptErrors::EvidenceUnavailable, "Canonical evidence blob is missing" unless status.success?
          out.b
        end

        # Prepared inputs use the same immutable Git owner, with a bounded
        # capture before any bytes can reach a worker transport.
        def bounded_blob(path, commit:, max_bytes:)
          validate_blob_path!(path)
          unless commit.is_a?(String) && commit.match?(/\A[0-9a-f]{40}(?:[0-9a-f]{24})?\z/) &&
              max_bytes.is_a?(Integer) && max_bytes.between?(1, 64 * 1024 * 1024)
            raise AttemptErrors::EvidenceUnavailable, "Canonical prepared blob selector differs"
          end
          environment = ENV.keys.to_h { |key| [key, nil] }
          environment.merge!("GIT_CONFIG_NOSYSTEM" => "1", "GIT_CONFIG_GLOBAL" => "/dev/null",
            "GIT_TERMINAL_PROMPT" => "0", "GIT_NO_REPLACE_OBJECTS" => "1", "PATH" => "/usr/bin:/bin", "LC_ALL" => "C")
          result = Herdr::Molecules::BoundedProcess.call([environment, "/usr/bin/git", "-C", repo_root,
            "-c", "core.hooksPath=/dev/null", "cat-file", "blob", "#{commit}:#{path}"],
            stdin_data: "", timeout_s: 30, output_limit: max_bytes)
          unless result.status.success? && !result.oversized
            raise AttemptErrors::EvidenceUnavailable, "Canonical prepared blob is missing or oversized"
          end
          result.stdout.b
        rescue Timeout::Error, Herdr::Molecules::BoundedProcess::PostLaunchError, SystemCallError, IOError
          raise AttemptErrors::EvidenceUnavailable, "Canonical prepared blob read is unavailable"
        end

        private

        def validate_mutation_id!(id)
          raise ArgumentError, "invalid authority ID" unless id.is_a?(String) && id.match?(ID)
        end

        def validate_blob_path!(path)
          unless path.is_a?(String) && path.match?(%r{\A(?:evidence/imports|execution/definitions|execution/prepared|candidates/bundles)/[a-zA-Z0-9_.-]+\z}) &&
              !%w[. ..].include?(File.basename(path))
            raise ArgumentError, "invalid canonical blob reference"
          end
        end

        def chain_mutation_events(attempt_id, previous, entries)
          entries.map do |entry|
            recorded_at = entry.fetch(:recorded_at) { Time.now.utc }
            raise ArgumentError, "internal event timestamp must be a UTC Time" unless recorded_at.is_a?(Time) && recorded_at.utc?
            event = Models::EvidenceEvent.build(type: entry.fetch(:type), attempt_id: attempt_id,
              payload: entry.fetch(:payload), previous_digest: previous, recorded_at: recorded_at)
            previous = event.fetch("digest")
            event
          end
        end

        # Git clean/smudge filters and CRLF conversion cannot redefine accepted
        # evidence bytes. Insert unfiltered objects after staging the events.
        def stage_mutation_blobs(blobs)
          blobs.each do |path, bytes|
            oid, error, status = Open3.capture3("git", "hash-object", "-w", "--stdin", "--no-filters",
              chdir: repo_root, stdin_data: bytes.b)
            unless status.success?
              raise AttemptErrors::EvidenceUnavailable, "Cannot write canonical evidence object: #{error.strip}"
            end
            git!("-C", checkout_dir, "update-index", "--add", "--cacheinfo", "100644,#{oid.strip},#{path}")
          end
        end

        def write_mutation_blobs(blobs, commit:)
          blobs.map do |path, bytes|
            validate_blob_path!(path)
            raise ArgumentError, "canonical blob must contain bytes" unless bytes.is_a?(String)
            target = File.join(checkout_dir, path)
            if File.exist?(target)
              # A checkout may have smudged the file; immutability is checked
              # against accepted bytes at the canonical commit, not projection.
              unless blob(path, commit: commit) == bytes.b
                raise AttemptErrors::Conflict, "Canonical evidence blob is immutable"
              end
            else
              FileUtils.mkdir_p(File.dirname(target))
              File.open(target, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW, 0600) do |file|
                file.write(bytes.b)
              end
            end
            path
          end
        end
      end
    end
  end
end

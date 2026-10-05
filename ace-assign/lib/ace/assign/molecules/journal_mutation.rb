# frozen_string_literal: true

require "json"
require "digest"

module Ace
  module Assign
    module Molecules
      # Protected authority mutations share the execution ref's lock and CAS.
      # Replies live in chained attempt events, rather than an RPC ledger.
      module JournalMutation
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/

        # The block runs against the current ref on every CAS attempt. It
        # returns events [{type:, payload:}], immutable blobs, and public data.
        # Only the authority calls this internal journal API; wire requests
        # cannot select blob paths, event types, or accepted response data.
        def mutate(assignment_id:, attempt_id:, mutation_id:, operation:, parameters_digest:, expected_generation:)
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
              replay = mutation_result(mutation_id)
              if replay
                unless replay["operation"] == operation && replay["parameters_digest"] == parameters_digest &&
                    replay["assignment_id"] == assignment_id && replay["attempt_id"] == attempt_id
                  raise AttemptErrors::Conflict, "Mutation ID is already bound to different input"
                end
                return replay.fetch("data").merge("journal_commit" => replay.fetch("journal_commit"))
              end
              current = read_events(assignment_id).select { |event| event["attempt_id"] == attempt_id }
              unless Models::EvidenceEvent.chain_valid?(current)
                raise AttemptErrors::EvidenceUnavailable, "Attempt event chain is corrupt"
              end
              generation = current.count { |event| event["type"] == "authority_mutation" }
              unless expected_generation == generation
                raise AttemptErrors::Conflict, "Authority registration generation changed"
              end
              plan = yield(current, old, generation)
              events = chain_mutation_events(attempt_id, current.last&.fetch("digest"), plan.fetch(:events, []))
              data = plan.fetch(:data).merge("generation" => generation + 1)
              receipt = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: attempt_id,
                previous_digest: events.last&.fetch("digest") || current.last&.fetch("digest"),
                payload: {"mutation_id" => mutation_id, "operation" => operation,
                          "parameters_digest" => parameters_digest, "assignment_id" => assignment_id,
                          "attempt_id" => attempt_id, "data" => data})
              events << receipt
              blobs = plan.fetch(:blobs, {})
              write_mutation_blobs(blobs, commit: old)
              write_event_files(assignment_id, events)
              git!("-C", checkout_dir, "add", "--", "execution/#{assignment_id}")
              stage_mutation_blobs(blobs)
              git!("-C", checkout_dir, "-c", "user.name=ace-assign", "-c", "user.email=ace-assign@localhost",
                "-c", "core.hooksPath=/dev/null", "commit", "-m", "evidence: authority #{operation} #{mutation_id}")
              commit = git!("-C", checkout_dir, "rev-parse", "HEAD").first
              return data.merge("journal_commit" => commit) if update_ref_cas(commit, old)
            end
            raise AttemptErrors::EvidenceUnavailable, "Authority mutation ref stayed conflicting"
          end
        end

        def mutation_result(mutation_id)
          validate_mutation_id!(mutation_id)
          assignment_ids.each do |assignment_id|
            events = read_events(assignment_id)
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
            commit = git!("log", "--diff-filter=A", "-1", "--format=%H", ref_value, "--", path).first
            raise AttemptErrors::EvidenceUnavailable, "Mutation acceptance commit is missing" if commit.empty?
            return event.fetch("payload").merge("journal_commit" => commit)
          end
          nil
        end

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

        private

        def validate_mutation_id!(id)
          raise ArgumentError, "invalid authority ID" unless id.is_a?(String) && id.match?(ID)
        end

        def validate_blob_path!(path)
          unless path.is_a?(String) && path.match?(%r{\A(?:evidence/imports|execution/definitions)/[a-zA-Z0-9_.-]+\z}) &&
              !%w[. ..].include?(File.basename(path))
            raise ArgumentError, "invalid canonical blob reference"
          end
        end

        def chain_mutation_events(attempt_id, previous, entries)
          entries.map do |entry|
            event = Models::EvidenceEvent.build(type: entry.fetch(:type), attempt_id: attempt_id,
              payload: entry.fetch(:payload), previous_digest: previous)
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

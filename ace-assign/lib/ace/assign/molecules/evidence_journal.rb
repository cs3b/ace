# frozen_string_literal: true

require_relative "canonical_attempt_state"

require "digest"
require "fileutils"
require "json"
require "open3"
require "ace/herdr/molecules/bounded_process"
require_relative "proposal_journal"
require_relative "journal_mutation"

module Ace
  module Assign
    module Molecules
      # Append-only execution evidence journal backed by a dedicated Git ref.
      #
      # Accepted evidence for assignment attempts is committed to a separate
      # configured evidence ref (default `refs/ace/execution`) in canonical,
      # non-secret paths `execution/<assignment-id>/events/`. The ref lives
      # outside the deliverable candidate branch: appending evidence never
      # advances or changes the reviewed candidate. Working state uses an
      # isolated, disposable detached worktree under the configured checkout
      # root.
      #
      # Concurrency: all ref updates serialize on a checkout-root flock, and
      # every update is additionally guarded by an expected-old-value
      # `git update-ref` compare-and-swap. On a CAS conflict the journal
      # reloads the authoritative ref and replays only still-valid,
      # non-duplicate events.
      class EvidenceJournal
        include JournalMutation
        include ProposalJournal
        CAS_ATTEMPTS = 3
        HISTORY_LIMIT = 100_000
        EVENT_BATCH_BYTES = 1024 * 1024

        # Selected by source composition, never by receipt or wire parameters.
        def evidence_mode
          @mode
        end

        # @param repo_root [String] Git repository root holding the evidence ref
        # @param ref [String, nil] Evidence ref (default from config)
        # @param checkout_root [String, nil] Isolated checkout root (default from config)
        def initialize(repo_root:, ref: nil, checkout_root: nil, mode: :local,
          evidence_reader: nil, service_authorizer: nil, read_boundary: nil)
          unless %i[local protected].include?(mode) &&
              (mode != :protected || [evidence_reader, service_authorizer].all? { |owner| owner.respond_to?(:call) })
            raise ArgumentError, "protected journal requires source-owned evidence and service boundaries"
          end
          @mode, @evidence_reader, @service_authorizer = mode, evidence_reader, service_authorizer
          if read_boundary && !%i[call blob_batch blob history_diff blob_sizes].all? { |method| read_boundary.respond_to?(method) }
            raise ArgumentError, "read-only journal boundary is malformed"
          end
          @read_boundary = read_boundary
          @repo_root = repo_root
          @ref = ref || default_config("evidence_git_ref") || "refs/ace/execution"
          root = checkout_root || default_config("evidence_checkout_root") || ".ace-local/assign/evidence-checkout"
          @checkout_root = Pathname.new(root).absolute? ? root : File.join(repo_root, root)
        end

        attr_reader :repo_root, :ref, :checkout_root

        # @return [Boolean] True when the repo can hold the evidence ref
        def available?
          git_ok?("rev-parse", "--git-dir")
        end

        # Current value of the evidence ref.
        #
        # @return [String, nil] Commit SHA or nil when the ref does not exist
        def ref_value
          out, stderr, status = git("rev-parse", "--verify", "--quiet", @ref)
          return out if status.success?

          raise AttemptErrors::EvidenceUnavailable, "Cannot read evidence ref #{@ref}: #{stderr}" if git_broken?(stderr)

          nil
        end

        # Read-only verification for a fixed immutable maintenance snapshot.
        def verify_commit!(commit)
          unless commit.is_a?(String) && commit.match?(/\A[0-9a-f]{40}\z/)
            raise AttemptErrors::EvidenceUnavailable, "canonical journal commit is invalid"
          end
          kind, error, status = git("cat-file", "-t", commit)
          unless status.success? && kind == "commit"
            raise AttemptErrors::EvidenceUnavailable, "canonical journal commit is unavailable: #{error}"
          end
          true
        end

        # All immutable owner queries select retained canonical evidence, not
        # arbitrary Git objects or valid-looking abandoned CAS candidates.
        def verify_canonical_prefix!(commit:, canonical_commit: ref_value)
          verify_commit!(commit)
          verify_commit!(canonical_commit)
          text, _error, status = git("rev-list", "--first-parent", "--parents",
            "--max-count=#{self.class::HISTORY_LIMIT + 1}", canonical_commit)
          nodes = text.lines.map(&:split)
          unless status.success? && nodes.size <= self.class::HISTORY_LIMIT && !nodes.empty? &&
              nodes.all? { |node| node.size.between?(1, 2) && node.all? { |sha| sha.match?(/\A[0-9a-f]{40}\z/) } } &&
              nodes.each_cons(2).all? { |left, right| left[1] == right[0] } && nodes.last.size == 1 &&
              nodes.any? { |node| node.first == commit }
            raise AttemptErrors::EvidenceUnavailable, "Evidence prefix is not retained canonical first-parent history"
          end
          true
        end

        # Normal append commits inherit the event unchanged. Locate its one
        # introduction; inherited appearances are not competing provenance.
        def event_commit!(assignment_id:, event_digest:, commit:)
          event_commits!(assignment_id: assignment_id, event_digests: [event_digest], commit: commit).fetch(event_digest)
        end

        # Operation-scoped batch of the same provenance proof. No retained
        # cache: every call authenticates the entire fixed first-parent history.
        def event_commits!(assignment_id:, event_digests:, commit:)
          event_commits_for_assignments!(selectors: {assignment_id => event_digests}, commit: commit).fetch(assignment_id)
        end

        # One immutable walk for an operation selecting several assignments.
        # Every selected assignment retains its complete chain and exact raw
        # blob proof; the result is returned, never cached on this owner.
        def event_commits_for_assignments!(selectors:, commit:)
          unless selectors.is_a?(Hash) && !selectors.empty? && selectors.size <= HISTORY_LIMIT &&
              selectors.keys.all? { |id| id.is_a?(String) && id.match?(JournalMutation::ID) } &&
              selectors.values.all? { |digests| digests.is_a?(Array) && !digests.empty? &&
                digests.uniq.size == digests.size && digests.all? { |digest| digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/) } } &&
              selectors.values.sum(&:size) <= HISTORY_LIMIT
            raise AttemptErrors::EvidenceUnavailable, "historical event selectors are invalid"
          end
          nodes = canonical_history_nodes!(commit)
          states = selectors.to_h do |id, digests|
            [id, digests.to_h { |digest| [digest, {retained: nil, blob: nil, absent: false, introduction: nil}] }]
          end
          each_history_event_snapshot!(states.keys, nodes: nodes) do |node, snapshots, files|
            states.each do |assignment_id, selected_states|
              events = snapshots.fetch(assignment_id)
              validated_attempt_chains!(events)
              matches = events.select { |event| selected_states.key?(event["digest"]) }.group_by { |event| event.fetch("digest") }
              selected_states.each do |digest, state|
                selected = matches.fetch(digest, [])
                raise AttemptErrors::EvidenceUnavailable, "historical event selector is ambiguous" if selected.size > 1
                if selected.empty?
                  raise AttemptErrors::EvidenceUnavailable, "historical event disappeared" if state[:retained]
                  next
                end
                event = selected.first
                blob = files.fetch(assignment_id).fetch(event_filename(event))
                if (state[:retained] && state[:retained] != event) || (state[:blob] && state[:blob] != blob)
                  raise AttemptErrors::EvidenceUnavailable, "historical event changed"
                end
                state[:blob] ||= blob
                state[:retained] ||= event
                state[:introduction] ||= node.first
              end
            end
          end
          unless states.values.all? { |selected_states| selected_states.values.all? { |state| state[:introduction] } }
            raise AttemptErrors::EvidenceUnavailable, "historical canonical event is unavailable"
          end
          states.to_h do |id, selected_states|
            [id.dup.freeze, selected_states.to_h { |digest, state| [digest.dup.freeze, state.fetch(:introduction).dup.freeze] }.freeze]
          end.freeze
        rescue KeyError, TypeError, ArgumentError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "historical canonical event selectors are unverifiable"
        end

        HISTORY_DIFF_BYTES = 256 * 1024 * 1024
        HISTORY_DIFF_FLAGS = %w[diff-tree --stdin --always --root -r --raw -z --no-renames
          --no-ext-diff --no-textconv --no-abbrev --].freeze

        # The existing history owner still validates every prefix. Git returns
        # all requested headers, including unchanged commits; only immutable
        # changed blob bytes are batched rather than respawned at each node.
        def each_history_event_snapshot!(ids, nodes:)
          files = ids.to_h { |id| [id, {}] }
          contents = ids.to_h { |id| [id, {}] }
          paths = ids.map { |id| "execution/#{id}/events/" }
          nodes.reverse.each_slice(64) do |chunk|
            commits = chunk.map(&:first)
            raw = history_diff!(commits, paths)
            changes = decode_history_diff!(commits, paths, raw)
            oids = changes.values.flatten(1).filter_map { |change| change[3] unless change[3] == "0" * 40 }.uniq
            decoded = {}
            oids.each_slice(64) do |batch|
              sizes = history_blob_sizes!(batch)
              entries = batch.zip(sizes)
              groups = []
              entries.each do |entry|
                groups << [] if groups.empty? || (!groups.last.empty? && groups.last.sum(&:last) + entry.last > EVENT_BATCH_BYTES)
                groups.last << entry
              end
              groups.each do |group|
                decode_event_blobs!(group, read_event_blobs!(group)).each_with_index do |bytes, index|
                  decoded[group.fetch(index).first] = JSON.parse(bytes)
                end
              end
            end
            chunk.each do |node|
              changes.fetch(node.first).each do |path, status, old, fresh|
                id = ids.find { |selected| path.start_with?("execution/#{selected}/events/") }
                name = path.delete_prefix("execution/#{id}/events/")
                current = files.fetch(id)[name]
                unless (status == "A" && old == "0" * 40 && current.nil?) ||
                    (%w[M D T].include?(status) && current == old)
                  raise AttemptErrors::EvidenceUnavailable, "historical tree change differs from previous immutable snapshot"
                end
                if status == "D"
                  files.fetch(id).delete(name)
                  contents.fetch(id).delete(name)
                else
                  files.fetch(id)[name] = fresh
                  contents.fetch(id)[name] = decoded.fetch(fresh)
                end
              end
              snapshots = contents.transform_values do |selected|
                events = selected.values
                digests = events.map { |event| event.fetch("digest") }
                raise AttemptErrors::EvidenceUnavailable, "historical event digest is ambiguous" unless digests.uniq.size == digests.size
                order_by_chain(events)
              end
              yield node, snapshots, files
            end
          end
          _events, actual = read_event_snapshots!(ids, commit: nodes.first.first)
          raise AttemptErrors::EvidenceUnavailable, "historical reconstructed tip differs from its immutable tree" unless files == actual
        rescue JSON::ParserError, KeyError, TypeError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "historical batched snapshots are unverifiable"
        end

        def history_diff!(commits, paths)
          return @read_boundary.history_diff(commits, paths, output_limit: HISTORY_DIFF_BYTES) if @read_boundary
          bounded_history_read!(HISTORY_DIFF_FLAGS + paths, commits.join("\n") + "\n", HISTORY_DIFF_BYTES)
        end

        def history_blob_sizes!(oids)
          raw = if @read_boundary
            @read_boundary.blob_sizes(oids)
          else
            bounded_history_read!(%w[cat-file --batch-check], oids.join("\n") + "\n", oids.size * 128)
          end
          lines = raw.lines
          raise AttemptErrors::EvidenceUnavailable, "historical blob metadata count differs" unless lines.size == oids.size
          lines.zip(oids).map do |line, oid|
            match = /\A([0-9a-f]{40}) blob (0|[1-9][0-9]*)\n\z/.match(line)
            raise AttemptErrors::EvidenceUnavailable, "historical blob metadata differs" unless match && match[1] == oid
            match[2].to_i
          end
        end

        def bounded_history_read!(argv, stdin, limit)
          result = Herdr::Molecules::BoundedProcess.call(["git", *argv], chdir: File.expand_path(@repo_root),
            stdin_data: stdin, timeout_s: 30, output_limit: limit)
          raise AttemptErrors::EvidenceUnavailable, "historical batch unavailable or exceeds bound" unless result.status.success? && !result.oversized
          result.stdout.to_s.b
        rescue Timeout::Error, Herdr::Molecules::BoundedProcess::PostLaunchError, IOError, SystemCallError
          raise AttemptErrors::EvidenceUnavailable, "historical batch is unavailable"
        end

        def decode_history_diff!(commits, paths, raw)
          unless raw.is_a?(String) && raw.end_with?("\0")
            raise AttemptErrors::EvidenceUnavailable, "historical diff frame is incomplete"
          end
          tokens = raw.split("\0", -1)
          tokens.pop
          result = commits.to_h { |commit| [commit, []] }
          position = 0
          commits.each do |commit|
            raise AttemptErrors::EvidenceUnavailable, "historical commit header differs" unless tokens[position] == commit
            position += 1
            seen = {}
            while tokens[position]&.start_with?(":")
              metadata, path = tokens.values_at(position, position + 1)
              match = /\A:([0-7]{6}) ([0-7]{6}) ([0-9a-f]{40}) ([0-9a-f]{40}) ([AMDT])\z/.match(metadata)
              unless match && path.is_a?(String) && paths.any? { |prefix| path.start_with?(prefix) } && !seen[path]
                raise AttemptErrors::EvidenceUnavailable, "historical tree metadata differs"
              end
              seen[path] = true
              position += 2
              next unless path.end_with?(".json")
              old, fresh, status = match.values_at(3, 4, 5)
              modes = match.values_at(1, 2)
              unless modes.all? { |mode| %w[000000 100644 100755 120000].include?(mode) } &&
                  (status == "A" ? old == "0" * 40 && fresh != "0" * 40 && modes.first == "000000" && modes.last != "000000" :
                    status == "D" ? old != "0" * 40 && fresh == "0" * 40 && modes.first != "000000" && modes.last == "000000" :
                      old != "0" * 40 && fresh != "0" * 40 && modes.none? { |mode| mode == "000000" })
                raise AttemptErrors::EvidenceUnavailable, "historical event object type differs"
              end
              result.fetch(commit) << [path, status, old, fresh]
            end
          end
          raise AttemptErrors::EvidenceUnavailable, "historical diff has extra headers or bytes" unless position == tokens.size
          result
        end
        private :each_history_event_snapshot!, :history_diff!, :history_blob_sizes!, :bounded_history_read!, :decode_history_diff!

        # Complete immutable index facts are authenticated before any caller
        # filters ownership. A missing current fact cannot hide an older one.
        def canonical_event_inventory!(commit:)
          nodes = canonical_history_nodes!(commit)
          root_events, introductions = nil, {}
          newer_chains, newer_files = nil, nil
          nodes.each do |node|
            ids = assignment_ids(commit: node.first)
            snapshots, files = ids.empty? ? [{}, {}] : read_event_snapshots!(ids, commit: node.first)
            chains = snapshots.transform_values { |events| validated_attempt_chains!(events) }
            snapshots.each do |id, events|
              unless events.all? { |event| files.fetch(id).key?(event_filename(event)) }
                raise AttemptErrors::EvidenceUnavailable, "canonical event filename differs"
              end
            end
            if root_events.nil?
              root_events = snapshots.reject { |_id, events| events.empty? }
              introductions = root_events.to_h { |id, events| [id, events.to_h { |event| [event.fetch("digest"), node.first] }] }
            else
              chains.each do |id, attempts|
                attempts.each do |attempt_id, chain|
                  newer = newer_chains.fetch(id, {}).fetch(attempt_id, [])
                  unless chain == newer.take(chain.size)
                    raise AttemptErrors::EvidenceUnavailable, "canonical inventory history removed or rewrote an attempt"
                  end
                end
              end
              files.each do |id, selected_files|
                unless selected_files.all? { |name, oid| newer_files.fetch(id, {})[name] == oid }
                  raise AttemptErrors::EvidenceUnavailable, "canonical inventory history removed or rewrote event bytes"
                end
              end
              snapshots.each do |id, events|
                events.each { |event| introductions.fetch(id)[event.fetch("digest")] = node.first }
              end
            end
            newer_chains, newer_files = chains, files
          end
          freeze_inventory_projection("commit" => commit, "events" => root_events, "introductions" => introductions)
        rescue KeyError, TypeError, ArgumentError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "canonical inventory history is unverifiable"
        end

        def canonical_history_nodes!(commit)
          verify_commit!(commit)
          topology, error, status = git("rev-list", "--first-parent", "--parents",
            "--max-count=#{HISTORY_LIMIT + 1}", commit)
          nodes = topology.lines.map(&:split)
          unless status.success? && !nodes.empty? && nodes.size <= HISTORY_LIMIT &&
              nodes.all? { |node| node.size.between?(1, 2) && node.all? { |sha| sha.match?(/\A[0-9a-f]{40}\z/) } } &&
              nodes.each_cons(2).all? { |left, right| left[1] == right[0] } && nodes.last.size == 1
            raise AttemptErrors::EvidenceUnavailable, "canonical history topology is unsupported or incomplete: #{error}"
          end
          nodes
        end

        def validated_attempt_chains!(events)
          chains = events.group_by { |event| event.fetch("attempt_id") }
          unless chains.values.all? { |chain| Models::EvidenceEvent.chain_valid?(chain) }
            raise AttemptErrors::EvidenceUnavailable, "historical canonical event chain is corrupt"
          end
          chains
        end

        def freeze_inventory_projection(value)
          case value
          when Hash
            value.to_h { |key, item| [freeze_inventory_projection(key), freeze_inventory_projection(item)] }.freeze
          when Array
            value.map { |item| freeze_inventory_projection(item) }.freeze
          when String
            value.dup.freeze
          else
            value.freeze
          end
        end
        private :canonical_history_nodes!, :validated_attempt_chains!, :freeze_inventory_projection

        # Append accepted events to the journal under lock + CAS.
        #
        # @param assignment_id [String] Assignment ID (journal path segment)
        # @param attempt_id [String] Attempt ID (commit message + dedupe scope)
        # @param events [Array<Hash>] Event payloads from Models::EvidenceEvent.build
        # @return [String] Journal commit SHA after the append
        # @raise [AttemptErrors::EvidenceUnavailable] when the ref stays conflicting
        def append(assignment_id:, attempt_id:, events:)
          return ref_value if events.empty?

          with_lock do
            CAS_ATTEMPTS.times do
              # Re-read the authoritative value every attempt. nil means the
              # ref does not exist yet; ensure_checkout! seeds it, so re-read
              # before computing the compare-and-swap baseline.
              old = ref_value
              ensure_checkout!
              old = ref_value if old.nil?
              sync_checkout(old)
              written = write_event_files(assignment_id, events)
              new_commit = written.zero? ? old : commit_events(assignment_id, attempt_id, events)
              return new_commit if update_ref_cas(new_commit, old)

              # CAS conflict: another writer advanced the ref. The next pass
              # resets the checkout to the authoritative tree and replays
              # only the events that are still missing (duplicates skipped).
            end

            raise AttemptErrors::EvidenceUnavailable,
              "Evidence ref #{@ref} stayed conflicting after #{CAS_ATTEMPTS} compare-and-swap attempts"
          end
        end

        # Build an event against the latest chain while holding the ref lock.
        # Re-run the eligibility guard on each CAS retry, never append a
        # stale chain continuation after another accepted writer.
        def record(assignment_id:, attempt_id:, type:, payload:, guard: nil)
          with_lock do
            CAS_ATTEMPTS.times do
              old = ref_value
              ensure_checkout!
              old = ref_value if old.nil?
              sync_checkout(old)
              guard&.call
              previous = read_events(assignment_id).reverse.find { |event| event["attempt_id"] == attempt_id }&.fetch("digest")
              event = Models::EvidenceEvent.build(type: type, attempt_id: attempt_id,
                payload: payload, previous_digest: previous)
              write_event_files(assignment_id, [event])
              commit = commit_events(assignment_id, attempt_id, [event])
              return commit if update_ref_cas(commit, old)
            end
            raise AttemptErrors::EvidenceUnavailable, "Evidence ref stayed conflicting during event recording"
          end
        end

        # Read all journal events recorded for an assignment, ordered by the
        # digest chain (never by filename: same-second events sort
        # alphabetically, which can invert lifecycle order).
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Hash>] Parsed events in journal order
        def read_events(assignment_id, commit: ref_value)
          return [] if commit.nil?
          read_event_snapshots!([assignment_id], commit: commit).first.fetch(assignment_id)
        end

        # Bounded argv/blob batches from the same immutable tree. Preserve the
        # actual file OIDs alongside parsed chains for introduction proofs.
        def read_event_snapshots!(assignment_ids, commit:)
          unless assignment_ids.is_a?(Array) && !assignment_ids.empty? && assignment_ids.size <= HISTORY_LIMIT &&
              assignment_ids.uniq.size == assignment_ids.size && assignment_ids.all? { |id| id.is_a?(String) && id.match?(JournalMutation::ID) }
            raise AttemptErrors::EvidenceUnavailable, "canonical assignment selectors are invalid"
          end
          events = assignment_ids.to_h { |id| [id, []] }
          files = assignment_ids.to_h { |id| [id, {}] }
          entries = []
          assignment_ids.each_slice(64) do |ids|
            paths, stderr, status = git("ls-tree", "-r", "-l", commit, "--", *ids.map { |id| "execution/#{id}/events/" })
            raise AttemptErrors::EvidenceUnavailable, "Cannot read journal events: #{stderr}" unless status.success?
            paths.lines.each do |line|
              metadata, path = line.chomp.split("\t", 2)
              next unless path&.end_with?(".json")
              _mode, kind, oid, size = metadata.split
              id = path.split("/")[1]
              unless events.key?(id) && path.start_with?("execution/#{id}/events/") && kind == "blob" &&
                  oid&.match?(/\A[0-9a-f]{40}\z/) && size&.match?(/\A(?:0|[1-9][0-9]*)\z/)
                raise AttemptErrors::EvidenceUnavailable, "canonical event blob selection is invalid"
              end
              name = path.delete_prefix("execution/#{id}/events/")
              raise AttemptErrors::EvidenceUnavailable, "canonical event file is ambiguous" if files.fetch(id).key?(name)
              files.fetch(id)[name] = oid
              entries << [oid, size.to_i, id]
            end
          end
          batches = []
          entries.each do |entry|
            batches << [] if batches.empty? || batches.last.size == 64 ||
              (!batches.last.empty? && batches.last.sum { |item| item[1] } + entry[1] > EVENT_BATCH_BYTES)
            batches.last << entry
          end
          batches.each do |batch|
            selected = batch.map { |oid, size, _id| [oid, size] }
            contents = decode_event_blobs!(selected, read_event_blobs!(selected))
            batch.zip(contents).each { |(_oid, _size, id), content| events.fetch(id) << JSON.parse(content) }
          end
          events.each_value do |chain|
            digests = chain.map { |event| event.fetch("digest") }
            unless digests.uniq.size == digests.size
              raise AttemptErrors::EvidenceUnavailable, "canonical event digest is ambiguous"
            end
          end
          [events.transform_values { |chain| order_by_chain(chain) }, files]
        rescue JSON::ParserError
          raise AttemptErrors::EvidenceUnavailable, "Corrupt canonical journal event"
        end
        private :read_event_snapshots!

        # Accepted receipt payloads recorded for an assignment.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Hash>] Accepted receipt payloads (digest included)
        def accepted_receipts(assignment_id)
          read_events(assignment_id)
            .select { |event| event["type"] == "receipt_accepted" }
            .map { |event| event.dig("payload", "receipt") }
            .compact
        end

        # Reserve a globally unique service request in the same evidence ref
        # as its owning attempt. The request index and attempt event are one
        # Git commit, so a ref race cannot admit two effects for one ID. An
        # exact authorization reference is consumed by its first live claim:
        # a second request presenting the same operation/project/target
        # authorization is rejected instead of dispatching a duplicate effect.
        # Dispatching callers claim directly as +uncertain+ so no commit
        # window exists where a stranded claim reads as accepted.
        def claim_service_request(binding, state: "accepted", guard: nil)
          guard ||= -> { authorization_conflict(binding) }
          update_service_request(binding.fetch("request_id"), expected: nil,
            replacement: binding.merge("state" => state, "claimed_at" => Time.now.utc.iso8601(9)),
            event_type: "service_claim", guard: guard)
        end

        # Reject a service request. A request not yet on file gets its
        # auditable rejection claim (which never consumed the authorization);
        # an existing live claim transitions to rejected but stays consuming:
        # only attributable evidence that the effect did not occur may free a
        # dispatched authorization, never a bare rejection.
        def reject_service_request(binding, reason:)
          request_id = binding.fetch("request_id")
          existing = service_request(request_id)
          if existing
            unless existing.except("state", "receipt", "reason", "claimed_at", "failed_at") == binding.except("state", "receipt", "reason", "claimed_at", "failed_at")
              raise AttemptErrors::Conflict, "Service request #{request_id} has different input"
            end
            return existing if existing["state"] == "rejected"
            return update_service_request(request_id, expected: existing,
              replacement: existing.merge("state" => "rejected", "reason" => reason),
              event_type: "service_transition")
          end
          update_service_request(request_id, expected: nil,
            replacement: binding.merge("state" => "rejected", "reason" => reason, "consumed" => false),
            event_type: "service_claim")
        end

        # Terminal writes are validated HERE at the journal boundary —
        # receipt schema, binding against the current record, and attested
        # outcome — so no caller-supplied flag decides trust. The
        # coordinator additionally performs content-level attestation and
        # file verification.
        def transition_service_request(request_id, state:, receipt: nil, validated: false)
          unless %w[succeeded failed uncertain rejected failed-settled].include?(state)
            raise ArgumentError, "invalid service request state"
          end
          current = service_request(request_id)
          raise AttemptErrors::NotFound, "Service request #{request_id} not found" unless current
          # Terminal states are immutable; failed-settled is reached only
          # from a dispatched (failed, uncertain, or consumed-rejected)
          # effect with a validated no-effect receipt.
          consumed_rejected = current["state"] == "rejected" && current["consumed"] != false
          if %w[succeeded failed-settled].include?(current["state"]) ||
              (current["state"] == "rejected" && !consumed_rejected) ||
              (consumed_rejected && state != "failed-settled")
            raise AttemptErrors::InvalidState, "Service request #{request_id} is terminal"
          end
          validate_terminal_receipt!(current, state, receipt) if terminal_state?(state)
          stamped = current.merge("state" => state, "receipt" => receipt)
          stamped["failed_at"] = Time.now.utc.iso8601(9) if state == "failed"
          update_service_request(request_id, expected: current,
            replacement: stamped,
            event_type: "service_transition")
        end

        TERMINAL_RECEIPT_FIELDS = %w[assignment_id attempt_id candidate_head evidence executor_uid
          input_digest operation outcome project_id request_id target transport].freeze
        TERMINAL_BINDING_FIELDS = %w[request_id assignment_id attempt_id project_id operation
          input_digest target candidate_head executor_uid transport].freeze

        def terminal_state?(state)
          %w[succeeded failed failed-settled].include?(state)
        end

        def validate_terminal_receipt!(current, state, receipt, pending: nil)
          unless receipt.is_a?(Hash) && receipt.keys.sort == TERMINAL_RECEIPT_FIELDS.sort
            raise AttemptErrors::ReceiptRejected,
              "Service terminal receipt has invalid fields"
          end
          TERMINAL_BINDING_FIELDS.each do |key|
            unless receipt[key] == current[key]
              raise AttemptErrors::ReceiptRejected, "Service terminal receipt does not match #{key}"
            end
          end
          expected_outcome = (state == "failed-settled") ? "failed" : state
          evidence_items = receipt["evidence"]
          valid_evidence = evidence_items.is_a?(Array) && !evidence_items.empty? &&
            evidence_items.all? do |item|
              item.is_a?(Hash) && item.keys.sort == %w[ref sha256] &&
                item["ref"].is_a?(String) && item["ref"].match?(/\A[a-zA-Z0-9_.:\/-]{1,256}\z/) &&
                item["sha256"].is_a?(String) && item["sha256"].match?(/\A[0-9a-f]{64}\z/)
            end
          executor_valid = receipt["executor_uid"].is_a?(Integer) && receipt["executor_uid"] >= 0
          unless receipt["outcome"] == expected_outcome && executor_valid && valid_evidence
            raise AttemptErrors::ReceiptRejected, "Service terminal receipt has invalid executor or evidence"
          end
          if state == "failed-settled" &&
              !receipt["evidence"].any? { |item| item["ref"].end_with?("no-effect") }
            raise AttemptErrors::ReceiptRejected,
              "Service settlement requires a no-effect attestation artifact"
          end
          if @mode == :protected
            if current["operation"] == "prune-preserved-workspace" && %w[succeeded failed-settled].include?(state)
              # The same installed evidence reader owns the entire imported
              # cleanup pair; individual textual markers cannot authorize it.
              contents = @evidence_reader.call(evidence_items, current, state, pending)
              unless contents.is_a?(Array) && contents.size == evidence_items.size &&
                  contents.each_with_index.all? { |content, index| content.is_a?(String) && Digest::SHA256.hexdigest(content.b) == evidence_items.fetch(index).fetch("sha256") }
                raise AttemptErrors::ReceiptRejected, "Canonical cleanup evidence is unverifiable"
              end
              return true
            end
            evidence_items.each do |item|
              content = @evidence_reader.call(item, current, state, pending)
              unless content.is_a?(String) && Digest::SHA256.hexdigest(content.b) == item["sha256"]
                raise AttemptErrors::ReceiptRejected, "Canonical service evidence is unverifiable"
              end
              verify_service_attestation!(content, current, state)
            end
            return true
          end
          repo_root = File.realpath(@repo_root)
          receipt["evidence"].each do |item|
            path = File.expand_path(item["ref"], repo_root)
            real = begin
              File.realpath(path)
            rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
              raise AttemptErrors::ReceiptRejected,
                "Service terminal receipt evidence is unverifiable: #{item["ref"]}"
            end
            intact = begin
              real.start_with?(repo_root + File::SEPARATOR) &&
                Digest::SHA256.file(real).hexdigest == item["sha256"]
            rescue Errno::EACCES, Errno::ELOOP
              false
            end
            raise AttemptErrors::ReceiptRejected,
              "Service terminal receipt evidence is unverifiable: #{item["ref"]}" unless intact
            verify_service_attestation!(File.read(real), current, state)
          end
        end

        def service_request(request_id, commit: ref_value)
          read_service_request(request_id, commit: commit, pending: {commit: commit})
        end

        # A read operation owns this view only until its caller returns. The
        # original complete first-parent/raw-blob owner supplies every fact;
        # it is never retained on the journal or reused for another operation.
        ServiceReadView = Struct.new(:journal, :commit, :inventory, :projection, keyword_init: true)

        def service_settlement_read(request_id, commit: ref_value)
          verify_canonical_prefix!(commit: commit)
          record = read_service_request(request_id, commit: commit, pending: {commit: commit}, terminal: false)
          return {record: nil, settlement_context: nil, read_view: nil}.freeze unless record
          id = record.fetch("assignment_id")
          events = read_events(id, commit: commit)
          selectors = events.map { |event| event.fetch("digest") }
          introductions = event_commits!(assignment_id: id, event_digests: selectors, commit: commit)
          inventory = freeze_inventory_projection("commit" => commit, "events" => {id => events}, "introductions" => {id => introductions})
          view = ServiceReadView.new(journal: self, commit: commit, inventory: inventory)
          if @mode == :protected && terminal_state?(record["state"])
            validate_terminal_receipt!(record, record["state"], record["receipt"],
              pending: {commit: commit, service_read_view: view})
          end
          view.freeze
          {record: freeze_inventory_projection(record), settlement_context: view.projection, read_view: view}.freeze
        end

        def read_service_request(request_id, commit:, pending:, terminal: true)
          validate_request_id!(request_id)
          value = commit
          return nil unless value
          out, stderr, status = git("show", "#{value}:#{service_request_path(request_id)}")
          if status.success?
            record = JSON.parse(out)
            verify_service_record!(record, commit: value) if @mode == :protected
            validate_terminal_receipt!(record, record["state"], record["receipt"], pending: pending) if terminal && @mode == :protected && terminal_state?(record["state"])
            return record
          end
          return nil if stderr.include?("does not exist") || stderr.include?("exists on disk")
          raise AttemptErrors::EvidenceUnavailable, "Cannot read service request: #{stderr}"
        rescue JSON::ParserError
          raise AttemptErrors::EvidenceUnavailable, "Corrupt service request #{request_id}"
        end

        private :read_service_request

        # Every service request recorded in this evidence ref, whatever the
        # owning assignment. Backs the journal-wide request-ID and
        # authorization-consumption checks.
        # Another live request holding the same exact authorization for the
        # same operation, project and target. Only requests that were born
        # rejected (never claimed, never dispatched) leave the decision
        # unconsumed: a withdrawn or failed claim keeps it consumed until
        # attributable evidence proves the effect did not occur.
        def authorization_conflict(binding)
          authorization = binding["authorization"]
          return nil unless authorization.is_a?(String) && !authorization.empty?
          service_request_records.find do |other|
            next false if other["request_id"] == binding.fetch("request_id")
            next false if other["state"] == "rejected" && other["consumed"] == false
            # A settled failure frees the exact authorization only while its
            # no-effect evidence remains verifiable in the repository.
            next false if other["state"] == "failed-settled" && settlement_evidence_intact?(other)
            other["authorization"] == authorization &&
              other["operation"] == binding.fetch("operation") &&
              other["project_id"] == binding.fetch("project_id") &&
              other["target"] == binding.fetch("target")
          end
        end

        def settlement_evidence_intact?(record)
          receipt = record["receipt"]
          return false unless receipt.is_a?(Hash)
          if @mode == :protected
            commit = ref_value
            verify_service_record!(record, commit: commit)
            validate_terminal_receipt!(record, "failed-settled", receipt, pending: {commit: commit})
            return true
          end
          repo_root = File.realpath(@repo_root)
          Array(receipt["evidence"]).all? do |item|
            path = File.expand_path(item["ref"].to_s, repo_root)
            real = begin
              File.realpath(path)
            rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
              next false
            end
            begin
              real.start_with?(repo_root + File::SEPARATOR) &&
                Digest::SHA256.file(real).hexdigest == item["sha256"]
            rescue Errno::EACCES, Errno::ELOOP
              false
            end
          end
        rescue AttemptErrors::EvidenceUnavailable, AttemptErrors::ReceiptRejected
          false
        end

        def service_request_records(commit: ref_value)
          value = commit
          return [] unless value
          paths, stderr, status = git("ls-tree", "-r", "--name-only", value, "--", "execution/requests/")
          raise AttemptErrors::EvidenceUnavailable, "Cannot read service request index: #{stderr}" unless status.success?
          paths.lines.map(&:strip).select { |path| path.end_with?(".json") }.filter_map do |path|
            content, error, read_status = git("show", "#{value}:#{path}")
            unless read_status.success?
              raise AttemptErrors::EvidenceUnavailable, "Cannot read service request #{path}: #{error}"
            end
            record = JSON.parse(content)
            verify_service_record!(record, commit: value) if @mode == :protected
            record
          end
        rescue JSON::ParserError
          raise AttemptErrors::EvidenceUnavailable, "Corrupt service request index"
        end

        def service_requests(assignment_id)
          request_ids = read_events(assignment_id)
            .select { |event| event["type"] == "service_claim" }
            .map { |event| event.dig("payload", "request_id") }.compact.uniq
          request_ids.filter_map { |request_id| service_request(request_id) }
        end

        # All attempts derivable from the journal, reconstructed from intent
        # and process_start facts with journal-authoritative state. The
        # journal is the owner of attempt-state interpretation.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Models::Attempt>] Derived attempts
        def derived_attempts(assignment_id)
          events = read_events(assignment_id)
          by_attempt = events.group_by { |event| event["attempt_id"] }
          by_attempt.delete(nil)

          by_attempt.filter_map do |attempt_id, attempt_events|
            intent = attempt_events.find { |event| event["type"] == "intent" }
            next unless intent

            state = derive_state(attempt_events)
            next if state.nil?

            build_attempt(assignment_id, attempt_id, intent["payload"], attempt_events, state)
          end
        end

        # Non-terminal attempts derived from the journal.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Models::Attempt>] Active attempts
        def active_attempts(assignment_id)
          derived_attempts(assignment_id).reject(&:terminal?)
        end

        # Assignment IDs present in the journal, discovered from the evidence
        # ref itself (works even when the local assignment cache is gone).
        #
        # @return [Array<String>] Assignment IDs with journal evidence
        def assignment_ids(commit: ref_value)
          value = commit
          return [] if value.nil?

          paths, stderr, status = git("ls-tree", "-d", "--name-only", value, "--", "execution/")
          raise AttemptErrors::EvidenceUnavailable, "Cannot discover journal assignments: #{stderr}" unless status.success?
          paths.lines.map { |path| path.strip.delete_prefix("execution/") }
            .reject { |id| id == "requests" }.sort
        end

        private

        # Sizes come from the same immutable tree selection. Batch memory is
        # bounded by that selection; an existing larger single event retains
        # its previous read semantics rather than gaining a lifetime ceiling.
        def read_event_blobs!(entries)
          limit = entries.sum { |_oid, size| size + 128 }
          return @read_boundary.blob_batch(entries.map(&:first), output_limit: limit) if @read_boundary
          result = Herdr::Molecules::BoundedProcess.call(["git", "cat-file", "--batch"],
            chdir: File.expand_path(@repo_root), stdin_data: entries.map { |oid, _size| "#{oid}\n" }.join,
            timeout_s: 30, output_limit: limit)
          unless result.status.success? && !result.oversized
            raise AttemptErrors::EvidenceUnavailable, "canonical blob batch is unavailable or exceeds selected sizes"
          end
          result.stdout.to_s.b
        rescue Timeout::Error, Herdr::Molecules::BoundedProcess::PostLaunchError, IOError, SystemCallError => error
          raise AttemptErrors::EvidenceUnavailable, "canonical blob batch is unavailable: #{error.message}"
        end

        def decode_event_blobs!(entries, output)
          output = output.b
          offset = 0
          entries.map do |oid, size|
            ending = output.index("\n", offset)
            unless ending && ending - offset <= 127 && output.byteslice(offset, ending - offset) == "#{oid} blob #{size}"
              raise AttemptErrors::EvidenceUnavailable, "canonical blob batch header is invalid"
            end
            offset = ending + 1
            content = output.byteslice(offset, size)
            unless content&.bytesize == size && output.byteslice(offset + size, 1) == "\n" &&
                Digest::SHA1.hexdigest("blob #{size}\0" + content) == oid
              raise AttemptErrors::EvidenceUnavailable, "canonical blob batch bytes are invalid"
            end
            offset += size + 1
            content
          end.tap do
            unless offset == output.bytesize
              raise AttemptErrors::EvidenceUnavailable, "canonical blob batch has unexpected trailing bytes"
            end
          end
        end

        def update_service_request(request_id, expected:, replacement:, event_type:, guard: nil)
          validate_request_id!(request_id)
          with_lock do
            CAS_ATTEMPTS.times do
              old = ref_value
              ensure_checkout!
              old = ref_value if old.nil?
              sync_checkout(old)
              prepared = prepare_service_update(request_id: request_id, expected: expected,
                replacement: replacement, event_type: event_type, guard: guard)
              return prepared.fetch(:record) if prepared[:replayed]
              write_service_records([prepared])
              assignment_id = replacement.fetch("assignment_id")
              attempt_id = replacement.fetch("attempt_id")
              prior = read_events(assignment_id).reverse
                .find { |entry| entry["attempt_id"] == attempt_id }&.fetch("digest")
              event = Models::EvidenceEvent.build(type: event_type, attempt_id: attempt_id,
                payload: prepared.fetch(:event).fetch(:payload), previous_digest: prior)
              write_event_files(assignment_id, [event])
              git!("-C", checkout_dir, "add", "--", service_request_path(request_id),
                "execution/#{assignment_id}/events")
              stage_service_records([prepared])
              state = replacement.fetch("state")
              git!("-C", checkout_dir, "-c", "user.name=ace-assign", "-c", "user.email=ace-assign@localhost",
                "commit", "-m", "evidence: service request #{request_id} #{state}")
              commit = git!("-C", checkout_dir, "rev-parse", "HEAD").first
              return replacement.merge("journal_commit" => commit) if update_ref_cas(commit, old)
            end
            raise AttemptErrors::EvidenceUnavailable, "Service request ref stayed conflicting"
          end
        end

        # Shared owner for ordinary service writes and atomic authority
        # imports. Call only after checkout sync, under this journal's CAS lock.
        def prepare_service_update(request_id:, expected:, replacement:, event_type:, guard: nil, pending: nil)
          validate_request_id!(request_id)
          unless replacement.is_a?(Hash) && replacement["request_id"] == request_id &&
              %w[service_claim service_transition service_challenge].include?(event_type) &&
              %w[accepted uncertain rejected succeeded failed failed-settled].include?(replacement["state"])
            raise ArgumentError, "invalid service update plan"
          end
          existing = service_request(request_id)
          if expected.nil? && existing
            return {record: existing, replayed: true} if existing.except("state", "receipt", "reason", "claimed_at") ==
              replacement.except("state", "receipt", "reason", "claimed_at")
            raise AttemptErrors::Conflict, "Service request #{request_id} has different input"
          end
          if expected && existing != expected
            raise AttemptErrors::Conflict, "Service request #{request_id} changed during transition"
          end
          if expected.nil?
            unless event_type == "service_claim" && %w[accepted uncertain rejected].include?(replacement["state"])
              raise AttemptErrors::InvalidState, "Service request needs an initial claim"
            end
            if %w[accepted uncertain].include?(replacement["state"])
              if replacement["authorization"].to_s.start_with?("proposal-")
                unless respond_to?(:proposal_authorize!, true)
                  raise AttemptErrors::UnauthorizedIdentity, "Canonical proposal producer is unavailable"
                end
                proposal_authorize!(replacement["authorization"], replacement)
              end
              conflict = authorization_conflict(replacement)
              raise_authorization_conflict!(conflict) if conflict
            end
          else
            challenge_update = event_type == "service_challenge" && pending && pending[:operation] == "claim_service_settlement" &&
              existing["state"] == replacement["state"] && existing["receipt"] == replacement["receipt"] &&
              %w[uncertain failed].include?(existing["state"])
            unless event_type == "service_transition" || challenge_update
              raise AttemptErrors::InvalidState, "Existing service request needs a transition"
            end
            terminal = %w[succeeded failed rejected failed-settled].include?(existing["state"])
            settlement = replacement["state"] == "failed-settled" &&
              (existing["state"] == "failed" || (existing["state"] == "rejected" && existing["consumed"] != false))
            if terminal && !settlement && !challenge_update
              raise AttemptErrors::InvalidState, "Service request #{request_id} is terminal"
            end
            mutable = %w[state receipt reason claimed_at failed_at dispatch_phase no_effect_challenge
              challenge_generation challenge_event_digest completion_digest no_effect_completion_digest]
            # Only this authenticated fresh dispatch may introduce the fixed
            # root collaborator identity. It is immutable on every later update.
            if @mode == :protected && pending && pending[:operation] == "begin_dispatch" &&
                existing["operation"] == "prune-preserved-workspace" && existing["dispatch_phase"] == "issued" &&
                replacement["dispatch_phase"] == "dispatch_started" &&
                %w[operation_owner_binding executor_process_binding].none? { |key| existing.key?(key) } &&
                %w[operation_owner_binding executor_process_binding].all? { |key| replacement.key?(key) }
              mutable.concat(%w[operation_owner_binding executor_process_binding])
            end
            unless existing.except(*mutable) == replacement.except(*mutable)
              raise AttemptErrors::Conflict, "Service request #{request_id} changed immutable binding"
            end
          end
          conflict = guard&.call
          raise_authorization_conflict!(conflict) if conflict
          @service_authorizer.call(existing, replacement, pending) if @mode == :protected
          validate_terminal_receipt!(replacement, replacement["state"], replacement["receipt"], pending: pending) if terminal_state?(replacement["state"])
          payload = {"request_id" => request_id, "state" => replacement.fetch("state"),
                     "input_digest" => replacement.fetch("input_digest"),
                     "record_digest" => Atoms::EvidenceDigest.digest(replacement),
                     "receipt_digest" => replacement["receipt"] && Atoms::EvidenceDigest.digest(replacement["receipt"])}
          {record: replacement, path: service_request_path(request_id),
           event: {type: event_type, payload: payload}, replayed: false}
        end

        def prepare_service_updates(updates, assignment_id:, attempt_id:, pending:)
          unless updates.is_a?(Array) && updates.length <= 1
            raise ArgumentError, "one service update is allowed per authority mutation"
          end
          updates.map do |update|
            unless update.is_a?(Hash) && update.keys.sort == %i[event_type expected replacement request_id].sort &&
                update.dig(:replacement, "assignment_id") == assignment_id && update.dig(:replacement, "attempt_id") == attempt_id
              raise ArgumentError, "service update does not match mutation attempt"
            end
            prepare_service_update(**update, pending: pending)
          end.reject { |prepared| prepared[:replayed] }
        end

        def write_service_records(records)
          records.each do |prepared|
            path = File.join(checkout_dir, prepared.fetch(:path))
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, JSON.pretty_generate(prepared.fetch(:record)))
          end
        end

        def stage_service_records(records)
          stage_mutation_blobs(records.to_h { |prepared| [prepared.fetch(:path), JSON.pretty_generate(prepared.fetch(:record))] })
        end

        def verify_service_record!(record, commit: ref_value)
          events = read_events(record.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == record.fetch("attempt_id") }
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "Canonical service event chain is unverifiable"
          end
          event = events.reverse.find do |entry|
            %w[service_claim service_transition service_challenge].include?(entry["type"]) && entry.dig("payload", "request_id") == record["request_id"]
          end
          unless event && event.dig("payload", "record_digest") == Atoms::EvidenceDigest.digest(record)
            raise AttemptErrors::EvidenceUnavailable, "Canonical service record does not match accepted event"
          end
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "Canonical service record has invalid binding"
        end

        def raise_authorization_conflict!(conflict)
          raise AttemptErrors::Conflict,
            "Authorization reference already consumed by request #{conflict.fetch('request_id')}"
        end

        def verify_service_attestation!(content, request, state)
          expression = /^ace-service-attestation request:#{Regexp.escape(request["request_id"])} input:#{Regexp.escape(request["input_digest"])} outcome:(\S+)( no-effect:(\S+))?$/
          attested = content.scan(expression).first
          outcome = state == "failed-settled" ? "failed" : state
          unless attested && attested.first == outcome && (state != "failed-settled" || attested[2] == "true")
            raise AttemptErrors::ReceiptRejected, "Service terminal evidence does not attest #{outcome}"
          end
        end

        def service_request_path(request_id)
          "execution/requests/#{request_id}.json"
        end

        def validate_request_id!(request_id)
          return if request_id.is_a?(String) && request_id.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/)
          raise ArgumentError, "invalid service request ID"
        end

        # Latest lifecycle state implied by the events, or nil when the
        # events do not describe a full attempt (intent missing).
        def derive_state(events)
          CanonicalAttemptState.derive(events)
        end

        def build_attempt(assignment_id, attempt_id, intent_payload, events, state)
          process_start = events.reverse.find do |event|
            event["type"] == "process_start" && event["attempt_id"] == attempt_id
          end
          candidate_head = nil
          events.each do |event|
            case event["type"]
            when "candidate_invalidated" then candidate_head = nil
            when "receipt_accepted" then candidate_head ||= event.dig("payload", "receipt", "head")
            when "delivery"
              candidate_head = event.dig("payload", "head") if %w[intent result].include?(event.dig("payload", "stage"))
            end
          end
          binding = Models::AttemptBinding.new(
            attempt_id: attempt_id,
            assignment_id: assignment_id,
            scope: intent_payload["scope"],
            project_id: intent_payload["project_id"],
            task_id: intent_payload["task_id"],
            actor: process_start&.dig("payload", "actor") || intent_payload["actor"] || "recovered",
            role: process_start&.dig("payload", "role") || intent_payload["role"] || "coordinator",
            runtime: process_start&.dig("payload", "runtime") || intent_payload["runtime"] || "recovered",
            base_head: intent_payload["base_head"],
            evidence_git_ref: ref,
            created_at: parse_event_time(intent_time(events, attempt_id))
          )
          Models::Attempt.new(
            binding: binding,
            state: state,
            candidate_head: candidate_head,
            journal_commit: ref_value
          )
        end

        def intent_time(events, attempt_id)
          intent = events.find { |event| event["type"] == "intent" && event["attempt_id"] == attempt_id }
          intent&.dig("recorded_at")
        end

        def parse_event_time(value)
          return Time.now.utc if value.nil?

          require "time"
          Time.parse(value)
        rescue ArgumentError
          Time.now.utc
        end

        private

        def event_files(assignment_id)
          Dir.glob(File.join(checkout_dir, "execution", assignment_id, "events", "*.json")).sort
        end

        # Order events by following previous_digest links from chain roots;
        # orphaned events (unknown predecessor) keep filename order after the
        # resolved chains.
        def order_by_chain(events)
          by_digest = {}
          events.each { |event| by_digest[event["digest"]] = event }

          next_of = {}
          events.each do |event|
            previous = event["previous_digest"]
            next_of[previous] = event if previous && by_digest.key?(previous)
          end

          roots = events.reject do |event|
            previous = event["previous_digest"]
            previous && by_digest.key?(previous)
          end

          ordered = []
          visited = {}
          roots.each do |root|
            cursor = root
            while cursor && !visited[cursor["digest"]]
              visited[cursor["digest"]] = true
              ordered << cursor
              cursor = next_of[cursor["digest"]]
            end
          end

          ordered + events.reject { |event| visited[event["digest"]] }
        end

        def event_filename(event)
          "#{event["recorded_at"].to_s.tr("-:T Z", "")}-#{event["type"]}-#{event["digest"][0, 12]}.json"
        end

        def write_event_files(assignment_id, events)
          written = 0
          events.each do |event|
            path = File.join(checkout_dir, "execution", assignment_id, "events", event_filename(event))
            next if File.exist?(path)

            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, JSON.pretty_generate(event))
            written += 1
          end
          written
        end

        def commit_events(assignment_id, attempt_id, events)
          types = events.map { |event| event["type"] }.uniq.join(",")
          git!("-C", checkout_dir, "add", "-A", "execution/#{assignment_id}")
          git!(
            "-C", checkout_dir,
            "-c", "user.name=ace-assign", "-c", "user.email=ace-assign@localhost",
            "commit", "-m", "evidence: #{assignment_id} #{attempt_id} (#{types})"
          )
          git!("-C", checkout_dir, "rev-parse", "HEAD").first
        end

        # Expected-old-value compare-and-swap; returns false on conflict.
        # A nil expectation is the create case: the ref must not exist.
        def update_ref_cas(new_commit, expected_old)
          return true if !expected_old.nil? && new_commit == expected_old

          expected = expected_old || ("0" * 40)
          _out, stderr, status = git("update-ref", @ref, new_commit, expected)
          return true if status.success?

          raise AttemptErrors::EvidenceUnavailable, "Cannot update evidence ref #{@ref}: #{stderr}" if git_broken?(stderr)

          false
        end

        def checkout_dir
          File.join(@checkout_root, "journal")
        end

        def lock_path
          File.join(@checkout_root, ".evidence.lock")
        end

        def with_lock
          raise AttemptErrors::EvidenceUnavailable, "read-only journal cannot mutate canonical evidence" if @read_boundary
          FileUtils.mkdir_p(@checkout_root)
          File.open(lock_path, File::RDWR | File::CREAT) do |lock|
            lock.flock(File::LOCK_EX)
            begin
              yield
            rescue StandardError
              # No rejected writer may leave staged or untracked transaction
              # data for the next writer to admit. This checkout is disposable.
              sync_checkout(ref_value) if File.exist?(File.join(checkout_dir, ".git"))
              raise
            ensure
              lock.flock(File::LOCK_UN)
            end
          end
        end

        def ensure_checkout!
          return if detached_worktree_at?(checkout_dir)

          FileUtils.rm_rf(checkout_dir)
          git!("worktree", "prune")
          value = ref_value
          if value.nil?
            seed_ref
            value = ref_value
          end
          git!("worktree", "add", "--detach", checkout_dir, value)
        end

        # Seed the evidence ref with an empty-tree commit so a worktree can
        # attach before any real evidence exists. The create is a
        # compare-and-swap against the zero SHA: a writer that loses the
        # race keeps the winner's ref instead of resetting it.
        def seed_ref
          empty_tree = git!("mktree").first
          seed = git!("-c", "user.name=ace-assign", "-c", "user.email=ace-assign@localhost",
            "commit-tree", empty_tree, "-m", "seed: ace-assign execution evidence").first
          _out, stderr, status = git("update-ref", @ref, seed, "0" * 40)
          return if status.success?

          raise AttemptErrors::EvidenceUnavailable, "Cannot seed evidence ref #{@ref}: #{stderr}" if git_broken?(stderr)
        end

        def detached_worktree_at?(path)
          dot_git = File.join(path, ".git")
          return false unless File.exist?(dot_git)

          out, _s = git("-C", path, "rev-parse", "--abbrev-ref", "HEAD")
          out.to_s.strip == "HEAD"
        end

        # Sync the disposable checkout to an authoritative ref value.
        def sync_checkout(target)
          return if target.nil?

          git!("-C", checkout_dir, "reset", "--hard", target)
          # All writers use this boundary, including CAS retries. Only the
          # journal's disposable namespaces are cleaned, never the candidate.
          git!("-C", checkout_dir, "clean", "-fd", "--", "execution", "evidence")
        rescue AttemptErrors::EvidenceUnavailable
          # Stale, broken, or unregistered worktree: rebuild from scratch.
          FileUtils.rm_rf(checkout_dir)
          git!("worktree", "prune")
          git!("worktree", "add", "--detach", checkout_dir, target)
        end

        def git(*argv)
          return @read_boundary.call(argv) if @read_boundary
          unless File.directory?(@repo_root)
            return ["", "repository root missing: #{@repo_root}", FAILED_RESULT]
          end

          out, stderr, status = Open3.capture3("git", *argv, chdir: @repo_root, stdin_data: "")
          [out.to_s.strip, stderr.to_s.strip, status]
        end

        def git!(*argv)
          out, stderr, status = git(*argv)
          unless status.success?
            raise AttemptErrors::EvidenceUnavailable, "git #{argv.join(" ")} failed: #{stderr}"
          end

          [out, stderr, status]
        end

        def git_ok?(*argv)
          git(*argv)[2].success?
        end

        # Distinguish "ref missing" (normal, quiet, no stderr) and expected
        # compare-and-swap conflicts (retryable) from a broken repository or
        # ref store.
        def git_broken?(stderr)
          message = stderr.to_s.strip
          return false if message.empty?
          return false if message.include?("unknown revision") || message.include?("not a valid ref")
          return false if message.include?("cannot lock ref") || message.include?("but expected")

          true
        end

        # Stand-in status for commands that cannot run at all.
        FailedResult = Struct.new(:success?)
        FAILED_RESULT = FailedResult.new(false).freeze

        def default_config(key)
          section = Ace::Assign.config["attempt"]
          section && section[key]
        end
      end
    end
  end
end

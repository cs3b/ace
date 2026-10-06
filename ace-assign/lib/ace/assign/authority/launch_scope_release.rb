# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class LaunchLifecycle
        # Source-only maintenance entry. Transport stop/drain/inhibition belongs
        # to the trusted installer; this method supplies the exact same locks
        # and canonical owner query, without a live endpoint or another ledger.
        def with_execution_slots(mapping_ids:, candidate_deployment:, &block)
          if Thread.current[:ace_assign_maintenance_contexts]&.key?(object_id)
            raise AttemptErrors::Conflict, "maintenance inventory cannot be entered recursively"
          end
          unless block && mapping_ids.is_a?(Array) && mapping_ids.size.between?(1, 256) && mapping_ids.uniq == mapping_ids
            raise ArgumentError, "fixed execution slot selections must be unique and bounded"
          end
          mapping_ids.each { |id| token!(id) }
          inventory = @deployment.maintenance_inventory(candidate_deployment)
          missing = mapping_ids - inventory.map(&:first)
          raise ArgumentError, "maintenance mapping is unavailable" unless missing.empty?
          # Installer publication cannot omit a removed or added fixed root.
          changed = (@deployment.data.fetch("launch_mappings").keys | candidate_deployment.data.fetch("launch_mappings").keys).select do |id|
            original = @deployment.data.fetch("launch_mappings")[id]
            candidate = candidate_deployment.data.fetch("launch_mappings")[id]
            original != candidate || (original && candidate &&
              (@deployment.project(original.fetch("project_id")) != candidate_deployment.project(candidate.fetch("project_id")) ||
               @deployment.authority(original.fetch("authority_id")) != candidate_deployment.authority(candidate.fetch("authority_id"))))
          end
          unless (changed - mapping_ids).empty?
            raise ArgumentError, "maintenance selection omits changed original/candidate mappings"
          end
          selected = inventory.select { |id, _owner, _map| mapping_ids.include?(id) }
          locks = selected.sort_by do |_id, owner, map|
            [owner.authority(map.fetch("authority_id")).fetch("state_root"),
              "execution-slot:#{map.fetch('execution_scope').fetch('slot_id')}"]
          end
          locks.each do |_id, owner, map|
            service = owner.authority(map.fetch("authority_id"))
            verify_maintenance_root!(service.fetch("state_root"), service.fetch("uid"))
          end
          enter = lambda do |offset|
            if offset < locks.size
              _id, owner, map = locks.fetch(offset)
              with_slot(map, deployment: owner) { enter.call(offset + 1) }
            else
              @mutex.synchronize do
                active = Thread.current[:ace_assign_maintenance_contexts] ||= {}
                raise AttemptErrors::Conflict, "maintenance inventory cannot be entered recursively" if active[object_id]
                snapshots = {}
                contexts = selected.map do |id, owner, map|
                  project = owner.project(map.fetch("project_id"))
                  identity = project.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root")
                  journal, commit = snapshots.fetch(identity) do
                    service = owner.authority(map.fetch("authority_id"))
                    identity.values_at(0, 2).each { |root| verify_maintenance_root!(root, service.fetch("uid")) }
                    journal = maintenance_journal_for(owner, map)
                    commit = journal.ref_value
                    unless commit.is_a?(String) && commit.match?(/\A[0-9a-f]{40}\z/)
                      raise AttemptErrors::EvidenceUnavailable, "maintenance canonical commit is unavailable"
                    end
                    unless [journal.repo_root, journal.ref, journal.checkout_root] == identity
                      raise AttemptErrors::EvidenceUnavailable, "maintenance journal differs from fixed descriptor"
                    end
                    journal.verify_commit!(commit)
                    journal.assignment_ids(commit: commit)
                    snapshots[identity] = [journal, commit.dup.freeze]
                  end
                  {mapping_id: id.dup.freeze, journal: journal, commit: commit}.freeze
                end.freeze
                active[object_id] = selected.zip(contexts).to_h { |entry, context| [context.fetch(:mapping_id), [entry, context]] }
                begin
                  block.call(contexts)
                ensure
                  active.delete(object_id)
                end
              end
            end
          end
          enter.call(0)
        end

        def slot_reusable!(mapping_id:, journal:, commit:)
          if Thread.current[:ace_assign_maintenance_contexts]&.key?(object_id)
            require_maintenance_context!(mapping_id, journal, commit)
            raise AttemptErrors::EvidenceUnavailable,
              "complete original authentication and current inventory maintenance verification is unavailable"
          end
          map = @deployment.mapping(mapping_id)
          require_slot_snapshot!(map, journal, commit)
          ensure_slot_available!(map, journal, commit: commit)
          require_slot_snapshot!(map, journal, commit)
          true
        end

        def retire_released_parent!(mapping_id:, journal:, commit:)
          slot_reusable!(mapping_id: mapping_id, journal: journal, commit: commit)
          map = @deployment.mapping(mapping_id)
          slot = map.fetch("execution_scope").fetch("slot_id")
          lineages = journal.assignment_ids(commit: commit).flat_map do |assignment_id|
            journal.read_events(assignment_id, commit: commit).group_by { |event| event.fetch("attempt_id") }.filter_map do |attempt_id, events|
              reservation = events.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
              next unless reservation
              prior_id = reservation.dig("payload", "data", "mapping_id")
              next unless @deployment.mapping(prior_id).fetch("execution_scope").fetch("slot_id") == slot
              Molecules::ExecutionScopeLineage.new(events: events, project_id: map.fetch("project_id"),
                assignment_id: assignment_id, attempt_id: attempt_id, mapping_id: prior_id)
            end
          end
          result = scope_observer_for(mapping_id).retire_released_parent!(lineages)
          require_slot_snapshot!(map, journal, commit)
          result
        end

        # Current connected release producer is the guarded pre-release abort.
        # Finish/stop owners will call the same settlement/proof core in their
        # terminal CAS; those consumer handlers are not this task's ownership.
        def release_scope_reservation!(params:, peer:, role:)
          strict!(params, %w[mapping_id assignment_id attempt_id mutation_id expected_generation])
          %w[assignment_id attempt_id mutation_id].each { |key| token!(params.fetch(key)) }
          generation!(params.fetch("expected_generation"))
          @kernel.live!(peer)
          map = @deployment.mapping(params.fetch("mapping_id"))
          journal = journal_for(map)
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical(params.reject { |key, _| key == "mutation_id" })))
          with_exclusion(params, map, journal) do
            release_scope_reservation_held!(params, map, journal, peer, role, digest)
          end
        end

        private

        def release_scope_reservation_held!(params, map, journal, peer, role, digest)
            @mutex.synchronize do
              current = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              scope_close_owner!(params, map, current, peer, role)
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: params.fetch("mutation_id"), operation: "scope_reservation_release", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |events, commit, _generation|
                lineage = scope_close_owner!(params, map, events, peer, role)
                terminal = guarded_scope_abort_receipt!(events, lineage, journal, commit)
                scope_observer_for(params.fetch("mapping_id")).verify_closed!(lineage)
                scope_settlement_complete!(journal: journal, events: events, params: params, map: map, commit: commit)
                if events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
                  raise AttemptErrors::Conflict, "reservation is already released"
                end
                {events: [], blobs: {}, data: {"assignment_id" => params.fetch("assignment_id"), "attempt_id" => params.fetch("attempt_id"),
                  "mapping_id" => params.fetch("mapping_id"), "scope_generation" => lineage.binding.fetch("scope_generation"),
                  "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "proof_id" => lineage.proof_id,
                  "terminal_event_id" => terminal.fetch("digest"), "reservation" => "released"}}
              end
            end
        end

        # A crash after guarded abort must not strand a known-clean reservation.
        # Resume against the current canonical generation under the same slot
        # exclusion; preserve the original immutable public abort reply.
        def resume_scope_release_held!(response, map, journal, peer, role)
          data = response.fetch(:data)
          params = data.slice("mapping_id", "assignment_id", "attempt_id")
          @mutex.synchronize do
            commit = journal.ref_value
            events = journal.read_events(params.fetch("assignment_id"), commit: commit).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
            lineage = scope_close_owner!(params, map, events, peer, role)
            return if scope_reservation_released?(events, lineage, journal, commit)
            params["expected_generation"] = journal.authority_generation(events)
          end
          params["mutation_id"] = "scope-release-#{Digest::SHA256.hexdigest(params.fetch('attempt_id'))[0, 48]}"
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical(params.reject { |key, _| key == "mutation_id" })))
          release_scope_reservation_held!(params, map, journal, peer, role, digest)
        end

        def verify_maintenance_root!(root, uid)
          Ace::Runtime::Molecules::ProtectedSocket.root_path!(root, directory: true, owner: uid)
          unless (File.stat(root).mode & 0o077).zero?
            raise AttemptErrors::EvidenceUnavailable, "maintenance state root is not private"
          end
          true
        rescue Ace::Runtime::RuntimeUnavailableError, SystemCallError
          raise AttemptErrors::EvidenceUnavailable, "maintenance fixed state root is unavailable"
        end

        def maintenance_journal_for(owner, map)
          return journal_for(map) if owner.equal?(@deployment)
          project = owner.project(map.fetch("project_id"))
          @maintenance_journals ||= {}
          key = project.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root")
          @maintenance_journals[key] ||= Molecules::EvidenceJournal.new(repo_root: key[0], ref: key[1], checkout_root: key[2])
        end

        def require_maintenance_context!(mapping_id, journal, commit)
          pair = Thread.current[:ace_assign_maintenance_contexts]&.dig(object_id, mapping_id)
          unless pair && pair.last.fetch(:journal).equal?(journal) && pair.last.fetch(:commit) == commit
            raise AttemptErrors::EvidenceUnavailable, "maintenance query requires its exact live inventory context"
          end
          _id, owner, map = pair.first
          key = [object_id, owner.authority(map.fetch("authority_id")).fetch("state_root"),
            "execution-slot:#{map.fetch('execution_scope').fetch('slot_id')}"]
          unless Thread.current[:ace_assign_scope_exclusions]&.fetch(key, false)
            raise AttemptErrors::EvidenceUnavailable, "maintenance slot exclusion is unavailable"
          end
          raise AttemptErrors::Conflict, "maintenance canonical ref changed" unless journal.ref_value == commit
          true
        end

        def require_slot_snapshot!(map, journal, commit)
          key = [object_id, @deployment.authority(map.fetch("authority_id")).fetch("state_root"),
            "execution-slot:#{map.fetch('execution_scope').fetch('slot_id')}"]
          unless Thread.current[:ace_assign_scope_exclusions]&.fetch(key, false) && journal.equal?(journal_for(map)) && journal.ref_value == commit
            raise AttemptErrors::EvidenceUnavailable, "slot query requires its held exclusion and exact current canonical ref"
          end
        end

        def guarded_scope_abort_receipt!(events, lineage, journal, commit)
          aborts = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "abort_launch" }
          terminal = aborts.last
          data = terminal&.dig("payload", "data")
          observation = data&.fetch("abort_observation", nil)
          unless data && data["phase"] == "failed" && observation.is_a?(Hash) && observation["release"] == "not_issued" &&
              observation.keys.sort == (SCOPE_ABORT_FIELDS + ["release"]).sort &&
              observation["kind"] == "protected_scope_before_release" && journal.canonical_attempt_state(events) == "failed" &&
              events.none? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "release_launch" }
            raise AttemptErrors::EvidenceUnavailable, "verified guarded terminal release is unavailable"
          end
          selectors = observation.reject { |key, _| %w[kind release].include?(key) }
          lineage.require_positive!(**selectors.transform_keys(&:to_sym))
          bytes = journal.blob(data.fetch("failure_ref"), commit: commit)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, 16_384) && Digest::SHA256.hexdigest(bytes) == data.fetch("failure_digest")
            raise AttemptErrors::EvidenceUnavailable, "guarded terminal failure bytes changed"
          end
          failure = JSON.parse(bytes.dup.force_encoding(Encoding::UTF_8), create_additions: false, max_nesting: 8, allow_duplicate_key: false, allow_comments: false)
          unless failure == observation.reject { |key, _| key == "release" }
            raise AttemptErrors::EvidenceUnavailable, "guarded terminal failure selectors changed"
          end
          preceding = events.take_while { |event| event["digest"] != terminal.fetch("digest") }
          transition = preceding.last
          unless transition && %w[transition reconciliation].include?(transition["type"]) &&
              transition.dig("payload", "reason") == "protected_scope_closed_before_release" &&
              (transition.dig("payload", "to") || transition.dig("payload", "resolution")) == "failed" &&
              transition.dig("payload", "abort_observation") == observation
            raise AttemptErrors::EvidenceUnavailable, "guarded terminal transition differs"
          end
          terminal
        rescue KeyError, JSON::ParserError, EncodingError
          raise AttemptErrors::EvidenceUnavailable, "guarded terminal lineage is incomplete"
        end

        def scope_reservation_released?(events, lineage, journal, commit)
          releases = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
          return false if releases.empty?
          raise AttemptErrors::EvidenceUnavailable, "canonical reservation release is repeated" unless releases.size == 1
          terminal = guarded_scope_abort_receipt!(events, lineage, journal, commit)
          data = releases.first.dig("payload", "data")
          expected = {"assignment_id" => lineage.binding.fetch("assignment_id"), "attempt_id" => lineage.binding.fetch("attempt_id"),
            "mapping_id" => lineage.binding.fetch("mapping_id"), "scope_generation" => lineage.binding.fetch("scope_generation"),
            "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "proof_id" => lineage.proof_id,
            "terminal_event_id" => terminal.fetch("digest"), "reservation" => "released"}
          unless data.is_a?(Hash) && data.reject { |key, _| key == "generation" } == expected &&
              events.index(releases.first) > events.index(terminal) &&
              data["generation"] == events.take(events.index(releases.first) + 1).count { |event| event["type"] == "authority_mutation" }
            raise AttemptErrors::EvidenceUnavailable, "canonical reservation release selectors differ"
          end
          true
        end
      end
    end
  end
end

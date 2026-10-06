# frozen_string_literal: true
require_relative "../molecules/terminal_scope_receipt"

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
          if @deployment_history && !@deployment_history.selects?(@deployment, selection: :original)
            raise AttemptErrors::EvidenceUnavailable, "maintenance requires original protected transaction descriptor"
          end
          if @deployment_history && !@deployment_history.selects?(candidate_deployment, selection: :candidate)
            raise AttemptErrors::EvidenceUnavailable, "maintenance candidate differs from protected history transaction"
          end
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
                  with_maintenance_inbox_inventory(candidate_deployment) { block.call(contexts) }
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
            maintenance_slot_lineages!(mapping_id, journal, commit)
            require_maintenance_context!(mapping_id, journal, commit)
            return true
          end
          map = @deployment.mapping(mapping_id)
          require_slot_snapshot!(map, journal, commit)
          ensure_slot_available!(map, journal, commit: commit)
          require_slot_snapshot!(map, journal, commit)
          true
        end

        def retire_released_parent!(mapping_id:, journal:, commit:)
          if (contexts = Thread.current[:ace_assign_maintenance_contexts]&.[](object_id))
            # The method itself enforces the whole transaction preflight. A
            # caller cannot validate one root then retire before checking others.
            contexts.each_value { |_entry, context| slot_reusable!(**context) }
            require_maintenance_context!(mapping_id, journal, commit)
            _id, owner, _map = contexts.fetch(mapping_id).first
            lineages = maintenance_slot_lineages!(mapping_id, journal, commit)
            result = maintenance_scope_observer_for(owner, mapping_id).retire_released_parent!(lineages)
            contexts.each_value { |_entry, context| require_maintenance_context!(context.fetch(:mapping_id), context.fetch(:journal), context.fetch(:commit)) }
            return result
          end
          slot_reusable!(mapping_id: mapping_id, journal: journal, commit: commit)
          map = @deployment.mapping(mapping_id)
          if @deployment_history
            protected = maintenance_journal_for(@deployment, map)
            return with_maintenance_inbox_inventory(@deployment_history.candidate) do
              lineages = maintenance_slot_lineages!(mapping_id, protected, commit, selected_context: [@deployment, map])
              result = scope_observer_for(mapping_id).retire_released_parent!(lineages)
              require_slot_snapshot!(map, journal, commit)
              result
            end
          end
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

        def with_maintenance_inbox_inventory(candidate)
          unless @deployment_history && @deployment_history.selects?(candidate, selection: :candidate)
            # No history grant is silently synthesized for arbitrary descriptors.
            return yield
          end
          require "ace/herdr/organisms/inbox"
          roots = (@deployment_history.descriptors + [candidate]).flat_map do |owner|
            owner.data.fetch("projects").values.flat_map do |project|
              project.fetch("inbox_contexts", {}).values.map { |context| context.fetch("deliveries_dir") }
            end
          end.uniq.sort
          roots.each { |root| verify_maintenance_inbox_root!(root) }
          enter = lambda do |offset|
            return yield if offset == roots.size
            Ace::Herdr::Organisms::Inbox.with_retained_records(deliveries_dir: roots.fetch(offset)) { enter.call(offset + 1) }
          end
          enter.call(0)
        end

        def verify_maintenance_inbox_root!(root)
          PrivateDirectory.verify!(root)
          @deployment.send(:verify_inbox_acl!, root, private_leaf: true)
          true
        rescue AttemptErrors::ReceiptRejected, Ace::Runtime::RuntimeUnavailableError
          raise AttemptErrors::EvidenceUnavailable, "maintenance retained inbox root is not protected"
        end

        def maintenance_scope_observer_for(owner, mapping_id)
          return scope_observer_for(mapping_id) if owner.equal?(@deployment)
          @maintenance_scope_observers ||= {}
          key = [owner.artifact_reference.fetch("sha256"), mapping_id]
          @maintenance_scope_observers[key] ||= ExecutionScopeObservation.new(mapping_id: mapping_id, deployment: owner, kernel: @kernel)
        end

        def maintenance_slot_lineages!(mapping_id, journal, commit, selected_context: nil)
          unless @deployment_history
            raise AttemptErrors::EvidenceUnavailable, "complete original authentication requires retained deployment history"
          end
          unless journal.evidence_mode == :protected
            raise AttemptErrors::EvidenceUnavailable, "maintenance requires original protected journal reader"
          end
          if selected_context
            selected_owner, selected_map = selected_context
            mapping_id = selected_owner.data.fetch("launch_mappings").find { |_id, fixed| fixed == selected_map }&.first
            raise AttemptErrors::EvidenceUnavailable, "historical admission map is unavailable" unless mapping_id
          else
            _id, selected_owner, selected_map = Thread.current[:ace_assign_maintenance_contexts].fetch(object_id).fetch(mapping_id).first
          end
          lineages = []
          retained_attempts = []
          journal.assignment_ids(commit: commit).each do |assignment_id|
            journal.read_events(assignment_id, commit: commit).group_by { |event| event.fetch("attempt_id") }.each do |attempt_id, events|
              raise AttemptErrors::EvidenceUnavailable, "maintenance canonical chain corrupt" unless Models::EvidenceEvent.chain_valid?(events)
              reservations = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
              # A chain with effect work but no permanent reservation is never
              # hidden behind the absence of an attributable slot selector.
              if reservations.empty?
                if events.any? { |event| %w[service_claim service_transition inbox_binding inbox_reconciliation scope_provisioning].include?(event["type"]) }
                  raise AttemptErrors::EvidenceUnavailable, "maintenance effect chain lacks reservation"
                end
                next
              end
              provisioning = events.select { |event| event["type"] == "scope_provisioning" }
              unless reservations.one? && provisioning.one?
                raise AttemptErrors::EvidenceUnavailable, "maintenance reservation identity ambiguous"
              end
              reservation = reservations.first.dig("payload", "data")
              identity = provisioning.first.fetch("payload")
              unless identity.is_a?(Hash) && identity.keys.sort == %w[deployment_digest descriptor_sha256 reservation_generation slot_id] &&
                  identity["reservation_generation"] == reservation.fetch("reservation_generation")
                raise AttemptErrors::EvidenceUnavailable, "maintenance provisioning selector differs"
              end
              original = @deployment_history.descriptor!(sha256: identity.fetch("descriptor_sha256"))
              original_map = original.mapping(reservation.fetch("mapping_id"))
              unless Digest::SHA256.hexdigest(JSON.generate(canonical(original_map))) == identity.fetch("deployment_digest") &&
                  original_map.fetch("project_id") == reservation.fetch("project_id") &&
                  original_map.fetch("execution_scope").fetch("slot_id") == identity.fetch("slot_id") &&
                  original.project(original_map.fetch("project_id")).values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root") ==
                    [journal.repo_root, journal.ref, journal.checkout_root]
                raise AttemptErrors::EvidenceUnavailable, "original descriptor canonical association differs"
              end
              retained_attempts << [assignment_id, attempt_id, events, original, original_map]
              next unless identity.fetch("slot_id") == selected_map.fetch("execution_scope").fetch("slot_id")
              unless original.maintenance_association(original_map) == selected_owner.maintenance_association(selected_map)
                raise AttemptErrors::EvidenceUnavailable, "original physical slot association differs"
              end
              lineage = maintenance_released_lineage!(journal, commit, assignment_id, attempt_id, events, original, original_map)
              lineages << lineage
            end
          end
          selected_attempts = retained_attempts.select { |entry| entry.last.fetch("execution_scope").fetch("slot_id") == selected_map.fetch("execution_scope").fetch("slot_id") }
          maintenance_current_inventory!(journal, commit, selected_attempts, all_attempts: retained_attempts,
            slot_filter: selected_map.fetch("execution_scope").fetch("slot_id"))
          maintenance_scope_observer_for(selected_owner, mapping_id).verify_maintenance_closed!(lineages)
          lineages.freeze
        rescue KeyError, TypeError, ArgumentError
          raise AttemptErrors::EvidenceUnavailable, "maintenance original identity is incomplete"
        end

        def maintenance_released_lineage!(journal, commit, assignment_id, attempt_id, events, original, map)
          releases = events.select { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_reservation_release" }
          raise AttemptErrors::EvidenceUnavailable, "maintenance reservation lacks unique release" unless releases.one?
          release = releases.first
          prefix_commit = journal.event_commit!(assignment_id: assignment_id, event_digest: release.fetch("digest"), commit: commit)
          prefix = journal.read_events(assignment_id, commit: prefix_commit).select { |event| event["attempt_id"] == attempt_id }
          unless prefix == events.take(events.index(release) + 1) && events.last == release
            raise AttemptErrors::EvidenceUnavailable, "post-release canonical work or release prefix differs"
          end
          id = release.dig("payload", "data", "mapping_id")
          lineage = Molecules::ExecutionScopeLineage.new(events: prefix, project_id: map.fetch("project_id"),
            assignment_id: assignment_id, attempt_id: attempt_id, mapping_id: id)
          unless lineage.binding && lineage.seal_event && lineage.proof_id
            raise AttemptErrors::EvidenceUnavailable, "historical released parent lacks canonical closed proof"
          end
          lineage.require_positive!(scope_generation: lineage.binding.fetch("scope_generation"),
            scope_binding_event_id: lineage.binding_event.fetch("digest"), seal_event_id: lineage.seal_event.fetch("digest"), proof_id: lineage.proof_id)
          terminal = if prefix.any? { |event| event["type"] == "receipt_accepted" }
            terminal_scope_receipt!(prefix, lineage, journal, prefix_commit, deployment: original)
          else
            guarded_scope_abort_receipt!(prefix, lineage, journal, prefix_commit)
          end
          expected = {"assignment_id" => assignment_id, "attempt_id" => attempt_id, "mapping_id" => id,
            "scope_generation" => lineage.binding.fetch("scope_generation"), "scope_binding_event_id" => lineage.binding_event.fetch("digest"),
            "proof_id" => lineage.proof_id, "terminal_event_id" => terminal.fetch("digest"), "reservation" => "released"}
          data = release.dig("payload", "data")
          unless data.is_a?(Hash) && data.except("generation") == expected && prefix.index(terminal) < prefix.index(release) &&
              data["generation"] == journal.authority_generation(prefix) &&
              lineage.binding.fetch("deployment_digest") == prefix.find { |event| event["type"] == "scope_provisioning" }.dig("payload", "deployment_digest")
            raise AttemptErrors::EvidenceUnavailable, "historical release parent/terminal binding differs"
          end
          params = expected.slice("assignment_id", "attempt_id", "mapping_id")
          service_events = prefix.any? { |event| %w[service_claim service_transition].include?(event["type"]) }
          inbox_events = prefix.any? { |event| event["type"].start_with?("inbox_") }
          if !@result_owner && (service_events || inbox_events || original.project(map.fetch("project_id")).fetch("inbox_contexts", {}).any? ||
              journal.service_request_records(commit: prefix_commit).any? { |record| record.values_at("assignment_id", "attempt_id") == [assignment_id, attempt_id] })
            raise AttemptErrors::EvidenceUnavailable, "historical settlement receipt owner unavailable"
          end
          if @result_owner
            @result_owner.service_settlement_complete!(journal: journal, events: prefix, params: params, map: map, commit: prefix_commit)
            @result_owner.historical_inbox_settlement_complete!(journal: journal, events: prefix, params: params, map: map,
              commit: prefix_commit, deployment: original, history: @deployment_history)
          end
          lineage
        end

        def maintenance_current_inventory!(journal, commit, attempts, all_attempts: nil, slot_filter: nil)
          indexed = attempts.to_h { |entry| [entry.values_at(0, 1), entry] }
          raise AttemptErrors::EvidenceUnavailable, "maintenance attempt attribution conflicts" unless indexed.size == attempts.size
          verified = {}
          verify_attempt = lambda do |entry|
            assignment_id, attempt_id, events, original, map = entry
            verified[[assignment_id, attempt_id]] ||= maintenance_released_lineage!(journal, commit,
              assignment_id, attempt_id, events, original, map)
          end
          journal.service_request_records(commit: commit).each do |record|
            entry = indexed[record.values_at("assignment_id", "attempt_id")]
            if !entry && all_attempts&.any? { |known| known.values_at(0, 1) == record.values_at("assignment_id", "attempt_id") &&
                known.last.fetch("project_id") == record["project_id"] &&
                known[2].find { |event| event.dig("payload", "operation") == "reserve_attempt" }.dig("payload", "data", "mapping_id") == record["mapping_id"] }
              next
            end
            raise AttemptErrors::EvidenceUnavailable, "current service request is unregistered" unless entry
            verify_attempt.call(entry)
            unless record["project_id"] == entry.last.fetch("project_id") &&
                record["mapping_id"] == entry[2].find { |event| event.dig("payload", "operation") == "reserve_attempt" }.dig("payload", "data", "mapping_id") &&
                %w[succeeded failed-settled].include?(record["state"])
              raise AttemptErrors::EvidenceUnavailable, "current service request is not historically settled"
            end
            journal.service_request(record.fetch("request_id"), commit: commit)
            release = entry[2].find { |event| event.dig("payload", "operation") == "scope_reservation_release" }
            prefix = journal.event_commit!(assignment_id: entry.first, event_digest: release.fetch("digest"), commit: commit)
            unless journal.service_request(record.fetch("request_id"), commit: prefix) == record
              raise AttemptErrors::EvidenceUnavailable, "current service request changed after release"
            end
          end
          require "ace/herdr/organisms/inbox"
          registrations = attempts.flat_map do |entry|
            entry[2].select { |event| event["type"] == "inbox_binding" }.map do |event|
              fixed = entry[3].inbox_context(entry[2].find { |item| item.dig("payload", "operation") == "reserve_attempt" }.dig("payload", "data", "mapping_id"),
                event.dig("payload", "inbox_context_id"))
              [fixed.fetch("deliveries_dir"), event.dig("payload", "event_id"), entry, event]
            end
          end
          unless registrations.map { |entry| entry.values_at(0, 1) }.uniq.size == registrations.size
            raise AttemptErrors::EvidenceUnavailable, "current inbox identity attribution conflicts"
          end
          fixed_roots = @deployment_history.descriptors.flat_map do |owner|
            owner.data.fetch("projects").values.select do |project|
              project.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root") == [journal.repo_root, journal.ref, journal.checkout_root]
            end.flat_map do |project|
              project.fetch("inbox_contexts", {}).values.filter_map do |context|
                if all_attempts
                  native = owner.mapping(context.fetch("native_mapping_id"))
                  next unless slot_filter == native.fetch("execution_scope").fetch("slot_id")
                end
                context.fetch("deliveries_dir")
              end
            end
          end.uniq
          fixed_roots.each do |root|
            unless Thread.current[:ace_herdr_retained_inventory_locks]&.key?(root)
              raise AttemptErrors::EvidenceUnavailable, "current inbox inventory lifetime lock is unavailable"
            end
            records = Ace::Herdr::Organisms::Inbox.retained_records(deliveries_dir: root)
            expected = registrations.select { |registration| registration.first == root }
            unless records.map(&:event_id).sort == expected.map { |registration| registration[1] }.sort
              raise AttemptErrors::EvidenceUnavailable, "current inbox retained registration set differs"
            end
            records.each do |record|
              registration = expected.find { |entry| entry[1] == record.event_id }
              entry, registered = registration.values_at(2, 3)
              verify_attempt.call(entry)
              proof = entry[2].reverse.find { |event| event["type"] == "inbox_reconciliation" && event.dig("payload", "event_id") == record.event_id }&.fetch("payload")
              public_identity = {"event_id" => record.event_id, "attempt_id" => record.inbox.fetch("attempt_id"),
                "payload_sha256" => record.answer_digest, "receipt_key_sha256" => record.inbox.fetch("receipt_key_sha256")}
              unless proof && record.state == "completed" && public_identity == registered.dig("payload", "registration") &&
                  record.inbox.fetch("claim_generation") == proof.fetch("claim_generation") &&
                  record.inbox.fetch("binding") == proof.dig("binding", "native_binding") &&
                  record.inbox.fetch("reconciliation") == JSON.parse(journal.blob(proof.dig("receipt_ref", "ref"), commit: commit))
                raise AttemptErrors::EvidenceUnavailable, "current inbox claim or retained settlement differs"
              end
              original = record.inbox.fetch("origin_target")
              native = proof.dig("binding", "scope_native_binding")
              unless original.is_a?(Hash) && original["session"] == native.fetch("workspace_id")
                raise AttemptErrors::EvidenceUnavailable, "current retained inbox original native identity differs"
              end
              child = entry[2].find { |event| event["type"] == "scope_child_bound" }&.dig("payload", "original_process_binding")
              if child && original.values_at("session", "pane", "terminal_id") != child.values_at("session", "pane", "terminal_id")
                raise AttemptErrors::EvidenceUnavailable, "current retained inbox original child identity differs"
              end
            end
          end
          true
        rescue KeyError, TypeError, ArgumentError, JSON::ParserError, Ace::Herdr::Error
          raise AttemptErrors::EvidenceUnavailable, "current retained inventory is unverifiable"
        end

        def release_scope_reservation_held!(params, map, journal, peer, role, digest)
            @mutex.synchronize do
              current = journal.read_events(params.fetch("assignment_id")).select { |event| event["attempt_id"] == params.fetch("attempt_id") }
              scope_close_owner!(params, map, current, peer, role)
              journal.mutate(assignment_id: params.fetch("assignment_id"), attempt_id: params.fetch("attempt_id"),
                mutation_id: params.fetch("mutation_id"), operation: "scope_reservation_release", parameters_digest: digest,
                expected_generation: params.fetch("expected_generation"), with_replay: true) do |events, commit, _generation|
                lineage = scope_close_owner!(params, map, events, peer, role)
                native_issuer_pending!(params, map)
                terminal = terminal_scope_receipt!(events, lineage, journal, commit)
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
          project = owner.project(map.fetch("project_id"))
          if owner.equal?(@deployment)
            current = journal_for(map)
            return current if current.evidence_mode == :protected
          end
          @maintenance_journals ||= {}
          key = project.values_at("journal_repository", "evidence_git_ref", "evidence_checkout_root")
          @maintenance_journals[key] ||= begin
            require_relative "service_evidence"
            reader = nil
            journal = Molecules::EvidenceJournal.new(repo_root: key[0], ref: key[1], checkout_root: key[2],
              mode: :protected,
              evidence_reader: ->(reference, record, state, pending) { reader.call(reference, record, state, pending) },
              service_authorizer: ->(*) {
                raise AttemptErrors::EvidenceUnavailable, "historical maintenance reader cannot mutate service records"
              })
            reader = ServiceEvidence.new(journal: journal)
            journal
          end
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

        def terminal_scope_receipt!(events, lineage, journal, commit, deployment: @deployment)
          if events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "abort_launch" }
            return guarded_scope_abort_receipt!(events, lineage, journal, commit)
          end
          reservation = events.find { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "reserve_attempt" }
          mapping = deployment.mapping(reservation.fetch("payload").fetch("data").fetch("mapping_id"))
          Molecules::TerminalScopeReceipt.verify!(events: events, lineage: lineage, journal: journal, commit: commit, mapping: mapping)
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
          terminal = terminal_scope_receipt!(events, lineage, journal, commit)
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

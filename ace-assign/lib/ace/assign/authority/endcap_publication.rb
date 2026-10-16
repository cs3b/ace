# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        # The same held assignment owner authenticates the receiver and current
        # candidate both before transfer and inside each canonical CAS attempt.
        # Ordinary HITL uses this same original launch and project journal;
        # no local assignment cache or caller-selected coordinator participates.
        def with_worker_hitl!(assignment:, attempt:, project:, requester_uid:, peer: nil)
          selected = @deployment.data.fetch("launch_mappings").select do |_id, map|
            map.fetch("project_id") == project && map.fetch("worker_uid") == requester_uid
          end
          raise AttemptErrors::UnauthorizedIdentity, "HITL worker mapping is missing or ambiguous" unless selected.size == 1
          mapping_id, map = selected.first
          params = {"mapping_id" => mapping_id, "assignment_id" => assignment, "attempt_id" => attempt}
          @launch.with_assignment(params: params, map: map) do |journal, _registration|
            protected_journal!(journal)
            events = attempt_events(journal, params)
            origin = active_origin(events, params)
            @launch.scope_open_for_effect!(events: events, params: params, map: map)
            if peer
              unless peer.values_at("uid", "gid", "groups") == map.values_at("worker_uid", "worker_gid", "worker_groups")
                raise AttemptErrors::UnauthorizedIdentity, "HITL requester credentials differ"
              end
              @kernel.live!(peer)
              worker_or_launcher!(peer, :worker, map, origin)
            end
            reverse = origin.fetch("process_binding").slice("session", "pane")
            unless reverse.values.all? { |value| value.is_a?(String) && !value.empty? } && reverse.size == 2
              raise AttemptErrors::EvidenceUnavailable, "HITL native reverse is unavailable"
            end
            yield settlement_immutable(reverse.merge("schema" => "ace.hitl.ref/v1"))
          end
        end

      end
    end
  end
end

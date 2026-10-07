# frozen_string_literal: true

require "ace/lab"
require "ace/assign/authority/client"

module Ace
  module Overseer
    module Organisms
      # Public topology supplies visibility; protected Deployment supplies the
      # actual fixed capacity. Canonical authority pages supply attempt facts.
      # None of these metadata observations is a mutation/cleanup grant.
      class ProtectedStatus
        ROW_KEYS = %w[assignment_id task_id definition_digest definition_generation attempt_id scope reservation_generation generation canonical_state original_binding_digest terminal_event_id reservation_release_event_id].sort.freeze

        def initialize(topology: nil, deployment_loader: nil, client_factory: nil)
          @topology = topology || Ace::Lab::Organisms::TopologyService.from_config
          @deployment_loader = deployment_loader || -> { Ace::Assign::Authority::Deployment.load }
          @client_factory = client_factory || ->(id, deployment) { Ace::Assign::Authority::Client.new(mapping_id: id, deployment: deployment) }
        end

        def collect(project:, agent: nil)
          deployment, pool, ids = selection!(project, agent)
          selected = agent ? [agent] : ids
          snapshots = selected.map do |id|
            client = @client_factory.call(id, deployment)
            {"agent_id" => id, "status" => "ok", "inventory" => inventory(client, project: project, mapping_id: id)}
          rescue Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError, Error
            {"agent_id" => id, "status" => "unavailable", "inventory" => nil}
          end
          {"project_id" => project, "provisioned_capacity" => pool.size, "visible_capacity" => ids.size,
            "visibility" => ids == pool ? "complete" : "partial", "agents" => snapshots}
        rescue KeyError, TypeError, NoMethodError
          raise Error, "Protected status metadata is malformed"
        end

        # The parent cannot impersonate its foreground child's original birth.
        # Join that child's bounded frame to its retained canonical snapshot.
        def join_ready!(project:, agent:, ready:)
          deployment, = selection!(project, agent)
          unless ready.is_a?(Hash) && ready.keys.all? { |key| key.is_a?(String) } && ready.keys.sort == %w[assignment_id attempt_id generation journal_commit mapping_id original_binding_digest type version] &&
              ready["version"].is_a?(Integer) && ready["version"] == 1 && ready["type"] == "launch_ready" && ready["mapping_id"] == agent
            raise Error, "Original launch readiness is malformed"
          end
          %w[assignment_id attempt_id].each { |key| token!(ready.fetch(key)) }
          positive!(ready.fetch("generation"))
          digest!(ready.fetch("original_binding_digest"))
          unless ready["journal_commit"].is_a?(String) && ready["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise Error, "Original launch readiness revision is malformed"
          end
          snapshot = inventory(@client_factory.call(agent, deployment), project: project, mapping_id: agent, commit: ready.fetch("journal_commit"))
          row = snapshot.fetch("items").find { |entry| entry.values_at("assignment_id", "attempt_id") == ready.values_at("assignment_id", "attempt_id") }
          unless row && row.values_at("generation", "original_binding_digest") == ready.values_at("generation", "original_binding_digest")
            raise Error, "Original launch readiness differs from canonical attempt"
          end
          {"journal_commit" => snapshot.fetch("journal_commit"), "item" => row}
        rescue KeyError, TypeError, NoMethodError
          raise Error, "Original launch readiness is malformed"
        rescue Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError
          raise Error, "Original launch readiness canonical snapshot is unavailable"
        end

        private

        def selection!(project, agent)
          token!(project)
          token!(agent) if agent
          topology = @topology.agents(project: project)
          raise Error, "Protected topology unavailable (#{topology.error_code})" unless topology.ok?
          deployment = @deployment_loader.call
          pool = deployment.data.fetch("launch_mappings").select { |_id, map| map.fetch("project_id") == project }.keys.sort
          raise Error, "Protected project has no provisioned mappings" if pool.empty?
          visible = topology.data.fetch("agents")
          unless visible.is_a?(Array) && visible.all? { |entry| entry.is_a?(Hash) && entry["project"] == project && pool.include?(entry["id"]) } &&
              visible.map { |entry| entry.fetch("id") }.uniq.size == visible.size
            raise Error, "Public agent visibility differs from protected project mappings"
          end
          ids = visible.map { |entry| entry.fetch("id") }.sort
          if agent && !ids.include?(agent)
            raise Error, "Requested protected agent is not visible in this project"
          end
          [deployment, pool, ids]
        end

        def inventory(client, project:, mapping_id:, commit: nil)
          after = nil
          rows = []
          selectors = {}
          loop do
            page = client.call("assignment_inventory", {"journal_commit" => commit, "after" => after, "limit" => 25}, timeout: 30).data
            unless page.is_a?(Hash) && page.keys.all? { |key| key.is_a?(String) } && page.keys.sort == %w[items journal_commit mapping_id next_after project_id] &&
                page["project_id"] == project && page["mapping_id"] == mapping_id &&
                page["journal_commit"].is_a?(String) && page["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
                (commit.nil? || page["journal_commit"] == commit) && page["items"].is_a?(Array) && page["items"].size <= 25
              raise Error, "Protected inventory snapshot differs"
            end
            commit ||= page.fetch("journal_commit")
            page.fetch("items").each do |row|
              validate_row!(row)
              selector = [row.fetch("assignment_id"), row.fetch("attempt_id")]
              if selectors[selector] || (!rows.empty? && (selector_order(selector) <=> selector_order(rows.last.values_at("assignment_id", "attempt_id"))) <= 0)
                raise Error, "Protected inventory ordering is ambiguous"
              end
              selectors[selector] = true
              rows << row
            end
            following = page.fetch("next_after")
            break if following.nil?
            unless following.is_a?(Hash) && following.keys.all? { |key| key.is_a?(String) } && following.keys.sort == %w[assignment_id attempt_id] && !page.fetch("items").empty? &&
                following == page.fetch("items").last.slice("assignment_id", "attempt_id") && following != after
              raise Error, "Protected inventory continuation is malformed"
            end
            after = following
          end
          {"journal_commit" => commit, "items" => rows}
        end

        def validate_row!(row)
          raise Error, "Protected inventory row is malformed" unless row.is_a?(Hash) && row.keys.all? { |key| key.is_a?(String) } && row.keys.sort == ROW_KEYS
          token!(row.fetch("assignment_id"))
          unless row["task_id"].is_a?(String) && !row["task_id"].empty? && row["task_id"].bytesize <= 32_768
            raise Error, "Protected task identity is malformed"
          end
          digest!(row.fetch("definition_digest"))
          positive!(row.fetch("definition_generation"))
          if row.fetch("attempt_id").nil?
            unless row.values_at("scope", "reservation_generation", "generation", "canonical_state", "original_binding_digest", "terminal_event_id", "reservation_release_event_id").all?(&:nil?)
              raise Error, "Registration-only inventory has attempt facts"
            end
          else
            token!(row.fetch("attempt_id"))
            raise Error, "Protected inventory scope is malformed" unless row["scope"].is_a?(String) && !row["scope"].empty? && row["scope"].bytesize <= 128
            positive!(row.fetch("reservation_generation"))
            positive!(row.fetch("generation"))
            unless %w[reserved running succeeded failed stopped uncertain].include?(row.fetch("canonical_state"))
              raise Error, "Protected canonical state is malformed"
            end
            %w[original_binding_digest terminal_event_id reservation_release_event_id].each { |key| digest!(row.fetch(key)) unless row.fetch(key).nil? }
            if row["reservation_release_event_id"] && (!row["terminal_event_id"] || !%w[succeeded failed stopped].include?(row["canonical_state"]))
              raise Error, "Protected release lacks terminal provenance"
            end
          end
        end

        def selector_order(value)
          [value.first.b, value.last.to_s.b]
        end

        def token!(value)
          raise Error, "Protected identity is invalid" unless value.is_a?(String) && value.match?(Ace::Assign::Authority::Deployment::TOKEN)
        end

        def digest!(value)
          raise Error, "Protected digest is invalid" unless value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)
        end

        def positive!(value)
          raise Error, "Protected generation is invalid" unless value.is_a?(Integer) && value.positive?
        end
      end
    end
  end
end

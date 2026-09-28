# frozen_string_literal: true

module Ace
  module Herdr
    module Molecules
      # Positive-evidence probe for tidy (spec 8wq.t.1w0): the only component
      # that interprets native `agent get` and `pane process-info` responses.
      # A pane qualifies for closing solely on explicit completion proof — an
      # observed `done` agent state or a pane with no foreground process.
      # Every unrecognized response, missing field, or probe failure is
      # preserve-only (no proof != dead).
      module PaneTidyProbe
        module_function

        # Probe the agent in a pane and, when no agent exists, the pane's
        # processes. Returns:
        #   :agent_done     - agent observed in state done (eligible)
        #   :process_exited - pane alive, empty foreground process list (eligible)
        #   :active         - live agent (idle/working/blocked) or live process
        #   :unknown        - unreadable/absent evidence (preserve)
        #   :unreadable     - probe failure (preserve)
        #   :gone           - pane no longer exists (nothing to close)
        def pane_evidence(executor, pane)
          agent_evidence = agent_evidence(executor, pane)
          return agent_evidence unless agent_evidence == :no_agent

          process_evidence(executor, pane)
        end

        # Interpret `agent get`: result.agent.agent_status. A missing agent
        # (:no_agent) defers to the process probe.
        def agent_evidence(executor, pane)
          status = dug_value(executor.agent_get(pane).parsed_json, "result", "agent", "agent_status")
          case status
          when "done" then :agent_done
          when "idle", "working", "blocked" then :active
          else :unknown
          end
        rescue AgentNotFoundError
          :no_agent
        rescue PaneNotFoundError
          :gone
        rescue ExecutorError
          :unreadable
        end

        # Interpret `pane process-info`. herdr serializes
        # `foreground_processes` with serde skip_serializing_if (v0.9.1
        # schema/panes.rs), so within a well-formed process_info object an
        # absent or empty list IS the process-exit proof; anything alive
        # appears as a non-empty array.
        def process_evidence(executor, pane)
          info = dug_value(executor.pane_process_info(pane).parsed_json, "result", "process_info")
          return :unknown unless info.is_a?(Hash)

          processes = info["foreground_processes"]
          return :unknown unless processes.nil? || processes.is_a?(Array)

          processes.to_a.empty? ? :process_exited : :active
        rescue PaneNotFoundError
          :gone
        rescue ExecutorError
          :unreadable
        end

        # Path walk that fails closed: nil unless every hop is a Hash
        def dug_value(parsed, *path)
          current = parsed
          path.each do |key|
            return nil unless current.is_a?(Hash)

            current = current[key]
          end
          current
        end
      end
    end
  end
end

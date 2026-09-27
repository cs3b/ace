# frozen_string_literal: true

module Ace
  module Herdr
    module Models
      # Outcome of a one-command agent dispatch: pure data carrier
      class DispatchOutcome
        attr_reader :workspace_id, :pane, :agent_name, :kind, :tab_created, :prompted

        def initialize(workspace_id:, pane:, agent_name:, kind:, tab_created:, prompted:)
          @workspace_id = workspace_id
          @pane = pane
          @agent_name = agent_name
          @kind = kind
          @tab_created = tab_created
          @prompted = prompted
          freeze
        end

        def to_h
          {
            "workspace" => workspace_id, "pane" => pane, "agent" => agent_name,
            "kind" => kind, "tab_created" => tab_created, "prompted" => prompted
          }
        end
      end
    end
  end
end

# frozen_string_literal: true

module Ace
  module Herdr
    module Organisms
      # Owner of the terminal-control behavior (spec 8wq.t.k84): normalizes
      # herdr's native JSON into the public one-line payloads, routes send
      # input to plain-pane or agent transport, and drives preset
      # instantiation. All native calls go through the executor; command
      # classes render the returned hashes as JSON lines.
      class ControlSurface
        DEFAULT_LINES = 40

        def initialize(executor: Molecules::HerdrExecutor.new)
          @executor = executor
        end

        # --- list -------------------------------------------------------------

        # Live panes, optionally scoped to a workspace
        def list_panes(workspace_id: nil)
          result_rows(@executor.pane_list(workspace_id: workspace_id).parsed_json, "panes")
            .map { |row| normalize_pane(row) }
        end

        # Live tabs, optionally scoped to a workspace (tmux windows analogue)
        def list_tabs(workspace_id: nil)
          result_rows(@executor.tab_list(workspace_id: workspace_id).parsed_json, "tabs")
            .map { |row| normalize_tab(row) }
        end

        # Live workspaces (tmux sessions analogue)
        def list_workspaces
          result_rows(@executor.workspace_list.parsed_json, "workspaces")
            .map { |row| normalize_workspace(row) }
        end

        private

        def normalize_pane(row)
          {
            id: row["pane_id"],
            tab: row["tab_id"],
            workspace: row["workspace_id"],
            title: row["terminal_title_stripped"] || row["terminal_title"],
            cwd: row["cwd"],
            focused: row["focused"],
            agent_status: row["agent_status"]
          }
        end

        def normalize_tab(row)
          {
            id: row["tab_id"],
            workspace: row["workspace_id"],
            title: row["label"],
            number: row["number"],
            pane_count: row["pane_count"],
            focused: row["focused"]
          }
        end

        def normalize_workspace(row)
          {
            id: row["workspace_id"],
            title: row["label"],
            number: row["number"],
            tab_count: row["tab_count"],
            pane_count: row["pane_count"],
            focused: row["focused"]
          }
        end

        # herdr list responses nest rows under result.<key>; anything else is
        # an explicit empty state, never an error
        def result_rows(parsed, key)
          rows = parsed.is_a?(Hash) && parsed["result"].is_a?(Hash) ? parsed["result"][key] : nil
          rows.is_a?(Array) ? rows : []
        end
      end
    end
  end
end

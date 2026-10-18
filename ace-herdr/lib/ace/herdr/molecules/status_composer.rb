# frozen_string_literal: true

module Ace
  module Herdr
    module Molecules
      # Pure join of the three normalized live lists (workspaces, tabs,
      # panes) into one nested status tree. Counts are recomputed from the
      # nesting so the tree is internally consistent even if the runtime's
      # own counters raced; panes referencing a tab or workspace missing
      # from the lists are kept in a deterministic synthetic "(unlinked)"
      # group instead of being dropped (task 8xg.t.sbz.6.0: a source gap
      # must stay visible, never become a "clean" empty layout).
      class StatusComposer
        UNLINKED = "(unlinked)"

        # @param workspaces [Array<Hash>] normalized workspace hashes
        # @param tabs [Array<Hash>] normalized tab hashes
        # @param panes [Array<Hash>] normalized pane hashes
        # @return [Hash] {workspaces: [...]} with nested tabs/panes and
        #   recomputed counts
        def self.call(workspaces:, tabs:, panes:)
          new.compose(workspaces: workspaces, tabs: tabs, panes: panes)
        end

        def compose(workspaces:, tabs:, panes:)
          panes_by_tab = group_panes(panes)
          tabs_by_workspace = group_tabs(tabs, panes_by_tab)

          roots = build_workspaces(workspaces, tabs_by_workspace, panes_by_tab)

          synthetic_root = build_synthetic_root(tabs_by_workspace, panes_by_tab)
          roots << synthetic_root if synthetic_root

          {workspaces: roots}
        end

        private

        def group_panes(panes)
          panes.group_by { |pane| pane[:tab] }
        end

        def group_tabs(tabs, panes_by_tab)
          # Tabs carry the panes nested under them; orphan panes whose tab
          # is absent from the tab list get a synthetic tab inside their
          # own workspace so the pane stays visible.
          tabs_by_workspace = Hash.new { |hash, key| hash[key] = [] }
          tabs.each do |tab|
            tabs_by_workspace[tab[:workspace]] << compose_tab(tab, panes_by_tab.delete(tab[:id]) || [])
          end

          panes_by_tab.each do |tab_id, orphan_panes|
            # Panes sharing a vanished tab id may still disagree on their
            # workspace (snapshot race): each workspace keeps its own
            # synthetic tab so neither side silently undercounts.
            orphan_panes.group_by { |pane| pane[:workspace] }.each do |workspace_id, workspace_panes|
              tabs_by_workspace[workspace_id] << synthetic_tab(tab_id, workspace_id, workspace_panes)
            end
          end
          tabs_by_workspace
        end

        def build_workspaces(workspaces, tabs_by_workspace, panes_by_tab)
          ordered(workspaces).map do |workspace|
            nested_tabs = sort_tabs(tabs_by_workspace.delete(workspace[:id]) || [])
            compose_workspace(workspace, nested_tabs)
          end
        end

        def build_synthetic_root(tabs_by_workspace, panes_by_tab)
          return nil if tabs_by_workspace.empty?

          nested_tabs = sort_tabs(tabs_by_workspace.values.flatten)
          compose_workspace(
            {id: UNLINKED, title: UNLINKED, number: nil, focused: nil, synthetic: true},
            nested_tabs
          )
        end

        def compose_workspace(workspace, nested_tabs)
          pane_count = nested_tabs.sum { |tab| tab[:pane_count] }
          {
            id: workspace[:id],
            title: workspace[:title],
            number: workspace[:number],
            focused: workspace[:focused],
            synthetic: workspace[:synthetic] || false,
            tab_count: nested_tabs.length,
            pane_count: pane_count,
            tabs: nested_tabs
          }
        end

        def compose_tab(tab, nested_panes)
          nested_panes = ordered(nested_panes)
          {
            id: tab[:id],
            title: tab[:title],
            number: tab[:number],
            focused: tab[:focused],
            synthetic: tab[:synthetic] || false,
            pane_count: nested_panes.length,
            panes: nested_panes
          }
        end

        def synthetic_tab(tab_id, workspace_id, orphan_panes)
          {
            id: tab_id,
            workspace: workspace_id,
            title: UNLINKED,
            number: nil,
            focused: nil,
            synthetic: true
          }.then { |tab| compose_tab(tab, orphan_panes) }
        end

        def sort_tabs(tabs)
          # Synthetic tabs sort last within their workspace
          synthetic, natural = tabs.partition { |tab| tab[:synthetic] }
          ordered(natural) + ordered(synthetic)
        end

        # Deterministic ordering: number, then id; nil numbers last
        def ordered(items)
          items.sort_by { |item| [item[:number] ? 0 : 1, item[:number] || 0, item[:id].to_s] }
        end
      end
    end
  end
end

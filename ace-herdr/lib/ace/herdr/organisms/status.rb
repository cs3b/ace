# frozen_string_literal: true

require "set"
require_relative "control_surface"
require_relative "../molecules/herdr_executor"
require_relative "../errors"

module Ace
  module Herdr
    module Organisms
      # Read-only live-layout snapshot: composes the existing list APIs
      # (workspaces -> tabs -> panes) into one tree and classifies the
      # runtime state. Writes nothing, starts nothing.
      class Status
        def initialize(executor: nil, binary: "herdr")
          @binary = binary
          surface = executor || Molecules::HerdrExecutor.new
          @control = ControlSurface.new(executor: surface)
        end

        # @return [Hash] snapshot with runtime state, counts, grouped tree
        def snapshot
          workspaces = @control.list_workspaces
          tabs = @control.list_tabs
          panes = @control.list_panes
          build_tree(workspaces, tabs, panes)
        rescue ExecutorUnavailableError => e
          failure("unavailable", e.message)
        rescue ExecutorError => e
          failure("error", e.message)
        end

        private

        def failure(state, message)
          {
            "runtime" => {"state" => state, "binary" => @binary, "error" => message},
            "counts" => nil,
            "workspaces" => nil,
            "unattached" => nil
          }
        end

        def build_tree(workspaces, tabs, panes)
          panes_by_tab = group_by(panes) { |pane| pane[:tab] }
          tabs_by_workspace = group_by(tabs) { |tab| tab[:workspace] }

          workspace_ids = Set.new(workspaces.map { |w| w[:id] })
          tab_ids = Set.new(tabs.map { |t| t[:id] })

          tree = workspaces.map do |workspace|
            attached = tabs_by_workspace.fetch(workspace[:id], [])
            {
              "workspace" => workspace,
              "tabs" => attached.map do |tab|
                {"tab" => tab, "panes" => panes_by_tab.fetch(tab[:id], [])}
              end
            }
          end

          orphan_tabs = tabs.select { |tab| !workspace_ids.include?(tab[:workspace]) }
          orphan_panes = panes.select { |pane| !tab_ids.include?(pane[:tab]) }

          {
            "runtime" => {"state" => "available", "binary" => @binary, "error" => nil},
            "counts" => {
              "workspaces" => workspaces.size,
              "tabs" => tabs.size,
              "panes" => panes.size
            },
            "workspaces" => tree,
            "unattached" => {"tabs" => orphan_tabs, "panes" => orphan_panes}
          }
        end

        def group_by(items)
          items.group_by { |item| yield(item) }
        end
      end
    end
  end
end

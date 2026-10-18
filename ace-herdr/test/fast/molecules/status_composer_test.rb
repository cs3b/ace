# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Molecules
      class StatusComposerTest < Minitest::Test
        def setup
          @workspaces = [
            {id: "w2", title: "scratch", number: 2, tab_count: 99, pane_count: 99, focused: false},
            {id: "w1", title: "main", number: 1, tab_count: 99, pane_count: 99, focused: true}
          ]
          @tabs = [
            {id: "w1:t2", workspace: "w1", title: "build", number: 2, pane_count: 99, focused: false},
            {id: "w1:t1", workspace: "w1", title: "agent", number: 1, pane_count: 99, focused: true}
          ]
          @panes = [
            {id: "p2", tab: "w1:t1", workspace: "w1", title: "pi", cwd: "/tmp/x", focused: false, agent_status: "working"},
            {id: "p1", tab: "w1:t1", workspace: "w1", title: nil, cwd: "/tmp/a", focused: true, agent_status: nil},
            {id: "p3", tab: "w1:t2", workspace: "w1", title: "sh", cwd: "/tmp/b", focused: false, agent_status: nil}
          ]
        end

        def test_nests_panes_under_workspace_and_tab
          tree = StatusComposer.call(workspaces: @workspaces, tabs: @tabs, panes: @panes)

          w1 = tree[:workspaces].first
          assert_equal "w1", w1[:id]
          assert_equal 2, w1[:tab_count]
          assert_equal 3, w1[:pane_count]
          t1 = w1[:tabs].first
          assert_equal "w1:t1", t1[:id]
          assert_equal 2, t1[:pane_count]
          assert_equal %w[p1 p2], t1[:panes].map { |pane| pane[:id] }
        end

        def test_counts_are_recomputed_not_trusted
          tree = StatusComposer.call(workspaces: @workspaces, tabs: @tabs, panes: @panes)

          w1 = tree[:workspaces].first
          refute_equal 99, w1[:tab_count]
          refute_equal 99, w1[:pane_count]
          refute_equal 99, w1[:tabs].first[:pane_count]
        end

        def test_orders_by_number_then_id
          tree = StatusComposer.call(workspaces: @workspaces, tabs: @tabs, panes: @panes)

          assert_equal %w[w1 w2], tree[:workspaces].map { |workspace| workspace[:id] }
          assert_equal %w[w1:t1 w1:t2], tree[:workspaces].first[:tabs].map { |tab| tab[:id] }
        end

        def test_nil_numbers_sort_last
          tabs = @tabs + [{id: "w1:t0", workspace: "w1", title: "odd", number: nil, pane_count: 0, focused: false}]
          tree = StatusComposer.call(workspaces: @workspaces, tabs: tabs, panes: @panes)

          assert_equal "w1:t0", tree[:workspaces].first[:tabs].last[:id]
        end

        def test_orphan_pane_lands_in_unlinked_tab_of_its_workspace
          panes = @panes + [{id: "p9", tab: "w1:missing", workspace: "w1", title: nil, cwd: "/tmp", focused: false, agent_status: nil}]
          tree = StatusComposer.call(workspaces: @workspaces, tabs: @tabs, panes: panes)

          w1 = tree[:workspaces].first
          unlinked = w1[:tabs].last
          assert unlinked[:synthetic]
          assert_equal "(unlinked)", unlinked[:title]
          assert_equal ["p9"], unlinked[:panes].map { |pane| pane[:id] }
          assert_equal 4, w1[:pane_count]
        end

        def test_pane_of_unknown_workspace_lands_in_synthetic_root
          panes = @panes + [{id: "p8", tab: "gone:t1", workspace: "gone", title: nil, cwd: "/tmp", focused: false, agent_status: nil}]
          tree = StatusComposer.call(workspaces: @workspaces, tabs: @tabs, panes: panes)

          root = tree[:workspaces].last
          assert root[:synthetic]
          assert_equal "(unlinked)", root[:id]
          assert_equal ["p8"], root[:tabs].flat_map { |tab| tab[:panes].map { |pane| pane[:id] } }
        end

        def test_tab_of_unknown_workspace_lands_in_synthetic_root
          tabs = @tabs + [{id: "gone:t1", workspace: "gone", title: "lost", number: 1, pane_count: 0, focused: false}]
          tree = StatusComposer.call(workspaces: @workspaces, tabs: tabs, panes: @panes)

          root = tree[:workspaces].last
          assert root[:synthetic]
          assert_equal ["gone:t1"], root[:tabs].map { |tab| tab[:id] }
        end

        def test_empty_lists_produce_empty_tree
          tree = StatusComposer.call(workspaces: [], tabs: [], panes: [])

          assert_equal [], tree[:workspaces]
        end

        def test_deterministic_for_repeated_calls
          args = {workspaces: @workspaces, tabs: @tabs, panes: @panes}

          assert_equal StatusComposer.call(**args), StatusComposer.call(**args)
        end
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Molecules
      class PresetResolverTest < Minitest::Test
        def lookup(presets)
          ->(name) { presets[name] }
        end

        # --- reference resolution and deep merge -------------------------------

        def test_overlay_wins_over_base_fields
          presets = {"base" => {"label" => "base", "focus" => false}}
          resolved = PresetResolver.resolve_refs(
            {"preset" => "base", "focus" => true}, lookup: lookup(presets)
          )

          assert_equal({"label" => "base", "focus" => true}, resolved)
        end

        def test_arrays_concat_so_collections_compose
          presets = {
            "base" => {"label" => "tab", "panes" => [{"label" => "shell"}]}
          }
          resolved = PresetResolver.resolve_refs(
            {"preset" => "base", "panes" => [{"label" => "agent"}]},
            lookup: lookup(presets)
          )

          assert_equal(
            [{"label" => "shell"}, {"label" => "agent"}],
            resolved["panes"]
          )
        end

        def test_nested_preset_chains_resolve_recursively
          presets = {
            "grandparent" => {"label" => "g", "cwd" => "/g"},
            "parent" => {"preset" => "grandparent", "cwd" => "/p"}
          }
          resolved = PresetResolver.resolve_refs(
            {"preset" => "parent"}, lookup: lookup(presets)
          )

          assert_equal({"label" => "g", "cwd" => "/p"}, resolved)
        end

        def test_hash_without_preset_key_passes_through
          hash = {"label" => "plain"}
          assert_equal(hash, PresetResolver.resolve_refs(hash, lookup: ->(_name) { {"x" => 1} }))
        end

        def test_missing_nested_preset_fails_closed_with_name
          error = assert_raises(PresetResolver::PresetNotFoundError) do
            PresetResolver.resolve_refs({"preset" => "ghost"}, lookup: lookup({}))
          end

          assert_match(/ghost/, error.message)
        end

        def test_cyclic_references_fail_closed
          presets = {"a" => {"preset" => "b"}, "b" => {"preset" => "a"}}

          assert_raises(PresetResolver::CircularPresetError) do
            PresetResolver.resolve_refs({"preset" => "a"}, lookup: lookup(presets))
          end
        end

        # --- workspace / tab walking --------------------------------------------

        def test_resolve_workspace_resolves_tab_entries
          presets = {"agent-tab" => {"label" => "agent", "panes" => [{"label" => "a", "agent" => {"kind" => "pi"}}]}}
          workspace = {
            "label" => "dev",
            "tabs" => [{"preset" => "agent-tab", "label" => "work"}, "scratch"]
          }

          resolved = PresetResolver.resolve_workspace(
            workspace,
            workspace_lookup: lookup({}),
            tab_lookup: lookup(presets)
          )

          assert_equal(
            [
              {"label" => "work", "panes" => [{"label" => "a", "agent" => {"kind" => "pi"}}]},
              {"label" => "scratch"}
            ],
            resolved["tabs"]
          )
        end

        def test_resolve_tab_normalizes_pane_string_shorthand_to_command
          resolved = PresetResolver.resolve_tab(
            {"label" => "t", "panes" => ["bin/dev", {"label" => "agent"}]},
            tab_lookup: lookup({})
          )

          assert_equal(
            [{"command" => "bin/dev"}, {"label" => "agent"}],
            resolved["panes"]
          )
        end

        def test_resolve_tab_inherits_and_composes_panes
          presets = {
            "shell-tab" => {"label" => "shell", "panes" => [{"label" => "shell"}]}
          }
          resolved = PresetResolver.resolve_tab(
            {"preset" => "shell-tab", "panes" => ["bin/dev"]},
            tab_lookup: lookup(presets)
          )

          assert_equal(
            [{"label" => "shell"}, {"command" => "bin/dev"}],
            resolved["panes"]
          )
        end
      end
    end
  end
end

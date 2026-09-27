# frozen_string_literal: true

require "ace/support/config"

module Ace
  module Herdr
    module Molecules
      # Resolves `preset:` references in herdr workspace/tab presets
      # (spec 8wq.t.k84): recursive lookup with deep merge (overlay wins),
      # array concat so collections compose, cycle detection, and
      # fail-closed missing references.
      module PresetResolver
        MAX_DEPTH = 10

        # Raised when a preset references an unknown nested preset
        class PresetNotFoundError < Ace::Herdr::Error; end

        # Raised when preset references form a cycle
        class CircularPresetError < Ace::Herdr::Error; end

        module_function

        # Resolve a workspace hash: the root may inherit another workspace
        # preset; each tab entry may inherit a tab preset.
        #
        # @param hash [Hash] Workspace configuration hash
        # @param workspace_lookup [Proc] name => workspace preset hash
        # @param tab_lookup [Proc] name => tab preset hash
        # @return [Hash] Fully resolved workspace hash
        def resolve_workspace(hash, workspace_lookup:, tab_lookup:)
          resolved = resolve_refs(hash, lookup: workspace_lookup)
          tabs = resolved["tabs"]
          if tabs.is_a?(Array)
            resolved = resolved.merge(
              "tabs" => tabs.map { |entry| resolve_tab(tab_entry(entry), tab_lookup: tab_lookup) }
            )
          end
          resolved
        end

        # Resolve a tab hash: it may inherit another tab preset; pane string
        # shorthand becomes a command entry.
        #
        # @param hash [Hash, String] Tab configuration hash (or label shorthand)
        # @param tab_lookup [Proc] name => tab preset hash
        # @return [Hash] Resolved tab hash
        def resolve_tab(hash, tab_lookup:)
          resolved = resolve_refs(tab_entry(hash), lookup: tab_lookup)
          panes = resolved["panes"]
          if panes.is_a?(Array)
            resolved = resolved.merge("panes" => panes.map { |entry| pane_entry(entry) })
          end
          resolved
        end

        # Resolve one `preset:` reference chain onto `hash`
        #
        # @param hash [Hash] Hash that may contain a "preset" key
        # @param lookup [Proc] name => preset hash (nil when unknown)
        # @param depth [Integer] Recursion depth (cycle guard)
        # @return [Hash] Resolved hash with the base deep-merged underneath
        def resolve_refs(hash, lookup:, depth: 0)
          raise CircularPresetError, "Preset resolution exceeded max depth (#{MAX_DEPTH})" if depth >= MAX_DEPTH
          return hash unless hash.is_a?(Hash) && hash.key?("preset")

          name = hash["preset"].to_s
          base = lookup.call(name)
          raise PresetNotFoundError, "Unknown preset '#{name}'" if base.nil?

          base = resolve_refs(base, lookup: lookup, depth: depth + 1)
          overlay = hash.reject { |key, _| key == "preset" }
          Ace::Support::Config::Atoms::DeepMerger.merge(base, overlay, array_strategy: :concat)
        end

        # @api private
        def tab_entry(entry)
          entry.is_a?(Hash) ? entry : {"label" => entry.to_s}
        end

        # @api private
        # Pane string shorthand declares a command to run in a new split
        def pane_entry(entry)
          entry.is_a?(Hash) ? entry : {"command" => entry.to_s}
        end
      end
    end
  end
end

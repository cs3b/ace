# frozen_string_literal: true

require "ace/support/config"

module Ace
  module Tmux
    module Atoms
      # Resolves `preset:` references in configuration hashes
      #
      # Pure function: takes a hash and a lookup proc, returns a resolved hash.
      # Uses DeepMerger for overlay merging.
      #
      # Resolution order:
      #   1. Load base preset via lookup proc
      #   2. Deep-merge overlay (the hash minus `preset` key) on top
      #   3. Recurse for nested presets (windows contain pane presets, etc.)
      module PresetResolver
        MAX_DEPTH = 10

        module_function

        # Resolve a session hash: resolve window presets, then pane presets within each window
        #
        # @param hash [Hash] Session configuration hash (may contain windows with preset: refs)
        # @param window_lookup [Proc] Proc that takes a name and returns window preset hash
        # @param pane_lookup [Proc] Proc that takes a name and returns pane preset hash
        # @return [Hash] Fully resolved session hash
        def resolve_session(hash, window_lookup:, pane_lookup:)
          result = hash.dup
          return result unless result["windows"].is_a?(Array)

          result["windows"] = result["windows"].map do |window|
            window = normalize_window(window)
            resolved = resolve_preset(window, lookup: window_lookup)
            resolve_window_panes(resolved, pane_lookup: pane_lookup)
          end

          result
        end

        # Resolve a window hash: resolve pane presets within it
        #
        # @param hash [Hash] Window configuration hash
        # @param pane_lookup [Proc] Proc that takes a name and returns pane preset hash
        # @return [Hash] Resolved window hash
        def resolve_window(hash, pane_lookup:)
          result = hash.dup
          resolve_window_panes(result, pane_lookup: pane_lookup)
        end

        # Resolve a single preset reference in a hash
        #
        # @param hash [Hash] Hash that may contain a "preset" key
        # @param lookup [Proc] Proc that takes a preset name and returns a hash
        # @param depth [Integer] Current recursion depth (for circular reference guard)
        # @return [Hash] Resolved hash with preset merged
        def resolve_preset(hash, lookup:, depth: 0)
          raise CircularPresetError, "Preset resolution exceeded max depth (#{MAX_DEPTH})" if depth >= MAX_DEPTH
          return hash unless hash.is_a?(Hash) && hash.key?("preset")

          preset_name = hash["preset"]
          base = lookup.call(preset_name)

          return hash.reject { |k, _| k == "preset" } unless base

          # The base preset may itself reference another preset — resolve recursively
          base = resolve_preset(base, lookup: lookup, depth: depth + 1)

          overlay = hash.reject { |k, _| k == "preset" }
          Ace::Support::Config::Atoms::DeepMerger.merge(base, overlay)
        end

        # Normalize window entry: string shorthand becomes a pane command
        #
        # @param window [Hash, String] Window config or string shorthand
        # @return [Hash] Normalized window hash
        def normalize_window(window)
          return window if window.is_a?(Hash)

          {"panes" => [window.to_s]}
        end

        # Normalize pane entry: string shorthand becomes commands array
        #
        # @param pane [Hash, String] Pane config or string shorthand
        # @return [Hash] Normalized pane hash
        def normalize_pane(pane)
          return pane if pane.is_a?(Hash)

          {"commands" => [pane.to_s]}
        end

        # @api private
        def resolve_window_panes(window_hash, pane_lookup:)
          return window_hash unless window_hash["panes"].is_a?(Array)

          window_hash = window_hash.dup
          window_hash["panes"] = resolve_panes_recursive(window_hash["panes"], pane_lookup: pane_lookup)

          window_hash
        end

        # @api private
        # Recursively resolve panes, handling nested containers with "direction" key.
        def resolve_panes_recursive(panes, pane_lookup:)
          panes.map do |entry|
            entry = normalize_pane(entry)

            if entry.is_a?(Hash) && entry.key?("direction")
              # Container node: recurse into its children
              resolved = entry.dup
              if resolved["panes"].is_a?(Array)
                resolved["panes"] = resolve_panes_recursive(resolved["panes"], pane_lookup: pane_lookup)
              end
              resolved
            else
              # Leaf pane: resolve preset as before
              resolve_preset(entry, lookup: pane_lookup)
            end
          end
        end
      end

      class CircularPresetError < StandardError; end
    end
  end
end

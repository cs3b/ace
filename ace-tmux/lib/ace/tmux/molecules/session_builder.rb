# frozen_string_literal: true

module Ace
  module Tmux
    module Molecules
      # Combines PresetLoader + PresetResolver to build fully resolved models
      #
      # Loads a session preset, resolves all nested window/pane presets,
      # and constructs the model hierarchy (Session → Window → Pane).
      class SessionBuilder
        # @param preset_loader [PresetLoader] Loader for finding presets
        def initialize(preset_loader:)
          @preset_loader = preset_loader
        end

        # Build a fully resolved Session model from a preset name
        #
        # @param preset_name [String] Session preset name
        # @return [Models::Session] Fully resolved session model
        # @raise [PresetNotFoundError] If session preset doesn't exist
        def build(preset_name)
          raw = @preset_loader.load("sessions", preset_name)
          raise PresetNotFoundError, "Session preset not found: #{preset_name}" unless raw

          # Resolve all preset references
          resolved = Atoms::PresetResolver.resolve_session(
            raw,
            window_lookup: @preset_loader.to_lookup("windows"),
            pane_lookup: @preset_loader.to_lookup("panes")
          )

          build_session_model(resolved)
        end

        # Build a fully resolved Window model from a preset name
        #
        # @param preset_name [String] Window preset name
        # @return [Models::Window] Fully resolved window model
        # @raise [PresetNotFoundError] If window preset doesn't exist
        def build_window(preset_name)
          raw = @preset_loader.load("windows", preset_name)
          raise PresetNotFoundError, "Window preset not found: #{preset_name}" unless raw

          resolved = Atoms::PresetResolver.resolve_window(
            raw,
            pane_lookup: @preset_loader.to_lookup("panes")
          )

          build_window_model(resolved)
        end

        private

        def build_session_model(hash)
          windows = (hash["windows"] || []).map { |w| build_window_model(w) }

          Models::Session.new(
            name: hash["name"],
            root: hash["root"],
            windows: windows,
            pre_window: hash["pre_window"],
            startup_window: hash["startup_window"],
            on_project_start: hash["on_project_start"],
            on_project_exit: hash["on_project_exit"],
            attach: hash.fetch("attach", true),
            tmux_options: hash["tmux_options"]
          )
        end

        def build_window_model(hash)
          if nested_layout?(hash)
            build_nested_window_model(hash)
          else
            build_flat_window_model(hash)
          end
        end

        def build_flat_window_model(hash)
          panes = (hash["panes"] || []).map { |p| build_pane_model(p) }

          Models::Window.new(
            name: hash["name"],
            layout: hash["layout"],
            root: hash["root"],
            panes: panes,
            pre_window: hash["pre_window"],
            focus: hash["focus"] || false,
            options: hash["options"] || {}
          )
        end

        def build_nested_window_model(hash)
          direction = parse_direction(hash["direction"] || "horizontal")
          tree = build_layout_tree(hash, direction: direction)
          panes = tree.leaves.map(&:pane)

          Models::Window.new(
            name: hash["name"],
            root: hash["root"],
            panes: panes,
            pre_window: hash["pre_window"],
            focus: hash["focus"] || false,
            options: hash["options"] || {},
            layout_tree: tree
          )
        end

        def build_layout_tree(hash, direction:)
          children = (hash["panes"] || []).map do |entry|
            if entry.is_a?(Hash) && entry.key?("direction")
              child_dir = parse_direction(entry["direction"])
              child_tree = build_layout_tree(entry, direction: child_dir)
              child_tree
            else
              pane = build_pane_model(entry)
              Models::LayoutNode.new(pane: pane, size: entry.is_a?(Hash) ? entry["size"] : nil)
            end
          end

          size = hash.is_a?(Hash) ? hash["size"] : nil
          Models::LayoutNode.new(direction: direction, children: children, size: size)
        end

        def nested_layout?(hash)
          return true if hash.is_a?(Hash) && hash.key?("direction")

          panes = hash["panes"]
          return false unless panes.is_a?(Array)

          panes.any? { |p| p.is_a?(Hash) && p.key?("direction") }
        end

        def parse_direction(str)
          str.to_s == "vertical" ? :vertical : :horizontal
        end

        def build_pane_model(hash)
          hash = Atoms::PresetResolver.normalize_pane(hash)

          Models::Pane.new(
            commands: hash["commands"] || [],
            focus: hash["focus"] || false,
            root: hash["root"],
            name: hash["name"],
            options: hash["options"] || {}
          )
        end
      end
    end
  end
end

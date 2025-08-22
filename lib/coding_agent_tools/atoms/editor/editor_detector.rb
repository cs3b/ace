# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    module Editor
      # Detects the user's preferred editor based on various sources
      class EditorDetector
        KNOWN_EDITORS = {
          "code" => {
            name: "Visual Studio Code",
            command: "code",
            line_support: true,
            line_format: "%file:%line"
          },
          "vim" => {
            name: "Vim",
            command: "vim",
            line_support: true,
            line_format: "+%line %file"
          },
          "nvim" => {
            name: "Neovim",
            command: "nvim",
            line_support: true,
            line_format: "+%line %file"
          },
          "emacs" => {
            name: "Emacs",
            command: "emacs",
            line_support: true,
            line_format: "+%line %file"
          },
          "subl" => {
            name: "Sublime Text",
            command: "subl",
            line_support: true,
            line_format: "%file:%line"
          },
          "mate" => {
            name: "TextMate",
            command: "mate",
            line_support: true,
            line_format: "%file -l %line"
          },
          "atom" => {
            name: "Atom",
            command: "atom",
            line_support: true,
            line_format: "%file:%line"
          },
          "nano" => {
            name: "Nano",
            command: "nano",
            line_support: true,
            line_format: "+%line %file"
          }
        }.freeze

        # Detect user's preferred editor
        # @param explicit_editor [String, nil] Explicitly specified editor
        # @param config [Hash] Configuration settings
        # @return [Hash] Editor configuration
        def detect_editor(explicit_editor: nil, config: {})
          # Priority order:
          # 1. Explicit command line flag
          # 2. User configuration
          # 3. Environment variables (EDITOR, VISUAL)
          # 4. System default detection
          # 5. Fallback

          if explicit_editor
            return resolve_editor(explicit_editor)
          end

          if config.dig("editor", "default")
            return resolve_editor(config["editor"]["default"])
          end

          # Check environment variables
          env_editor = ENV["VISUAL"] || ENV["EDITOR"]
          if env_editor
            return resolve_editor(env_editor)
          end

          # Auto-detect available editors
          detect_available_editor
        end

        # Check if an editor is available on the system
        # @param editor_command [String] Editor command to check
        # @return [Boolean] True if available
        def available?(editor_command)
          return false if editor_command.nil? || editor_command.empty?

          system("command -v #{editor_command} >/dev/null 2>&1")
        end

        # Get list of available editors
        # @return [Array<Hash>] Available editors with metadata
        def available_editors
          KNOWN_EDITORS.select do |command, config|
            available?(command)
          end.map do |command, config|
            config.merge(command: command)
          end
        end

        private

        # Resolve editor configuration from name/command
        # @param editor_name [String] Editor name or command
        # @return [Hash] Editor configuration
        def resolve_editor(editor_name)
          # Handle full paths to editors
          editor_command = File.basename(editor_name)

          # Check if it's a known editor
          if KNOWN_EDITORS.key?(editor_command)
            config = KNOWN_EDITORS[editor_command].dup
            config[:command] = editor_name # Use full path if provided
            return config
          end

          # Unknown editor - create basic configuration
          {
            name: editor_name,
            command: editor_name,
            line_support: false,
            line_format: "%file"
          }
        end

        # Auto-detect the first available editor
        # @return [Hash] Editor configuration
        def detect_available_editor
          # Preferred order for auto-detection
          preferred_order = %w[code vim nvim emacs subl mate atom nano]

          preferred_order.each do |command|
            if available?(command)
              config = KNOWN_EDITORS[command].dup
              config[:auto_detected] = true
              return config
            end
          end

          # Fallback to system default
          {
            name: "System Default",
            command: "open", # macOS default, adjust for other platforms
            line_support: false,
            line_format: "%file",
            fallback: true
          }
        end
      end
    end
  end
end

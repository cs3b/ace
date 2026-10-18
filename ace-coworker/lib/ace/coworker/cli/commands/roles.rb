# frozen_string_literal: true

require "json"

module Ace
  module Coworker
    module CLI
      module Commands
        class Roles < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "List the role preset catalog (gem defaults + project overrides)"

          option :format, default: "table", desc: "Output format (table, json)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(preset_loader: nil)
            super()
            @preset_loader = preset_loader
          end

          # Read-only catalog query; always exit 0 (an empty catalog is a
          # state, not an error).
          def call(**options)
            loader = @preset_loader || begin
              project_root = Molecules::ProjectRoot.new.resolve
              Molecules::RolePresetLoader.new(project_root: project_root)
            end
            presets = loader.list

            return if options[:quiet]

            if options[:format] == "json"
              puts JSON.pretty_generate("roles" => presets)
            else
              puts render_table(presets)
            end
          rescue Ace::Coworker::Error => e
            raise Ace::Support::Cli::Error, e.message
          end

          private

          def render_table(presets)
            return "Coworker roles: none found (gem .ace-defaults/coworker/roles/ and project .ace/coworker/roles/)" if presets.empty?

            lines = ["Coworker roles:"]
            presets.each do |preset|
              lines << "  #{preset['name'].ljust(10)} #{preset['source'].ljust(8)} #{preset['description']}"
              lines << "  #{" " * 10} instructions: #{preset['instructions']}"
            end
            lines.join("\n")
          end
        end
      end
    end
  end
end

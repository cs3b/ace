# frozen_string_literal: true
module Ace
  module Design
    module CLI
      module Commands
        class PresetList < Ace::Support::Cli::Command
          desc "List packaged and configured design presets"
          option :json, type: :boolean, default: false
          def call(json: false, **)
            entries = Molecules::Preset.list
            if json
              CLI.output({"presets" => entries}, json: true)
            else
              entries.each { |item| puts "#{item.fetch('name')}: #{item['description']} [#{item.fetch('verification', 'custom')}]" }
            end
            0
          end
        end
        class PresetShow < Ace::Support::Cli::Command
          desc "Show sources, strengths, compatibility and requirements"
          argument :name, required: true
          option :json, type: :boolean, default: false
          def call(name:, json: false, **)
            data = Molecules::Preset.definition(name).merge("name" => name)
            json ? CLI.output(data, json: true) : puts(YAML.dump(data))
            0
          end
        end
      end
    end
  end
end

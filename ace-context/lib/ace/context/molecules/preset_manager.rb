# frozen_string_literal: true

require 'ace/core'
require 'yaml'

module Ace
  module Context
    module Molecules
      # Manages context presets from markdown files in .ace/context/presets/
      class PresetManager
        attr_reader :presets

        def initialize
          @presets = load_presets
        end

        def list_presets
          @presets.values.map(&:dup)
        end

        def get_preset(name)
          preset = @presets[name.to_s]
          preset&.dup
        end

        def preset_exists?(name)
          @presets.key?(name.to_s)
        end

        private

        def load_presets
          presets = {}

          # Use VirtualConfigResolver to find all context/*.md files
          require 'ace/core/organisms/virtual_config_resolver'
          resolver = Ace::Core::Organisms::VirtualConfigResolver.new

          # Get all context/presets/*.md files from virtual map
          resolver.glob("context/presets/*.md").each do |relative_path, absolute_path|
            name = File.basename(absolute_path, '.md')
            preset_data = load_preset_from_file(absolute_path)

            if preset_data
              preset_data[:name] = name
              preset_data[:source_file] = absolute_path
              presets[name] = preset_data
            end
          end

          presets
        end

        def load_preset_from_file(file)
          content = File.read(file)
          frontmatter, body = parse_frontmatter(content)

          return nil unless frontmatter

          {
            description: frontmatter['description'] || "#{File.basename(file, '.md')} preset",
            params: frontmatter['params'] || {},
            context: frontmatter['context'] || {},
            body: body.strip,
            format: frontmatter.dig('params', 'format') || 'markdown',
            output: frontmatter.dig('params', 'output') || 'stdio',
            cache: frontmatter.dig('params', 'output') == 'cache',
            metadata: frontmatter['metadata'] || {}
          }
        rescue => e
          warn "Error loading preset from #{file}: #{e.message}"
          nil
        end

        def parse_frontmatter(content)
          # Match YAML frontmatter between --- markers
          if content =~ /\A---\s*\n(.*?)\n---\s*\n(.*)\z/m
            yaml_content = $1
            body_content = $2

            begin
              frontmatter = YAML.safe_load(yaml_content, permitted_classes: [Symbol])
              [frontmatter, body_content]
            rescue => e
              warn "Error parsing YAML frontmatter: #{e.message}"
              [nil, content]
            end
          else
            [nil, content]
          end
        end
      end
    end
  end
end
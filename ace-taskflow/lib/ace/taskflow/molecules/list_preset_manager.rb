# frozen_string_literal: true

require 'ace/core'
require 'yaml'

module Ace
  module Taskflow
    module Molecules
      # Manages list presets for tasks, ideas, and releases from YAML files in .ace/taskflow/presets/
      class ListPresetManager
        attr_reader :presets

        def initialize
          @presets = load_presets
        end

        def list_presets(type = :all)
          filtered_presets = case type
          when :tasks
            @presets.select { |_, preset| preset[:type].nil? || preset[:type] == 'tasks' }
          when :ideas
            @presets.select { |_, preset| preset[:type].nil? || preset[:type] == 'ideas' }
          when :releases
            @presets.select { |_, preset| preset[:type].nil? || preset[:type] == 'releases' }
          else
            @presets
          end
          filtered_presets.values.map(&:dup)
        end

        def get_preset(name, type = :tasks)
          preset = @presets[name.to_s]
          return nil unless preset

          # Check if preset is compatible with the requested type
          preset_type = preset[:type]
          return nil if preset_type && preset_type != type.to_s

          preset.dup
        end

        def preset_exists?(name, type = :tasks)
          preset = @presets[name.to_s]
          return false unless preset

          preset_type = preset[:type]
          preset_type.nil? || preset_type == type.to_s
        end

        def apply_preset(name, additional_filters = {})
          preset = get_preset(name)
          return nil unless preset

          # Merge preset filters with additional filters
          merged_filters = preset[:filters].dup
          additional_filters.each do |key, value|
            if merged_filters[key] && merged_filters[key].is_a?(Array) && value.is_a?(Array)
              merged_filters[key] = (merged_filters[key] + value).uniq
            else
              merged_filters[key] = value
            end
          end

          {
            name: name,
            description: preset[:description],
            context: preset[:context] || 'current',
            filters: merged_filters,
            sort: preset[:sort] || { by: :sort, ascending: true },
            display: preset[:display] || {},
            type: preset[:type] || 'tasks'
          }
        end

        private

        def load_presets
          presets = default_presets

          # Use VirtualConfigResolver to find all taskflow/presets/*.yml files
          require 'ace/core/organisms/virtual_config_resolver'
          resolver = Ace::Core::Organisms::VirtualConfigResolver.new

          # Get all taskflow/presets/*.yml files from virtual map
          resolver.glob("taskflow/presets/*.yml").each do |relative_path, absolute_path|
            name = File.basename(absolute_path, '.yml')
            preset_data = load_preset_from_file(absolute_path)

            if preset_data
              preset_data[:name] = name
              preset_data[:source_file] = absolute_path
              preset_data[:custom] = true
              presets[name] = preset_data
            end
          end

          presets
        end

        def load_preset_from_file(file)
          content = File.read(file)
          data = YAML.safe_load(content, permitted_classes: [Symbol])

          return nil unless data.is_a?(Hash)

          {
            description: data['description'] || "#{File.basename(file, '.yml')} preset",
            context: data['context'],
            filters: data['filters'] || {},
            sort: data['sort'] || { by: :sort, ascending: true },
            display: data['display'] || {},
            type: data['type']
          }
        rescue => e
          warn "Error loading preset from #{file}: #{e.message}"
          nil
        end

        def default_presets
          {
            'next' => {
              name: 'next',
              description: 'Next actionable tasks (pending + in-progress)',
              context: 'current',
              filters: { status: ['pending', 'in-progress'] },
              sort: { by: :sort, ascending: true },
              display: { group_by: nil },
              type: 'tasks',
              default: true
            },
            'recent' => {
              name: 'recent',
              description: 'Recently modified items',
              context: 'current',
              filters: {},
              sort: { by: :modified, ascending: false },
              display: { show_dates: true },
              type: nil, # Universal preset
              default: true
            },
            'all' => {
              name: 'all',
              description: 'All items across all contexts',
              context: 'all',
              filters: {},
              sort: { by: :context, ascending: true },
              display: { group_by: :context },
              type: nil, # Universal preset
              default: true
            },
            'pending' => {
              name: 'pending',
              description: 'Pending items only',
              context: 'current',
              filters: { status: ['pending'] },
              sort: { by: :sort, ascending: true },
              display: {},
              type: nil, # Universal preset
              default: true
            },
            'in-progress' => {
              name: 'in-progress',
              description: 'In-progress items only',
              context: 'current',
              filters: { status: ['in-progress'] },
              sort: { by: :sort, ascending: true },
              display: {},
              type: nil, # Universal preset
              default: true
            },
            'done' => {
              name: 'done',
              description: 'Completed items',
              context: 'current',
              filters: { status: ['done'] },
              sort: { by: :modified, ascending: false },
              display: { show_dates: true },
              type: nil, # Universal preset
              default: true
            }
          }
        end
      end
    end
  end
end
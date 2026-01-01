# frozen_string_literal: true

require 'ace/config'
require 'yaml'
require_relative '../configuration'

module Ace
  module Taskflow
    module Molecules
      # Manages list presets for tasks, ideas, and releases from YAML files in .ace/taskflow/presets/
      class ListPresetManager
        attr_reader :presets

        def initialize
          @presets = load_presets
          @config = Taskflow.configuration
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
          # If type is nil, only return universal presets (preset_type must be nil)
          if type.nil?
            return nil if preset_type
          else
            # If type is specified, return nil if preset_type exists and doesn't match
            return nil if preset_type && preset_type != type.to_s
          end

          preset.dup
        end

        def preset_exists?(name, type = :tasks)
          preset = @presets[name.to_s]
          return false unless preset

          preset_type = preset[:type]
          preset_type.nil? || preset_type == type.to_s
        end

        def apply_preset(name, additional_filters = {}, type = :tasks)
          preset = get_preset(name, type)
          # If no type-specific preset found, try universal presets (type: nil)
          preset ||= get_preset(name, nil) if type
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

          # Apply folder prefix to glob patterns based on type
          glob_with_prefix = apply_folder_prefix(preset[:glob], type)

          {
            name: name,
            description: preset[:description],
            release: preset[:release] || 'current',
            filters: merged_filters,
            glob: glob_with_prefix,
            sort: preset[:sort] || { by: :sort, ascending: true },
            display: preset[:display] || {},
            type: preset[:type] || 'tasks'
          }
        end

        # Apply folder prefix to glob patterns based on type
        # Converts relative patterns like "maybe/**/*.s.md" to "ideas/maybe/**/*.s.md"
        # Uses configured folder names from config.directories
        def apply_folder_prefix(glob_patterns, folder_type)
          # Provide default pattern if none specified
          glob_patterns ||= @config.default_glob_pattern

          # Get configured folder name
          folder_name = case folder_type
          when :ideas
            @config.ideas_dir
          when :tasks
            @config.task_dir
          else
            return glob_patterns # No prefix for unknown types
          end

          # Apply prefix to each pattern
          Array(glob_patterns).map do |pattern|
            # Skip patterns that already have a folder prefix (legacy patterns)
            if pattern.include?('/')
              # Check if it starts with a known folder name - if so, keep as is
              if pattern.start_with?("#{@config.ideas_dir}/", "#{@config.task_dir}/")
                pattern
              else
                # Prefix the pattern
                "#{folder_name}/#{pattern}"
              end
            else
              # Simple pattern without slash - prefix it
              "#{folder_name}/#{pattern}"
            end
          end
        end

        private

        def load_presets
          presets = default_presets

          # Use VirtualConfigResolver to find all taskflow/presets/*.yml files
          resolver = Ace::Config.virtual_resolver

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

          # Load glob patterns - support both single string and array
          glob = data.dig('filters', 'glob')
          glob = [glob] if glob.is_a?(String)

          # Validate glob patterns
          if glob
            valid_globs = []
            glob.each do |pattern|
              if valid_glob?(pattern)
                valid_globs << pattern
              else
                warn "Invalid glob pattern in #{file}: #{pattern.inspect}"
              end
            end
            glob = valid_globs.empty? ? nil : valid_globs
          end

          # Extract filters and remove glob from it since it's stored separately
          filters = (data['filters'] || {}).dup
          filters.delete('glob')

          {
            description: data['description'] || "#{File.basename(file, '.yml')} preset",
            release: data['release'],
            filters: filters,
            glob: glob,
            sort: data['sort'] || { by: :sort, ascending: true },
            display: data['display'] || {},
            type: data['type']
          }
        rescue StandardError => e
          warn "Error loading preset from #{file}: #{e.message}"
          nil
        end

        def valid_glob?(pattern)
          return false unless pattern.is_a?(String) && !pattern.empty?
          # Disallow dangerous characters
          return false if pattern =~ /[<>|]/
          # Ensure it's a relative path (no absolute paths)
          return false if pattern.start_with?('/')
          true
        rescue StandardError
          false
        end

        def default_presets
          {
            'next' => {
              name: 'next',
              description: 'Next actionable tasks (pending + in-progress)',
              release: 'current',
              filters: { status: ['pending', 'in-progress'] },
              sort: { by: :sort, ascending: true },
              display: { group_by: nil },
              type: 'tasks',
              default: true
            },
            'recent' => {
              name: 'recent',
              description: 'Recently modified items',
              release: 'current',
              filters: {},
              sort: { by: :modified, ascending: false },
              display: { show_dates: true },
              type: nil, # Universal preset
              default: true
            },
            'all' => {
              name: 'all',
              description: 'All tasks in current release (all statuses)',
              release: 'current',
              filters: {},
              sort: { by: :sort, ascending: true },
              display: {},
              type: nil, # Universal preset
              default: true
            },
            'all-releases' => {
              name: 'all-releases',
              description: 'All tasks across all releases',
              release: 'all',
              filters: {},
              sort: { by: :release, ascending: true },
              display: { group_by: :release },
              type: nil, # Universal preset
              default: true
            },
            'pending' => {
              name: 'pending',
              description: 'Pending items only',
              release: 'current',
              filters: { status: ['pending'] },
              sort: { by: :sort, ascending: true },
              display: {},
              type: nil, # Universal preset
              default: true
            },
            'in-progress' => {
              name: 'in-progress',
              description: 'In-progress items only',
              release: 'current',
              filters: { status: ['in-progress'] },
              sort: { by: :sort, ascending: true },
              display: {},
              type: nil, # Universal preset
              default: true
            },
            'done' => {
              name: 'done',
              description: 'Completed items',
              release: 'current',
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
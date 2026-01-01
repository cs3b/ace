# frozen_string_literal: true

require 'ace/config'
require 'yaml'
require 'set'
require_relative '../atoms/preset_validator'
require_relative '../atoms/section_validator'

module Ace
  module Context
    module Molecules
      # Manages context presets from markdown files in .ace/context/presets/
      class PresetManager
        attr_reader :presets

        def initialize
          @section_validator = Atoms::SectionValidator.new
          @presets = load_presets
          @preset_cache = {}  # Cache for composed presets during single execution
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

        # Load a preset with composition support
        # Returns fully composed preset data with all dependent presets merged
        def load_preset_with_composition(name, visited = Set.new)
          # Check circular dependency
          validation = Atoms::PresetValidator.check_circular_dependency(name, visited.to_a)
          unless validation[:success]
            return {
              error: validation[:error],
              success: false
            }
          end

          # Check if preset exists
          preset = get_preset(name)
          unless preset
            return {
              error: "Preset '#{name}' not found. Available presets: #{@presets.keys.join(', ')}",
              success: false
            }
          end

          # Mark this preset as visited
          new_visited = visited.dup.add(name)

          # Extract preset references
          preset_refs = Atoms::PresetValidator.extract_preset_references(preset)

          # If no references, return preset as-is
          if preset_refs.empty?
            preset[:success] = true
            return preset
          end

          # Load all referenced presets recursively
          composed_presets = []
          errors = []

          preset_refs.each do |ref_name|
            composed = load_preset_with_composition(ref_name, new_visited)
            if composed[:success]
              composed_presets << composed
            else
              errors << composed[:error]
            end
          end

          # If there were errors loading dependencies, return error
          if errors.any?
            return {
              error: "Failed to load preset dependencies: #{errors.join(', ')}",
              success: false,
              partial_presets: composed_presets
            }
          end

          # Merge all composed presets with current preset
          # Order: dependencies first, then current preset
          merged = merge_preset_data(composed_presets + [preset])
          merged[:success] = true
          merged[:composed] = true
          merged[:composed_from] = preset_refs + [name]

          merged
        end

        # Merge multiple preset data structures
        # Arrays are concatenated and deduplicated (first occurrence wins)
        # Scalars follow "last wins" strategy
        def merge_preset_data(presets)
          return presets.first if presets.size == 1

          merged = {
            description: nil,
            params: {},
            context: {},
            body: '',
            # Don't set format here - let ContextLoader determine the default
            output: nil,
            cache: false,
            metadata: {}
          }

          # Collect all sections for merging
          all_sections = []

          presets.each do |preset|
            # Merge context configuration
            if preset[:context]
              context = preset[:context]

              # Merge params (scalar override)
              if context['params']
                merged[:context]['params'] ||= {}
                merged[:context]['params'].merge!(context['params'])
              end

              # Merge files array (deduplicate)
              if context['files']
                merged[:context]['files'] ||= []
                merged[:context]['files'].concat(context['files'])
              end

              # Merge commands array (deduplicate)
              if context['commands']
                merged[:context]['commands'] ||= []
                merged[:context]['commands'].concat(context['commands'])
              end

              # Collect sections for separate processing
              if context['sections']
                all_sections << context['sections']
              end

              # Copy other context keys
              context.each do |key, value|
                next if %w[params files commands sections].include?(key)
                merged[:context][key] = value
              end
            end

            # Scalar overrides (last wins)
            merged[:description] = preset[:description] if preset[:description]
            # Don't override format from preset - let ContextLoader handle defaults based on embed_document_source
            merged[:output] = preset[:output] if preset[:output]
            merged[:cache] = preset[:cache] if preset[:cache]

            # Merge params at root level (for backward compatibility)
            if preset[:params]
              merged[:params].merge!(preset[:params])
            end

            # Concatenate body content
            if preset[:body] && !preset[:body].empty?
              merged[:body] += "\n\n" unless merged[:body].empty?
              merged[:body] += preset[:body]
            end

            # Deep merge metadata
            if preset[:metadata]
              merged[:metadata] = deep_merge_hash(merged[:metadata], preset[:metadata])
            end
          end

          # Merge sections using SectionProcessor if any exist
          if all_sections.any?
            require_relative 'section_processor'
            section_processor = Molecules::SectionProcessor.new
            merged_sections = section_processor.merge_sections(*all_sections)
            merged[:context]['sections'] = merged_sections
          end

          # Deduplicate arrays
          if merged[:context]['files']
            merged[:context]['files'].uniq!
          end

          if merged[:context]['commands']
            merged[:context]['commands'].uniq!
          end

          # Extract all merged params to root level (maintains backward compatibility)
          # This ensures params like output, format, timeout, max_size are accessible at root
          if merged[:context]['params']
            merged_params = merged[:context]['params']

            # Store params hash at root level
            merged[:params] = merged_params

            # Extract ALL param keys to root level
            merged_params.each do |key, value|
              merged[key.to_sym] = value
            end

            # Derive cache boolean from output param
            merged[:cache] = (merged_params['output'] == 'cache')
          end

          merged
        end

        private

        # Deep merge two hashes (similar to ContextMerger but simpler)
        def deep_merge_hash(hash1, hash2)
          merged = hash1.dup

          hash2.each do |key, value2|
            if merged.key?(key)
              value1 = merged[key]
              merged[key] = if value1.is_a?(Hash) && value2.is_a?(Hash)
                              deep_merge_hash(value1, value2)
                            elsif value1.is_a?(Array) && value2.is_a?(Array)
                              (value1 + value2).uniq
                            else
                              value2  # Last wins
                            end
            else
              merged[key] = value2
            end
          end

          merged
        end

        def load_presets
          presets = {}

          # Use ace-config VirtualConfigResolver to find all context/*.md files
          resolver = Ace::Config.virtual_resolver

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

          # Only support NEW structure: context.params
          context_config = frontmatter['context'] || {}
          params = context_config['params'] || {}

          # Validate sections if present
          if context_config['sections']
            unless @section_validator.validate_sections(context_config['sections'])
              errors = @section_validator.errors
              warn "Warning: Section validation failed in #{file}:\n  #{errors.join("\n  ")}\n\nPlease review the sections configuration in this file. The preset will continue to load, but section functionality may be limited."
              # Don't fail loading, just warn - allow users to fix configuration
            end
          end

          preset_data = {
            description: frontmatter['description'] || "#{File.basename(file, '.md')} preset",
            params: params,
            context: context_config,
            body: body.strip,
            format: params['format'], # Don't set default here - let ContextLoader handle defaults
            output: params['output'] || 'stdio',
            cache: params['output'] == 'cache',
            metadata: frontmatter['metadata'] || {}
          }

          # Add section validation metadata if sections were validated
          if context_config['sections']
            preset_data[:metadata][:sections_validated] = true
            preset_data[:metadata][:section_validation_errors] = @section_validator.errors unless @section_validator.errors.empty?
          end

          # Extract all params to root level (for backward compatibility and consistency)
          params.each do |key, value|
            preset_data[key.to_sym] = value
          end

          # Re-derive cache from output param (in case it was set via params extraction)
          preset_data[:cache] = (params['output'] == 'cache')

          preset_data
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
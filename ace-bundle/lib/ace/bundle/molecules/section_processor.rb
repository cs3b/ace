# frozen_string_literal: true

require_relative '../atoms/section_validator'
require_relative '../atoms/content_checker'

module Ace
  module Bundle
    module Molecules
      # Processes and manages section definitions and composition
      class SectionProcessor
        def initialize
          @validator = Atoms::SectionValidator.new
        end

        # Processes section definitions from configuration
        # @param config [Hash] configuration hash containing sections
        # @param preset_manager [PresetManager] preset manager for loading referenced presets
        # @return [Hash] processed sections hash
        def process_sections(config, preset_manager = nil)
          sections_config = extract_sections_config(config)
          return {} if sections_config.nil? || sections_config.empty?

          unless @validator.validate_sections(sections_config)
            errors = @validator.errors
            raise Ace::Bundle::SectionValidationError, "Section validation failed:\n  #{errors.join("\n  ")}\n\nPlease check your sections configuration and ensure all required fields are properly formatted."
          end

          processed_sections = normalize_sections(sections_config)

          # Process preset references within sections if preset manager is available
          if preset_manager
            processed_sections = process_section_presets(processed_sections, preset_manager)
          end
        end

        # Checks if configuration already has sections
        # @param config [Hash] configuration to check
        # @return [Boolean] true if has sections
        def has_sections?(config)
          # Use 'bundle' key for configuration
          bundle = config['bundle'] || config[:bundle]
          return false unless bundle

          sections = bundle['sections'] || bundle[:sections]
          sections && !sections.empty?
        end

        # Merges sections from multiple configurations
        # @param sections_list [Array<Hash>] list of sections hashes
        # @return [Hash] merged sections
        def merge_sections(*sections_list)
          merged = {}

          sections_list.compact.each do |sections|
            next if sections.empty?

            sections.each do |name, section|
              if merged.key?(name)
                merged[name] = merge_section_data(merged[name], section)
              else
                merged[name] = deep_copy(section)
              end
            end
          end

          # Validate final merged sections
          unless @validator.validate_sections(merged)
            errors = @validator.errors
            raise Ace::Bundle::SectionValidationError, "Merged sections validation failed after processing:\n  #{errors.join("\n  ")}\n\nThis error occurred after merging preset content. Please check if referenced presets are compatible."
          end

          merged
        end

        # Gets sections sorted by YAML insertion order
        # @param sections [Hash] sections hash
        # @return [Array] array of [name, section] pairs in YAML order
        def sorted_sections(sections)
          # In Ruby 3.2+, hash insertion order is preserved
          # This returns sections in the order they appear in the YAML file
          sections.to_a
        end

        # Filters sections by content type (based on actual content, not content_type field)
        # @param sections [Hash] sections hash
        # @param content_type [String] content type to filter by (files, commands, diffs, content)
        # @return [Hash] filtered sections
        def filter_sections_by_type(sections, content_type)
          sections.select { |_, section|
            has_content_type?(section, content_type)
          }
        end

        # Processes preset references within sections
        # @param sections [Hash] sections hash
        # @param preset_manager [PresetManager] preset manager for loading referenced presets
        # @return [Hash] sections with preset content merged in
        def process_section_presets(sections, preset_manager)
          processed = deep_copy(sections)

          processed.each do |section_name, section_data|
            presets = section_data[:presets] || section_data['presets']
            next unless presets&.any?

            # Load all referenced presets
            merged_preset_content = merge_section_presets(presets, preset_manager, section_name)

            # Merge preset content into section
            processed[section_name] = merge_preset_content_into_section(section_data, merged_preset_content)

            # Remove the presets reference after processing (normalized to symbol)
            processed[section_name].delete(:presets)
          end

          processed
        end

        # Gets section names for a content type
        # @param sections [Hash] sections hash
        # @param content_type [String] content type
        # @return [Array<String>] section names
        def get_section_names_by_type(sections, content_type)
          filter_sections_by_type(sections, content_type).keys
        end

        # Merges multiple presets for use within a section
        # @param preset_names [Array<String>] array of preset names
        # @param preset_manager [PresetManager] preset manager
        # @param section_name [String] section name for error reporting
        # @return [Hash] merged preset content
        def merge_section_presets(preset_names, preset_manager, section_name)
          all_presets = []
          errors = []

          preset_names.each do |preset_name|
            preset = preset_manager.load_preset_with_composition(preset_name)
            if preset[:success]
              all_presets << preset
            else
              errors << "Failed to load preset '#{preset_name}' for section '#{section_name}': #{preset[:error]}"
            end
          end

          if errors.any?
            raise Ace::Bundle::SectionValidationError, "Section preset loading failed for section '#{section_name}':\n  #{errors.join("\n  ")}\n\nPlease ensure all referenced presets exist and are accessible. Check preset names for typos and verify preset files are in the correct location."
          end

          # Extract bundle content from presets
          preset_contents = all_presets.map { |preset| preset[:bundle] || {} }
          merge_preset_content(*preset_contents)
        end

        # Merges preset content into a section
        # @param section_data [Hash] original section data
        # @param preset_content [Hash] merged preset content
        # @return [Hash] section with preset content merged
        def merge_preset_content_into_section(section_data, preset_content)
          merged = deep_copy(section_data)

          # Merge content from preset bundle (handle both string and symbol keys)
          %w[files commands ranges diffs].each do |content_type|
            preset_files = preset_content[content_type] || preset_content[content_type.to_sym]
            if preset_files&.any?
              # Get existing files from both string and symbol keys
              existing_files = merged[content_type] || merged[content_type.to_sym] || []
              merged[content_type] = (existing_files + preset_files).uniq
            end
          end

          # Merge sections from preset bundle (flatten into current section)
          if preset_content['sections']&.any?
            preset_content['sections'].each do |_, preset_section|
              merged = merge_section_data(merged, preset_section)
            end
          end

          # Merge other content
          if preset_content['content'] && !preset_content['content'].empty?
            existing_content = merged['content'] || merged[:content] || ''
            if existing_content.empty?
              merged['content'] = preset_content['content']
            else
              merged['content'] = existing_content + "\n\n#{preset_content['content']}"
            end
          end

          merged
        end

        # Merges preset content structures (similar to PresetManager but focused on bundles)
        # @param preset_contents [Array<Hash>] array of preset content hashes
        # @return [Hash] merged preset content
        def merge_preset_content(*preset_contents)
          return {} if preset_contents.empty?
          return preset_contents.first if preset_contents.size == 1

          merged = {
            'files' => [],
            'commands' => [],
            'ranges' => [],
            'diffs' => [],
            'sections' => {},
            'content' => ''
          }

          preset_contents.each do |content|
            next unless content

            # Merge arrays (concatenate and deduplicate)
            %w[files commands ranges diffs].each do |array_key|
              if content[array_key]&.any?
                merged[array_key].concat(content[array_key])
                merged[array_key].uniq!
              end
            end

            # Merge sections
            if content['sections']&.any?
              content['sections'].each do |section_name, section_data|
                if merged['sections'].key?(section_name)
                  merged['sections'][section_name] = merge_section_data(
                    merged['sections'][section_name],
                    section_data
                  )
                else
                  merged['sections'][section_name] = deep_copy(section_data)
                end
              end
            end

            # Concatenate content
            if content['content'] && !content['content'].empty?
              if merged['content'].empty?
                merged['content'] = content['content']
              else
                merged['content'] += "\n\n#{content['content']}"
              end
            end
          end

          merged
        end

        # Public access for testing content type detection
        # @param section [Hash] section definition
        # @param content_type [String] content type to check for
        # @return [Boolean] true if section has the specified content type
        def has_content_type?(section, content_type)
          case content_type
          when 'files'
            !!(section['files'] || section[:files])
          when 'commands'
            !!(section['commands'] || section[:commands])
          when 'diffs'
            !!(section['ranges'] || section[:ranges] || section['diffs'] || section[:diffs])
          when 'presets'
            !!(section['presets'] || section[:presets])
          when 'content'
            !!(section['content'] || section[:content])
          else
            false
          end
        end

        private

        # Recursively converts all string keys to symbols
        # @param obj [Hash, Array, Object] object to symbolize
        # @return [Hash, Array, Object] object with symbolized keys
        def symbolize_keys_deep(obj)
          case obj
          when Hash
            obj.each_with_object({}) do |(key, value), result|
              sym_key = key.respond_to?(:to_sym) ? key.to_sym : key
              result[sym_key] = symbolize_keys_deep(value)
            end
          when Array
            obj.map { |item| symbolize_keys_deep(item) }
          else
            obj
          end
        end

        # Extracts sections configuration from the main config
        def extract_sections_config(config)
          # Use 'bundle' key for configuration
          bundle = config['bundle'] || config[:bundle]
          return {} unless bundle

          bundle['sections'] || bundle[:sections] || {}
        end

        # Normalizes sections configuration (string keys to symbols, defaults, etc.)
        def normalize_sections(sections)
          normalized = {}

          sections.each do |name, section|
            normalized[name] = normalize_section(name, section)
          end

          normalized
        end

        # Normalizes a single section
        def normalize_section(name, section)
          normalized = {}

          # Convert string keys to symbols for consistency
          section.each do |key, value|
            normalized[key.to_sym] = value
          end

          # Normalize field names for backward compatibility
          if normalized[:desciription]
            normalized[:description] = normalized[:desciription]
            normalized.delete(:desciription)
          end

          # Normalize diff/diffs to ranges format
          # Supports two formats:
          # 1. diffs: [...] - simple array of range strings (legacy)
          # 2. diff: { ranges: [...], paths: [...], since: "..." } - complex format with options
          if normalized[:diff]
            diff_config = normalized[:diff]
            if diff_config.is_a?(Hash)
              # Extract ranges from complex diff config
              if diff_config[:ranges] || diff_config['ranges']
                normalized[:ranges] = diff_config[:ranges] || diff_config['ranges']
              elsif diff_config[:since] || diff_config['since']
                # Convert 'since' to range format
                since_ref = diff_config[:since] || diff_config['since']
                normalized[:ranges] = ["#{since_ref}...HEAD"]
              end
              # Note: paths filtering will be handled by ace-git when implemented
            elsif diff_config.is_a?(String)
              # Single range string
              normalized[:ranges] = [diff_config]
            elsif diff_config.is_a?(Array)
              # Array of ranges
              normalized[:ranges] = diff_config
            end
            # Remove the diff key after normalization
            normalized.delete(:diff)
          elsif normalized[:diffs]
            # Legacy diffs format - just rename to ranges
            normalized[:ranges] = normalized[:diffs]
            normalized.delete(:diffs)
          end

          # Ensure title is set with robust title generation
          normalized[:title] ||= generate_title_from_name(name) if name

          normalized
        end


        # Merges two section data hashes
        # Normalizes keys to symbols for consistent internal access
        def merge_section_data(existing, new_section)
          # Normalize keys for consistent internal access
          existing_normalized = symbolize_keys_deep(existing)
          new_normalized = symbolize_keys_deep(new_section)
          merged = deep_copy(existing_normalized)

          # Merge files arrays
          if merged[:files] || new_normalized[:files]
            merged[:files] = ((merged[:files] || []) + (new_normalized[:files] || [])).uniq
          end

          # Merge commands arrays
          if merged[:commands] || new_normalized[:commands]
            merged[:commands] = ((merged[:commands] || []) + (new_normalized[:commands] || [])).uniq
          end

          # Merge ranges arrays (skip if only _processed_diffs present)
          if merged[:ranges] || new_normalized[:ranges]
            merged[:ranges] = ((merged[:ranges] || []) + (new_normalized[:ranges] || [])).uniq
          end

          # Merge diffs arrays (legacy format)
          if merged[:diffs] || new_normalized[:diffs]
            merged[:diffs] = ((merged[:diffs] || []) + (new_normalized[:diffs] || [])).uniq
          end

          # Merge processed diffs with source-based deduplication
          merged_processed = merged[:_processed_diffs] || []
          new_processed = new_normalized[:_processed_diffs] || []
          if merged_processed.any? || new_processed.any?
            merged[:_processed_diffs] = (merged_processed + new_processed).uniq { |d|
              d.is_a?(Hash) ? (d[:source] || d[:range] || d) : d
            }
          end

          # Merge content (concatenate)
          if merged[:content] || new_normalized[:content]
            existing_content = merged[:content] || ''
            new_content = new_normalized[:content] || ''

            if !new_content.empty?
              merged[:content] = existing_content.empty? ? new_content : "#{existing_content}\n\n#{new_content}"
            end
          end

          # Merge exclude patterns
          if merged[:exclude] || new_normalized[:exclude]
            merged[:exclude] = ((merged[:exclude] || []) + (new_normalized[:exclude] || [])).uniq
          end

          # Override non-array fields with new values
          %i[title priority description template content_type].each do |field|
            merged[field] = new_normalized[field] if new_normalized[field]
          end

          merged
        end

        # Creates deep copy of object
        def deep_copy(obj)
          case obj
          when Hash
            obj.each_with_object({}) { |(k, v), h| h[k] = deep_copy(v) }
          when Array
            obj.map { |item| deep_copy(item) }
          else
            obj
          end
        end

        # Generates human-readable title from section name
        def generate_title_from_name(name)
          return nil unless name

          # Convert underscores and hyphens to spaces, capitalize each word
          name.to_s.gsub(/[_-]/, ' ')
               .split
               .map(&:capitalize)
               .join(' ')
        end

        # Helper methods to detect content types in sections
        # Delegates to shared ContentChecker atom for consistency

        def has_files_content?(section_data)
          Atoms::ContentChecker.has_files_content?(section_data)
        end

        def has_commands_content?(section_data)
          Atoms::ContentChecker.has_commands_content?(section_data)
        end

        def has_diffs_content?(section_data)
          Atoms::ContentChecker.has_diffs_content?(section_data)
        end

        def has_content_content?(section_data)
          Atoms::ContentChecker.has_content_content?(section_data)
        end

      end

    end
  end
end

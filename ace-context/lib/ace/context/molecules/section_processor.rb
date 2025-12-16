# frozen_string_literal: true

require_relative '../atoms/section_validator'
require_relative '../atoms/content_checker'

module Ace
  module Context
    module Molecules
      # Processes and manages section definitions, composition, and migration
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
            raise SectionValidationError, "Section validation failed:\n  #{errors.join("\n  ")}\n\nPlease check your sections configuration and ensure all required fields are properly formatted."
          end

          processed_sections = normalize_sections(sections_config)

          # Process preset references within sections if preset manager is available
          if preset_manager
            processed_sections = process_section_presets(processed_sections, preset_manager)
          end

          merge_legacy_content(processed_sections, config)
        end

        # Migrates legacy configuration to section-based format
        # @param config [Hash] legacy configuration
        # @return [Hash] migrated configuration with sections
        def migrate_legacy_to_sections(config)
          return config if has_sections?(config)

          migrated = deep_copy(config)
          sections = create_legacy_sections(migrated)

          if sections.any?
            migrated['context'] ||= {}
            migrated['context']['sections'] = sections
          end

          migrated
        end

        # Checks if configuration already has sections
        # @param config [Hash] configuration to check
        # @return [Boolean] true if has sections
        def has_sections?(config)
          context = config['context'] || config[:context]
          return false unless context

          sections = context['sections'] || context[:sections]
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
            raise SectionValidationError, "Merged sections validation failed after processing:\n  #{errors.join("\n  ")}\n\nThis error occurred after merging preset content. Please check if referenced presets are compatible."
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

            # Remove the presets reference after processing
            processed[section_name].delete(:presets)
            processed[section_name].delete('presets')
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
            raise SectionValidationError, "Section preset loading failed for section '#{section_name}':\n  #{errors.join("\n  ")}\n\nPlease ensure all referenced presets exist and are accessible. Check preset names for typos and verify preset files are in the correct location."
          end

          # Extract context content from presets
          preset_contents = all_presets.map { |preset| preset[:context] || {} }
          merge_preset_content(*preset_contents)
        end

        # Merges preset content into a section
        # @param section_data [Hash] original section data
        # @param preset_content [Hash] merged preset content
        # @return [Hash] section with preset content merged
        def merge_preset_content_into_section(section_data, preset_content)
          merged = deep_copy(section_data)

          # Merge content from preset context (handle both string and symbol keys)
          %w[files commands ranges diffs].each do |content_type|
            preset_files = preset_content[content_type] || preset_content[content_type.to_sym]
            if preset_files&.any?
              # Get existing files from both string and symbol keys
              existing_files = merged[content_type] || merged[content_type.to_sym] || []
              merged[content_type] = (existing_files + preset_files).uniq
            end
          end

          # Merge sections from preset context (flatten into current section)
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

        # Merges preset content structures (similar to PresetManager but focused on context)
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

        # Extracts sections configuration from the main config
        def extract_sections_config(config)
          context = config['context'] || config[:context]
          return {} unless context

          context['sections'] || context[:sections] || {}
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
              # Note: paths filtering will be handled by ace-git-diff when implemented
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

        # Merges legacy content into sections
        def merge_legacy_content(sections, config)
          context = config['context'] || config[:context]
          return sections unless context

          # Create attachments section for legacy content
          legacy_content = collect_legacy_content(context)

          if legacy_content.any?
            sections['attachments'] = create_attachments_section(legacy_content)
          end

          sections
        end

        # Collects legacy content from configuration
        def collect_legacy_content(context)
          legacy_content = {}

          # Legacy files
          if context['files'] || context[:files]
            legacy_content[:files] = context['files'] || context[:files]
          end

          # Legacy commands
          if context['commands'] || context[:commands]
            legacy_content[:commands] = context['commands'] || context[:commands]
          end

          # Legacy diff/diffs/ranges - normalize to ranges
          if context['diff'] || context[:diff]
            diff_config = context['diff'] || context[:diff]
            if diff_config.is_a?(Hash)
              # Extract ranges from complex diff config
              if diff_config['ranges'] || diff_config[:ranges]
                legacy_content[:ranges] = diff_config['ranges'] || diff_config[:ranges]
              elsif diff_config['since'] || diff_config[:since]
                since_ref = diff_config['since'] || diff_config[:since]
                legacy_content[:ranges] = ["#{since_ref}...HEAD"]
              end
            elsif diff_config.is_a?(String)
              legacy_content[:ranges] = [diff_config]
            elsif diff_config.is_a?(Array)
              legacy_content[:ranges] = diff_config
            end
          elsif context['diffs'] || context[:diffs]
            legacy_content[:ranges] = context['diffs'] || context[:diffs]
          elsif context['ranges'] || context[:ranges]
            legacy_content[:ranges] = context['ranges'] || context[:ranges]
          end

          legacy_content
        end

        # Creates attachments section for legacy content
        def create_attachments_section(legacy_content)
          {
            title: "Attachments",
            **legacy_content
          }
        end

        # Creates legacy sections from legacy configuration
        def create_legacy_sections(config)
          context = config['context'] || config[:context]
          return {} unless context

          sections = {}

          # Files section
          if context['files'] || context[:files]
            sections['files'] = {
              title: "Files",
              files: context['files'] || context[:files],
              exclude: context['exclude'] || context[:exclude]
            }
          end

          # Commands section
          if context['commands'] || context[:commands]
            sections['commands'] = {
              title: "Commands",
              commands: context['commands'] || context[:commands]
            }
          end

          # Diffs section - handle diff/diffs/ranges
          ranges = nil
          if context['diff'] || context[:diff]
            diff_config = context['diff'] || context[:diff]
            if diff_config.is_a?(Hash)
              ranges = diff_config['ranges'] || diff_config[:ranges]
              if !ranges && (diff_config['since'] || diff_config[:since])
                since_ref = diff_config['since'] || diff_config[:since]
                ranges = ["#{since_ref}...HEAD"]
              end
            elsif diff_config.is_a?(String)
              ranges = [diff_config]
            elsif diff_config.is_a?(Array)
              ranges = diff_config
            end
          elsif context['diffs'] || context[:diffs]
            ranges = context['diffs'] || context[:diffs]
          elsif context['ranges'] || context[:ranges]
            ranges = context['ranges'] || context[:ranges]
          end

          if ranges
            sections['diffs'] = {
              title: "Diffs",
              ranges: ranges
            }
          end

          sections
        end

        # Merges two section data hashes
        def merge_section_data(existing, new_section)
          merged = deep_copy(existing)

          # Merge files arrays
          if has_files_content?(merged) || has_files_content?(new_section)
            merged['files'] = ((merged['files'] || []) + (new_section['files'] || [])).uniq
            merged.delete(:files) if merged.key?(:files) # Remove symbol key if string key exists
          end

          # Merge commands arrays
          if has_commands_content?(merged) || has_commands_content?(new_section)
            merged['commands'] = ((merged['commands'] || []) + (new_section['commands'] || [])).uniq
            merged.delete(:commands) if merged.key?(:commands) # Remove symbol key if string key exists
          end

          # Merge diffs/ranges arrays
          # Only set ranges/diffs when either side actually has values (not for _processed_diffs-only sections)
          # This prevents empty arrays from triggering downstream diff-handling paths
          merged_ranges = merged['ranges'] || merged[:ranges]
          new_ranges = new_section['ranges'] || new_section[:ranges]
          merged_diffs_arr = merged['diffs'] || merged[:diffs]
          new_diffs_arr = new_section['diffs'] || new_section[:diffs]

          if merged_ranges || new_ranges
            merged['ranges'] = ((merged_ranges || []) + (new_ranges || [])).uniq
            merged.delete(:ranges) if merged.key?(:ranges)
          end
          if merged_diffs_arr || new_diffs_arr
            merged['diffs'] = ((merged_diffs_arr || []) + (new_diffs_arr || [])).uniq
            merged.delete(:diffs) if merged.key?(:diffs)
          end

          # Also merge processed diffs (from PR fetches)
          # Deduplicate to prevent prompt size bloat when same PR/section is merged repeatedly
          merged_processed = merged[:_processed_diffs] || merged['_processed_diffs'] || []
          new_processed = new_section[:_processed_diffs] || new_section['_processed_diffs'] || []
          if merged_processed.any? || new_processed.any?
            merged[:_processed_diffs] = (merged_processed + new_processed).uniq
            merged.delete('_processed_diffs') if merged.key?('_processed_diffs')
          end

          # Merge content (concatenate)
          if has_content_content?(merged) || has_content_content?(new_section)
            existing_content = merged['content'] || merged[:content] || ''
            new_content = new_section['content'] || new_section[:content] || ''

            if !new_content.empty?
              if existing_content.empty?
                merged['content'] = new_content
              else
                merged['content'] = existing_content + "\n\n#{new_content}"
              end
            end
            merged.delete(:content) if merged.key?(:content) # Remove symbol key if string key exists
          end

          # Merge exclude patterns
          if merged['exclude'] || new_section['exclude']
            merged['exclude'] = ((merged['exclude'] || []) + (new_section['exclude'] || [])).uniq
          end

          # Override non-array fields with new values
          %w[title priority description template].each do |field|
            merged[field] = new_section[field] if new_section[field]
          end

          # Preserve content_type if present in either section
          if new_section['content_type']
            merged['content_type'] = new_section['content_type']
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

      # Custom exception for section validation errors
      class SectionValidationError < StandardError; end
    end
  end
end
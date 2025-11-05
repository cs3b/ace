# frozen_string_literal: true

require_relative '../atoms/section_validator'

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
        # @return [Hash] processed sections hash
        def process_sections(config)
          sections_config = extract_sections_config(config)
          return {} if sections_config.nil? || sections_config.empty?

          unless @validator.validate_sections(sections_config)
            raise SectionValidationError, "Section validation failed: #{@validator.errors.join(', ')}"
          end

          processed_sections = normalize_sections(sections_config)
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
            raise SectionValidationError, "Merged sections validation failed: #{@validator.errors.join(', ')}"
          end

          merged
        end

        # Gets sections sorted by priority
        # @param sections [Hash] sections hash
        # @return [Array] array of [name, section] pairs sorted by priority
        def sorted_sections(sections)
          sections.sort_by { |name, data| data['priority'] || data[:priority] || 999 }
        end

        # Filters sections by content type
        # @param sections [Hash] sections hash
        # @param content_type [String] content type to filter by
        # @return [Hash] filtered sections
        def filter_sections_by_type(sections, content_type)
          sections.select { |_, section|
            section['content_type'] == content_type || section[:content_type] == content_type
          }
        end

        # Gets section names for a content type
        # @param sections [Hash] sections hash
        # @param content_type [String] content type
        # @return [Array<String>] section names
        def get_section_names_by_type(sections, content_type)
          filter_sections_by_type(sections, content_type).keys
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

          # Set default priority if not specified
          normalized[:priority] ||= 999

          # Ensure title is set
          normalized[:title] ||= name.to_s.humanize if name

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

          # Legacy diffs/ranges
          if context['diffs'] || context[:diffs]
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
            content_type: "files",
            priority: 999,
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
              content_type: "files",
              priority: 100,
              files: context['files'] || context[:files]
            }
          end

          # Commands section
          if context['commands'] || context[:commands]
            sections['commands'] = {
              title: "Commands",
              content_type: "commands",
              priority: 200,
              commands: context['commands'] || context[:commands]
            }
          end

          # Diffs section
          if context['diffs'] || context[:diffs] || context['ranges'] || context[:ranges]
            sections['diffs'] = {
              title: "Diffs",
              content_type: "diffs",
              priority: 300,
              ranges: context['diffs'] || context[:diffs] || context['ranges'] || context[:ranges]
            }
          end

          sections
        end

        # Merges two section data hashes
        def merge_section_data(existing, new_section)
          merged = deep_copy(existing)

          # Merge arrays based on content type
          case merged['content_type'] || merged[:content_type]
          when 'files'
            merged['files'] = (merged['files'] || []) + (new_section['files'] || [])
            merged['files'].uniq!
          when 'commands'
            merged['commands'] = (merged['commands'] || []) + (new_section['commands'] || [])
            merged['commands'].uniq!
          when 'diffs'
            merged['ranges'] = (merged['ranges'] || []) + (new_section['ranges'] || [])
            merged['ranges'].uniq!
          when 'content'
            # For content sections, new content overwrites old
            merged['content'] = new_section['content'] if new_section['content']
          end

          # Override non-array fields with new values
          %w[title priority template].each do |field|
            merged[field] = new_section[field] if new_section[field]
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
      end

      # Custom exception for section validation errors
      class SectionValidationError < StandardError; end
    end
  end
end
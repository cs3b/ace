# frozen_string_literal: true

require 'pathname'
require 'yaml'

module Ace
  module Context
    module Molecules
      # Discovers context templates from filesystem and generates default presets
      class TemplateDiscoverer
        DEFAULT_TEMPLATE_PATHS = [
          'docs/context/*.md',
          '.ace/context/templates/*.md',
          '.coding-agent/templates/*.md'
        ].freeze

        DEFAULT_CACHE_DIR = 'docs/context/.cache'
        DEFAULT_FORMAT = 'markdown-xml'
        DEFAULT_CHUNK_LIMIT = 60_000

        def initialize(template_paths: nil, settings: {})
          @template_paths = template_paths || DEFAULT_TEMPLATE_PATHS
          @settings = settings
          @cache_dir = settings['cache_directory'] || DEFAULT_CACHE_DIR
          @default_chunk_limit = settings['default_chunk_limit'] || DEFAULT_CHUNK_LIMIT
        end

        # Discover all template files and generate presets
        # @return [Array<Hash>] Array of discovered preset configurations
        def discover_templates
          templates = []

          @template_paths.each do |pattern|
            Dir.glob(pattern).each do |path|
              next unless File.file?(path)

              preset = generate_preset_from_template(path)
              templates << preset if preset
            end
          end

          templates
        end

        # Generate a preset configuration from a template file
        # @param path [String] Path to template file
        # @return [Hash, nil] Preset configuration or nil if invalid
        def generate_preset_from_template(path)
          basename = File.basename(path, '.md')

          # Skip special files
          return nil if basename.start_with?('.')
          return nil if basename == 'README'

          # Extract frontmatter if present
          frontmatter = extract_frontmatter(path)

          # Build preset configuration
          preset = {
            name: basename,
            template: path,
            output: build_output_path(basename),
            format: frontmatter['format'] || DEFAULT_FORMAT,
            chunk_limit: frontmatter['chunk_limit'] || @default_chunk_limit,
            discovered: true  # Mark as discovered for priority handling
          }

          # Add description
          if frontmatter['description']
            preset[:description] = frontmatter['description']
          else
            preset[:description] = "#{basename.tr('_-', ' ').capitalize} context (auto-discovered)"
          end

          # Add any additional frontmatter fields
          %w[tags include exclude].each do |field|
            preset[field.to_sym] = frontmatter[field] if frontmatter[field]
          end

          preset
        end

        # Extract YAML frontmatter from a markdown file
        # @param path [String] Path to file
        # @return [Hash] Extracted frontmatter or empty hash
        def extract_frontmatter(path)
          content = File.read(path, encoding: 'UTF-8')

          # Check for YAML frontmatter
          if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
            frontmatter_text = $1
            begin
              frontmatter = YAML.safe_load(frontmatter_text) || {}
              return frontmatter.is_a?(Hash) ? frontmatter : {}
            rescue Psych::SyntaxError
              # Invalid YAML, ignore frontmatter
              return {}
            end
          end

          {}
        rescue => e
          # File read error, return empty frontmatter
          {}
        end

        # Check if a file is a valid context template
        # @param path [String] Path to check
        # @return [Boolean] True if valid template
        def valid_template?(path)
          return false unless File.exist?(path)
          return false unless path.end_with?('.md', '.markdown')

          content = File.read(path, encoding: 'UTF-8')

          # Check for context-tool-config marker
          return true if content.include?('<context-tool-config>')

          # Check for common template patterns
          return true if content.match?(/^files:\s*$/m)
          return true if content.match?(/^commands:\s*$/m)
          return true if content.match?(/^include:\s*$/m)

          # Check if it has valid frontmatter with context-related fields
          frontmatter = extract_frontmatter(path)
          return true if frontmatter['files'] || frontmatter['commands'] || frontmatter['include']

          false
        rescue
          false
        end

        private

        # Build output path for a preset
        # @param basename [String] Base name of the template
        # @return [String] Output path
        def build_output_path(basename)
          # Use .cache subdirectory for auto-discovered templates
          cache_dir = @cache_dir.sub('/cached', '/.cache')
          "#{cache_dir}/#{basename}.md"
        end
      end
    end
  end
end
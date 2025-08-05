# frozen_string_literal: true

require 'yaml'
require 'pathname'

module CodingAgentTools
  module Molecules
    class TreeConfigLoader
      DEFAULT_CONFIG = {
        'default_depth' => 3,
        'global_excludes' => ['.git', 'node_modules', 'coverage', 'tmp', '.DS_Store', '*.log'],
        'contexts' => {
          'default' => {
            'excludes' => [],
            'includes' => [],
            'max_depth' => 3
          }
        },
        'autocorrect' => {
          'enabled' => true,
          'similarity_threshold' => 0.6,
          'max_suggestions' => 5,
          'use_fzf' => true
        },
        'repositories' => {
          'scan_order' => ['.'],
          'specific_excludes' => {}
        }
      }.freeze

      def initialize(project_root = nil, config_path = nil)
        @project_root = project_root || detect_project_root
        @config_path = config_path || default_config_path
      end

      def load
        return DEFAULT_CONFIG unless config_exists?

        config = YAML.load_file(@config_path)
        validate_config!(config)
        merge_with_defaults(config)
      rescue Psych::SyntaxError => e
        raise Error, "Invalid YAML in tree configuration: #{e.message}"
      rescue => e
        raise Error, "Failed to load tree configuration: #{e.message}"
      end

      def config_exists?
        File.exist?(@config_path)
      end

      def default_config_path
        File.join(@project_root, '.coding-agent', 'tree.yml')
      end

      private

      def detect_project_root
        current_dir = Pathname.new(Dir.pwd)

        loop do
          return current_dir.to_s if project_root_marker_exists?(current_dir)

          parent = current_dir.parent
          break if parent == current_dir # reached filesystem root

          current_dir = parent
        end

        Dir.pwd # fallback to current directory
      end

      def project_root_marker_exists?(dir)
        markers = ['.coding-agent', '.git', 'CLAUDE.md', 'Gemfile']
        markers.any? { |marker| File.exist?(File.join(dir, marker)) }
      end

      def validate_config!(config)
        raise Error, 'Configuration must be a Hash' unless config.is_a?(Hash)

        raise Error, 'contexts must be a Hash' if config['contexts'] && !config['contexts'].is_a?(Hash)

        raise Error, 'autocorrect must be a Hash' if config['autocorrect'] && !config['autocorrect'].is_a?(Hash)

        return unless config['repositories'] && !config['repositories'].is_a?(Hash)

        raise Error, 'repositories must be a Hash'
      end

      def merge_with_defaults(config)
        merged = DEFAULT_CONFIG.dup

        # Deep merge contexts
        merged['contexts'] = DEFAULT_CONFIG['contexts'].merge(config['contexts']) if config['contexts']

        # Merge other sections
        ['default_depth', 'global_excludes', 'autocorrect', 'repositories'].each do |key|
          merged[key] = config[key] if config.key?(key)
        end

        merged
      end
    end
  end
end

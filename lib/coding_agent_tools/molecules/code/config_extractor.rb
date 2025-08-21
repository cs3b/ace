# frozen_string_literal: true

require "yaml"

module CodingAgentTools
  module Molecules
    module Code
      # Extracts YAML configuration from markdown files with front matter
      class ConfigExtractor
        # Extract YAML configuration from a markdown file
        # @param file_path [String] Path to the markdown file
        # @return [Hash, nil] The extracted configuration or nil if no YAML found
        def extract_from_file(file_path)
          return nil unless File.exist?(file_path)
          
          content = File.read(file_path)
          extract_from_content(content)
        end

        # Extract YAML configuration from markdown content
        # @param content [String] The markdown content with potential YAML front matter
        # @return [Hash, nil] The extracted configuration or nil if no YAML found
        def extract_from_content(content)
          return nil if content.nil? || content.empty?

          # Check for YAML front matter (between --- markers)
          if content.start_with?("---\n")
            yaml_match = content.match(/\A---\n(.*?)\n---\n/m)
            if yaml_match
              begin
                return YAML.safe_load(yaml_match[1])
              rescue YAML::SyntaxError => e
                raise "Invalid YAML in front matter: #{e.message}"
              end
            end
          end

          # Check for YAML code blocks in markdown
          yaml_blocks = extract_yaml_blocks(content)
          return merge_yaml_blocks(yaml_blocks) unless yaml_blocks.empty?

          nil
        end

        # Merge configuration from multiple sources
        # @param base_config [Hash] Base configuration
        # @param override_config [Hash] Override configuration
        # @return [Hash] Merged configuration
        def merge_configs(base_config, override_config)
          return override_config if base_config.nil?
          return base_config if override_config.nil?

          deep_merge(base_config, override_config)
        end

        private

        # Extract YAML blocks from markdown content
        def extract_yaml_blocks(content)
          blocks = []
          
          # Match ```yaml or ```yml code blocks
          content.scan(/```ya?ml\n(.*?)\n```/m) do |match|
            begin
              config = YAML.safe_load(match[0])
              blocks << config if config.is_a?(Hash)
            rescue YAML::SyntaxError
              # Skip invalid YAML blocks
            end
          end

          blocks
        end

        # Merge multiple YAML blocks into a single configuration
        def merge_yaml_blocks(blocks)
          return nil if blocks.empty?
          return blocks.first if blocks.size == 1

          # Merge all blocks together
          blocks.reduce({}) do |merged, block|
            deep_merge(merged, block)
          end
        end

        # Deep merge two hashes
        def deep_merge(hash1, hash2)
          hash1.merge(hash2) do |_key, old_val, new_val|
            if old_val.is_a?(Hash) && new_val.is_a?(Hash)
              deep_merge(old_val, new_val)
            elsif old_val.is_a?(Array) && new_val.is_a?(Array)
              old_val + new_val
            else
              new_val
            end
          end
        end
      end
    end
  end
end
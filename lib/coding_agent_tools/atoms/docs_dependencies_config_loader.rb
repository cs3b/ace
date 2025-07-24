# frozen_string_literal: true

require "yaml"

module CodingAgentTools::Atoms
  # Atom for loading docs-dependencies configuration
  # Handles configuration from .coding-agent/lint.yml
  class DocsDependenciesConfigLoader
    DEFAULT_CONFIG = {
      enabled: true,
      file_patterns: {
        workflows: "dev-handbook/workflow-instructions/**/*.wf.md",
        guides: "dev-handbook/guides/**/*.g.md",
        tasks: "dev-taskflow/**/tasks/*.md",
        docs: "docs/*.md",
        taskflow_docs: "dev-taskflow/*.md"
      },
      exclude_patterns: [
        "dev-taskflow/done/**/*",
        "dev-taskflow/sessions/**/*",
        "**/.*"
      ],
      skip_folders: [],
      include_external_links: false,
      include_anchor_links: false
    }.freeze

    def initialize(config_path = ".coding-agent/lint.yml")
      @config_path = config_path
    end

    # Load configuration with fallback to defaults
    def load_config
      return DEFAULT_CONFIG unless @config_path && File.exist?(@config_path)

      begin
        yaml_config = YAML.load_file(@config_path)
        docs_config = yaml_config&.dig("docs_dependencies") || {}
        
        # Merge with defaults, preserving structure
        merged_config = deep_merge(DEFAULT_CONFIG, symbolize_keys(docs_config))
        
        # Validate configuration
        validate_config(merged_config)
        
        merged_config
      rescue => e
        warn "Warning: Failed to load config from #{@config_path}: #{e.message}"
        warn "Using default configuration"
        DEFAULT_CONFIG
      end
    end

    # Get file patterns based on configuration
    def get_file_patterns(config = nil)
      config ||= load_config
      config[:file_patterns] || DEFAULT_CONFIG[:file_patterns]
    end

    # Get exclude patterns based on configuration
    def get_exclude_patterns(config = nil)
      config ||= load_config
      config[:exclude_patterns] || DEFAULT_CONFIG[:exclude_patterns]
    end

    # Get skip folders based on configuration
    def get_skip_folders(config = nil)
      config ||= load_config
      config[:skip_folders] || DEFAULT_CONFIG[:skip_folders]
    end

    # Check if external links should be included
    def include_external_links?(config = nil)
      config ||= load_config
      config[:include_external_links] || DEFAULT_CONFIG[:include_external_links]
    end

    # Check if anchor links should be included
    def include_anchor_links?(config = nil)
      config ||= load_config
      config[:include_anchor_links] || DEFAULT_CONFIG[:include_anchor_links]
    end

    # Check if docs-dependencies is enabled
    def enabled?(config = nil)
      config ||= load_config
      config[:enabled] != false  # Default to true unless explicitly disabled
    end

    private

    def deep_merge(base, override)
      result = base.dup
      
      override.each do |key, value|
        if value.is_a?(Hash) && result[key].is_a?(Hash)
          result[key] = deep_merge(result[key], value)
        else
          result[key] = value
        end
      end
      
      result
    end

    def symbolize_keys(hash)
      return hash unless hash.is_a?(Hash)
      
      hash.each_with_object({}) do |(key, value), result|
        symbol_key = key.to_sym
        result[symbol_key] = value.is_a?(Hash) ? symbolize_keys(value) : value
      end
    end

    def validate_config(config)
      # Basic validation
      unless config[:file_patterns].is_a?(Hash)
        raise "file_patterns must be a hash"
      end

      unless config[:exclude_patterns].is_a?(Array)
        raise "exclude_patterns must be an array"
      end

      unless config[:skip_folders].is_a?(Array)
        raise "skip_folders must be an array"
      end
    end
  end
end
# frozen_string_literal: true

require_relative 'lint/version'

# Load ace-core for config management
require 'ace/core'

# Models
require_relative 'lint/models/validation_error'
require_relative 'lint/models/lint_result'

# Atoms
require_relative 'lint/atoms/type_detector'
require_relative 'lint/atoms/kramdown_parser'
require_relative 'lint/atoms/yaml_parser'
require_relative 'lint/atoms/frontmatter_extractor'

# Molecules
require_relative 'lint/molecules/markdown_linter'
require_relative 'lint/molecules/yaml_linter'
require_relative 'lint/molecules/frontmatter_validator'
require_relative 'lint/molecules/kramdown_formatter'

# Organisms
require_relative 'lint/organisms/lint_orchestrator'
require_relative 'lint/organisms/result_reporter'

# Commands
require_relative 'lint/commands/lint_command'

# CLI
require_relative 'lint/cli'

module Ace
  module Lint
    class Error < StandardError; end

    # Check if debug mode is enabled
    # @return [Boolean] True if debug mode is enabled
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Load general ace-lint configuration using ace-core config cascade
    # Follows ADR-022: Configuration Default and Override Pattern
    # Priority: gem defaults < user config
    # @return [Hash] Configuration hash
    def self.config
      @config ||= begin
        require 'yaml'
        require 'ace/core/atoms/deep_merger'

        # Load gem defaults from .ace.example/lint/config.yml
        gem_defaults = load_gem_defaults

        # Load user config via ace-core cascade
        user_config = Ace::Core.config.get('ace', 'lint') || {}

        # Merge gem defaults with user config
        Ace::Core::Atoms::DeepMerger.merge(gem_defaults, user_config)
      rescue StandardError => e
        warn "Warning: Could not load ace-lint config: #{e.message}" if debug?
        load_gem_defaults || {}
      end
    end

    # Load gem defaults from .ace.example/lint/config.yml
    # Per ADR-022: gem MUST include .ace.example/ - missing file is a packaging error
    # @return [Hash] Default configuration from gem
    # @raise [Error] If default config file is missing (gem packaging error)
    def self.load_gem_defaults
      gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace.example", "lint", "config.yml")

      unless File.exist?(defaults_path)
        raise Error, "Default config not found: #{defaults_path}. " \
              "This is a gem packaging error - .ace.example/ must be included in the gem."
      end

      YAML.safe_load_file(defaults_path, permitted_classes: [], aliases: true) || {}
    end
    private_class_method :load_gem_defaults

    # Load kramdown-specific configuration
    # Follows ADR-022: Configuration Default and Override Pattern
    # Config location: .ace/lint/kramdown.yml
    # @return [Hash] Kramdown configuration
    def self.kramdown_config
      @kramdown_config ||= begin
        require 'yaml'
        require 'ace/core/atoms/deep_merger'

        # Load gem defaults from .ace.example/lint/kramdown.yml
        gem_defaults = load_kramdown_gem_defaults

        # Load user config via ace-core cascade
        base_config = Ace::Core.config
        user_config = base_config.get('ace', 'lint', 'kramdown') || {}

        # Merge gem defaults with user config
        Ace::Core::Atoms::DeepMerger.merge(gem_defaults, user_config)
      rescue StandardError => e
        warn "Warning: Could not load kramdown config: #{e.message}"
        load_kramdown_gem_defaults || {}
      end
    end

    # Load gem defaults from .ace.example/lint/kramdown.yml
    # Per ADR-022: gem MUST include .ace.example/ - missing file is a packaging error
    # @return [Hash] Default kramdown configuration from gem
    # @raise [Error] If default config file is missing (gem packaging error)
    def self.load_kramdown_gem_defaults
      gem_root = Gem.loaded_specs["ace-lint"]&.gem_dir ||
                 File.expand_path("../..", __dir__)
      defaults_path = File.join(gem_root, ".ace.example", "lint", "kramdown.yml")

      unless File.exist?(defaults_path)
        raise Error, "Default config not found: #{defaults_path}. " \
              "This is a gem packaging error - .ace.example/ must be included in the gem."
      end

      YAML.safe_load_file(defaults_path, permitted_classes: [], aliases: true) || {}
    end
    private_class_method :load_kramdown_gem_defaults

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config = nil
      @kramdown_config = nil
    end
  end
end

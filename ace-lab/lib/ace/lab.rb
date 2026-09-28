# frozen_string_literal: true

require_relative "lab/version"
require "ace/support/config"

module Ace
  module Lab
    class Error < StandardError; end

    # Raised when topology configuration violates the schema contract
    class InvalidConfigurationError < Error; end
  end
end

# Load all ace-lab components
require_relative "lab/atoms/topology_schema"
require_relative "lab/atoms/binding_freshness"
require_relative "lab/atoms/public_projection"
require_relative "lab/models/runtime_binding"
require_relative "lab/models/topology_entry"
require_relative "lab/models/query_result"
require_relative "lab/molecules/topology_loader"
require_relative "lab/molecules/caller_authorizer"
require_relative "lab/molecules/inventory_query"
require_relative "lab/molecules/exact_resolver"
require_relative "lab/molecules/capability_router"
require_relative "lab/organisms/topology_service"
require_relative "lab/cli"

module Ace
  module Lab
    # Returns the gem root directory
    # @return [String] Path to the gem root directory
    def self.gem_root
      @gem_root ||= Gem.loaded_specs["ace-lab"]&.gem_dir ||
        File.expand_path("../..", __dir__)
    end

    # Check if debug mode is enabled
    # @return [Boolean]
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Load ace-lab configuration using the ADR-022 cascade.
    # Deployed topology lives in .ace/lab/config.yml (project) or
    # ~/.ace/lab/config.yml (user); gem defaults are an empty, safe topology.
    # Thread-safe: uses mutex for initialization
    # @return [Hash] Merged configuration hash with defaults
    def self.config
      return @config if defined?(@config) && @config

      @config_mutex.synchronize do
        @config ||= load_config
      end
    end

    # Reset config cache (useful for testing)
    def self.reset_config!
      @config_mutex.synchronize do
        @config = nil
      end
    end

    @config_mutex = Mutex.new

    # Load configuration using Ace::Support::Config cascade.
    # Load failures raise InvalidConfigurationError (classified by the query
    # boundary) — silently falling back to empty defaults would misreport
    # broken deployed configuration as an authorization denial (review R4).
    # @return [Hash] Merged configuration
    # @raise [Ace::Lab::InvalidConfigurationError]
    def self.load_config
      resolver = Ace::Support::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      resolver.resolve_namespace("lab").data
    rescue Ace::Lab::InvalidConfigurationError
      raise
    rescue => e
      raise InvalidConfigurationError, "invalid lab configuration: #{e.class}: #{e.message}"
    end
    private_class_method :load_config
  end
end

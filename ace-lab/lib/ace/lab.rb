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
require_relative "lab/molecules/grant_resolver"
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

    # Same discovery the cascade resolver performs for this namespace
    LAB_FILE_PATTERNS = ["lab/config.yml", "lab/config.yaml"].freeze

    # Authorization grants live in a trusted, deployment-controlled file —
    # never in the caller-writable configuration cascade (review round 4, F3)
    AUTHORIZATION_ENV = "ACE_LAB_AUTHORIZATION_FILE"
    DEFAULT_AUTHORIZATION_PATH = "/etc/lab/ace-lab/authorization.yml"

    # Path of the trusted authorization grants document
    # @return [String]
    def self.authorization_path
      ENV[AUTHORIZATION_ENV] || DEFAULT_AUTHORIZATION_PATH
    end

    # Load configuration using Ace::Support::Config cascade.
    # Load failures raise InvalidConfigurationError (classified by the query
    # boundary) — silently falling back to empty defaults would misreport
    # broken deployed configuration as an authorization denial (review R4).
    # @return [Hash] Merged configuration
    # @raise [Ace::Lab::InvalidConfigurationError]
    def self.load_config
      cascade_documents

      resolver = Ace::Support::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      resolver.resolve_namespace("lab").data
    rescue Ace::Lab::InvalidConfigurationError
      raise
    rescue => e
      # Fixed diagnostic only: the underlying exception message may quote
      # configuration content, which must never surface pre-authorization
      # (review round 3, F2)
      raise InvalidConfigurationError, "invalid lab configuration: could not load deployed configuration (#{e.class})"
    end
    private_class_method :load_config

    # The individual cascade documents for this namespace, same discovery the
    # resolver performs, each validated before use. Cascade merging treats a
    # non-mapping document as an empty overlay, so a malformed root (e.g. a
    # YAML array) would be silently ignored (review round 3, F1). Messages
    # carry the file path — never parsed content.
    #
    # Exposed because authorization grants need per-tier documents: a
    # caller-writable tier must never be able to EXPAND grants (review
    # round 4, F3), which the merged view cannot express.
    #
    # @return [Array<Hash>] {path:, document:, defaults:}
    def self.cascade_documents
      finder = Ace::Support::Config::Molecules::ConfigFinder.new(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root,
        file_patterns: LAB_FILE_PATTERNS
      )

      finder.find_all.select(&:exists).map do |cascade_path|
        path = cascade_path.path
        document = begin
          require "yaml"
          YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
        rescue
          raise InvalidConfigurationError, "invalid lab configuration: #{path} could not be parsed as YAML"
        end
        unless document.nil? || document.is_a?(Hash)
          raise InvalidConfigurationError, "invalid lab configuration: #{path} must contain a YAML mapping"
        end

        {path: path, document: document || {}, defaults: path.start_with?(gem_root)}
      end
    end
  end
end

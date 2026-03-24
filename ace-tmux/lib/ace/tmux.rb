# frozen_string_literal: true

require_relative "tmux/version"
require "ace/support/config"

# Define error hierarchy before loading components (they reference these classes)
module Ace
  module Tmux
    class Error < StandardError; end

    # Raised when a preset is not found
    class PresetNotFoundError < Error; end

    # Raised when not running inside tmux
    class NotInTmuxError < Error; end
  end
end

# Load all ace-tmux components
require_relative "tmux/models/pane"
require_relative "tmux/models/layout_node"
require_relative "tmux/models/window"
require_relative "tmux/models/session"
require_relative "tmux/atoms/tmux_command_builder"
require_relative "tmux/atoms/layout_string_builder"
require_relative "tmux/atoms/preset_resolver"
require_relative "tmux/molecules/config_loader"
require_relative "tmux/molecules/preset_loader"
require_relative "tmux/molecules/tmux_executor"
require_relative "tmux/molecules/session_builder"
require_relative "tmux/organisms/session_manager"
require_relative "tmux/organisms/window_manager"
require_relative "tmux/cli"

module Ace
  module Tmux
    # Initialize mutex for thread-safe config access
    @config_mutex = Mutex.new

    # Returns the gem root directory
    # @return [String] Path to the gem root directory
    def self.gem_root
      @gem_root ||= Gem.loaded_specs["ace-tmux"]&.gem_dir ||
        File.expand_path("../..", __dir__)
    end

    # Check if debug mode is enabled
    # @return [Boolean]
    def self.debug?
      ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
    end

    # Load ace-tmux configuration using ace-config cascade
    # Thread-safe: uses mutex for initialization
    # @return [Hash] Configuration hash with defaults merged
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

    # Load configuration using Ace::Support::Config cascade
    # @return [Hash] Merged configuration
    def self.load_config
      resolver = Ace::Support::Config.create(
        config_dir: ".ace",
        defaults_dir: ".ace-defaults",
        gem_path: gem_root
      )

      config = resolver.resolve_namespace("tmux")
      config.data
    rescue => e
      warn "ace-tmux: Could not load config: #{e.class} - #{e.message}" if debug?
      load_gem_defaults_fallback
    end
    private_class_method :load_config

    # Load gem defaults directly as fallback
    # @return [Hash] Defaults hash or empty hash
    def self.load_gem_defaults_fallback
      defaults_path = File.join(gem_root, ".ace-defaults", "tmux", "config.yml")
      return {} unless File.exist?(defaults_path)

      require "yaml"
      YAML.safe_load_file(defaults_path, permitted_classes: [Date], aliases: true) || {}
    rescue
      {}
    end
    private_class_method :load_gem_defaults_fallback
  end
end

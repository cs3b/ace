# frozen_string_literal: true

module Ace
  # Core functionality for ACE gems
  module Core
    # Atomic operations - pure functions with no side effects
    # Atoms are the building blocks for more complex operations.
    # See ADR-011 for ATOM architecture details.
    module Atoms
      # ConfigSummary displays effective configuration state to stderr.
      #
      # Only shows values that differ from defaults, filtering sensitive keys.
      # Output format: "Config: key=value key2=value2" (space-separated)
      #
      # ## Sensitive Key Filtering
      #
      # Keys ending with sensitive patterns are filtered out:
      # - token, password, secret, credential, key, api_key
      #
      # Keys containing these patterns but NOT ending with them are shown:
      # - max_tokens (contains "tokens" but doesn't end with it) ✓ shown
      # - keyboard_layout (contains "key" but doesn't end with it) ✓ shown
      # - auth_token (ends with "token") ✗ filtered
      # - api_key (ends with "key") ✗ filtered
      #
      # ## Usage
      #
      #   ConfigSummary.display(
      #     command: "review",
      #     config: Gem.config,            # Effective config
      #     defaults: Gem.default_config,   # Defaults for diffing
      #     options: { verbose: true },     # Thor options hash
      #     quiet: false,
      #     summary_keys: %w[model preset] # Optional allowlist
      #   )
      #   # Output to stderr: "Config: model=gflash preset=pr"
      #
      class ConfigSummary
        # Match keys ENDING with sensitive words (not containing them)
        SENSITIVE_REGEX = /(_|^)(token|password|secret|credential|key|api_key)$/i

        # Display configuration summary to stderr
        #
        # @param command [String] Command name for context
        # @param config [Hash] Effective configuration (merged result)
        # @param defaults [Hash] Default configuration to diff against
        # @param options [Hash] CLI options (Thor options hash)
        # @param quiet [Boolean] Suppress output if true
        # @param summary_keys [Array<String>, nil] Allowlist of keys to include (nil = all non-sensitive)
        # @return [nil]
        #
        # @example Basic usage
        #   ConfigSummary.display(
        #     command: "review",
        #     config: { model: "gflash", format: "markdown" },
        #     defaults: { "model" => "glite", "format" => "markdown" },
        #     options: { verbose: true }
        #   )
        #   # Outputs: "Config: model=gflash verbose=true"
        #
        # @example With quiet mode
        #   ConfigSummary.display(
        #     command: "review",
        #     config: { model: "gflash" },
        #     defaults: {},
        #     options: {},
        #     quiet: true
        #   )
        #   # No output
        #
        # @example With allowlist
        #   ConfigSummary.display(
        #     command: "review",
        #     config: { model: "gflash", format: "markdown" },
        #     defaults: {},
        #     options: { verbose: true },
        #     summary_keys: %w[model]
        #   )
        #   # Outputs: "Config: model=gflash"
        #   # (format and verbose not in allowlist)
        #
        def self.display(command:, config: {}, defaults: {}, options: {}, quiet: false, summary_keys: nil)
          return if quiet

          # Only display config when verbose mode is explicitly enabled
          return unless options[:verbose]

          summary = new(command, config, defaults, options, summary_keys).build
          warn "Config: #{summary}" unless summary.empty?
        end

        # Display configuration summary only if help was NOT requested.
        #
        # This is the recommended method for commands that need to show config
        # but want to avoid polluting --help output with configuration details.
        #
        # @param command [String] Command name for context
        # @param config [Hash] Effective configuration (merged result)
        # @param defaults [Hash] Default configuration to diff against
        # @param options [Hash] CLI options (Thor options hash)
        # @param quiet [Boolean] Suppress output if true
        # @param summary_keys [Array<String>, nil] Allowlist of keys to include (nil = all non-sensitive)
        # @return [nil]
        #
        # @example Usage in command
        #   def execute
        #     # Check for help BEFORE displaying config
        #     return show_help if help_requested?(options, args)
        #
        #     # Now safe to display config
        #     ConfigSummary.display_if_needed(
        #       command: "review",
        #       config: Gem.config,
        #       defaults: Gem.default_config,
        #       options: options
        #     )
        #   end
        #
        def self.display_if_needed(command:, config: {}, defaults: {}, options: {}, quiet: false, summary_keys: nil, args: ARGV)
          return if quiet
          return if help_requested?(options, args)

          display(command: command, config: config, defaults: defaults, options: options, summary_keys: summary_keys)
        end

        # Check if help was requested via options or arguments.
        #
        # @param options [Hash] CLI options hash (from Thor)
        # @param args [Array<String>] Command arguments (defaults to ARGV for CLI context)
        # @return [Boolean] true if help was requested
        #
        # @note The `args` parameter defaults to ARGV for CLI usage convenience.
        #       In test or non-CLI contexts, pass an explicit array to avoid global state.
        #
        def self.help_requested?(options = {}, args = ARGV)
          options[:help] ||
            options[:h] ||
            args.include?("--help") ||
            args.include?("-h")
        end

        def initialize(command, config, defaults, options, summary_keys)
          @command = command
          @config = flatten_hash(config || {})
          @defaults = flatten_hash(defaults || {})
          @options = options || {}
          @summary_keys = summary_keys&.map(&:to_s)
        end

        # Build the configuration summary string
        #
        # @return [String] Space-separated key=value pairs
        def build
          pairs = []

          # 1. Add CLI options that were explicitly set (non-nil, non-false)
          @options.each do |key, value|
            next if value.nil? || value == false
            next if sensitive_key?(key.to_s)
            next if @summary_keys && !@summary_keys.include?(key.to_s)
            pairs << format_pair(key, value)
          end

          # 2. Add config values that differ from defaults (if not already in options)
          @config.each do |key, value|
            # Skip if already shown from options (check both symbol and string)
            next if @options.key?(key.to_sym) || @options.key?(key.to_s)
            next if @defaults[key] == value
            next if sensitive_key?(key)
            next if @summary_keys && !@summary_keys.include?(key)
            pairs << format_pair(key, value)
          end

          pairs.sort.join(" ")
        end

        private

        # Flatten nested hash to dot notation
        # { llm: { provider: "google" } } → { "llm.provider" => "google" }
        #
        # @param hash [Hash] Hash to flatten
        # @param prefix [String, nil] Current key prefix
        # @return [Hash] Flattened hash with dot-notation keys
        def flatten_hash(hash, prefix = nil)
          hash.each_with_object({}) do |(key, value), result|
            full_key = prefix ? "#{prefix}.#{key}" : key.to_s
            if value.is_a?(Hash)
              result.merge!(flatten_hash(value, full_key))
            else
              result[full_key] = value
            end
          end
        end

        # Format a key-value pair for output
        #
        # @param key [String, Symbol] Key
        # @param value [Object] Value
        # @return [String] Formatted "key=value" string
        def format_pair(key, value)
          value_str = case value
          when true then "true"
          when Array then value.join(",")
          else value.to_s
          end
          "#{key}=#{value_str}"
        end

        # Check if a key is sensitive (should be filtered)
        #
        # @param key [String, Symbol] Key to check
        # @return [Boolean] true if key is sensitive
        def sensitive_key?(key)
          key.to_s.match?(SENSITIVE_REGEX)
        end
      end
    end
  end
end

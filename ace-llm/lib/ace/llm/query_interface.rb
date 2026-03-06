# frozen_string_literal: true

require_relative "molecules/client_registry"
require_relative "molecules/provider_model_parser"
require_relative "molecules/format_handlers"
require_relative "molecules/file_io_handler"
require_relative "molecules/fallback_orchestrator"
require_relative "models/fallback_config"

module Ace
  module LLM
    # QueryInterface provides a simple Ruby API with named parameters matching the CLI
    # This allows direct Ruby calls to LLM providers without subprocess overhead
    class QueryInterface
      # Query an LLM provider with named parameters matching CLI flags exactly
      #
      # @param provider_model [String] Provider:model or alias (e.g., "glite", "google:gemini-2.0-flash-lite")
      # @param prompt [String] The user prompt to send to the LLM
      # @param output [String, nil] Optional file path to write output (--output FILE)
      # @param format [String] Output format: "text", "json", "yaml", "raw" (--format FORMAT)
      # @param temperature [Float, nil] Optional temperature for generation (--temperature FLOAT)
      # @param max_tokens [Integer, nil] Optional maximum tokens (--max-tokens INT)
      # @param system [String, nil] Optional system prompt (--system TEXT)
      # @param timeout [Integer] Request timeout in seconds (--timeout SECONDS)
      # @param force [Boolean] Force overwrite output file (--force)
      # @param debug [Boolean] Enable debug output (--debug)
      # @param model [String, nil] Model name (overrides PROVIDER[:MODEL] if both present) (--model MODEL)
      # @param prompt_override [String, nil] Prompt text (overrides positional prompt if both present) (--prompt PROMPT)
      # @param fallback [Boolean, nil] Enable/disable fallback (nil = auto from env/config)
      # @param fallback_providers [Array<String>, nil] Custom fallback provider list
      # @param system_file [String, nil] Path to system prompt file (for file-based providers)
      # @param prompt_file [String, nil] Path to user prompt file (for file-based providers)
      # @param cli_args [String, Array<String>, nil] Extra args for CLI providers (auto-prefixed with --)
      # @param system_append [String, nil] Additional system content appended by compatible providers
      # @param preset [String, nil] Optional execution preset name (--preset or model@preset)
      #
      # @return [Hash] Response with :text, :model, :provider, and other metadata
      # @raise [Error] If provider/model invalid or request fails
      def self.query(provider_model, prompt = nil,
                    output: nil,
                    format: "text",
                    temperature: nil,
                    max_tokens: nil,
                    system: nil,
                    timeout: nil,
                    force: false,
                    debug: false,
                    model: nil,
                    prompt_override: nil,
                    fallback: nil,
                    fallback_providers: nil,
                    system_file: nil,
                    prompt_file: nil,
                    cli_args: nil,
                    system_append: nil,
                    preset: nil,
                    sandbox: nil,
                    subprocess_env: nil,
                    last_message_file: nil)

        # Initialize registry and parser
        registry = Molecules::ClientRegistry.new
        parser = Molecules::ProviderModelParser.new(registry: registry)

        # Parse model/alias
        parse_result = parser.parse(provider_model)
        raise Error, parse_result.error unless parse_result.valid?
        resolved_preset = resolve_preset_name(parse_result.preset, preset)
        preset_options = resolved_preset ? Ace::LLM.preset_for_provider(resolved_preset, parse_result.provider) : {}

        # Resolve final model: model parameter > positional :MODEL > provider default
        final_model = model || parse_result.model

        # Validate that we have a model from some source
        if final_model.nil? || final_model.empty?
          raise Error, "No model specified and no default available for #{parse_result.provider}"
        end

        # Resolve final prompt: prompt_override parameter > positional prompt
        final_prompt = prompt_override || prompt

        # Validate that we have a prompt from some source
        if final_prompt.nil? || final_prompt.empty?
          raise Error, "No prompt specified. Use positional prompt or prompt_override: parameter"
        end

        # Build messages array
        messages = []
        messages << { role: "system", content: system } if system && !system.empty?
        messages << { role: "user", content: final_prompt }

        # Build generation options
        generation_opts = {}
        resolved_temperature = first_non_nil(temperature, preset_options["temperature"])
        resolved_max_tokens = first_non_nil(max_tokens, preset_options["max_tokens"])
        resolved_cli_args = first_non_nil(cli_args, preset_options["cli_args"])
        resolved_system_append = first_non_empty(system_append, preset_options["system_append"])
        resolved_subprocess_env = first_non_nil(subprocess_env, preset_options["subprocess_env"])

        generation_opts[:temperature] = resolved_temperature unless resolved_temperature.nil?
        generation_opts[:max_tokens] = resolved_max_tokens unless resolved_max_tokens.nil?
        generation_opts[:system_file] = system_file if system_file
        generation_opts[:prompt_file] = prompt_file if prompt_file
        generation_opts[:cli_args] = resolved_cli_args unless blank_value?(resolved_cli_args)
        generation_opts[:system_append] = resolved_system_append unless blank_value?(resolved_system_append)
        generation_opts[:sandbox] = sandbox if sandbox
        generation_opts[:subprocess_env] = resolved_subprocess_env unless resolved_subprocess_env.nil?
        generation_opts[:last_message_file] = last_message_file if last_message_file

        # Debug output if requested
        if debug
          $stderr.puts "Provider: #{parse_result.provider}"
          $stderr.puts "Model: #{final_model}"
          $stderr.puts "Preset: #{resolved_preset}" if resolved_preset
          $stderr.puts "Temperature: #{resolved_temperature}" unless resolved_temperature.nil?
          $stderr.puts "Max tokens: #{resolved_max_tokens}" unless resolved_max_tokens.nil?
        end

        # Load fallback configuration
        fallback_config = load_fallback_config(fallback, fallback_providers, parser: parser)

        # Execute with or without fallback
        # Resolve timeout from explicit args > preset > config cascade
        timeout_value = first_non_nil(timeout, preset_options["timeout"], Molecules::ConfigLoader.get("llm.timeout"), 120)
        resolved_timeout = normalize_timeout(timeout_value)

        response = execute_with_fallback(
          provider: parse_result.provider,
          model: final_model,
          messages: messages,
          generation_opts: generation_opts,
          registry: registry,
          fallback_config: fallback_config,
          timeout: resolved_timeout,
          debug: debug
        )

        # Extract text content based on response structure
        text_content = extract_text_content(response)

        # Build result hash
        result = {
          text: text_content,
          model: final_model,
          provider: parse_result.provider,
          preset: resolved_preset,
          usage: response[:usage],
          metadata: response[:metadata]
        }

        # Handle output option if provided
        if output && !output.empty?
          handler = Molecules::FormatHandlers.get_handler(format)

          # Format the content based on requested format
          formatted_content = case format
          when "json"
            handler.format(result)
          when "yaml"
            handler.format(result)
          when "raw"
            handler.format(response)
          else # "text" or default
            text_content
          end

          # Write to file
          file_handler = Molecules::FileIoHandler.new
          file_handler.write_content(formatted_content, output, format: format, force: force)

          $stderr.puts "Output written to: #{output}" if debug
        end

        result
      end

      private

      def self.resolve_preset_name(suffix_preset, explicit_preset)
        suffix = suffix_preset&.to_s&.strip
        explicit = explicit_preset&.to_s&.strip

        suffix = nil if suffix&.empty?
        explicit = nil if explicit&.empty?

        if suffix && explicit
          raise Error, "Preset specified twice: use either model@preset or --preset, not both"
        end

        suffix || explicit
      end
      private_class_method :resolve_preset_name

      def self.first_non_nil(*values)
        values.each { |value| return value unless value.nil? }
        nil
      end
      private_class_method :first_non_nil

      def self.first_non_empty(*values)
        values.each do |value|
          next if blank_value?(value)

          return value
        end
        nil
      end
      private_class_method :first_non_empty

      def self.blank_value?(value)
        return true if value.nil?
        return true if value.respond_to?(:empty?) && value.empty?

        false
      end
      private_class_method :blank_value?

      # Load fallback configuration from parameters and environment
      # @param fallback [Boolean, nil] Explicit fallback enable/disable
      # @param fallback_providers [Array<String>, nil] Custom provider list
      # @param parser [Molecules::ProviderModelParser, nil] Parser for alias/provider normalization
      # @return [Models::FallbackConfig] Fallback configuration
      def self.load_fallback_config(fallback, fallback_providers, parser: nil)
        parser ||= Molecules::ProviderModelParser.new

        # Normalize at each merge layer to prevent FallbackConfig#validate_providers!
        # from rejecting duplicates during intermediate merges (e.g., config + env both
        # specifying the same provider). Final normalization deduplicates the merged result.

        # Baseline from config cascade (project/user/defaults)
        config_fallback = Molecules::ConfigLoader.get("llm.fallback")
        normalized_config_fallback = normalize_fallback_provider_hash(config_fallback, parser)
        config = Models::FallbackConfig.from_hash(normalized_config_fallback)

        # Keep legacy env overrides for backward compatibility
        env_overrides = load_fallback_env_overrides
        env_overrides = normalize_fallback_provider_hash(env_overrides, parser)
        config = config.merge(env_overrides) unless env_overrides.empty?

        # Explicit call-site values always win
        explicit_overrides = {}
        explicit_overrides[:enabled] = fallback unless fallback.nil?
        explicit_overrides[:providers] = fallback_providers if fallback_providers
        explicit_overrides = normalize_fallback_provider_hash(explicit_overrides, parser)
        config = config.merge(explicit_overrides) unless explicit_overrides.empty?

        normalized_chains = config.chains.transform_values do |chain|
          normalize_fallback_providers(chain, parser)
        end

        config.merge(
          providers: normalize_fallback_providers(config.providers, parser),
          chains: normalized_chains
        )
      end

      # Execute query with fallback support
      # @param provider [String] Provider name
      # @param model [String] Model name
      # @param messages [Array<Hash>] Messages array
      # @param generation_opts [Hash] Generation options
      # @param registry [Molecules::ClientRegistry] Client registry
      # @param fallback_config [Models::FallbackConfig] Fallback configuration
      # @param timeout [Integer] Request timeout
      # @param debug [Boolean] Debug mode
      # @return [Hash] Response from provider
      def self.execute_with_fallback(provider:, model:, messages:, generation_opts:,
                                     registry:, fallback_config:, timeout:, debug:)
        # If fallback is disabled, execute directly
        if fallback_config.disabled?
          client = registry.get_client(provider, model: model, timeout: timeout)
          return client.generate(messages, **generation_opts)
        end

        # Create status callback for user feedback
        status_callback = ->(msg) { $stderr.puts msg }

        # Create orchestrator
        orchestrator = Molecules::FallbackOrchestrator.new(
          config: fallback_config,
          status_callback: status_callback,
          timeout: timeout
        )

        # Build provider string with model if specified
        primary_provider_string = model ? "#{provider}:#{model}" : provider

        # Execute with fallback
        orchestrator.execute(primary_provider: primary_provider_string, registry: registry) do |client|
          client.generate(messages, **generation_opts)
        end
      end

      # Extract text content from various response formats
      # @param response [Hash] The response from the LLM client
      # @return [String] The extracted text content
      def self.extract_text_content(response)
        # Handle different response structures
        if response[:text]
          # Direct text field
          response[:text]
        elsif response[:content]
          # Content field (some providers)
          response[:content]
        elsif response[:choices] && response[:choices].is_a?(Array) && !response[:choices].empty?
          # OpenAI-style response
          choice = response[:choices].first
          if choice[:message] && choice[:message][:content]
            choice[:message][:content]
          elsif choice[:text]
            choice[:text]
          else
            ""
          end
        elsif response[:candidates] && response[:candidates].is_a?(Array) && !response[:candidates].empty?
          # Google-style response
          candidate = response[:candidates].first
          if candidate[:content] && candidate[:content][:parts] && !candidate[:content][:parts].empty?
            candidate[:content][:parts].first[:text] || ""
          else
            ""
          end
        else
          # Fallback to string representation if structure unknown
          response.to_s
        end
      end

      # Load fallback-related environment variables as overrides.
      # Keeps compatibility with the previous fallback configuration contract.
      def self.load_fallback_env_overrides
        overrides = {}

        env_enabled = ENV["ACE_LLM_FALLBACK_ENABLED"]
        overrides[:enabled] = parse_env_boolean(env_enabled) unless env_enabled.nil?

        env_providers = ENV["ACE_LLM_FALLBACK_PROVIDERS"]
        if env_providers && !env_providers.strip.empty?
          overrides[:providers] = env_providers.split(",").map(&:strip)
        end

        retry_count = parse_env_integer(ENV["ACE_LLM_FALLBACK_RETRY_COUNT"])
        overrides[:retry_count] = retry_count unless retry_count.nil?

        retry_delay = parse_env_float(ENV["ACE_LLM_FALLBACK_RETRY_DELAY"])
        overrides[:retry_delay] = retry_delay unless retry_delay.nil?

        max_timeout = ENV["ACE_LLM_FALLBACK_MAX_TOTAL_TIMEOUT"] || ENV["ACE_LLM_FALLBACK_MAX_TIMEOUT"]
        parsed_max_timeout = parse_env_float(max_timeout)
        overrides[:max_total_timeout] = parsed_max_timeout unless parsed_max_timeout.nil?

        overrides
      end
      private_class_method :load_fallback_env_overrides

      def self.normalize_fallback_providers(providers, parser)
        seen = {}
        normalized = []

        Array(providers).each do |raw_provider|
          provider = raw_provider.to_s.strip
          next if provider.empty?

          parse_result = parser.parse(provider)
          canonical_provider = if parse_result.valid?
                                 "#{parse_result.provider}:#{parse_result.model}"
                               else
                                 provider
                               end

          next if seen[canonical_provider]

          seen[canonical_provider] = true
          normalized << canonical_provider
        end

        normalized
      end
      private_class_method :normalize_fallback_providers

      def self.normalize_fallback_provider_hash(hash, parser)
        return {} unless hash

        normalized = hash.dup
        providers = normalized[:providers] || normalized["providers"]
        if providers
          normalized_providers = normalize_fallback_providers(providers, parser)
          normalized[:providers] = normalized_providers
          normalized["providers"] = normalized_providers if normalized.key?("providers")
        end

        chains = normalized[:chains] || normalized["chains"]
        if chains.is_a?(Hash)
          normalized_chains = chains.transform_values do |chain|
            normalize_fallback_providers(Array(chain), parser)
          end
          normalized[:chains] = normalized_chains
          normalized["chains"] = normalized_chains if normalized.key?("chains")
        end

        normalized
      end
      private_class_method :normalize_fallback_provider_hash

      def self.parse_env_boolean(value)
        return true if value.to_s.strip.downcase == "true"
        return false if value.to_s.strip.downcase == "false"

        nil
      end
      private_class_method :parse_env_boolean

      def self.parse_env_integer(value)
        return nil if value.nil? || value.strip.empty?

        Integer(value)
      rescue ArgumentError
        nil
      end
      private_class_method :parse_env_integer

      def self.parse_env_float(value)
        return nil if value.nil? || value.strip.empty?

        Float(value)
      rescue ArgumentError
        nil
      end
      private_class_method :parse_env_float

      def self.normalize_timeout(value)
        return nil if value.nil?
        return value if value.is_a?(Numeric) && value.finite?

        normalized = value.to_s.strip
        normalized_timeout = Float(normalized)
        raise ArgumentError, "timeout must be positive" unless normalized_timeout.positive?

        normalized_timeout
      rescue ArgumentError, TypeError
        raise ArgumentError, "timeout must be a positive numeric value, got #{value.inspect}"
      end
      private_class_method :normalize_timeout
    end
  end
end

# frozen_string_literal: true

require_relative "molecules/client_registry"
require_relative "molecules/provider_model_parser"
require_relative "molecules/preset_loader"
require_relative "molecules/thinking_level_loader"
require_relative "molecules/format_handlers"
require_relative "molecules/file_io_handler"
require_relative "molecules/fallback_orchestrator"
require_relative "models/fallback_config"

module Ace
  module LLM
    # QueryInterface provides a simple Ruby API with named parameters matching the CLI
    # This allows direct Ruby calls to LLM providers without subprocess overhead.
    class QueryInterface
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
        working_dir: nil,
        subprocess_env: nil,
        last_message_file: nil)
        registry = Molecules::ClientRegistry.new
        parser = Molecules::ProviderModelParser.new(registry: registry)

        parse_result = parser.parse(provider_model)
        raise Error, parse_result.error unless parse_result.valid?

        resolved_preset = resolve_preset_name(parse_result.preset, preset)
        execution_overrides = load_execution_overrides(
          provider: parse_result.provider,
          preset: resolved_preset,
          thinking_level: parse_result.thinking_level
        )

        final_model = model || parse_result.model
        if final_model.nil? || final_model.empty?
          raise Error, "No model specified and no default available for #{parse_result.provider}"
        end

        final_prompt = prompt_override || prompt
        if final_prompt.nil? || final_prompt.empty?
          raise Error, "No prompt specified. Use positional prompt or prompt_override: parameter"
        end

        messages = []
        messages << {role: "system", content: system} if system && !system.empty?
        messages << {role: "user", content: final_prompt}

        generation_opts = {}
        resolved_temperature = first_non_nil(temperature, execution_overrides["temperature"])
        resolved_max_tokens = first_non_nil(max_tokens, execution_overrides["max_tokens"])
        resolved_cli_args = first_non_nil(cli_args, execution_overrides["cli_args"])
        resolved_system_append = first_non_empty(system_append, execution_overrides["system_append"])
        resolved_sandbox = first_non_nil(sandbox, execution_overrides["sandbox"])
        resolved_working_dir = first_non_nil(working_dir, execution_overrides["working_dir"])
        resolved_subprocess_env = merge_hash_values(execution_overrides["subprocess_env"], subprocess_env)

        generation_opts[:temperature] = resolved_temperature unless resolved_temperature.nil?
        generation_opts[:max_tokens] = resolved_max_tokens unless resolved_max_tokens.nil?
        generation_opts[:system_file] = system_file if system_file
        generation_opts[:prompt_file] = prompt_file if prompt_file
        generation_opts[:cli_args] = resolved_cli_args unless blank_value?(resolved_cli_args)
        generation_opts[:system_append] = resolved_system_append unless blank_value?(resolved_system_append)
        generation_opts[:sandbox] = resolved_sandbox if resolved_sandbox
        generation_opts[:working_dir] = resolved_working_dir unless blank_value?(resolved_working_dir)
        generation_opts[:subprocess_env] = resolved_subprocess_env unless resolved_subprocess_env.nil?
        generation_opts[:last_message_file] = last_message_file if last_message_file

        if debug
          warn "Provider: #{parse_result.provider}"
          warn "Model: #{final_model}"
          warn "Preset: #{resolved_preset}" if resolved_preset
          warn "Thinking level: #{parse_result.thinking_level}" if parse_result.thinking_level
          warn "Temperature: #{resolved_temperature}" unless resolved_temperature.nil?
          warn "Max tokens: #{resolved_max_tokens}" unless resolved_max_tokens.nil?
        end

        fallback_config = load_fallback_config(fallback, fallback_providers, parser: parser)
        timeout_value = first_non_nil(timeout, execution_overrides["timeout"], Molecules::ConfigLoader.get("llm.timeout"), 120)
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

        text_content = extract_text_content(response)

        result = {
          text: text_content,
          model: final_model,
          provider: parse_result.provider,
          preset: resolved_preset,
          thinking_level: parse_result.thinking_level,
          usage: response[:usage],
          metadata: response[:metadata]
        }

        if output && !output.empty?
          handler = Molecules::FormatHandlers.get_handler(format)

          formatted_content = case format
          when "json"
            handler.format(result)
          when "yaml"
            handler.format(result)
          when "raw"
            handler.format(response)
          else
            text_content
          end

          file_handler = Molecules::FileIoHandler.new
          file_handler.write_content(formatted_content, output, format: format, force: force)

          warn "Output written to: #{output}" if debug
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

      def self.load_execution_overrides(provider:, preset:, thinking_level:)
        merged = {}
        if preset
          preset_options = Molecules::PresetLoader.load_for_provider(provider, preset)
          merged = merge_execution_overrides(merged, preset_options)
        end
        if thinking_level
          thinking_options = Molecules::ThinkingLevelLoader.load_for_provider(provider, thinking_level)
          merged = merge_execution_overrides(merged, thinking_options)
        end
        merged
      end
      private_class_method :load_execution_overrides

      def self.merge_execution_overrides(base, overlay)
        left = base.respond_to?(:to_h) ? deep_stringify_keys(base.to_h) : deep_stringify_keys(base || {})
        right = overlay.respond_to?(:to_h) ? deep_stringify_keys(overlay.to_h) : deep_stringify_keys(overlay || {})
        merged = left.dup

        right.each do |key, value|
          merged[key] = case key
          when "cli_args"
            append_cli_args(merged[key], value)
          when "subprocess_env"
            merge_hash_values(merged[key], value)
          else
            value
          end
        end

        merged
      end
      private_class_method :merge_execution_overrides

      def self.append_cli_args(base_value, override_value)
        base_args = normalize_cli_args_value(base_value)
        override_args = normalize_cli_args_value(override_value)
        combined = base_args + override_args
        return nil if combined.empty?

        combined
      end
      private_class_method :append_cli_args

      def self.normalize_cli_args_value(value)
        case value
        when nil
          []
        when Array
          value.dup
        else
          [value]
        end
      end
      private_class_method :normalize_cli_args_value

      def self.merge_hash_values(base_value, override_value)
        base_hash = base_value.respond_to?(:to_h) ? base_value.to_h : base_value
        override_hash = override_value.respond_to?(:to_h) ? override_value.to_h : override_value
        return override_hash unless base_hash.is_a?(Hash) && override_hash.is_a?(Hash)

        deep_stringify_keys(base_hash).merge(deep_stringify_keys(override_hash))
      end
      private_class_method :merge_hash_values

      def self.deep_stringify_keys(value)
        case value
        when Hash
          value.each_with_object({}) do |(key, nested_value), acc|
            acc[key.to_s] = deep_stringify_keys(nested_value)
          end
        when Array
          value.map { |item| deep_stringify_keys(item) }
        else
          value
        end
      end
      private_class_method :deep_stringify_keys

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

      def self.load_fallback_config(fallback, fallback_providers, parser: nil)
        parser ||= Molecules::ProviderModelParser.new

        config_fallback = Molecules::ConfigLoader.get("llm.fallback")
        normalized_config_fallback = normalize_fallback_provider_hash(config_fallback, parser)
        config = Models::FallbackConfig.from_hash(normalized_config_fallback)

        env_overrides = load_fallback_env_overrides
        env_overrides = normalize_fallback_provider_hash(env_overrides, parser)
        config = config.merge(env_overrides) unless env_overrides.empty?

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

      def self.execute_with_fallback(provider:, model:, messages:, generation_opts:,
        registry:, fallback_config:, timeout:, debug:)
        if fallback_config.disabled?
          client = registry.get_client(provider, model: model, timeout: timeout)
          return client.generate(messages, **generation_opts)
        end

        status_callback = ->(msg) { warn msg }

        orchestrator = Molecules::FallbackOrchestrator.new(
          config: fallback_config,
          status_callback: status_callback,
          timeout: timeout
        )

        primary_provider_string = model ? "#{provider}:#{model}" : provider

        orchestrator.execute(primary_provider: primary_provider_string, registry: registry) do |client|
          client.generate(messages, **generation_opts)
        end
      end

      def self.extract_text_content(response)
        if response[:text]
          response[:text]
        elsif response[:content]
          response[:content]
        elsif response[:choices] && response[:choices].is_a?(Array) && !response[:choices].empty?
          choice = response[:choices].first
          if choice[:message] && choice[:message][:content]
            choice[:message][:content]
          elsif choice[:text]
            choice[:text]
          else
            ""
          end
        elsif response[:candidates] && response[:candidates].is_a?(Array) && !response[:candidates].empty?
          candidate = response[:candidates].first
          if candidate[:content] && candidate[:content][:parts] && !candidate[:content][:parts].empty?
            candidate[:content][:parts].first[:text] || ""
          else
            ""
          end
        else
          response.to_s
        end
      end

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

# frozen_string_literal: true

require "dry/cli"
require "ace/core/cli/dry_cli/base"

module Ace
  module LLM
    module CLI
      module Commands
      # Query command for ace-llm
      class Query < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Query an LLM provider"

        argument :provider_model, required: false, desc: "PROVIDER[:MODEL] or alias (e.g., gflash, google:gemini-2.5-flash)"
        argument :prompt_text, required: false, desc: "Prompt text (can also use --prompt flag)"

        option :quiet, type: :boolean, default: false, desc: "Suppress non-essential output"
        option :verbose, type: :boolean, default: false, desc: "Show verbose output"
        option :debug, type: :boolean, default: false, desc: "Show debug output"

        option :output, type: :string, aliases: %w[o], desc: "Output file path"
        option :format, type: :string, aliases: %w[f], desc: "Output format (text, json, markdown)"
        option :temperature, type: :float, aliases: %w[t], desc: "Temperature (0.0-2.0)"
        option :max_tokens, type: :integer, aliases: %w[m], desc: "Maximum output tokens"
        option :system, type: :string, aliases: %w[s], desc: "System instruction/prompt"
        option :system_append, type: :string, desc: "Append to system prompt"
        option :preset, type: :string, desc: "Execution preset name (or use model@preset)"
        option :cli_args, type: :string, desc: "Extra args for CLI providers (auto-prefixed with --; use --flag value or flag=value for values)"
        option :timeout, type: :integer, desc: "Request timeout in seconds"
        option :model, type: :string, desc: "Model name (overrides PROVIDER[:MODEL])"
        option :prompt, type: :string, desc: "Prompt text (overrides positional PROMPT)"
        option :force, type: :boolean, default: false, desc: "Force overwrite existing files"

        option :version, type: :boolean, desc: "Show version information"
        option :list_providers, type: :boolean, desc: "List available LLM providers"

        def call(provider_model: nil, prompt_text: nil, **options)
          if options[:version]
            puts "ace-llm #{Ace::LLM::VERSION}"
            return
          end

          if options[:list_providers]
            list_providers
            return
          end

          @provider_model = provider_model
          if @provider_model.nil? && options[:model]
            @provider_model = options[:model]
            @model_from_option = true
          end

          @prompt = options[:prompt] || prompt_text

          return show_help if @provider_model.nil? && @prompt.nil?
          return show_provider_help if @prompt.nil? || @prompt.empty?
          return show_help if @provider_model.nil? || @provider_model.empty?

          display_config_summary(options)
          execute_query(options)
        rescue Ace::LLM::Error => e
          raise Ace::Core::CLI::Error.new(e.message)
        rescue ArgumentError, EncodingError => e
          raise Ace::Core::CLI::Error.new(e.message)
        end

        private

        def show_help
          puts "Usage: ace-llm PROVIDER[:MODEL] [PROMPT] [options]"
          puts "       ace-llm PROVIDER --prompt PROMPT [options]"
          puts "       ace-llm PROVIDER PROMPT --model MODEL [options]"
          puts ""
          puts "Query any LLM provider through a unified interface"
          puts ""
          puts "Options:"
          puts "  -o, --output FILE              Output file path"
          puts "  -f, --format FORMAT            Output format (text, json, markdown)"
          puts "  -t, --temperature FLOAT        Temperature (0.0-2.0)"
          puts "  -m, --max-tokens INT           Maximum output tokens"
          puts "  -s, --system TEXT              System instruction/prompt"
          puts "      --system-append TEXT       Append to system prompt"
          puts "      --preset NAME              Execution preset name (or use model@preset)"
          puts "      --cli-args TEXT            Extra args for CLI providers (auto-prefixed with --; use --flag value or flag=value)"
          puts "      --timeout SECONDS          Request timeout in seconds"
          puts "      --model MODEL              Model name (overrides PROVIDER[:MODEL])"
          puts "      --prompt PROMPT            Prompt text (overrides positional PROMPT)"
          puts "      --force                    Force overwrite existing files"
          puts "  -q, --quiet                    Suppress config summary output"
          puts "  -d, --debug                    Enable debug output"
          puts "  -h, --help                     Show this help message"
          puts ""
          puts "Examples:"
          puts '  ace-llm google:gemini-2.5-flash "What is Ruby?"'
          puts '  ace-llm gflash "Quick question" # using alias'
          puts '  ace-llm gflash@ro "Summarize this diff"'
          puts '  ace-llm codex:gpt-5:high@ro "Review this code"'
          puts '  ace-llm claude:sonnet "Summarize this diff" --preset rw'
          puts '  ace-llm claude:sonnet "Hi" --cli-args "dangerously-skip-permissions"'
          puts '  ace-llm claude:sonnet "Hi" --cli-args "--model=claude-sonnet-4-0 --verbose"'
          puts ""
          puts "Provider Aliases:"
          puts "  Short aliases for common provider:MODEL combinations:"
          puts "    gflash    → google:gemini-2.5-flash"
          puts "    glite     → google:gemini-2.0-flash-lite"
          puts "    gpt4      → openai:gpt-4"
          puts "    claude    → anthropic:claude-3-5-sonnet"
        end

        def show_provider_help
          puts "Available aliases for '#{@provider_model}':"
          puts ""

          resolver = Ace::LLM::Molecules::LlmAliasResolver.new
          aliases = resolver.available_aliases

          if aliases[:global] && !aliases[:global].empty?
            puts "Global aliases:"
            aliases[:global].each do |alias_name, target|
              puts "  #{alias_name} → #{target}"
            end
          end

          puts ""
          puts "Use: ace-llm #{@provider_model} \"your prompt here\""
        end

        def display_config_summary(options)
          return if quiet?(options)

          require "ace/core"
          summary_keys = %w[provider_model preset temperature max_tokens format timeout system_append cli_args]
          Ace::Core::Atoms::ConfigSummary.display(
            command: "query",
            config: options.merge(provider_model: @provider_model),
            defaults: {},
            options: options,
            quiet: false,
            summary_keys: summary_keys
          )
        end

        def execute_query(options)
          file_handler = Ace::LLM::Molecules::FileIoHandler.new
          prompt_text = file_handler.read_content(@prompt)
          system_text = options[:system] ? file_handler.read_content(options[:system]) : nil
          system_append_text = options[:system_append] ? file_handler.read_content(options[:system_append]) : nil
          normalized_timeout = normalize_timeout(options[:timeout])

          resolved_model_override = @model_from_option ? nil : options[:model]
          response = Ace::LLM::QueryInterface.query(
            @provider_model,
            prompt_text,
            temperature: options[:temperature],
            max_tokens: options[:max_tokens],
            system: system_text,
            timeout: normalized_timeout,
            debug: options[:debug],
            model: resolved_model_override,
            cli_args: options[:cli_args],
            system_append: system_append_text,
            preset: options[:preset]
          )

          output_response(response, options)
        rescue Ace::LLM::ProviderError => e
          if e.message.include?("not found") || e.message.include?("not registered")
            available = Ace::LLM::ClientRegistry.available_providers rescue []
            raise Ace::Core::CLI::Error, "#{e.message}\nAvailable providers: #{available.join(", ")}"
          end
          raise
        end

        def output_response(response, options)
          format = options[:format] || "text"
          handler = Ace::LLM::Molecules::FormatHandlers.get_handler(format)
          formatted_output = handler.format(response)

          if options[:output]
            file_handler = Ace::LLM::Molecules::FileIoHandler.new
            file_handler.write_content(
              formatted_output,
              options[:output],
              format: format,
              force: options[:force]
            )

            puts handler.generate_summary(response, options[:output])
          else
            puts formatted_output
          end
        end

        def list_providers
          require "ace/llm/molecules/client_registry"

          registry = Ace::LLM::Molecules::ClientRegistry.new
          providers = registry.list_providers_with_status
          configuration = Ace::LLM.configuration

          if configuration.provider_filter_applied?
            total = configuration.configured_provider_names.length
            puts "Available LLM Providers (filtered - #{providers.length} of #{total} active):"
          else
            puts "Available LLM Providers:"
          end
          puts ""

          providers.each do |provider|
            status = provider[:available] ? "\u2713" : "\u2717"
            api_status = if provider[:api_key_required]
                           provider[:api_key_present] ? "API key configured" : "API key required"
                         else
                           "No API key needed"
                         end

            models = provider[:models] || []
            model_count = models.empty? ? "" : " \u00b7 #{models.length} models"
            puts "#{status} #{provider[:name]}#{model_count} (#{api_status})"

            print_wrapped_list(models, indent: "  ") unless models.empty?
            puts "  Gem required: #{provider[:gem]}" unless provider[:available]
            puts ""
          end

          return unless configuration.provider_filter_applied?

          inactive = configuration.inactive_provider_names
          return if inactive.empty?

          puts "Inactive providers (#{inactive.length}):"
          print_wrapped_list(inactive, indent: "  ")
          puts ""
        end

        def print_wrapped_list(items, indent: "  ", max_width: 78)
          current_line = indent.dup

          items.each_with_index do |item, i|
            is_last = i == items.length - 1
            entry = is_last ? item.to_s : "#{item},"

            if current_line == indent
              current_line << entry
            elsif current_line.length + 1 + entry.length > max_width
              puts current_line
              current_line = "#{indent}#{entry}"
            else
              current_line << " #{entry}"
            end
          end

          puts current_line unless current_line.strip.empty?
        end

        def error_output(message)
          $stderr.puts "Error: #{message}"
        end

        def normalize_timeout(value)
          return nil if value.nil?
          return value if value.is_a?(Numeric)

          normalized = value.to_s.strip
          Float(normalized)
        rescue ArgumentError
          raise ArgumentError, "timeout must be numeric, got #{value.inspect}"
        end
      end
    end
  end
end
end

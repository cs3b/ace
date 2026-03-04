# frozen_string_literal: true

require "dry/cli"
require "ace/core/cli/dry_cli/base"

module Ace
  module LLM
    module CLI
      module Commands
      # Query command for ace-llm
      #
      # This command queries LLM providers through a unified interface.
      # It supports provider:MODEL syntax, provider aliases, and various
      # output formatting options.
      #
      # @example Basic usage
      #   Ace::LLM::Commands::Query.new.call(
      #     "google:gemini-2.5-flash",
      #     "What is Ruby?",
      #     temperature: 0.7
      #   )
      class Query < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "Query an LLM provider"

        # Positional arguments
        argument :provider_model, required: false, desc: "PROVIDER[:MODEL] or alias (e.g., gflash, google:gemini-2.5-flash)"
        argument :prompt_text, required: false, desc: "Prompt text (can also use --prompt flag)"

        # Standard options
        option :quiet, type: :boolean, default: false, desc: "Suppress non-essential output"
        option :verbose, type: :boolean, default: false, desc: "Show verbose output"
        option :debug, type: :boolean, default: false, desc: "Show debug output"

        # Query-specific options
        option :output, type: :string, aliases: %w[o], desc: "Output file path"
        option :format, type: :string, aliases: %w[f], desc: "Output format (text, json, markdown)"
        option :temperature, type: :float, aliases: %w[t], desc: "Temperature (0.0-2.0)"
        option :max_tokens, type: :integer, aliases: %w[m], desc: "Maximum output tokens"
        option :system, type: :string, aliases: %w[s], desc: "System instruction/prompt"
        option :system_append, type: :string, desc: "Append to system prompt"
        option :cli_args, type: :string, desc: "Extra args for CLI providers (auto-prefixed with --; use --flag value or flag=value for values)"
        option :timeout, type: :integer, desc: "Request timeout in seconds"
        option :model, type: :string, desc: "Model name (overrides PROVIDER[:MODEL])"
        option :prompt, type: :string, desc: "Prompt text (overrides positional PROMPT)"
        option :force, type: :boolean, default: false, desc: "Force overwrite existing files"

        # Discovery and meta options
        option :version, type: :boolean, desc: "Show version information"
        option :list_providers, type: :boolean, desc: "List available LLM providers"

        # Execute the query command
        #
        # @param provider_model [String, nil] PROVIDER[:MODEL] or alias from positional arg
        # @param prompt_text [String, nil] Prompt text from positional arg
        # @param options [Hash] Command options
        # @return [Integer] Exit code (0 for success, 1 for failure)
        def call(provider_model: nil, prompt_text: nil, **options)
          if options[:version]
            puts "ace-llm #{Ace::LLM::VERSION}"
            return
          end

          if options[:list_providers]
            list_providers
            return
          end

          # Resolve provider_model: positional arg > --model flag
          @provider_model = provider_model
          if @provider_model.nil? && options[:model]
            @provider_model = options[:model]
            @model_from_option = true # Track that model came from --model flag
          end

          # Resolve prompt: --prompt flag > positional argument
          @prompt = options[:prompt] || prompt_text

          # If no provider and no prompt options, show help
          if @provider_model.nil? && @prompt.nil?
            return show_help
          end

          # If no prompt provided, show provider-specific help
          if @prompt.nil? || @prompt.empty?
            return show_provider_help
          end

          # If no provider specified at all, show general help
          if @provider_model.nil? || @provider_model.empty?
            return show_help
          end

          display_config_summary(options)

          # Execute the query
          execute_query(options)
        rescue Ace::LLM::Error => e
          raise Ace::Core::CLI::Error.new(e.message)
        rescue ArgumentError, EncodingError => e
          raise Ace::Core::CLI::Error.new(e.message)
        end

        private

        # Show command help
        #
        # @return [Integer] Exit code (0 for success)
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
          puts '  ace-llm google --prompt "What is Ruby?" # using --prompt flag'
          puts '  ace-llm google "What is Ruby?" --model gemini-2.0-flash-lite'
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

        # Show provider-specific help with aliases
        #
        # @return [Integer] Exit code (0 for success)
        def show_provider_help
          puts "Available aliases for '#{@provider_model}':"
          puts ""

          # Show aliases from resolver
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

        # Display configuration summary
        #
        # @param options [Hash] Command options
        # @return [nil]
        def display_config_summary(options)
          return if quiet?(options)

          require "ace/core"
          # Filter out sensitive keys (prompt, system) from config summary
          # These contain the full query text which should not be dumped to stderr
          summary_keys = %w[provider_model temperature max_tokens format timeout system_append cli_args]
          Ace::Core::Atoms::ConfigSummary.display(
            command: "query",
            config: options.merge(provider_model: @provider_model),
            defaults: {},
            options: options,
            quiet: false,
            summary_keys: summary_keys
          )
        end

        # Execute the LLM query
        #
        # @param options [Hash] Command options
        # @return [Integer] Exit code (0 for success, 1 for failure)
        def execute_query(options)
          file_handler = Ace::LLM::Molecules::FileIoHandler.new
          prompt_text = file_handler.read_content(@prompt)
          system_text = options[:system] ? file_handler.read_content(options[:system]) : nil
          system_append_text = options[:system_append] ? file_handler.read_content(options[:system_append]) : nil
          normalized_timeout = normalize_timeout(options[:timeout])

          # If --model was used as provider_model fallback (no positional provider), avoid passing it twice.
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
            system_append: system_append_text
          )

          # Format and output response
          output_response(response, options)
        rescue Ace::LLM::ProviderError => e
          # Surface actionable guidance for common CLI errors
          if e.message.include?("not found") || e.message.include?("not registered")
            available = Ace::LLM::ClientRegistry.available_providers rescue []
            raise Ace::Core::CLI::Error, "#{e.message}\nAvailable providers: #{available.join(", ")}"
          end
          raise
        end

        # Format and output the response
        #
        # @param response [Hash] LLM response hash
        # @param options [Hash] Command options
        # @return [nil]
        def output_response(response, options)
          # Get format handler (default to text)
          format = options[:format] || "text"
          handler = Ace::LLM::Molecules::FormatHandlers.get_handler(format)
          formatted_output = handler.format(response)

          if options[:output]
            # Write to file
            file_handler = Ace::LLM::Molecules::FileIoHandler.new
            file_handler.write_content(
              formatted_output,
              options[:output],
              format: format,
              force: options[:force]
            )

            # Show summary
            puts handler.generate_summary(response, options[:output])
          else
            # Output to stdout
            puts formatted_output
          end
        end

        # List available LLM providers with status
        def list_providers
          require "ace/llm/molecules/client_registry"

          registry = Ace::LLM::Molecules::ClientRegistry.new
          providers = registry.list_providers_with_status

          puts "Available LLM Providers:"
          puts ""

          providers.each do |provider|
            status = provider[:available] ? "\u2713" : "\u2717"
            api_status = if provider[:api_key_required]
                          provider[:api_key_present] ? "(API key configured)" : "(API key required)"
                        else
                          "(No API key needed)"
                        end

            puts "#{status} #{provider[:name]} #{api_status}"

            if provider[:models] && !provider[:models].empty?
              puts "  Models: #{provider[:models].join(', ')}"
            end

            unless provider[:available]
              puts "  Gem required: #{provider[:gem]}"
            end

            puts ""
          end
        end

        # Output error message to stderr
        #
        # @param message [String] Error message
        # @return [nil]
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

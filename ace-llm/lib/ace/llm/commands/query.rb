# frozen_string_literal: true

require "dry/cli"
require "ace/core/cli/dry_cli/base"

module Ace
  module LLM
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

        # Standard options
        option :quiet, type: :boolean, default: false, desc: "Suppress config summary output"
        option :verbose, type: :boolean, default: false, desc: "Enable verbose output"
        option :debug, type: :boolean, default: false, desc: "Enable debug output"

        # Query-specific options
        option :output, type: :string, aliases: %w[o], desc: "Output file path"
        option :format, type: :string, aliases: %w[f], desc: "Output format (text, json, markdown)"
        option :temperature, type: :float, aliases: %w[t], desc: "Temperature (0.0-2.0)"
        option :max_tokens, type: :integer, aliases: %w[m], desc: "Maximum output tokens"
        option :system, type: :string, aliases: %w[s], desc: "System instruction/prompt"
        option :system_append, type: :string, desc: "Append to system prompt"
        option :timeout, type: :integer, desc: "Request timeout in seconds"
        option :model, type: :string, desc: "Model name (overrides PROVIDER[:MODEL])"
        option :prompt, type: :string, desc: "Prompt text (overrides positional PROMPT)"
        option :force, type: :boolean, default: false, desc: "Force overwrite existing files"

        # Execute the query command
        #
        # @param args [Array<String>] Positional arguments (provider:MODEL, prompt)
        # @param options [Hash] Command options
        # @return [Integer] Exit code (0 for success, 1 for failure)
        def call(*args, **options)
          # Extract provider_model and prompt from args and options
          @provider_model, positional_prompt = extract_provider_model_and_prompt(args, options)

          # Resolve prompt: --prompt flag > positional argument
          @prompt = options[:prompt] || positional_prompt

          # If no provider_model or prompt, show help
          if @provider_model.nil? || @provider_model.empty?
            return show_help
          end

          if @prompt.nil? || @prompt.empty?
            return show_provider_help
          end

          display_config_summary(options)

          # Execute the query
          execute_query(options)
        rescue Ace::LLM::Error => e
          error_output(e.message)
          1
        rescue StandardError => e
          if debug?(options)
            error_output("Error: #{e.class}: #{e.message}")
            error_output(e.backtrace.join("\n"))
          else
            error_output("Error: #{e.message}")
            error_output("Use --debug for more information")
          end
          1
        end

        private

        # Show command help
        #
        # @return [Integer] Exit code (0 for success)
        def show_help
          cmd = Ace::LLM::CLI::COMMAND_NAME
          puts "Usage: #{cmd} PROVIDER[:MODEL] [PROMPT] [options]"
          puts "       #{cmd} PROVIDER --prompt PROMPT [options]"
          puts "       #{cmd} PROVIDER PROMPT --model MODEL [options]"
          puts "       #{cmd} --model PROVIDER:MODEL PROMPT [options]"
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
          puts "      --timeout SECONDS          Request timeout in seconds"
          puts "      --model MODEL              Model name (overrides PROVIDER[:MODEL])"
          puts "      --prompt PROMPT            Prompt text (overrides positional PROMPT)"
          puts "      --force                    Force overwrite existing files"
          puts "  -q, --quiet                    Suppress config summary output"
          puts "  -d, --debug                    Enable debug output"
          puts "  -h, --help                     Show this help message"
          puts ""
          puts "Examples:"
          puts "  #{cmd} google:gemini-2.5-flash \"What is Ruby?\""
          puts "  #{cmd} gflash \"Quick question\" # using alias"
          puts "  #{cmd} google --prompt \"What is Ruby?\" # using --prompt flag"
          puts "  #{cmd} google \"What is Ruby?\" --model gemini-2.0-flash-lite"
          puts "  #{cmd} --model google:gemini-2.5-flash \"What is Ruby?\""
          puts ""
          puts "Provider Aliases:"
          puts "  Short aliases for common provider:MODEL combinations:"
          puts "    gflash    → google:gemini-2.5-flash"
          puts "    glite     → google:gemini-2.0-flash-lite"
          puts "    gpt4      → openai:gpt-4"
          puts "    claude    → anthropic:claude-3-5-sonnet"
          0
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
          puts "Use: #{Ace::LLM::CLI::COMMAND_NAME} #{@provider_model} \"your prompt here\""
          0
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
          summary_keys = %w[provider_model temperature max_tokens format timeout system_append]
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
          # Parse provider and model
          parser = Ace::LLM::Molecules::ProviderModelParser.new
          parse_result = parser.parse(@provider_model)

          unless parse_result.valid?
            error_output(parse_result.error)
            return 1
          end

          # Resolve final model: --model flag > positional :MODEL > provider default
          final_model = options[:model] || parse_result.model

          # Validate that we have a model from some source
          if final_model.nil? || final_model.empty?
            error_output("No model specified and no default available for #{parse_result.provider}")
            error_output("Use --model MODEL or PROVIDER:MODEL syntax")
            return 1
          end

          # Load prompt content
          file_handler = Ace::LLM::Molecules::FileIoHandler.new
          prompt_text = file_handler.read_content(@prompt)

          # Build messages
          messages = build_messages(prompt_text, options)

          # Create client and generate response
          registry = Ace::LLM::Molecules::ClientRegistry.new
          client = create_client(registry, parse_result.provider, final_model, options)
          response = client.generate(messages, **generation_options(options))

          # Format and output response
          output_response(response, options)
          0
        end

        # Build message array from prompt and system instructions
        #
        # @param prompt_text [String] User prompt text
        # @param options [Hash] Command options
        # @return [Array<Hash>] Message array
        def build_messages(prompt_text, options)
          messages = []

          # Add system message if provided
          if options[:system]
            file_handler = Ace::LLM::Molecules::FileIoHandler.new
            system_text = file_handler.read_content(options[:system])
            messages << { role: "system", content: system_text }
          end

          # Add user message
          messages << { role: "user", content: prompt_text }
          messages
        end

        # Create an LLM client
        #
        # @param registry [Molecules::ClientRegistry] Client registry
        # @param provider [String] Provider name
        # @param model [String] Model name
        # @param options [Hash] Command options
        # @return [Object] LLM client instance
        def create_client(registry, provider, model, options)
          registry.get_client(
            provider,
            model: model,
            timeout: options[:timeout] || 30
          )
        rescue Ace::LLM::ProviderError => e
          error_output(e.message)
          error_output("Available providers: #{registry.available_providers.join(', ')}")
          raise
        rescue LoadError => e
          error_output("Provider '#{provider}' requires missing gem: #{e.message}")
          error_output("Please install the required gem and try again")
          raise
        end

        # Build generation options from command options
        #
        # @param options [Hash] Command options
        # @return [Hash] Generation options
        def generation_options(options)
          opts = {}
          # Type-convert numeric options (dry-cli returns strings, Thor converted to floats/ints)
          opts[:temperature] = options[:temperature].to_f if options[:temperature]
          opts[:max_tokens] = options[:max_tokens].to_i if options[:max_tokens]
          opts[:timeout] = options[:timeout].to_i if options[:timeout]

          # Pass system_append for providers that support it
          if options[:system_append] && !options[:system_append].empty?
            file_handler = Ace::LLM::Molecules::FileIoHandler.new
            append_content = file_handler.read_content(options[:system_append])
            opts[:system_append] = append_content unless append_content.nil? || append_content.empty?
          end

          opts
        end

        # Format and output the response
        #
        # @param response [String] LLM response text
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

        # Output error message to stderr
        #
        # @param message [String] Error message
        # @return [nil]
        def error_output(message)
          $stderr.puts "Error: #{message}"
        end

        # Extract provider_model and prompt from args and options
        #
        # When --model contains provider:model format and no positional PROVIDER is given,
        # use --model as the source for both provider and model.
        #
        # @param args [Array<String>] Positional arguments (always empty without argument declarations)
        # @param options [Hash] Command options (contains options[:args] with positional args)
        # @return [Array<String>] [provider_model, prompt]
        def extract_provider_model_and_prompt(args, options)
          # CRITICAL: dry-cli puts all positional args in options[:args]
          # Get positional arguments from options[:args]
          args = options[:args] || []

          # Special case: if --model is provided (may be alias or provider:model)
          if options[:model]
            # Resolve alias if needed
            model_value = resolve_alias_if_needed(options[:model])

            if model_value.include?(":")
              # --model contains provider:model format
              provider_model = model_value
              prompt = args.empty? ? nil : args.join(" ")
              return [provider_model, prompt]
            end

            # --model is just a model name (with positional provider)
            # If the positional arg is not a known provider, we can't determine
            # which arg is the provider vs the prompt - show help
            if args.first && !args.first.include?(":")
              # Check if first arg is a valid provider
              registry = Ace::LLM::Molecules::ClientRegistry.new
              unless registry.available_providers.include?(args.first)
                # Not a valid provider - ambiguous case
                return [nil, nil]
              end
            end

            provider_model = args.first
            prompt = args.empty? ? nil : args.join(" ")
            return [provider_model, prompt]
          end

          # Default behavior: positional provider:model syntax
          provider_model = args.first
          prompt = args[1..]&.join(" ")
          [provider_model, prompt]
        end

        # Resolve alias if needed
        #
        # @param model_value [String] The model value from --model option
        # @return [String] Resolved provider:model or alias
        def resolve_alias_if_needed(model_value)
          # If it contains ":", it's already provider:model format
          return model_value if model_value.include?(":")

          # Otherwise, check if it's an alias
          resolver = Ace::LLM::Molecules::LlmAliasResolver.new
          aliases = resolver.available_aliases

          # Check global aliases
          global_aliases = aliases[:global] || {}
          if global_aliases[model_value]
            return global_aliases[model_value]
          end

          # Not an alias, return as-is
          model_value
        end
      end
    end
  end
end

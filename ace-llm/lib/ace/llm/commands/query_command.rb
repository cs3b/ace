# frozen_string_literal: true

module Ace
  module LLM
    module Commands
      class QueryCommand
        def initialize(args, options = {})
          @args = args
          @options = options
          @registry = Molecules::ClientRegistry.new
        end

        def execute
          result = parse_arguments
          return result if result == 0 # Help was displayed, exit early

          display_config_summary

          # Build and execute query
          execute_query
        rescue Ace::LLM::Error => e
          error_output(e.message)
          1
        rescue StandardError => e
          if @options[:debug]
            error_output("Error: #{e.class}: #{e.message}")
            error_output(e.backtrace.join("\n"))
          else
            error_output("Error: #{e.message}")
            error_output("Use --debug for more information")
          end
          1
        end

        private

        def parse_arguments
          if @args.empty?
            show_help
            return 0
          end

          @provider_model = @args.shift
          positional_prompt = @args.join(" ")

          # Resolve prompt: --prompt flag > positional argument
          @prompt = @options[:prompt] || positional_prompt

          # If no prompt provided from any source, show help for the provider
          if @prompt.nil? || @prompt.empty?
            show_provider_help
            return 0
          end

          nil # Return nil to indicate we should continue
        end

        def show_help
          puts "Usage: ace-llm-query PROVIDER[:MODEL] [PROMPT] [options]"
          puts "       ace-llm-query PROVIDER --prompt PROMPT [options]"
          puts "       ace-llm-query PROVIDER PROMPT --model MODEL [options]"
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
          puts "  -d, --debug                    Enable debug output"
          puts "  -h, --help                     Show this help message"
          puts "      --list-providers           List available providers"
          puts ""
          puts "Examples:"
          puts '  ace-llm-query google:gemini-2.5-flash "What is Ruby?"'
          puts '  ace-llm-query gflash "Quick question" # using alias'
          puts '  ace-llm-query google --prompt "What is Ruby?" # using --prompt flag'
          puts '  ace-llm-query google "What is Ruby?" --model gemini-2.0-flash-lite'
          puts ""
          puts "Providers: #{@registry.available_providers.join(', ')}"
          0
        end

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
          puts "Use: ace-llm-query #{@provider_model} \"your prompt here\""
          0
        end

        def execute_query
          # Parse provider and model
          parser = Ace::LLM::Molecules::ProviderModelParser.new
          parse_result = parser.parse(@provider_model)

          unless parse_result.valid?
            error_output(parse_result.error)
            return 1
          end

          # Resolve final model: --model flag > positional :MODEL > provider default
          final_model = @options[:model] || parse_result.model

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
          messages = build_messages(prompt_text)

          # Create client and generate response
          client = create_client(parse_result.provider, final_model)
          response = client.generate(messages, **generation_options)

          # Format and output response
          output_response(response)
          0
        end

        def build_messages(prompt_text)
          messages = []

          # Add system message if provided
          if @options[:system]
            file_handler = Ace::LLM::Molecules::FileIoHandler.new
            system_text = file_handler.read_content(@options[:system])
            messages << { role: "system", content: system_text }
          end

          # Add user message
          messages << { role: "user", content: prompt_text }
          messages
        end

        def create_client(provider, model)
          # Use registry to get client
          @registry.get_client(
            provider,
            model: model,
            timeout: @options[:timeout] || 30
          )
        rescue Ace::LLM::ProviderError => e
          error_output(e.message)
          error_output("Available providers: #{@registry.available_providers.join(', ')}")
          raise
        rescue LoadError => e
          error_output("Provider '#{provider}' requires missing gem: #{e.message}")
          error_output("Please install the required gem and try again")
          raise
        end

        def generation_options
          opts = {}
          opts[:temperature] = @options[:temperature] if @options[:temperature]
          opts[:max_tokens] = @options[:max_tokens] if @options[:max_tokens]

          # Pass system_append for providers that support it
          if @options[:system_append] && !@options[:system_append].empty?
            file_handler = Ace::LLM::Molecules::FileIoHandler.new
            append_content = file_handler.read_content(@options[:system_append])
            opts[:system_append] = append_content unless append_content.nil? || append_content.empty?
          end

          opts
        end

        def output_response(response)
          # Get format handler (default to text)
          format = @options[:format] || "text"
          handler = Ace::LLM::Molecules::FormatHandlers.get_handler(format)
          formatted_output = handler.format(response)

          if @options[:output]
            # Write to file
            file_handler = Ace::LLM::Molecules::FileIoHandler.new
            file_handler.write_content(
              formatted_output,
              @options[:output],
              format: format,
              force: @options[:force]
            )

            # Show summary
            puts handler.generate_summary(response, @options[:output])
          else
            # Output to stdout
            puts formatted_output
          end
        end

        def error_output(message)
          $stderr.puts "Error: #{message}"
        end

        def display_config_summary
          return if @options[:quiet]

          require "ace/core"
          # Filter out sensitive keys (prompt, system) from config summary
          # These contain the full query text which should not be dumped to stderr
          summary_keys = %w[provider_model temperature max_tokens format timeout system_append]
          Ace::Core::Atoms::ConfigSummary.display(
            command: "query",
            config: @options.merge(provider_model: @provider_model),
            defaults: {},
            options: @options,
            quiet: false,
            summary_keys: summary_keys
          )
        end
      end
    end
  end
end

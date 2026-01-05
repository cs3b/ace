# frozen_string_literal: true

require "ace/core/cli/base"

module Ace
  module LLM
    class CLI < Ace::Core::CLI::Base
      # class_options :quiet, :verbose, :debug inherited from Base

      default_task :query

      # Override help to add provider aliases section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Provider Aliases:"
        shell.say "  Short aliases for common provider:MODEL combinations:"
        shell.say "    gflash    → google:gemini-2.5-flash"
        shell.say "    glite     → google:gemini-2.0-flash-lite"
        shell.say "    gpt4      → openai:gpt-4"
        shell.say "    claude    → anthropic:claude-3-5-sonnet"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-llm-query gflash 'What is Ruby?'     # Using alias"
        shell.say "  ace-llm-query google:gemini-2.5-flash 'Explain'"
      end

      desc "query [PROVIDER[:MODEL]] [PROMPT]", "Query an LLM provider"
      long_desc <<~DESC
        Query any LLM provider through a unified interface.

        SYNTAX:
          ace-llm-query [PROVIDER[:MODEL]] [PROMPT] [OPTIONS]

        The provider:MODEL syntax allows specifying both provider and model.
        You can use provider aliases (e.g., 'gflash' for 'google:gemini-2.5-flash').

        EXAMPLES:

          # Full provider:model specification
          $ ace-llm-query google:gemini-2.5-flash "What is Ruby?"

          # Using provider alias
          $ ace-llm-query gflash "Quick question"

          # Using --prompt flag
          $ ace-llm-query google --prompt "What is Ruby?"

          # Override model with --model flag
          $ ace-llm-query google "What is Ruby?" --model gemini-2.0-flash-lite

          # With temperature and max tokens
          $ ace-llm-query gpt4 "Explain APIs" --temperature 0.7 --max-tokens 1000

          # Save output to file
          $ ace-llm-query gflash "Generate code" --output response.md

          # With system prompt
          $ ace-llm-query claude "You are expert: " --system "Be concise"

        CONFIGURATION:

          Global config:  ~/.ace/llm/config.yml
          Project config: .ace/llm/config.yml
          Example:        ace-llm/.ace-defaults/llm/config.yml

          API keys configured via provider settings or ENV

        OUTPUT:

          By default, response printed to stdout
          Use --output to save to file
          Exit codes: 0 (success), 1 (error)

        PROVIDER ALIASES:

          gflash    → google:gemini-2.5-flash
          glite     → google:gemini-2.0-flash-lite
          gpt4      → openai:gpt-4
          claude    → anthropic:claude-3-5-sonnet
      DESC
      option :output, type: :string, aliases: "-o", desc: "Output file path"
      option :format, type: :string, aliases: "-f", desc: "Output format (text, json, markdown)"
      option :temperature, type: :numeric, aliases: "-t", desc: "Temperature (0.0-2.0)"
      option :max_tokens, type: :numeric, aliases: "-m", desc: "Maximum output tokens"
      option :system, type: :string, aliases: "-s", desc: "System instruction/prompt"
      option :system_append, type: :string, desc: "Append to system prompt"
      option :timeout, type: :numeric, desc: "Request timeout in seconds"
      option :model, type: :string, desc: "Model name (overrides PROVIDER[:MODEL])"
      option :prompt, type: :string, desc: "Prompt text (overrides positional PROMPT)"
      option :force, type: :boolean, desc: "Force overwrite existing files"
      def query(*args)
        # Handle --help/-h passed as first argument
        if args.first == "--help" || args.first == "-h"
          invoke :help, ["query"]
          return 0
        end
        require_relative "commands/query_command"
        Commands::QueryCommand.new(args, options).execute
      end

      desc "list-providers", "List available LLM providers"
      long_desc <<~DESC
        List all available LLM providers with their status.

        EXAMPLES:

          # List all providers
          $ ace-llm-query list-providers
          $ ace-llm-query --list-providers

        CONFIGURATION:

          Global config:  ~/.ace/llm/config.yml
          Project config: .ace/llm/config.yml
          Example:        ace-llm/.ace-defaults/llm/config.yml

        OUTPUT:

          Table format with columns: provider, status, available models
          Exit codes: 0 (success), 1 (error)
      DESC
      def list_providers
        require_relative "commands/list_providers_command"
        Commands::ListProvidersCommand.new.execute
      end

      map "--list-providers" => :list_providers

      desc "version", "Show version"
      long_desc <<~DESC
        Display the current version of ace-llm-query.

        EXAMPLES:

          $ ace-llm-query version
          $ ace-llm-query --version
      DESC
      def version
        puts "ace-llm-query #{Ace::LLM::VERSION}"
        0
      end
      map "--version" => :version

      # Handle unknown commands as arguments to the default 'query' command
      def method_missing(command, *args)
        invoke :query, [command.to_s] + args
      end
      # respond_to_missing? inherited from Ace::Core::CLI::Base
    end
  end
end

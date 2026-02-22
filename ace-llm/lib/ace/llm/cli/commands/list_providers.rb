# frozen_string_literal: true

require "dry/cli"
require "ace/core/cli/dry_cli/base"

module Ace
  module LLM
    module CLI
      module Commands
      # ListProviders command for ace-llm
      #
      # This command lists all available LLM providers with their status
      # and available models.
      #
      # @example Basic usage
      #   Ace::LLM::Commands::ListProviders.new.call
      class ListProviders < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc "List available LLM providers"

        # Standard options
        option :quiet, type: :boolean, default: false, desc: "Suppress non-essential output"
        option :verbose, type: :boolean, default: false, desc: "Show verbose output"
        option :debug, type: :boolean, default: false, desc: "Show debug output"

        # Execute the list-providers command
        #
        # @param args [Array<String>] Positional arguments (unused)
        # @param options [Hash] Command options
        # @return [Integer] Exit code (0 for success)
        def call(*args, **options)
          require "ace/llm/molecules/client_registry"

          registry = Ace::LLM::Molecules::ClientRegistry.new
          providers = registry.list_providers_with_status

          puts "Available LLM Providers:"
          puts ""

          providers.each do |provider|
            status = provider[:available] ? "✓" : "✗"
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

          0
        end
      end
    end
  end
end
end

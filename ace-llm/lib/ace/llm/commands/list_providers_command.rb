# frozen_string_literal: true

require_relative "../molecules/client_registry"

module Ace
  module LLM
    module Commands
      class ListProvidersCommand
        def initialize
          @registry = Molecules::ClientRegistry.new
        end

        def execute
          puts "Available LLM Providers:"
          puts ""

          providers = @registry.list_providers_with_status

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

# frozen_string_literal: true

require "json"

module Ace
  module LLM
    module ModelsDev
      module Commands
        module Providers
          # List all providers with model counts
          class List < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc "List all providers with model counts"

            option :json, type: :boolean, desc: "Output as JSON"

            def call(**options)
              cache_manager = Molecules::CacheManager.new

              unless cache_manager.cached?
                warn "No cache data. Run 'ace-llm-models cache sync' first."
                return 1
              end

              providers = cache_manager.list_providers

              if options[:json]
                puts JSON.pretty_generate(providers)
                return 0
              end

              puts "Providers (#{providers.size}):"
              providers.sort_by { |p| -p[:model_count] }.each do |provider|
                puts "  #{provider[:id]}: #{provider[:model_count]} models"
              end
              0
            rescue CacheError => e
              warn "Error: #{e.message}"
              1
            end
          end
        end
      end
    end
  end
end

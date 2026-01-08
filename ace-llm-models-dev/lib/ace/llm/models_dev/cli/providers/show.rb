# frozen_string_literal: true

require "json"

module Ace
  module LLM
    module ModelsDev
      module Commands
        module Providers
          # Show provider details and models
          class Show < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc "Show provider details and models"

            argument :provider_id, required: true, desc: "Provider ID"
            option :json, type: :boolean, desc: "Output as JSON"

            def call(provider_id:, **options)
              cache_manager = Molecules::CacheManager.new

              unless cache_manager.cached?
                warn "No cache data. Run 'ace-llm-models cache sync' first."
                return 1
              end

              provider_data = cache_manager.get_provider(provider_id)

              unless provider_data
                warn "Provider '#{provider_id}' not found"
                return 1
              end

              if options[:json]
                puts JSON.pretty_generate(provider_data)
                return 0
              end

              puts "Provider: #{provider_id}"
              puts "Models (#{provider_data[:models].size}):"
              provider_data[:models].each do |model|
                status = model[:deprecated] ? " (deprecated)" : ""
                puts "  #{model[:id]}#{status}"
                puts "    #{model[:name]}"
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

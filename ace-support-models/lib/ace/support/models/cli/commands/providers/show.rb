# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module Providers
            # Show provider details and models
            class Show < Ace::Support::Cli::Command
              include Ace::Support::Cli::Base

              desc "Show provider details and models"

              argument :provider_id, required: true, desc: "Provider ID"
              option :json, type: :boolean, desc: "Output as JSON"

              def call(provider_id:, **options)
                cache_manager = Molecules::CacheManager.new

                unless cache_manager.cached?
                  raise Ace::Support::Cli::Error.new("No cache data. Run 'ace-models cache sync' first.")
                end

                provider_data = cache_manager.get_provider(provider_id)

                unless provider_data
                  raise Ace::Support::Cli::Error.new("Provider '#{provider_id}' not found")
                end

                if options[:json]
                  puts JSON.pretty_generate(provider_data)
                  return
                end

                puts "Provider: #{provider_id}"
                puts "Models (#{provider_data[:models].size}):"
                provider_data[:models].each do |model|
                  status = model[:deprecated] ? " (deprecated)" : ""
                  puts "  #{model[:id]}#{status}"
                  puts "    #{model[:name]}"
                end
              rescue CacheError => e
                raise Ace::Support::Cli::Error.new(e.message)
              end
            end
          end
        end
      end
    end
  end
end

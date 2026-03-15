# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module Providers
            # List all providers with model counts
            class List < Ace::Support::Cli::Command
              include Ace::Core::CLI::Base

              desc "List all providers with model counts"

              option :json, type: :boolean, desc: "Output as JSON"

              def call(**options)
                cache_manager = Molecules::CacheManager.new

                unless cache_manager.cached?
                  raise Ace::Core::CLI::Error.new("No cache data. Run 'ace-models cache sync' first.")
                end

                providers = cache_manager.list_providers

                if options[:json]
                  puts JSON.pretty_generate(providers)
                  return
                end

                puts "Providers (#{providers.size}):"
                providers.sort_by { |p| -p[:model_count] }.each do |provider|
                  puts "  #{provider[:id]}: #{provider[:model_count]} models"
                end
              rescue CacheError => e
                raise Ace::Core::CLI::Error.new(e.message)
              end
            end
          end
        end
      end
    end
  end
end

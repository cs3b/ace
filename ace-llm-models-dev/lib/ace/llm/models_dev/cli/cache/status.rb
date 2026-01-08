# frozen_string_literal: true

require "json"

module Ace
  module LLM
    module ModelsDev
      module Commands
        module Cache
          # Show cache info (freshness, age, counts)
          class Status < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc "Show cache info (freshness, age, counts)"

            option :json, type: :boolean, desc: "Output as JSON"

            def call(**options)
              status_data = Organisms::SyncOrchestrator.new.status

              if options[:json]
                puts JSON.pretty_generate(status_data)
                return 0
              end

              unless status_data[:cached]
                warn "No cache data. Run 'ace-llm-models cache sync' first."
                return 1
              end

              puts "Cache Status:"
              puts "  Cached: Yes"
              puts "  Fresh: #{status_data[:fresh] ? 'Yes' : 'No (stale)'}"
              puts "  Last sync: #{status_data[:last_sync_at]}"
              puts

              if status_data[:stats]
                puts "Statistics:"
                puts "  Providers: #{status_data[:stats][:provider_count]}"
                puts "  Models: #{status_data[:stats][:model_count]}"
                puts
                puts "Top providers by model count:"
                status_data[:stats][:top_providers].each do |provider, count|
                  puts "  #{provider}: #{count}"
                end
              end
              0
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module Cache
            # Show cache info (freshness, age, counts)
            class Status < Ace::Support::Cli::Command
              include Ace::Support::Cli::Base

              desc "Show cache info (freshness, age, counts)"

              option :json, type: :boolean, desc: "Output as JSON"

              def call(**options)
                status_data = Organisms::SyncOrchestrator.new.status

                if options[:json]
                  puts JSON.pretty_generate(status_data)
                  return
                end

                unless status_data[:cached]
                  raise Ace::Support::Cli::Error.new("No cache data. Run 'ace-models cache sync' first.")
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
              end
            end
          end
        end
      end
    end
  end
end

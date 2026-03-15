# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module Cache
            # Fetch models from models.dev API
            class Sync < Ace::Support::Cli::Command
              include Ace::Core::CLI::Base

              desc "Fetch models from models.dev API"

              option :force, type: :boolean, aliases: ["-f"], desc: "Force sync even if cache is fresh"
              option :json, type: :boolean, desc: "Output as JSON"

              example [
                "           # Sync cache",
                "--force    # Force sync even if cache is fresh",
                "--json     # Output as JSON"
              ]

              def call(**options)
                result = Organisms::SyncOrchestrator.new.sync(force: options[:force])

                if options[:json]
                  puts JSON.pretty_generate(result)
                  return
                end

                case result[:status]
                when :success
                  puts result[:message]
                  puts "Duration: #{result[:duration]}s"
                when :skipped
                  puts result[:message]
                  puts "Last synced: #{result[:last_sync_at]}"
                when :error
                  raise Ace::Core::CLI::Error.new(result[:message])
                end
              end
            end
          end
        end
      end
    end
  end
end

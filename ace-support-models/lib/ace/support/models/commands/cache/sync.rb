# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module Commands
        module Cache
          # Fetch models from models.dev API
          class Sync < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

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
                return 0
              end

              case result[:status]
              when :success
                puts result[:message]
                puts "Duration: #{result[:duration]}s"
                0
              when :skipped
                puts result[:message]
                puts "Last synced: #{result[:last_sync_at]}"
                0
              when :error
                warn "Error: #{result[:message]}"
                1
              end
            end
          end
        end
      end
    end
  end
end

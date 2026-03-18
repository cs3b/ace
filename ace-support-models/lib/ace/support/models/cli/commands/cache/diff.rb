# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module Cache
            # Show changes since last sync
            class Diff < Ace::Support::Cli::Command
              include Ace::Support::Cli::Base

              desc "Show changes since last sync"

              option :json, type: :boolean, desc: "Output as JSON"

              def call(**options)
                result = Molecules::DiffGenerator.new.generate

                if options[:json]
                  puts JSON.pretty_generate(result.to_h)
                  return
                end

                unless result.any_changes?
                  puts "No changes since last sync"
                  return
                end

                if result.added_providers.any?
                  puts "New providers:"
                  result.added_providers.each { |p| puts "  + #{p}" }
                  puts
                end

                if result.removed_providers.any?
                  puts "Removed providers:"
                  result.removed_providers.each { |p| puts "  - #{p}" }
                  puts
                end

                if result.added_models.any?
                  puts "New models:"
                  result.added_models.each { |m| puts "  + #{m}" }
                  puts
                end

                if result.removed_models.any?
                  puts "Removed models:"
                  result.removed_models.each { |m| puts "  - #{m}" }
                  puts
                end

                if result.updated_models.any?
                  puts "Updated models:"
                  result.updated_models.each do |update|
                    puts "  ~ #{update.model_id}: #{update.summary}"
                  end
                  puts
                end

                puts "Summary: #{result.summary}"
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

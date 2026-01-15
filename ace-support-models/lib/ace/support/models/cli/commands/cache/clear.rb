# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module Cache
            # Clear local cache
            class Clear < Dry::CLI::Command
              include Ace::Core::CLI::DryCli::Base

              desc "Clear local cache"

              option :json, type: :boolean, desc: "Output as JSON"

              def call(**options)
                cache_manager = Molecules::CacheManager.new
                result = cache_manager.clear

                if options[:json]
                  puts JSON.pretty_generate(result)
                  return 0
                end

                if result[:status] == :success
                  puts "Cache cleared successfully"
                  puts "Deleted: #{result[:deleted_files].join(', ')}" if result[:deleted_files]&.any?
                  0
                else
                  warn "Error: #{result[:message]}"
                  1
                end
              rescue StandardError => e
                warn "Error: #{e.message}"
                1
              end
            end
          end
        end
      end
    end
  end
end

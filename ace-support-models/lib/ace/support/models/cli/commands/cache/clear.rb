# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module Cache
            # Clear local cache
            class Clear < Ace::Support::Cli::Command
              include Ace::Support::Cli::Base

              desc "Clear local cache"

              option :json, type: :boolean, desc: "Output as JSON"

              def call(**options)
                cache_manager = Molecules::CacheManager.new
                result = cache_manager.clear

                if options[:json]
                  puts JSON.pretty_generate(result)
                  return
                end

                if result[:status] == :success
                  puts "Cache cleared successfully"
                  puts "Deleted: #{result[:deleted_files].join(', ')}" if result[:deleted_files]&.any?
                else
                  raise Ace::Support::Cli::Error.new(result[:message])
                end
              rescue StandardError => e
                raise Ace::Support::Cli::Error.new(e.message)
              end
            end
          end
        end
      end
    end
  end
end

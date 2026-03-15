# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          # Note: Using Models_ prefix to avoid conflict with outer Models module
          module ModelsSubcommands
            # Search for models
            class Search < Ace::Support::Cli::Command
              include Ace::Core::CLI::Base

              desc "Search for models (query optional with filters)"

              argument :query, required: false, desc: "Search query"
              option :provider, type: :string, aliases: ["-p"], desc: "Limit to provider"
              option :limit, type: :integer, aliases: ["-l"], default: 20, desc: "Max results"
              option :filter, type: :array, aliases: ["-f"], desc: "Filter by key:value (repeatable)"
              option :json, type: :boolean, desc: "Output as JSON"

              example [
                "gpt-4                     # Search by name",
                "opus -p anthropic         # Search within a provider",
                "-f reasoning:true         # Filter by capability",
                "-f tool_call:true -f min_context:100000  # Multiple filters",
                "gpt -l 5                  # Limit results"
              ]

              def call(query: nil, **options)
                # Validate filters before searching
                filter_errors = Atoms::ModelFilter.validate(options[:filter])
                unless filter_errors.empty?
                  filter_errors.each { |e| warn "Error: #{e}" }
                  raise Ace::Core::CLI::Error.new("Invalid model search filters")
                end

                searcher = Molecules::ModelSearcher.new
                filters = parse_filters(options[:filter])
                limit = options[:limit] || 20

                # Single search with total count for efficient pagination
                result = searcher.search(
                  query,
                  provider: options[:provider],
                  limit: limit,
                  filters: filters.empty? ? nil : filters,
                  with_total: true
                )

                models = result[:models]
                total_models_count = result[:total]

                if models.empty?
                  if options[:json]
                    puts "[]"
                  else
                    message = query ? "No models found matching '#{query}'" : "No models found"
                    message += " with filters: #{options[:filter].join(', ')}" if options[:filter]&.any?
                    puts message
                  end
                  return
                end

                if options[:json]
                  json_result = {
                    models: models.map(&:to_h),
                    showing: models.size,
                    total: total_models_count
                  }
                  puts JSON.pretty_generate(json_result)
                else
                  if models.size < total_models_count
                    puts "Showing #{models.size} of #{total_models_count} results:"
                  else
                    puts "Found #{models.size} model(s):"
                  end
                  models.each do |model|
                    status = model.deprecated? ? " (deprecated)" : ""
                    puts "  #{model.full_id}#{status}"
                    puts "    #{model.name}"
                  end
                end
              rescue CacheError => e
                raise Ace::Core::CLI::Error.new(e.message)
              end

              private

              def parse_filters(filter_array)
                Atoms::ModelFilter.parse_all(filter_array)
              end
            end
          end
        end
      end
    end
  end
end

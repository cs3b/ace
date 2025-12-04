# frozen_string_literal: true

require "thor"

module Ace
  module LLM
    module ModelsDev
      # CLI for ace-llm-models
      class CLI < Thor
        def self.exit_on_failure?
          true
        end

        desc "sync", "Sync models from models.dev API"
        option :force, type: :boolean, aliases: "-f", desc: "Force sync even if cache is fresh"
        def sync
          result = Organisms::SyncOrchestrator.new.sync(force: options[:force])

          case result[:status]
          when :success
            puts result[:message]
            puts "Duration: #{result[:duration]}s"
          when :skipped
            puts result[:message]
            puts "Last synced: #{result[:last_sync_at]}"
          when :error
            warn "Error: #{result[:message]}"
            exit 1
          end
        end

        desc "validate MODEL_ID", "Validate a model exists"
        def validate(model_id)
          model = Molecules::ModelValidator.new.validate(model_id)
          puts "✓ #{model.full_id} is valid"
          puts "  Name: #{model.name}"
          puts "  Provider: #{model.provider_id}"
          puts "  Status: #{model.status || 'active'}"
        rescue ProviderNotFoundError => e
          warn "✗ Provider '#{e.provider_id}' not found"
          exit 1
        rescue ModelNotFoundError => e
          warn "✗ #{e.message}"
          exit 1
        rescue CacheError => e
          warn "Error: #{e.message}"
          exit 1
        end

        desc "cost MODEL_ID", "Show pricing for a model"
        option :input, type: :numeric, aliases: "-i", default: 1000, desc: "Input tokens"
        option :output, type: :numeric, aliases: "-o", default: 500, desc: "Output tokens"
        option :reasoning, type: :numeric, aliases: "-r", default: 0, desc: "Reasoning tokens"
        def cost(model_id)
          calculator = Molecules::CostCalculator.new
          result = calculator.calculate(
            model_id,
            input_tokens: options[:input],
            output_tokens: options[:output],
            reasoning_tokens: options[:reasoning]
          )

          puts calculator.format(result)
        rescue ProviderNotFoundError, ModelNotFoundError => e
          warn "Error: #{e.message}"
          exit 1
        rescue CacheError => e
          warn "Error: #{e.message}"
          exit 1
        end

        desc "diff", "Show changes since last sync"
        def diff
          result = Molecules::DiffGenerator.new.generate

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
          warn "Error: #{e.message}"
          exit 1
        end

        desc "search QUERY", "Search for models"
        option :provider, type: :string, aliases: "-p", desc: "Limit to provider"
        option :limit, type: :numeric, aliases: "-l", default: 20, desc: "Max results"
        def search(query)
          searcher = Molecules::ModelSearcher.new
          models = searcher.search(query, provider: options[:provider], limit: options[:limit])

          if models.empty?
            puts "No models found matching '#{query}'"
            return
          end

          puts "Found #{models.size} model(s):"
          models.each do |model|
            status = model.deprecated? ? " (deprecated)" : ""
            puts "  #{model.full_id}#{status}"
            puts "    #{model.name}"
          end
        rescue CacheError => e
          warn "Error: #{e.message}"
          exit 1
        end

        desc "stats", "Show statistics about cached data"
        def stats
          status = Organisms::SyncOrchestrator.new.status

          unless status[:cached]
            warn "No cache data. Run 'ace-llm-models sync' first."
            exit 1
          end

          puts "Cache Status:"
          puts "  Cached: Yes"
          puts "  Fresh: #{status[:fresh] ? 'Yes' : 'No (stale)'}"
          puts "  Last sync: #{status[:last_sync_at]}"
          puts

          if status[:stats]
            puts "Statistics:"
            puts "  Providers: #{status[:stats][:provider_count]}"
            puts "  Models: #{status[:stats][:model_count]}"
            puts
            puts "Top providers by model count:"
            status[:stats][:top_providers].each do |provider, count|
              puts "  #{provider}: #{count}"
            end
          end
        end

        desc "version", "Show version"
        def version
          puts "ace-llm-models-dev #{VERSION}"
        end

        # Default to help
        default_task :help
      end
    end
  end
end

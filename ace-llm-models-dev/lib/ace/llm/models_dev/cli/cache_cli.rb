# frozen_string_literal: true

require "thor"
require "json"

module Ace
  module LLM
    module ModelsDev
      module Commands
        # Cache management subcommands
        class CacheCLI < Thor
          def self.exit_on_failure?
            false
          end

          desc "sync", "Fetch models from models.dev API"
          long_desc <<-LONGDESC
Download model data from models.dev and cache locally.
Cache is valid for 24 hours; use --force to refresh early.

Examples:
\x5  ace-llm-models cache sync
\x5  ace-llm-models cache sync --force
\x5  ace-llm-models cache sync --json
          LONGDESC
          option :force, type: :boolean, aliases: "-f", desc: "Force sync even if cache is fresh"
          option :json, type: :boolean, desc: "Output as JSON"
          def sync
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

          desc "status", "Show cache info (freshness, age, counts)"
          option :json, type: :boolean, desc: "Output as JSON"
          def status
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

          desc "diff", "Show changes since last sync"
          option :json, type: :boolean, desc: "Output as JSON"
          def diff
            result = Molecules::DiffGenerator.new.generate

            if options[:json]
              puts JSON.pretty_generate(result.to_h)
              return 0
            end

            unless result.any_changes?
              puts "No changes since last sync"
              return 0
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
            0
          rescue CacheError => e
            warn "Error: #{e.message}"
            return 1
          end

          desc "clear", "Clear local cache"
          option :json, type: :boolean, desc: "Output as JSON"
          def clear
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
            return 1
          end

          # Default to help
          default_task :help
        end
      end
    end
  end
end

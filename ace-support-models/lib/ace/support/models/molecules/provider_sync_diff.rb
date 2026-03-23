# frozen_string_literal: true

require "date"

module Ace
  module Support
    module Models
      module Molecules
        # Generates diff between current provider configs and models.dev data
        # Shows added, removed, and deprecated models for each provider
        class ProviderSyncDiff
          # Model change types
          ADDED = :added
          REMOVED = :removed
          UNCHANGED = :unchanged
          DEPRECATED = :deprecated

          attr_reader :cache_manager

          # Initialize diff generator
          # @param cache_manager [CacheManager, nil] Cache manager for models.dev data
          def initialize(cache_manager: nil)
            @cache_manager = cache_manager || CacheManager.new
          end

          # Generate diff for all providers
          # @param current_configs [Hash<String, Hash>] Provider name => config hash
          # @param provider_filter [String, nil] Limit to specific provider
          # @param since_date [Date, nil] Only show models released after this date
          # @param show_all [Boolean] Show all models regardless of date (ignores since_date)
          # @return [Hash] Diff results by provider
          def generate(current_configs, provider_filter: nil, since_date: nil, show_all: false)
            models_dev_data = load_models_dev_data
            results = {}

            current_configs.each do |provider_name, config|
              # Skip if filtering and this isn't the target provider
              next if provider_filter && provider_name != provider_filter

              # Determine the models.dev ID to use (may be mapped via models_dev_id field)
              models_dev_id = Atoms::ProviderConfigReader.extract_models_dev_id(config)

              # Find matching provider in models.dev
              provider_data = find_provider(models_dev_data, models_dev_id)

              if provider_data.nil?
                # Generate hint for unmapped providers
                hint = suggest_models_dev_id(models_dev_data, provider_name)
                results[provider_name] = {
                  status: :not_found,
                  message: "Provider not found in models.dev",
                  hint: hint
                }
                next
              end

              # Determine the date to filter by
              filter_date = determine_filter_date(config, since_date, show_all)

              # Generate diff for this provider
              results[provider_name] = diff_provider(config, provider_data, since_date: filter_date, provider_name: provider_name)
              results[provider_name][:last_synced] = Atoms::ProviderConfigReader.extract_last_synced(config)
              results[provider_name][:models_dev_id] = models_dev_id if models_dev_id != provider_name
            end

            results
          end

          # Generate diff for a single provider
          # @param config [Hash] Current provider config
          # @param provider_data [Hash] models.dev provider data
          # @param since_date [Date, nil] Only include models released after this date
          # @param provider_name [String, nil] Provider name for canonicalization (e.g., "openrouter")
          # @return [Hash] Diff result
          def diff_provider(config, provider_data, since_date: nil, provider_name: nil)
            current_models = Set.new(Atoms::ProviderConfigReader.extract_models(config))
            models_dev_models = extract_models_dev_models(provider_data)

            # Build a set of canonical model names from models.dev for efficient lookup
            models_dev_canonical = Set.new(models_dev_models.keys)

            # Build a mapping of canonical names to original names for current models
            # This handles cases like "model:nitro" -> "model"
            current_canonical_to_original = {}
            current_models.each do |model_id|
              canonical = Atoms::ModelNameCanonicalizer.canonicalize(model_id, provider: provider_name)
              current_canonical_to_original[canonical] ||= []
              current_canonical_to_original[canonical] << model_id
            end

            added = []
            added_with_dates = {}
            removed = []
            unchanged = []
            deprecated = []

            # Check models.dev models against current config
            # Use canonical names for matching
            models_dev_models.each do |model_id, model_data|
              # Check if any current model (or its canonical form) matches this models.dev model
              has_match = current_canonical_to_original.key?(model_id)

              if has_match
                if model_data[:status] == "deprecated"
                  deprecated << model_id
                else
                  unchanged << model_id
                end
              else
                if model_data[:status] == "deprecated"
                  # Don't suggest adding deprecated models
                  next
                end

                # Filter by release date if specified
                if since_date && model_data[:release_date]
                  next if model_data[:release_date] <= since_date
                end

                added << model_id
                added_with_dates[model_id] = model_data[:release_date]
              end
            end

            # Check for removed models (in config but not in models.dev)
            # Use canonical names to avoid false positives for suffixed models
            current_models.each do |model_id|
              canonical = Atoms::ModelNameCanonicalizer.canonicalize(model_id, provider: provider_name)
              unless models_dev_canonical.include?(canonical)
                removed << model_id
              end
            end

            {
              status: :ok,
              added: added.sort,
              added_with_dates: added_with_dates,
              removed: removed.sort,
              unchanged: unchanged.sort,
              deprecated: deprecated.sort,
              models_dev_count: models_dev_models.size,
              current_count: current_models.size,
              filtered_by_date: !since_date.nil?
            }
          end

          # Calculate summary statistics
          # @param results [Hash] Diff results by provider
          # @return [Hash] Summary stats
          def summary(results)
            total_added = 0
            total_removed = 0
            total_unchanged = 0
            total_deprecated = 0
            providers_synced = 0
            providers_skipped = 0

            results.each do |_provider, result|
              if result[:status] == :ok
                providers_synced += 1
                total_added += result[:added].size
                total_removed += result[:removed].size
                total_unchanged += result[:unchanged].size
                total_deprecated += result[:deprecated].size
              else
                providers_skipped += 1
              end
            end

            {
              added: total_added,
              removed: total_removed,
              unchanged: total_unchanged,
              deprecated: total_deprecated,
              providers_synced: providers_synced,
              providers_skipped: providers_skipped
            }
          end

          # Check if there are any changes
          # @param results [Hash] Diff results
          # @return [Boolean] true if any changes detected
          def any_changes?(results)
            results.any? do |_provider, result|
              next false unless result[:status] == :ok

              result[:added].any? || result[:removed].any?
            end
          end

          private

          def load_models_dev_data
            data = cache_manager.read
            raise CacheError, "No models.dev cache found. Run 'ace-models sync' first." unless data

            data
          end

          def find_provider(models_dev_data, provider_name)
            return nil unless provider_name

            # Try exact match first
            return models_dev_data[provider_name] if models_dev_data.key?(provider_name)

            # Try case-insensitive match
            models_dev_data.each do |id, data|
              return data if id.downcase == provider_name.downcase
            end

            # Try matching by provider name field
            models_dev_data.each do |_id, data|
              name = data["name"] || data["id"]
              return data if name&.downcase == provider_name.downcase
            end

            nil
          end

          def extract_models_dev_models(provider_data)
            models = provider_data["models"] || {}
            result = {}

            models.each do |model_id, model_data|
              release_date = parse_date(model_data["release_date"])
              result[model_id] = {
                status: model_data["status"],
                name: model_data["name"] || model_id,
                release_date: release_date
              }
            end

            result
          end

          def parse_date(value)
            return nil unless value

            case value
            when Date
              value
            when String
              Date.parse(value)
            end
          rescue ArgumentError
            nil
          end

          def determine_filter_date(config, explicit_since_date, show_all)
            return nil if show_all

            # Use explicit --since date if provided
            return explicit_since_date if explicit_since_date

            # Otherwise use last_synced from config
            Atoms::ProviderConfigReader.extract_last_synced(config)
          end

          def suggest_models_dev_id(models_dev_data, provider_name)
            # Try to find a provider that might match
            provider_lower = provider_name.downcase

            # Common mappings
            common_mappings = {
              "claude" => "anthropic",
              "gpt" => "openai",
              "gemini" => "google",
              "llama" => "meta"
            }

            # Check common mappings first
            common_mappings.each do |key, value|
              if provider_lower.include?(key) && models_dev_data.key?(value)
                return "Add 'models_dev_id: #{value}' to provider config"
              end
            end

            # Try fuzzy matching on provider names
            models_dev_data.each do |id, _data|
              if id.downcase.include?(provider_lower) || provider_lower.include?(id.downcase)
                return "Add 'models_dev_id: #{id}' to provider config"
              end
            end

            nil
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "digest"
require "json"

module Ace
  module Support
    module Models
      module Atoms
        # Reconciles an observed local selection with a bundled native catalog.
        # Missing entries on first observation carry no evidence of consent.
        class ProviderCatalogReconciler
          def self.reconcile(config, catalog)
            local = ProviderConfigReader.extract_models(config)
            offered = ProviderConfigReader.extract_models(catalog)
            previous = config["sync_state"]
            previous = nil unless valid_state?(previous)
            removed = previous ? (previous["removed"] + previous["accepted"] - local).uniq : []
            unknown = previous ? previous["unknown"] - local : offered - local
            added = previous ? offered - previous["catalog"] - local - removed - unknown : []
            models = local + added
            state = {
              "catalog" => offered,
              "catalog_digest" => Digest::SHA256.hexdigest(JSON.generate(catalog)),
              "accepted" => models.dup,
              "unknown" => unknown,
              "removed" => removed - local
            }
            desired = config.reject { |key, _| key.start_with?("_source_") }
            # Preserve hash-form local model metadata, as well as order/default.
            desired["models"] = if config["models"].is_a?(Hash)
              config["models"].merge(added.to_h { |id| [id, {}] })
            else
              models
            end
            desired["sync_state"] = state
            {
              config: desired, added: added, offered: (unknown & offered),
              removed: state["removed"], changed: desired != config.reject { |key, _| key.start_with?("_source_") }
            }
          end

          def self.valid_state?(state)
            state.is_a?(Hash) && state["catalog_digest"].is_a?(String) &&
              %w[catalog accepted unknown removed].all? do |key|
                state[key].is_a?(Array) && state[key].all? { |id| id.is_a?(String) }
              end
          end
          private_class_method :valid_state?
        end
      end
    end
  end
end

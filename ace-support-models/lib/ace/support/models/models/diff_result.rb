# frozen_string_literal: true

module Ace
  module Support
    module Models
      module Models
        # Represents the diff between two API versions
        class DiffResult
          attr_reader :added_models, :removed_models, :updated_models,
            :added_providers, :removed_providers,
            :previous_sync_at, :current_sync_at

          # Initialize diff result
          def initialize(attrs = {})
            @added_models = attrs[:added_models] || []
            @removed_models = attrs[:removed_models] || []
            @updated_models = attrs[:updated_models] || []
            @added_providers = attrs[:added_providers] || []
            @removed_providers = attrs[:removed_providers] || []
            @previous_sync_at = attrs[:previous_sync_at]
            @current_sync_at = attrs[:current_sync_at]
          end

          # Check if there are any changes
          # @return [Boolean]
          def any_changes?
            added_models.any? || removed_models.any? || updated_models.any? ||
              added_providers.any? || removed_providers.any?
          end

          # Total number of changes
          # @return [Integer]
          def total_changes
            added_models.size + removed_models.size + updated_models.size +
              added_providers.size + removed_providers.size
          end

          # Summary string
          # @return [String]
          def summary
            parts = []
            parts << "#{added_models.size} new model(s)" if added_models.any?
            parts << "#{removed_models.size} removed model(s)" if removed_models.any?
            parts << "#{updated_models.size} updated model(s)" if updated_models.any?
            parts << "#{added_providers.size} new provider(s)" if added_providers.any?
            parts << "#{removed_providers.size} removed provider(s)" if removed_providers.any?

            return "No changes" if parts.empty?

            parts.join(", ")
          end

          # Convert to hash
          # @return [Hash]
          def to_h
            {
              added_models: added_models,
              removed_models: removed_models,
              updated_models: updated_models,
              added_providers: added_providers,
              removed_providers: removed_providers,
              previous_sync_at: previous_sync_at&.iso8601,
              current_sync_at: current_sync_at&.iso8601,
              summary: summary
            }
          end
        end

        # Represents an update to a model
        class ModelUpdate
          attr_reader :model_id, :changes

          def initialize(model_id:, changes:)
            @model_id = model_id
            @changes = changes
          end

          # Convert to hash
          def to_h
            {
              model_id: model_id,
              changes: changes
            }
          end

          # Summary of changes
          def summary
            changes.map { |field, (old_val, new_val)| "#{field}: #{old_val} → #{new_val}" }.join(", ")
          end
        end
      end
    end
  end
end

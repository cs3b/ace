# frozen_string_literal: true

require "digest"
require "json"
require_relative "campaign_execution"

module Ace
  module Assign
    module Authority
      # Shared byte/schema validation; each lifecycle separately authenticates
      # the registration's owner, campaign provenance and original selection.
      module AssignmentDefinition
        def self.parse(bytes:, digest:, assignment_id:, project_id:)
          unless bytes.is_a?(String) && bytes.bytesize <= 32_768 && digest.is_a?(String) &&
              Digest::SHA256.hexdigest(bytes) == digest
            raise ArgumentError, "invalid assignment definition digest or size"
          end
          value = JSON.parse(bytes)
          allowed = %w[session_id name description created_at updated_at source_config parent task_id project_id prepared_work review_campaign campaign_execution]
          unless value.is_a?(Hash) && (value.keys - allowed).empty? &&
              %w[session_id name created_at source_config task_id project_id].all? { |key| value[key].is_a?(String) && !value[key].empty? } &&
              value["session_id"] == assignment_id && value["project_id"] == project_id
            raise ArgumentError, "invalid managed assignment definition"
          end
          CampaignExecution.validate_parent!(value.fetch("review_campaign")) if value.key?("review_campaign")
          assignment = Models::Assignment.from_h(value)
          unless assignment.managed? && assignment.task_id.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/)
            raise ArgumentError, "definition is not managed or task identity is invalid"
          end
          assignment
        end
      end
    end
  end
end

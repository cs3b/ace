# frozen_string_literal: true

module Ace
  module Lab
    module Models
      # Non-secret result submitted to the assignment evidence coordinator.
      # The coordinator independently verifies every binding before acceptance.
      module ServiceReceipt
        BINDING_FIELDS = %w[request_id assignment_id attempt_id project_id operation
          input_digest target candidate_head].freeze

        def self.build(binding, executor_result)
          BINDING_FIELDS.to_h { |field| [field, binding.fetch(field)] }.merge(executor_result)
        end
      end
    end
  end
end

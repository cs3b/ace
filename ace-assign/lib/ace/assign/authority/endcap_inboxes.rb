# frozen_string_literal: true

module Ace
  module Assign
    module Authority
      class Endcap
        INBOX_REGISTRATION_FIELDS = %w[event_id attempt_id payload_sha256].freeze

        private

        def inbox_registration?(value)
          value.is_a?(Hash) && value.keys.sort == INBOX_REGISTRATION_FIELDS.sort &&
            %w[event_id attempt_id].all? { |key| value[key].is_a?(String) && Molecules::JournalMutation::ID.match?(value[key]) } &&
            %w[payload_sha256].all? { |key| value[key].is_a?(String) && DIGEST.match?(value[key]) }
        end

        def inbox_native_lineage!(record, lineage)
          workspace = lineage.native_event.fetch("payload").fetch("workspace_id")
          original = record.fetch("origin_target")
          binding = record.fetch("binding")
          unless original.is_a?(Hash) && binding.is_a?(Hash) &&
              original["session"] == workspace && binding["session"] == workspace
            raise AttemptErrors::EvidenceUnavailable, "inbox original native workspace differs"
          end
          if lineage.child_event
            child = lineage.child_event.fetch("payload").fetch("original_process_binding")
            unless original.values_at("session", "pane", "terminal_id") == child.values_at("session", "pane", "terminal_id")
              raise AttemptErrors::EvidenceUnavailable, "inbox original native child differs"
            end
          end
          true
        end

      end
    end
  end
end

# frozen_string_literal: true

require_relative "protected_assignment_context"
require_relative "task_context_entry"

module Ace
  module Assign
    module Authority
      # The selected immutable Lab owner sets the hook before entry evaluation.
      # Its presence alone never grants scope; original fetch admission decides.
      class PreparedTaskContext
        SCHEMA = "ace.assign.prepared-task-context/v1"
        MAX_RESPONSE = 6_307_840

        def initialize(context: nil)
          @context = context
        end

        def call(mapping:, assignment:, attempt:, task:)
          unless [mapping, attempt, task].all? { |value| value.is_a?(String) && value.match?(PreparedWork::TOKEN) } &&
              assignment.is_a?(String)
            unavailable!("task-context selectors")
          end
          assignment_id, scope = assignment.split("@", 2)
          unless assignment_id&.match?(PreparedWork::TOKEN) && scope&.match?(PreparedWork::SCOPE)
            unavailable!("task-context scoped assignment")
          end
          unless Object.const_defined?(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, false)
            unavailable!("selected original task-context entry is absent")
          end
          selected_entry = Object.const_get(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, false)
          TaskContextEntry.validate!(selected_entry)
          objects = [selected_entry, *selected_entry.keys, *selected_entry.values]
          selected_entry.values.each { |reference| objects.concat(reference.keys); objects.concat(reference.values) }
          unavailable!("selected task-context entry is mutable") unless objects.all?(&:frozen?)
          context = @context || ProtectedAssignmentContext.load
          input = context.resolve(options: {mapping: mapping, attempt: attempt}, assignment_id: assignment_id, scope: scope)
          unavailable!("original protected task-context admission") unless input &&
            input.descriptor.fetch("task_context_entry") == selected_entry
          item = input.work.manifest.fetch("context").find { |entry| entry.fetch("task_id") == task }
          unavailable!("task is outside captured original context") unless item
          text = input.work.files.fetch(item.fetch("text").fetch("filename"))
          record = input.descriptor.slice("mapping_id", "assignment_id", "attempt_id", "scope", "definition_digest", "selection_sha256")
            .merge("schema" => SCHEMA, "task_id" => task, "text" => text)
          response = JSON.generate(record) + "\n"
          unavailable!("task-context response bound") if response.bytesize > MAX_RESPONSE
          response.freeze
        rescue ArgumentError, KeyError
          unavailable!("task-context input or original entry differs")
        end

        private

        def unavailable!(reason)
          raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: #{reason}"
        end
      end
    end
  end
end

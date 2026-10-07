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
        PRINCIPAL_SCHEMA = "ace.assign.task-context-principal/v1"
        SELECTION_SCHEMA = "ace.assign.task-context-selection/v1"
        MAX_PRINCIPAL = 1_024
        MAX_SELECTION = 65_536

        def initialize(context: nil)
          @context = context
        end

        def call(mapping:, assignment:, attempt:, task:)
          unavailable!("task-context task selector") unless task.is_a?(String) && task.match?(PreparedWork::TOKEN)
          selected_entry = selected_entry!
          input = resolved_input(mapping: mapping, assignment: assignment, attempt: attempt)
          unavailable!("original protected task-context admission") unless input.descriptor.fetch("task_context_entry") == selected_entry
          item = input.work.manifest.fetch("context").find { |entry| entry.fetch("task_id") == task }
          unavailable!("task is outside captured original context") unless item
          text = input.work.files.fetch(item.fetch("text").fetch("filename"))
          record = input.descriptor.slice("mapping_id", "assignment_id", "attempt_id", "scope", "definition_digest", "selection_sha256")
            .merge("schema" => SCHEMA, "task_id" => task, "text" => text)
          response!(record, MAX_RESPONSE)
        rescue ArgumentError, KeyError
          unavailable!("task-context input or original entry differs")
        end

        def principal
          selected_entry!
          context = installed_context!
          response!({"schema" => PRINCIPAL_SCHEMA, "uid" => context.uid, "protected_worker" => context.protected_worker?}, MAX_PRINCIPAL)
        end

        def selection(mapping:, assignment:, attempt:)
          selected_entry!
          # Current discovery selects a trusted classifier only. Original fetch
          # independently selects the retained entry; no text leaves this mode.
          input = resolved_input(mapping: mapping, assignment: assignment, attempt: attempt)
          response!(input.descriptor.slice("mapping_id", "assignment_id", "attempt_id", "scope", "definition_digest", "selection_sha256", "task_context_entry")
            .merge("schema" => SELECTION_SCHEMA), MAX_SELECTION)
        rescue ArgumentError, KeyError
          unavailable!("task-context original selection differs")
        end

        private

        def selected_entry!
          unless Object.const_defined?(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, false)
            unavailable!("selected original task-context entry is absent")
          end
          selected_entry = Object.const_get(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, false)
          TaskContextEntry.validate!(selected_entry)
          objects = [selected_entry, *selected_entry.keys, *selected_entry.values]
          selected_entry.values.each { |reference| objects.concat(reference.keys); objects.concat(reference.values) }
          unavailable!("selected task-context entry is mutable") unless objects.all?(&:frozen?)
          selected_entry
        rescue ArgumentError, KeyError, TypeError
          unavailable!("task-context selected entry differs")
        end

        def installed_context!
          @context ||= ProtectedAssignmentContext.load
          unavailable!("published task-context installed owner is absent") unless @context.installed?
          @context
        end

        def resolved_input(mapping:, assignment:, attempt:)
          unless [mapping, attempt].all? { |value| value.is_a?(String) && value.match?(PreparedWork::TOKEN) } && assignment.is_a?(String)
            unavailable!("task-context selectors")
          end
          assignment_id, scope = assignment.split("@", 2)
          unless assignment_id&.match?(PreparedWork::TOKEN) && scope&.match?(PreparedWork::SCOPE)
            unavailable!("task-context scoped assignment")
          end
          input = installed_context!.resolve(options: {mapping: mapping, attempt: attempt}, assignment_id: assignment_id, scope: scope)
          unavailable!("original protected task-context admission") unless input
          input
        end

        def response!(record, limit)
          response = JSON.generate(record) + "\n"
          unavailable!("task-context response bound") if response.bytesize > limit
          response.freeze
        end

        def unavailable!(reason)
          raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: #{reason}"
        end
      end
    end
  end
end

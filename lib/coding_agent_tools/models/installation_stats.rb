# frozen_string_literal: true

module CodingAgentTools
  module Models
    # InstallationStats tracks statistics during Claude command installation
    # This is a model - pure data carrier with no behavior
    class InstallationStats
      attr_accessor :created, :skipped, :updated, :errors,
                    :custom_commands, :generated_commands, 
                    :workflow_commands, :agents

      def initialize(
        created: 0,
        skipped: 0,
        updated: 0,
        errors: [],
        custom_commands: 0,
        generated_commands: 0,
        workflow_commands: 0,
        agents: 0
      )
        @created = created
        @skipped = skipped
        @updated = updated
        @errors = errors
        @custom_commands = custom_commands
        @generated_commands = generated_commands
        @workflow_commands = workflow_commands
        @agents = agents
      end

      # Convert to hash for backward compatibility
      def to_h
        {
          created: created,
          skipped: skipped,
          updated: updated,
          errors: errors,
          custom_commands: custom_commands,
          generated_commands: generated_commands,
          workflow_commands: workflow_commands,
          agents: agents
        }
      end

      # Total number of commands
      def total_commands
        custom_commands + generated_commands + workflow_commands
      end

      # Check if there are any errors
      def errors?
        !errors.empty?
      end

      # Add an error message
      def add_error(message)
        errors << message
      end

      # Increment a specific counter
      def increment(counter, amount = 1)
        case counter
        when :created then @created += amount
        when :skipped then @skipped += amount
        when :updated then @updated += amount
        when :custom_commands then @custom_commands += amount
        when :generated_commands then @generated_commands += amount
        when :workflow_commands then @workflow_commands += amount
        when :agents then @agents += amount
        else
          raise ArgumentError, "Unknown counter: #{counter}"
        end
      end
    end
  end
end
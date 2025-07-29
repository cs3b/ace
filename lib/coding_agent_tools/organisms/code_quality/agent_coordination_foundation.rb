# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    module CodeQuality
      # Foundation organism for future agent coordination (Phase 3)
      # Provides extensibility hooks and interfaces for agent integration
      class AgentCoordinationFoundation
        # Agent coordination hooks - to be implemented by agent systems
        attr_accessor :on_error_file_ready, :on_agent_complete, :on_all_agents_complete

        def initialize
          @agent_registry = {}
          @error_assignments = {}
          @completion_status = {}

          # Default no-op hooks
          @on_error_file_ready = ->(file, agent_id) {}
          @on_agent_complete = ->(agent_id, results) {}
          @on_all_agents_complete = ->(final_results) {}
        end

        # Register an agent for coordination
        def register_agent(agent_id, capabilities: [])
          @agent_registry[agent_id] = {
            id: agent_id,
            capabilities: capabilities,
            status: :idle,
            assigned_file: nil
          }
        end

        # Assign error files to agents
        def assign_error_files(error_files)
          return {success: false, error: "No agents registered"} if @agent_registry.empty?

          assignments = {}
          available_agents = @agent_registry.keys

          error_files.each_with_index do |file, index|
            agent_id = available_agents[index % available_agents.size]

            assignments[agent_id] ||= []
            assignments[agent_id] << file

            # Update agent status
            @agent_registry[agent_id][:status] = :assigned
            @agent_registry[agent_id][:assigned_file] = file

            # Trigger hook
            @on_error_file_ready.call(file, agent_id)
          end

          @error_assignments = assignments

          {
            success: true,
            assignments: assignments,
            agents_used: assignments.keys.size
          }
        end

        # Mark agent work as complete
        def mark_agent_complete(agent_id, results)
          return unless @agent_registry[agent_id]

          @agent_registry[agent_id][:status] = :complete
          @completion_status[agent_id] = {
            completed_at: Time.now,
            results: results
          }

          # Trigger completion hook
          @on_agent_complete.call(agent_id, results)

          # Check if all agents are complete
          check_all_complete
        end

        # Get coordination status
        def status
          {
            agents: @agent_registry.transform_values { |a| a[:status] },
            assignments: @error_assignments,
            completions: @completion_status.keys,
            all_complete: all_agents_complete?
          }
        end

        # Prepare parallel processing metadata
        def prepare_parallel_metadata(error_files)
          {
            total_files: error_files.size,
            recommended_agents: calculate_optimal_agents(error_files.size),
            estimated_time: estimate_processing_time(error_files),
            parallelization_strategy: determine_strategy(error_files),
            workflow_instruction: "dev-handbook/workflow-instructions/fix-linting-issue-from.wf.md"
          }
        end

        # Generate agent instructions for a specific error file
        def generate_agent_instructions(error_file)
          {
            file: error_file,
            instructions: [
              "1. Read the error file: #{error_file}",
              "2. For each error listed:",
              "   - Navigate to the source file",
              "   - Understand the context",
              "   - Apply the appropriate fix",
              "   - Validate the fix doesn't break anything",
              "3. Run targeted linting on fixed files",
              "4. Report completion status"
            ],
            guidelines: [
              "Fix only issues listed in your assigned file",
              "Do not modify files assigned to other agents",
              "Preserve code functionality",
              "Follow project coding standards"
            ]
          }
        end

        private

        def all_agents_complete?
          return false if @agent_registry.empty?

          @agent_registry.all? { |_id, agent| agent[:status] == :complete }
        end

        def check_all_complete
          if all_agents_complete?
            final_results = compile_final_results
            @on_all_agents_complete.call(final_results)
          end
        end

        def compile_final_results
          {
            total_agents: @agent_registry.size,
            successful_agents: @completion_status.size,
            total_fixes: @completion_status.values.sum { |c| c[:results]&.dig(:fixes_applied) || 0 },
            duration: calculate_total_duration,
            agent_results: @completion_status
          }
        end

        def calculate_total_duration
          return 0 if @completion_status.empty?

          start_time = @completion_status.values.map { |c| c[:completed_at] }.min
          end_time = @completion_status.values.map { |c| c[:completed_at] }.max

          end_time - start_time
        end

        def calculate_optimal_agents(file_count)
          # Simple heuristic: 1 agent per file, max 4
          [file_count, 4].min
        end

        def estimate_processing_time(error_files)
          # Rough estimate: 30 seconds per error file with 4 parallel agents
          total_errors = error_files.size
          return 0 if total_errors == 0

          parallel_factor = [total_errors, 4].min

          (total_errors * 30.0 / parallel_factor).ceil
        end

        def determine_strategy(error_files)
          case error_files.size
          when 0
            :sequential
          when 1
            :sequential
          when 2..4
            :parallel_simple
          else
            :parallel_distributed
          end
        end
      end
    end
  end
end

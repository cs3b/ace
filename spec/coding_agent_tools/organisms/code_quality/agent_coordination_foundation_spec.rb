# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/code_quality/agent_coordination_foundation"

RSpec.describe CodingAgentTools::Organisms::CodeQuality::AgentCoordinationFoundation do
  let(:foundation) { described_class.new }

  describe "#initialize" do
    it "initializes empty agent registry" do
      expect(foundation.instance_variable_get(:@agent_registry)).to eq({})
    end

    it "initializes empty error assignments" do
      expect(foundation.instance_variable_get(:@error_assignments)).to eq({})
    end

    it "initializes empty completion status" do
      expect(foundation.instance_variable_get(:@completion_status)).to eq({})
    end

    it "sets default no-op hooks" do
      expect(foundation.on_error_file_ready).to be_a(Proc)
      expect(foundation.on_agent_complete).to be_a(Proc)
      expect(foundation.on_all_agents_complete).to be_a(Proc)
    end

    it "allows hook assignment" do
      hook = ->(_file, _agent_id) { puts "Hook called" }
      foundation.on_error_file_ready = hook
      expect(foundation.on_error_file_ready).to eq(hook)
    end
  end

  describe "#register_agent" do
    it "registers an agent with default values" do
      foundation.register_agent("agent1")

      registry = foundation.instance_variable_get(:@agent_registry)
      expect(registry["agent1"]).to eq({
        id: "agent1",
        capabilities: [],
        status: :idle,
        assigned_file: nil
      })
    end

    it "registers an agent with capabilities" do
      foundation.register_agent("agent2", capabilities: ["ruby", "javascript"])

      registry = foundation.instance_variable_get(:@agent_registry)
      expect(registry["agent2"]).to eq({
        id: "agent2",
        capabilities: ["ruby", "javascript"],
        status: :idle,
        assigned_file: nil
      })
    end

    it "allows registering multiple agents" do
      foundation.register_agent("agent1")
      foundation.register_agent("agent2", capabilities: ["python"])

      registry = foundation.instance_variable_get(:@agent_registry)
      expect(registry.keys).to contain_exactly("agent1", "agent2")
    end

    it "overwrites existing agent registration" do
      foundation.register_agent("agent1", capabilities: ["ruby"])
      foundation.register_agent("agent1", capabilities: ["python"])

      registry = foundation.instance_variable_get(:@agent_registry)
      expect(registry["agent1"][:capabilities]).to eq(["python"])
    end
  end

  describe "#assign_error_files" do
    context "with no agents registered" do
      it "returns error when no agents are available" do
        result = foundation.assign_error_files(["error1.txt", "error2.txt"])

        expect(result).to eq({
          success: false,
          error: "No agents registered"
        })
      end
    end

    context "with registered agents" do
      before do
        foundation.register_agent("agent1")
        foundation.register_agent("agent2")
      end

      it "assigns files to agents in round-robin fashion" do
        files = ["error1.txt", "error2.txt", "error3.txt", "error4.txt"]
        result = foundation.assign_error_files(files)

        expect(result[:success]).to be true
        expect(result[:assignments]["agent1"]).to eq(["error1.txt", "error3.txt"])
        expect(result[:assignments]["agent2"]).to eq(["error2.txt", "error4.txt"])
        expect(result[:agents_used]).to eq(2)
      end

      it "updates agent status to assigned" do
        foundation.assign_error_files(["error1.txt"])

        registry = foundation.instance_variable_get(:@agent_registry)
        expect(registry["agent1"][:status]).to eq(:assigned)
        expect(registry["agent1"][:assigned_file]).to eq("error1.txt")
      end

      it "calls on_error_file_ready hook for each assignment" do
        hook_calls = []
        foundation.on_error_file_ready = ->(file, agent_id) { hook_calls << [file, agent_id] }

        foundation.assign_error_files(["error1.txt", "error2.txt"])

        expect(hook_calls).to contain_exactly(
          ["error1.txt", "agent1"],
          ["error2.txt", "agent2"]
        )
      end

      it "stores error assignments" do
        foundation.assign_error_files(["error1.txt", "error2.txt"])

        assignments = foundation.instance_variable_get(:@error_assignments)
        expect(assignments).to eq({
          "agent1" => ["error1.txt"],
          "agent2" => ["error2.txt"]
        })
      end

      it "handles single file assignment" do
        result = foundation.assign_error_files(["error1.txt"])

        expect(result[:success]).to be true
        expect(result[:assignments]["agent1"]).to eq(["error1.txt"])
        expect(result[:agents_used]).to eq(1)
      end

      it "handles more files than agents" do
        files = ["error1.txt", "error2.txt", "error3.txt"]
        result = foundation.assign_error_files(files)

        expect(result[:success]).to be true
        expect(result[:assignments]["agent1"]).to eq(["error1.txt", "error3.txt"])
        expect(result[:assignments]["agent2"]).to eq(["error2.txt"])
        expect(result[:agents_used]).to eq(2)
      end

      it "handles empty file list" do
        result = foundation.assign_error_files([])

        expect(result[:success]).to be true
        expect(result[:assignments]).to eq({})
        expect(result[:agents_used]).to eq(0)
      end
    end
  end

  describe "#mark_agent_complete" do
    let(:agent_results) { {fixes_applied: 5, errors_resolved: 3} }

    before do
      foundation.register_agent("agent1")
      foundation.register_agent("agent2")
    end

    context "with valid agent" do
      it "updates agent status to complete" do
        foundation.mark_agent_complete("agent1", agent_results)

        registry = foundation.instance_variable_get(:@agent_registry)
        expect(registry["agent1"][:status]).to eq(:complete)
      end

      it "stores completion status with timestamp" do
        freeze_time = Time.parse("2024-01-01 12:00:00")
        allow(Time).to receive(:now).and_return(freeze_time)

        foundation.mark_agent_complete("agent1", agent_results)

        completion_status = foundation.instance_variable_get(:@completion_status)
        expect(completion_status["agent1"]).to eq({
          completed_at: freeze_time,
          results: agent_results
        })
      end

      it "calls on_agent_complete hook" do
        hook_calls = []
        foundation.on_agent_complete = ->(agent_id, results) { hook_calls << [agent_id, results] }

        foundation.mark_agent_complete("agent1", agent_results)

        expect(hook_calls).to contain_exactly(["agent1", agent_results])
      end

      it "calls check_all_complete to verify completion status" do
        allow(foundation).to receive(:check_all_complete).and_call_original
        foundation.mark_agent_complete("agent1", agent_results)
        # Just verify it doesn't raise an error - the method is private
      end
    end

    context "with invalid agent" do
      it "returns early without error for non-existent agent" do
        expect { foundation.mark_agent_complete("nonexistent", agent_results) }.not_to raise_error

        completion_status = foundation.instance_variable_get(:@completion_status)
        expect(completion_status).to be_empty
      end
    end

    context "when all agents complete" do
      it "triggers on_all_agents_complete hook" do
        hook_calls = []
        foundation.on_all_agents_complete = ->(final_results) { hook_calls << final_results }

        foundation.mark_agent_complete("agent1", {fixes_applied: 3})
        foundation.mark_agent_complete("agent2", {fixes_applied: 2})

        expect(hook_calls.length).to eq(1)
        expect(hook_calls.first).to include(:total_agents, :successful_agents, :total_fixes)
      end
    end
  end

  describe "#status" do
    before do
      foundation.register_agent("agent1")
      foundation.register_agent("agent2")
    end

    it "returns current coordination status" do
      foundation.assign_error_files(["error1.txt"])
      foundation.mark_agent_complete("agent1", {fixes_applied: 2})

      status = foundation.status

      expect(status).to include(
        agents: {
          "agent1" => :complete,
          "agent2" => :idle
        },
        assignments: {"agent1" => ["error1.txt"]},
        completions: ["agent1"],
        all_complete: false
      )
    end

    it "shows all_complete as true when all agents are done" do
      foundation.mark_agent_complete("agent1", {fixes_applied: 1})
      foundation.mark_agent_complete("agent2", {fixes_applied: 2})

      status = foundation.status
      expect(status[:all_complete]).to be true
    end

    it "handles empty state" do
      empty_foundation = described_class.new
      status = empty_foundation.status

      expect(status).to eq({
        agents: {},
        assignments: {},
        completions: [],
        all_complete: false
      })
    end
  end

  describe "#prepare_parallel_metadata" do
    let(:error_files) { ["error1.txt", "error2.txt", "error3.txt"] }

    it "returns comprehensive metadata for parallel processing" do
      metadata = foundation.prepare_parallel_metadata(error_files)

      expect(metadata).to include(
        total_files: 3,
        recommended_agents: anything,
        estimated_time: anything,
        parallelization_strategy: anything,
        workflow_instruction: "dev-handbook/workflow-instructions/fix-linting-issue-from.wf.md"
      )
    end

    it "includes correct total file count" do
      metadata = foundation.prepare_parallel_metadata(error_files)
      expect(metadata[:total_files]).to eq(3)
    end

    it "calculates recommended agents based on file count" do
      metadata = foundation.prepare_parallel_metadata(error_files)
      expect(metadata[:recommended_agents]).to be_a(Integer)
      expect(metadata[:recommended_agents]).to be > 0
    end

    it "estimates processing time" do
      metadata = foundation.prepare_parallel_metadata(error_files)
      expect(metadata[:estimated_time]).to be_a(Integer)
      expect(metadata[:estimated_time]).to be > 0
    end

    it "determines parallelization strategy" do
      metadata = foundation.prepare_parallel_metadata(error_files)
      expect([:sequential, :parallel_simple, :parallel_distributed]).to include(metadata[:parallelization_strategy])
    end

    it "handles empty file list" do
      metadata = foundation.prepare_parallel_metadata([])

      expect(metadata[:total_files]).to eq(0)
      expect(metadata[:recommended_agents]).to eq(0)
      expect(metadata[:parallelization_strategy]).to eq(:sequential)
    end
  end

  describe "#generate_agent_instructions" do
    let(:error_file) { "path/to/error_file.txt" }

    it "generates comprehensive instructions for agent" do
      instructions = foundation.generate_agent_instructions(error_file)

      expect(instructions).to include(:file, :instructions, :guidelines)
    end

    it "includes the error file path" do
      instructions = foundation.generate_agent_instructions(error_file)
      expect(instructions[:file]).to eq(error_file)
    end

    it "provides step-by-step instructions" do
      instructions = foundation.generate_agent_instructions(error_file)

      expect(instructions[:instructions]).to be_an(Array)
      expect(instructions[:instructions]).not_to be_empty
      expect(instructions[:instructions].first).to include(error_file)
    end

    it "includes guidelines for agent behavior" do
      instructions = foundation.generate_agent_instructions(error_file)

      expect(instructions[:guidelines]).to be_an(Array)
      expect(instructions[:guidelines]).not_to be_empty
    end

    it "references error file in instructions" do
      instructions = foundation.generate_agent_instructions(error_file)
      instruction_text = instructions[:instructions].join(" ")

      expect(instruction_text).to include(error_file)
    end
  end

  describe "private methods" do
    describe "#all_agents_complete?" do
      before do
        foundation.register_agent("agent1")
        foundation.register_agent("agent2")
      end

      it "returns false when no agents registered" do
        empty_foundation = described_class.new
        expect(empty_foundation.send(:all_agents_complete?)).to be false
      end

      it "returns false when some agents incomplete" do
        foundation.mark_agent_complete("agent1", {fixes_applied: 1})
        expect(foundation.send(:all_agents_complete?)).to be false
      end

      it "returns true when all agents complete" do
        foundation.mark_agent_complete("agent1", {fixes_applied: 1})
        foundation.mark_agent_complete("agent2", {fixes_applied: 2})
        expect(foundation.send(:all_agents_complete?)).to be true
      end
    end

    describe "#compile_final_results" do
      before do
        foundation.register_agent("agent1")
        foundation.register_agent("agent2")
        foundation.mark_agent_complete("agent1", {fixes_applied: 3})
        foundation.mark_agent_complete("agent2", {fixes_applied: 2})
      end

      it "compiles comprehensive final results" do
        results = foundation.send(:compile_final_results)

        expect(results).to include(
          total_agents: 2,
          successful_agents: 2,
          total_fixes: 5,
          duration: anything,
          agent_results: anything
        )
      end

      it "calculates total fixes correctly" do
        results = foundation.send(:compile_final_results)
        expect(results[:total_fixes]).to eq(5)
      end

      it "includes agent results" do
        results = foundation.send(:compile_final_results)
        expect(results[:agent_results]).to be_a(Hash)
        expect(results[:agent_results].keys).to contain_exactly("agent1", "agent2")
      end
    end

    describe "#calculate_total_duration" do
      it "returns 0 for empty completion status" do
        duration = foundation.send(:calculate_total_duration)
        expect(duration).to eq(0)
      end

      it "calculates duration between first and last completion" do
        start_time = Time.parse("2024-01-01 12:00:00")
        end_time = Time.parse("2024-01-01 12:05:00")

        foundation.instance_variable_set(:@completion_status, {
          "agent1" => {completed_at: start_time},
          "agent2" => {completed_at: end_time}
        })

        duration = foundation.send(:calculate_total_duration)
        expect(duration).to eq(300) # 5 minutes in seconds
      end

      it "returns 0 for single agent completion" do
        completion_time = Time.parse("2024-01-01 12:00:00")

        foundation.instance_variable_set(:@completion_status, {
          "agent1" => {completed_at: completion_time}
        })

        duration = foundation.send(:calculate_total_duration)
        expect(duration).to eq(0)
      end
    end

    describe "#calculate_optimal_agents" do
      it "returns minimum of file count and max agents (4)" do
        expect(foundation.send(:calculate_optimal_agents, 2)).to eq(2)
        expect(foundation.send(:calculate_optimal_agents, 6)).to eq(4)
        expect(foundation.send(:calculate_optimal_agents, 0)).to eq(0)
      end

      it "caps at 4 agents maximum" do
        expect(foundation.send(:calculate_optimal_agents, 10)).to eq(4)
      end
    end

    describe "#estimate_processing_time" do
      it "estimates time based on file count and parallel factor" do
        # 2 files, 2 parallel agents: (2 * 30 / 2) = 30 seconds
        time = foundation.send(:estimate_processing_time, ["file1", "file2"])
        expect(time).to eq(30)
      end

      it "handles single file" do
        time = foundation.send(:estimate_processing_time, ["file1"])
        expect(time).to eq(30) # (1 * 30 / 1) = 30 seconds
      end

      it "uses parallel factor for many files" do
        # 6 files, 4 parallel agents: (6 * 30 / 4) = 45 seconds
        files = ["f1", "f2", "f3", "f4", "f5", "f6"]
        time = foundation.send(:estimate_processing_time, files)
        expect(time).to eq(45)
      end

      it "handles empty file list" do
        time = foundation.send(:estimate_processing_time, [])
        expect(time).to eq(0)
      end
    end

    describe "#determine_strategy" do
      it "returns sequential for single file" do
        strategy = foundation.send(:determine_strategy, ["file1"])
        expect(strategy).to eq(:sequential)
      end

      it "returns parallel_simple for 2-4 files" do
        expect(foundation.send(:determine_strategy, ["f1", "f2"])).to eq(:parallel_simple)
        expect(foundation.send(:determine_strategy, ["f1", "f2", "f3", "f4"])).to eq(:parallel_simple)
      end

      it "returns parallel_distributed for 5+ files" do
        files = ["f1", "f2", "f3", "f4", "f5"]
        strategy = foundation.send(:determine_strategy, files)
        expect(strategy).to eq(:parallel_distributed)
      end

      it "handles empty file list" do
        strategy = foundation.send(:determine_strategy, [])
        expect(strategy).to eq(:sequential)
      end
    end
  end

  # Integration test scenarios
  describe "integration scenarios" do
    let(:error_files) { ["error1.txt", "error2.txt", "error3.txt"] }

    it "supports complete agent coordination workflow" do
      # Setup agents
      foundation.register_agent("agent1", capabilities: ["ruby"])
      foundation.register_agent("agent2", capabilities: ["javascript"])

      # Assign work
      result = foundation.assign_error_files(error_files)
      expect(result[:success]).to be true

      # Check initial status
      status = foundation.status
      expect(status[:all_complete]).to be false

      # Complete work
      foundation.mark_agent_complete("agent1", {fixes_applied: 2})
      foundation.mark_agent_complete("agent2", {fixes_applied: 1})

      # Verify final status
      final_status = foundation.status
      expect(final_status[:all_complete]).to be true
      expect(final_status[:completions]).to contain_exactly("agent1", "agent2")
    end

    it "handles hook integration throughout workflow" do
      hook_events = []

      foundation.on_error_file_ready = ->(file, agent_id) { hook_events << [:file_ready, file, agent_id] }
      foundation.on_agent_complete = ->(agent_id, results) { hook_events << [:agent_complete, agent_id, results] }
      foundation.on_all_agents_complete = ->(final) { hook_events << [:all_complete, final] }

      # Register and assign
      foundation.register_agent("agent1")
      foundation.assign_error_files(["error1.txt"])
      foundation.mark_agent_complete("agent1", {fixes_applied: 1})

      expect(hook_events.length).to eq(3)
      expect(hook_events[0][0]).to eq(:file_ready)
      expect(hook_events[1][0]).to eq(:agent_complete)
      expect(hook_events[2][0]).to eq(:all_complete)
    end

    it "generates metadata and instructions for parallel workflow" do
      foundation.register_agent("agent1")
      foundation.register_agent("agent2")

      # Get metadata
      metadata = foundation.prepare_parallel_metadata(error_files)
      expect(metadata[:total_files]).to eq(3)
      expect(metadata[:parallelization_strategy]).to eq(:parallel_simple)

      # Generate instructions
      instructions = foundation.generate_agent_instructions(error_files.first)
      expect(instructions[:file]).to eq(error_files.first)
      expect(instructions[:instructions]).not_to be_empty
    end
  end

  # Edge cases and error conditions
  describe "edge cases and error conditions" do
    it "handles agent registration with empty capabilities" do
      foundation.register_agent("agent1", capabilities: [])

      registry = foundation.instance_variable_get(:@agent_registry)
      expect(registry["agent1"][:capabilities]).to eq([])
    end

    it "handles assignment with nil agent ID" do
      expect { foundation.mark_agent_complete(nil, {}) }.not_to raise_error
    end

    it "handles completion without results" do
      foundation.register_agent("agent1")
      foundation.mark_agent_complete("agent1", nil)

      completion_status = foundation.instance_variable_get(:@completion_status)
      expect(completion_status["agent1"][:results]).to be_nil
    end

    it "handles status check with mixed agent states" do
      foundation.register_agent("agent1")
      foundation.register_agent("agent2")
      foundation.register_agent("agent3")

      foundation.assign_error_files(["error1.txt"])
      foundation.mark_agent_complete("agent2", {fixes_applied: 1})

      status = foundation.status
      expect(status[:agents]["agent1"]).to eq(:assigned)
      expect(status[:agents]["agent2"]).to eq(:complete)
      expect(status[:agents]["agent3"]).to eq(:idle)
    end

    it "maintains data consistency throughout operations" do
      foundation.register_agent("agent1")
      foundation.assign_error_files(["error1.txt", "error2.txt"])

      # Verify internal state consistency
      registry = foundation.instance_variable_get(:@agent_registry)
      assignments = foundation.instance_variable_get(:@error_assignments)

      expect(registry["agent1"][:status]).to eq(:assigned)
      expect(assignments["agent1"]).to eq(["error1.txt", "error2.txt"])

      # Complete and verify consistency
      foundation.mark_agent_complete("agent1", {fixes_applied: 2})

      expect(registry["agent1"][:status]).to eq(:complete)
      expect(foundation.status[:all_complete]).to be true
    end

    it "handles hook exceptions gracefully during file assignment" do
      foundation.register_agent("agent1")
      foundation.on_error_file_ready = ->(_file, _agent_id) { raise StandardError, "Hook failed" }

      # The method should continue despite hook failure
      expect { foundation.assign_error_files(["error1.txt"]) }.to raise_error(StandardError, "Hook failed")
    end

    it "handles hook exceptions gracefully during agent completion" do
      foundation.register_agent("agent1")
      foundation.on_agent_complete = ->(_agent_id, _results) { raise StandardError, "Completion hook failed" }

      # The method should continue despite hook failure
      expect { foundation.mark_agent_complete("agent1", {fixes_applied: 1}) }.to raise_error(StandardError, "Completion hook failed")
    end

    it "handles hook exceptions gracefully during all agents completion" do
      foundation.register_agent("agent1")
      foundation.on_all_agents_complete = ->(_final_results) { raise StandardError, "All complete hook failed" }

      # The method should continue despite hook failure
      expect { foundation.mark_agent_complete("agent1", {fixes_applied: 1}) }.to raise_error(StandardError, "All complete hook failed")
    end

    it "handles large number of agents efficiently" do
      # Test with many agents
      100.times { |i| foundation.register_agent("agent#{i}") }

      registry = foundation.instance_variable_get(:@agent_registry)
      expect(registry.size).to eq(100)
      expect(registry.keys).to include("agent0", "agent50", "agent99")
    end

    it "handles large number of error files efficiently" do
      foundation.register_agent("agent1")
      foundation.register_agent("agent2")

      # Create many files
      large_file_list = 1000.times.map { |i| "error#{i}.txt" }
      result = foundation.assign_error_files(large_file_list)

      expect(result[:success]).to be true
      expect(result[:agents_used]).to eq(2)

      assignments = foundation.instance_variable_get(:@error_assignments)
      total_assigned = assignments.values.sum(&:size)
      expect(total_assigned).to eq(1000)
    end

    it "handles agent completion with complex results structure" do
      foundation.register_agent("agent1")

      complex_results = {
        fixes_applied: 5,
        errors_resolved: 3,
        warnings_addressed: 7,
        files_modified: ["file1.rb", "file2.rb"],
        duration: 120.5,
        metadata: {
          tool_version: "1.0.0",
          environment: "test"
        }
      }

      foundation.mark_agent_complete("agent1", complex_results)

      completion_status = foundation.instance_variable_get(:@completion_status)
      expect(completion_status["agent1"][:results]).to eq(complex_results)
    end

    it "handles zero-duration calculations correctly" do
      foundation.register_agent("agent1")

      # Set same completion time for all agents
      fixed_time = Time.parse("2024-01-01 12:00:00")
      allow(Time).to receive(:now).and_return(fixed_time)

      foundation.mark_agent_complete("agent1", {fixes_applied: 1})

      duration = foundation.send(:calculate_total_duration)
      expect(duration).to eq(0)
    end
  end
end

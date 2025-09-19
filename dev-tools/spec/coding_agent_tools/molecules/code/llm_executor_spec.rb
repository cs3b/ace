# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require_relative "../../../../lib/coding_agent_tools/molecules/code/llm_executor"

RSpec.describe CodingAgentTools::Molecules::Code::LLMExecutor do
  let(:executor) { described_class.new }
  let(:mock_command_executor) { instance_double("CodingAgentTools::Organisms::System::CommandExecutor") }
  
  # Create a proper mock result class
  let(:mock_execution_result) do
    double("ExecutionResult", success?: true, stdout: "LLM response", stderr: "")
  end

  before do
    allow(CodingAgentTools::Organisms::System::CommandExecutor).to receive(:new).and_return(mock_command_executor)
  end

  describe "#initialize" do
    it "creates command executor instance" do
      expect(CodingAgentTools::Organisms::System::CommandExecutor).to receive(:new)
      described_class.new
    end
  end

  describe "#execute_query" do
    let(:model) { "google:gemini-2.0-flash-exp" }
    let(:subject_content) { "Review this code change" }
    let(:system_content) { "You are a code reviewer" }

    context "without output file" do
      it "executes llm-query command with temporary files" do
        allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)

        result = executor.execute_query(model, subject_content, system_content)

        expect(mock_command_executor).to have_received(:execute) do |*args|
          expect(args).to include("llm-query", model)
          expect(args).to include("--system")
          expect(args).to include("--timeout", "600")
          expect(args.length).to eq(7) # command, model, subject_path, --system, system_path, --timeout, timeout_value
        end
        expect(result).to eq("LLM response")
      end

      it "uses custom timeout when specified" do
        allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)

        executor.execute_query(model, subject_content, system_content, timeout: 300)

        expect(mock_command_executor).to have_received(:execute) do |*args|
          expect(args).to include("--timeout", "300")
        end
      end

      it "handles command execution failure" do
        failed_result = double("FailedResult", success?: false, stderr: "Command failed")
        allow(mock_command_executor).to receive(:execute).and_return(failed_result)

        expect {
          executor.execute_query(model, subject_content, system_content)
        }.to raise_error("LLM query failed: Command failed")
      end
    end

    context "with output file" do
      let(:output_file) { "/tmp/test_output.md" }

      it "executes llm-query command with output file" do
        allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)
        allow(File).to receive(:exist?).with(output_file).and_return(true)
        allow(File).to receive(:read).with(output_file).and_return("File content")

        result = executor.execute_query(model, subject_content, system_content, output_file: output_file)

        expect(mock_command_executor).to have_received(:execute) do |*args|
          expect(args).to include("--output", output_file)
        end
        expect(result).to eq("File content")
      end

      it "returns stdout when output file doesn't exist" do
        allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)
        allow(File).to receive(:exist?).with(output_file).and_return(false)

        result = executor.execute_query(model, subject_content, system_content, output_file: output_file)

        expect(result).to eq("LLM response")
      end
    end

    context "with temporary file handling" do
      it "creates temporary files with correct content" do
        allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)
        
        # Mock Tempfile to track file creation and content
        subject_tempfile = instance_double("Tempfile", path: "/tmp/subject-123.md")
        system_tempfile = instance_double("Tempfile", path: "/tmp/system-456.md")
        
        allow(Tempfile).to receive(:create).with(["subject-", ".md"]).and_yield(subject_tempfile)
        allow(Tempfile).to receive(:create).with(["system-", ".md"]).and_yield(system_tempfile)
        
        allow(subject_tempfile).to receive(:write).with(subject_content)
        allow(subject_tempfile).to receive(:flush)
        allow(system_tempfile).to receive(:write).with(system_content)
        allow(system_tempfile).to receive(:flush)

        executor.execute_query(model, subject_content, system_content)

        expect(subject_tempfile).to have_received(:write).with(subject_content)
        expect(subject_tempfile).to have_received(:flush)
        expect(system_tempfile).to have_received(:write).with(system_content)
        expect(system_tempfile).to have_received(:flush)
      end
    end
  end

  describe "#execute_streaming" do
    let(:model) { "google:gemini-2.0-flash-exp" }
    let(:subject_content) { "Review this code change" }
    let(:system_content) { "You are a code reviewer" }

    it "executes system command for streaming output" do
      allow(executor).to receive(:system).and_return(true)

      # Mock Tempfile creation
      subject_tempfile = instance_double("Tempfile", path: "/tmp/subject-123.md")
      system_tempfile = instance_double("Tempfile", path: "/tmp/system-456.md")
      
      allow(Tempfile).to receive(:create).with(["subject-", ".md"]).and_yield(subject_tempfile)
      allow(Tempfile).to receive(:create).with(["system-", ".md"]).and_yield(system_tempfile)
      
      allow(subject_tempfile).to receive(:write).with(subject_content)
      allow(subject_tempfile).to receive(:flush)
      allow(system_tempfile).to receive(:write).with(system_content)
      allow(system_tempfile).to receive(:flush)

      expect {
        executor.execute_streaming(model, subject_content, system_content)
      }.not_to raise_error

      expect(executor).to have_received(:system).with(
        "llm-query #{model} /tmp/subject-123.md --system /tmp/system-456.md --timeout 600"
      )
    end

    it "uses custom timeout in streaming mode" do
      allow(executor).to receive(:system).and_return(true)
      
      # Mock Tempfile creation
      subject_tempfile = instance_double("Tempfile", path: "/tmp/subject-123.md")
      system_tempfile = instance_double("Tempfile", path: "/tmp/system-456.md")
      
      allow(Tempfile).to receive(:create).with(["subject-", ".md"]).and_yield(subject_tempfile)
      allow(Tempfile).to receive(:create).with(["system-", ".md"]).and_yield(system_tempfile)
      
      allow(subject_tempfile).to receive(:write)
      allow(subject_tempfile).to receive(:flush)
      allow(system_tempfile).to receive(:write)
      allow(system_tempfile).to receive(:flush)

      executor.execute_streaming(model, subject_content, system_content, timeout: 300)

      expect(executor).to have_received(:system).with(
        include("--timeout 300")
      )
    end

    it "handles streaming command failure" do
      allow(executor).to receive(:system).and_return(false)
      
      # Mock Tempfile creation
      subject_tempfile = instance_double("Tempfile", path: "/tmp/subject-123.md")
      system_tempfile = instance_double("Tempfile", path: "/tmp/system-456.md")
      
      allow(Tempfile).to receive(:create).with(["subject-", ".md"]).and_yield(subject_tempfile)
      allow(Tempfile).to receive(:create).with(["system-", ".md"]).and_yield(system_tempfile)
      
      allow(subject_tempfile).to receive(:write)
      allow(subject_tempfile).to receive(:flush)
      allow(system_tempfile).to receive(:write)
      allow(system_tempfile).to receive(:flush)

      expect {
        executor.execute_streaming(model, subject_content, system_content)
      }.to raise_error(RuntimeError, /LLM query failed with exit code/)
    end
  end

  describe "edge cases" do
    let(:model) { "google:gemini-2.0-flash-exp" }

    it "handles empty subject content" do
      allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)

      result = executor.execute_query(model, "", "system prompt")

      expect(result).to eq("LLM response")
    end

    it "handles empty system content" do
      allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)

      result = executor.execute_query(model, "subject", "")

      expect(result).to eq("LLM response")
    end

    it "handles very long content" do
      long_content = "a" * 10000
      allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)

      result = executor.execute_query(model, long_content, "system prompt")

      expect(result).to eq("LLM response")
    end

    it "handles special characters in content" do
      special_content = "Content with\nnewlines\tand\r\nspecial chars: !@#$%^&*()"
      allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)

      result = executor.execute_query(model, special_content, "system prompt")

      expect(result).to eq("LLM response")
    end
  end

  describe "integration behavior" do
    it "maintains access to executor instance" do
      expect(executor.executor).to eq(mock_command_executor)
    end

    it "preserves command structure for llm-query compatibility" do
      allow(mock_command_executor).to receive(:execute).and_return(mock_execution_result)

      executor.execute_query("test-model", "test subject", "test system")

      expect(mock_command_executor).to have_received(:execute) do |*args|
        # Verify the command follows the expected llm-query structure
        expect(args[0]).to eq("llm-query")
        expect(args[1]).to eq("test-model")
        expect(args[2]).to be_a(String) # subject file path
        expect(args[3]).to eq("--system")
        expect(args[4]).to be_a(String) # system file path
        expect(args[5]).to eq("--timeout")
        expect(args[6]).to eq("600")
      end
    end
  end
end
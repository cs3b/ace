# frozen_string_literal: true

require "spec_helper"

# Load dependencies directly to avoid Zeitwerk issues
require_relative "../../../lib/coding_agent_tools/atoms/system_command_executor"
require_relative "../../../lib/coding_agent_tools/molecules/llm_client"

RSpec.describe CodingAgentTools::Molecules::LLMClient do
  let(:temp_dir) { Dir.mktmpdir }
  let(:input_path) { File.join(temp_dir, "input.txt") }
  let(:system_path) { File.join(temp_dir, "system.txt") }
  let(:output_path) { File.join(temp_dir, "output.txt") }
  let(:mock_command_executor) { instance_double(CodingAgentTools::Atoms::SystemCommandExecutor) }
  
  before do
    # Create test files
    File.write(input_path, "Test input content")
    File.write(system_path, "Test system prompt")
    
    # Create output directory
    FileUtils.mkdir_p(File.dirname(output_path))
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    context "with default parameters" do
      let(:client) { described_class.new }

      it "uses gflash as default model" do
        expect(client.instance_variable_get(:@model)).to eq("gflash")
      end

      it "disables debug mode by default" do
        expect(client.instance_variable_get(:@debug)).to be false
      end

      it "creates a SystemCommandExecutor instance" do
        executor = client.instance_variable_get(:@command_executor)
        expect(executor).to be_a(CodingAgentTools::Atoms::SystemCommandExecutor)
      end
    end

    context "with custom parameters" do
      let(:client) { described_class.new(model: "gpt4", debug: true) }

      it "uses custom model" do
        expect(client.instance_variable_get(:@model)).to eq("gpt4")
      end

      it "enables debug mode when requested" do
        expect(client.instance_variable_get(:@debug)).to be true
      end
    end
  end

  describe "#enhance_idea" do
    let(:client) { described_class.new(model: "test-model", debug: false) }

    before do
      # Inject mock command executor
      client.instance_variable_set(:@command_executor, mock_command_executor)
    end

    context "with valid paths" do
      context "when LLM query succeeds on first attempt" do
        before do
          # Mock successful command execution
          allow(mock_command_executor).to receive(:execute).and_return({
            success: true,
            output: "Query executed successfully",
            error: nil
          })
          
          # Mock file system operations more broadly
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(output_path).and_return(true)
          allow(File).to receive(:read).with(output_path).and_return("Enhanced content")
        end

        it "returns successful result" do
          result = client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )

          expect(result).to be_success
          expect(result.output).to eq(output_path)
          expect(result.error_message).to be_nil
          expect(result.retry_count).to eq(0)
        end

        it "executes correct llm-query command" do
          expected_command = "llm-query test-model \"#{input_path}\" --system \"#{system_path}\" --output \"#{output_path}\""
          
          expect(mock_command_executor).to receive(:execute).with(expected_command)
          
          client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )
        end
      end

      context "when LLM query succeeds after retries" do
        before do
          call_count = 0
          allow(mock_command_executor).to receive(:execute) do
            call_count += 1
            if call_count < 3
              { success: false, error: "Temporary API failure" }
            else
              { success: true, output: "Query executed successfully" }
            end
          end
          
          # Mock file system operations more broadly
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(output_path) { call_count >= 3 }
          allow(File).to receive(:read).with(output_path).and_return("Enhanced content after retries")
          
          # Mock sleep to prevent actual delays
          allow(client).to receive(:sleep)
        end

        it "retries and eventually succeeds" do
          result = client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )

          expect(result).to be_success
          expect(result.output).to eq(output_path)
          expect(result.retry_count).to eq(2)
          expect(mock_command_executor).to have_received(:execute).exactly(3).times
        end

        it "implements exponential backoff" do
          expect(client).to receive(:sleep).with(1).ordered
          expect(client).to receive(:sleep).with(3).ordered
          
          client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )
        end
      end

      context "when LLM query fails permanently" do
        before do
          allow(mock_command_executor).to receive(:execute).and_return({
            success: false,
            error: "Persistent API failure"
          })
          
          # Mock sleep to prevent actual delays
          allow(client).to receive(:sleep)
        end

        it "fails after maximum retries" do
          result = client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )

          expect(result).not_to be_success
          expect(result.output).to be_nil
          expect(result.error_message).to include("LLM enhancement failed after 4 attempts")
          expect(result.error_message).to include("Persistent API failure")
          expect(result.retry_count).to eq(3)
          expect(mock_command_executor).to have_received(:execute).exactly(4).times
        end
      end

      context "when command raises exception" do
        before do
          call_count = 0
          allow(mock_command_executor).to receive(:execute) do
            call_count += 1
            if call_count == 1
              raise StandardError, "Network connection failed"
            else
              { success: true, output: "Recovery successful" }
            end
          end
          
          # Mock output file creation on recovery
          allow(File).to receive(:exist?) do |path|
            if path == output_path && call_count > 1
              true
            elsif [input_path, system_path].include?(path)
              true
            elsif path == File.dirname(output_path)
              true
            else
              false
            end
          end
          
          allow(File).to receive(:read).with(output_path).and_return("Recovered content")
          allow(client).to receive(:sleep)
        end

        it "handles exceptions and retries" do
          result = client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )

          expect(result).to be_success
          expect(result.retry_count).to eq(1)
          expect(mock_command_executor).to have_received(:execute).exactly(2).times
        end
      end

      context "when output file is empty" do
        before do
          allow(mock_command_executor).to receive(:execute).and_return({
            success: true,
            output: "Command succeeded"
          })
          
          # Mock file system operations more broadly
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(output_path).and_return(true)
          allow(File).to receive(:read).with(output_path).and_return("   \n\t  ")
          allow(client).to receive(:sleep)
        end

        it "treats empty output as failure and retries" do
          call_count = 0
          allow(File).to receive(:read).with(output_path) do
            call_count += 1
            call_count < 3 ? "   \n\t  " : "Valid content"
          end

          result = client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )

          expect(result).to be_success
          expect(result.retry_count).to eq(2)
        end
      end

      context "when output file is not created" do
        before do
          allow(mock_command_executor).to receive(:execute).and_return({
            success: true,
            output: "Command succeeded"
          })
          
          # Mock file system operations more broadly
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with(output_path).and_return(false)
          allow(client).to receive(:sleep)
        end

        it "treats missing output file as failure" do
          result = client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )

          expect(result).not_to be_success
          expect(result.error_message).to include("LLM enhancement failed after 4 attempts")
        end
      end
    end

    context "with invalid paths" do
      it "raises ArgumentError when input file does not exist" do
        expect {
          client.enhance_idea(
            input_path: "/nonexistent/input.txt",
            system_path: system_path,
            output_path: output_path
          )
        }.to raise_error(ArgumentError, /Input file not found/)
      end

      it "raises ArgumentError when system file does not exist" do
        expect {
          client.enhance_idea(
            input_path: input_path,
            system_path: "/nonexistent/system.txt",
            output_path: output_path
          )
        }.to raise_error(ArgumentError, /System prompt file not found/)
      end

      it "raises ArgumentError when output directory does not exist" do
        expect {
          client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: "/nonexistent/dir/output.txt"
          )
        }.to raise_error(ArgumentError, /Output directory not found/)
      end
    end

    context "with different model providers" do
      let(:models_and_commands) do
        {
          "gflash" => "llm-query gflash",
          "gpt4" => "llm-query gpt4",
          "claude" => "llm-query claude",
          "custom-model" => "llm-query custom-model"
        }
      end

      before do
        allow(mock_command_executor).to receive(:execute).and_return({
          success: true,
          output: "Success"
        })
        
        # Mock file system operations more broadly
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(output_path).and_return(true)
        allow(File).to receive(:read).with(output_path).and_return("Model response")
      end

      it "uses correct command for each model" do
        models_and_commands.each do |model, expected_command_start|
          test_client = described_class.new(model: model)
          test_client.instance_variable_set(:@command_executor, mock_command_executor)
          
          expect(mock_command_executor).to receive(:execute) do |command|
            expect(command).to start_with(expected_command_start)
            { success: true, output: "Success" }
          end
          
          test_client.enhance_idea(
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )
        end
      end
    end

    context "with debug mode enabled" do
      let(:client) { described_class.new(debug: true) }

      before do
        client.instance_variable_set(:@command_executor, mock_command_executor)
        
        allow(mock_command_executor).to receive(:execute).and_return({
          success: true,
          output: "Success"
        })
        
        # Mock file system operations more broadly
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(output_path).and_return(true)
        allow(File).to receive(:read).with(output_path).and_return("Debug response")
      end

      it "outputs debug messages" do
        expect(client).to receive(:puts).with(/Debug: LLM enhancement attempt 1\/4/)
        expect(client).to receive(:puts).with(/Debug: Executing:/)
        expect(client).to receive(:puts).with(/Debug: LLM enhancement successful/)
        
        client.enhance_idea(
          input_path: input_path,
          system_path: system_path,
          output_path: output_path
        )
      end
    end

    context "with paths containing special characters" do
      let(:special_input_path) { File.join(temp_dir, "input with spaces & special chars.txt") }
      let(:special_system_path) { File.join(temp_dir, "system \"quoted\" path.txt") }
      let(:special_output_path) { File.join(temp_dir, "output's path.txt") }

      before do
        File.write(special_input_path, "Special input")
        File.write(special_system_path, "Special system")
        
        allow(mock_command_executor).to receive(:execute).and_return({
          success: true,
          output: "Success"
        })
        
        # Mock file system operations more broadly
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(special_output_path).and_return(true)
        allow(File).to receive(:read).with(special_output_path).and_return("Special response")
      end

      it "properly escapes paths in shell commands" do
        expect(mock_command_executor).to receive(:execute) do |command|
          expect(command).to include("\"#{special_input_path}\"")
          expect(command).to include("\"#{special_system_path.gsub('"', '\\"')}\"")
          expect(command).to include("\"#{special_output_path}\"")
          { success: true, output: "Success" }
        end
        
        client.enhance_idea(
          input_path: special_input_path,
          system_path: special_system_path,
          output_path: special_output_path
        )
      end
    end
  end

  describe "LLMResult struct" do
    it "provides success? predicate method" do
      success_result = described_class::LLMResult.new(true, "output", nil, 0)
      failure_result = described_class::LLMResult.new(false, nil, "error", 2)

      expect(success_result).to be_success
      expect(failure_result).not_to be_success
    end

    it "stores all result data" do
      result = described_class::LLMResult.new(true, "/path/to/output", nil, 1)

      expect(result.success).to be true
      expect(result.output).to eq("/path/to/output")
      expect(result.error_message).to be_nil
      expect(result.retry_count).to eq(1)
    end
  end

  describe "constants" do
    it "defines correct retry configuration" do
      expect(described_class::MAX_RETRIES).to eq(3)
      expect(described_class::RETRY_DELAYS).to eq([1, 3, 9])
    end
  end

  describe "error handling and degraded functionality" do
    let(:client) { described_class.new }

    before do
      client.instance_variable_set(:@command_executor, mock_command_executor)
    end

    context "when llm-query command is not available" do
      before do
        allow(mock_command_executor).to receive(:execute).and_return({
          success: false,
          error: "llm-query: command not found"
        })
        
        allow(client).to receive(:sleep)
      end

      it "reports command unavailability in error message" do
        result = client.enhance_idea(
          input_path: input_path,
          system_path: system_path,
          output_path: output_path
        )

        expect(result).not_to be_success
        expect(result.error_message).to include("command not found")
      end
    end

    context "when API credentials are missing" do
      before do
        allow(mock_command_executor).to receive(:execute).and_return({
          success: false,
          error: "API key not configured"
        })
        
        allow(client).to receive(:sleep)
      end

      it "reports credential issues" do
        result = client.enhance_idea(
          input_path: input_path,
          system_path: system_path,
          output_path: output_path
        )

        expect(result).not_to be_success
        expect(result.error_message).to include("API key not configured")
      end
    end

    context "when network is unavailable" do
      before do
        call_count = 0
        allow(mock_command_executor).to receive(:execute) do
          call_count += 1
          case call_count
          when 1, 2
            { success: false, error: "Network unreachable" }
          when 3
            { success: false, error: "Connection timeout" }
          else
            { success: false, error: "Host unreachable" }
          end
        end
        
        allow(client).to receive(:sleep)
      end

      it "attempts retries for network issues" do
        result = client.enhance_idea(
          input_path: input_path,
          system_path: system_path,
          output_path: output_path
        )

        expect(result).not_to be_success
        expect(result.retry_count).to eq(3)
        expect(mock_command_executor).to have_received(:execute).exactly(4).times
      end
    end
  end

  describe "fallback behavior" do
    let(:client) { described_class.new }

    before do
      client.instance_variable_set(:@command_executor, mock_command_executor)
    end

    context "when primary model fails" do
      it "continues with the same model (no automatic fallback)" do
        # The current implementation doesn't include automatic model fallback
        # This test documents current behavior and can be updated if fallback is added
        
        allow(mock_command_executor).to receive(:execute).and_return({
          success: false,
          error: "Model unavailable"
        })
        
        allow(client).to receive(:sleep)

        result = client.enhance_idea(
          input_path: input_path,
          system_path: system_path,
          output_path: output_path
        )

        expect(result).not_to be_success
        expect(mock_command_executor).to have_received(:execute).exactly(4).times
        
        # All calls should use the same model
        expect(mock_command_executor).to have_received(:execute).exactly(4).times do |command|
          expect(command).to include("gflash")  # Default model
        end
      end
    end
  end

  describe "integration scenarios" do
    context "with real file system operations" do
      let(:client) { described_class.new(debug: false) }

      before do
        # Use real SystemCommandExecutor but mock the actual command
        real_executor = CodingAgentTools::Atoms::SystemCommandExecutor.new
        client.instance_variable_set(:@command_executor, real_executor)
        
        # Mock the system call to prevent actual llm-query execution
        allow(Open3).to receive(:popen3) do |command, &block|
          # Simulate successful command execution
          mock_stdin = double("stdin", close: nil)
          mock_stdout = double("stdout", read: "Mocked LLM response")
          mock_stderr = double("stderr", read: "")
          mock_wait_thr = double("wait_thr", value: double("process_status", exitstatus: 0))
          
          # Create the output file to simulate real behavior
          File.write(output_path, "Mocked enhanced content")
          
          block.call(mock_stdin, mock_stdout, mock_stderr, mock_wait_thr)
        end
      end

      it "performs end-to-end enhancement workflow" do
        result = client.enhance_idea(
          input_path: input_path,
          system_path: system_path,
          output_path: output_path
        )

        expect(result).to be_success
        expect(result.output).to eq(output_path)
        expect(File.exist?(output_path)).to be true
        expect(File.read(output_path)).to eq("Mocked enhanced content")
      end
    end
  end
end
# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/idea_capture"
require "tempfile"
require "fileutils"

RSpec.describe CodingAgentTools::Organisms::IdeaCapture do
  let(:temp_dir) { Dir.mktmpdir("idea_capture_test") }
  let(:debug) { false }
  let(:big_user_input_allowed) { false }
  let(:model) { "gflash" }
  
  # Mock molecule dependencies
  let(:mock_context_loader) { instance_double(CodingAgentTools::Molecules::ContextLoader) }
  let(:mock_idea_enhancer) { instance_double(CodingAgentTools::Molecules::IdeaEnhancer) }
  let(:mock_path_resolver) { instance_double(CodingAgentTools::Molecules::PathResolver) }
  let(:mock_llm_client) { instance_double(CodingAgentTools::Molecules::LLMClient) }

  subject do
    described_class.new(
      model: model,
      debug: debug,
      big_user_input_allowed: big_user_input_allowed
    )
  end

  before do
    # Mock molecule initialization
    allow(CodingAgentTools::Molecules::ContextLoader).to receive(:new).and_return(mock_context_loader)
    allow(CodingAgentTools::Molecules::IdeaEnhancer).to receive(:new).and_return(mock_idea_enhancer)
    allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)
    allow(CodingAgentTools::Molecules::LLMClient).to receive(:new).and_return(mock_llm_client)
    
    # Add default stubs for File operations to handle unexpected calls
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:write).and_call_original
    allow(FileUtils).to receive(:mkdir_p).and_call_original
    
    # Add default stubs for molecule methods
    allow(mock_context_loader).to receive(:load_docs_context).and_return({success: true, context: ""})
    allow(mock_path_resolver).to receive(:generate_capture_idea_paths).and_return({
      success: true,
      input_path: File.join(temp_dir, "idea-input.md"),
      system_path: File.join(temp_dir, "system.prompt.md"),
      output_path: File.join(temp_dir, "enhanced-idea.md")
    })
    allow(mock_llm_client).to receive(:enhance_idea).and_return(double(success?: true, error: nil))
    allow(mock_idea_enhancer).to receive(:validate_idea_content).and_return({valid: true})
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    context "with default parameters" do
      subject { described_class.new }

      it "initializes with default model" do
        expect(subject.instance_variable_get(:@model)).to eq("google:gemini-2.5-flash-lite")
      end

      it "initializes with debug disabled" do
        expect(subject.instance_variable_get(:@debug)).to be false
      end

      it "initializes with big input disabled by default" do
        expect(subject.instance_variable_get(:@big_user_input_allowed)).to be false
      end

      it "sets max input size to BIG_INPUT_THRESHOLD when big input is disabled" do
        expect(subject.instance_variable_get(:@max_input_size)).to eq(described_class::BIG_INPUT_THRESHOLD)
      end
    end

    context "with custom parameters" do
      let(:model) { "claude" }
      let(:debug) { true }
      let(:big_user_input_allowed) { true }

      it "initializes with custom model" do
        expect(subject.instance_variable_get(:@model)).to eq("claude")
      end

      it "initializes with debug enabled" do
        expect(subject.instance_variable_get(:@debug)).to be true
      end

      it "initializes with big input allowed" do
        expect(subject.instance_variable_get(:@big_user_input_allowed)).to be true
      end

      it "sets max input size to infinity when big input is allowed" do
        expect(subject.instance_variable_get(:@max_input_size)).to eq(Float::INFINITY)
      end
    end

    it "initializes molecule dependencies correctly" do
      # Create an instance to trigger the constructor calls
      described_class.new
      
      expect(CodingAgentTools::Molecules::ContextLoader).to have_received(:new)
      expect(CodingAgentTools::Molecules::IdeaEnhancer).to have_received(:new)
      expect(CodingAgentTools::Molecules::PathResolver).to have_received(:new)
      expect(CodingAgentTools::Molecules::LLMClient).to have_received(:new).with(model: "google:gemini-2.5-flash-lite", debug: false)
    end
  end

  describe "#capture_idea" do
    let(:idea_text) { "This is a great idea for improving the workflow" }
    let(:input_path) { File.join(temp_dir, "idea-input.md") }
    let(:system_path) { File.join(temp_dir, "system-prompt.md") }
    let(:output_path) { File.join(temp_dir, "enhanced-idea.md") }
    
    let(:path_generation_result) do
      {
        success: true,
        input_path: input_path,
        system_path: system_path,
        output_path: output_path
      }
    end

    let(:context_result) do
      {
        success: true,
        context: "Project context information",
        files_loaded: 3,
        files_failed: 0
      }
    end

    let(:llm_result) do
      instance_double(CodingAgentTools::Molecules::LLMClient::LLMResult, success?: true, error_message: nil)
    end

    before do
      # Create temp directories
      FileUtils.mkdir_p(temp_dir)
      FileUtils.mkdir_p(File.dirname(input_path))
      FileUtils.mkdir_p(File.dirname(output_path))

      # Mock successful path generation
      allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
        .with(idea_text)
        .and_return(path_generation_result)

      # Mock successful context loading
      allow(mock_context_loader).to receive(:load_docs_context)
        .and_return(context_result)

      # Mock successful system prompt template loading
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(anything).and_return(true)
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(anything).and_return("System prompt template")
      allow(File).to receive(:write).and_call_original

      # Mock successful LLM enhancement
      allow(mock_llm_client).to receive(:enhance_idea)
        .with(input_path: input_path, system_path: system_path, output_path: output_path)
        .and_return(llm_result)
    end

    context "with valid input" do
      it "returns successful result" do
        result = subject.capture_idea(idea_text)

        expect(result).to be_a(described_class::CaptureResult)
        expect(result.success?).to be true
        expect(result.output_path).to eq(output_path)
        expect(result.error_message).to be_nil
      end

      it "generates paths using path resolver" do
        subject.capture_idea(idea_text)

        expect(mock_path_resolver).to have_received(:generate_capture_idea_paths).with(idea_text)
      end

      it "saves raw idea to input file" do
        expect(File).to receive(:write).with(input_path, idea_text.strip)

        subject.capture_idea(idea_text)
      end

      it "loads project context" do
        subject.capture_idea(idea_text)

        expect(mock_context_loader).to have_received(:load_docs_context)
      end

      it "enhances idea using LLM client" do
        subject.capture_idea(idea_text)

        expect(mock_llm_client).to have_received(:enhance_idea).with(
          input_path: input_path,
          system_path: system_path,
          output_path: output_path
        )
      end

      context "with debug enabled" do
        let(:debug) { true }

        it "includes debug information in result" do
          result = subject.capture_idea(idea_text)

          expect(result.debug_info).to eq("Enhancement completed")
        end

        it "outputs debug messages" do
          expect(subject).to receive(:puts).with("Debug: Starting idea capture process")
          expect(subject).to receive(:puts).with(/Debug: Generated paths:/)
          expect(subject).to receive(:puts).with(/Debug: Saved raw idea to:/)
          expect(subject).to receive(:puts).with(/Debug: Context loading result:/)
          expect(subject).to receive(:puts).with(/Debug: Generated system prompt:/)
          expect(subject).to receive(:puts).with("Debug: Idea enhancement completed successfully")

          subject.capture_idea(idea_text)
        end
      end
    end

    context "input validation" do
      context "with nil input" do
        it "returns failure result" do
          result = subject.capture_idea(nil)

          expect(result.success?).to be false
          expect(result.error_message).to eq("Idea text cannot be nil")
        end
      end

      context "with empty input" do
        it "returns failure result" do
          result = subject.capture_idea("   ")

          expect(result.success?).to be false
          expect(result.error_message).to eq("Idea text cannot be empty")
        end
      end

      context "with input too short" do
        it "returns failure result" do
          result = subject.capture_idea("Hi")

          expect(result.success?).to be false
          expect(result.error_message).to eq("Idea text must be at least 5 characters")
        end
      end

      context "with input too large" do
        let(:large_input) { "a" * (described_class::BIG_INPUT_THRESHOLD + 1000) }

        context "when big input is not allowed" do
          it "returns failure result with size information" do
            result = subject.capture_idea(large_input)

            expect(result.success?).to be false
            expect(result.error_message).to include("Input too large:")
            expect(result.error_message).to include("KB")
            expect(result.error_message).to include("words")
            expect(result.error_message).to include("Use --big-user-input-allowed to proceed")
          end
        end

        context "when big input is allowed" do
          let(:big_user_input_allowed) { true }

          it "accepts large input" do
            # Mock the path resolver to handle large input specifically
            allow(mock_path_resolver).to receive(:generate_capture_idea_paths).with(large_input).and_return({
              success: true,
              input_path: File.join(temp_dir, "idea-input.md"),
              system_path: File.join(temp_dir, "system.prompt.md"),
              output_path: File.join(temp_dir, "enhanced-idea.md")
            })
            
            result = subject.capture_idea(large_input)

            expect(result.success?).to be true
          end
        end
      end
    end

    context "path generation failures" do
      before do
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(success: false, error: "Path generation failed")
      end

      it "returns failure result" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be false
        expect(result.error_message).to eq("Path generation failed: Path generation failed")
      end
    end

    context "file save failures" do
      before do
        allow(File).to receive(:write).with(input_path, anything).and_raise(Errno::EACCES, "Permission denied")
      end

      it "returns failure result" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be false
        expect(result.error_message).to include("Failed to save raw idea:")
      end
    end

    context "context loading failures" do
      before do
        allow(mock_context_loader).to receive(:load_docs_context)
          .and_return(success: false, error: "Context loading failed")
      end

      it "continues with system prompt generation" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
      end
    end

    context "system prompt generation failures" do
      before do
        allow(File).to receive(:exist?).with(anything).and_return(false)
      end

      it "returns failure result" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be false
        expect(result.error_message).to include("System prompt template not found:")
      end
    end

    context "LLM enhancement failures" do
      let(:failed_llm_result) do
        instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: false,
          error_message: "LLM service unavailable"
        )
      end

      before do
        allow(mock_llm_client).to receive(:enhance_idea)
          .and_return(failed_llm_result)
      end

      it "saves fallback idea with error information" do
        expected_content = "# Raw Idea (Enhanced Version Failed)\n\n"
        expected_content += "**Enhancement Error:** LLM service unavailable\n\n"
        expected_content += "## Original Idea\n\n#{idea_text.strip}"

        expect(File).to receive(:write).with(output_path, expected_content)

        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        expect(result.output_path).to eq(output_path)
        expect(result.debug_info).to eq("Saved raw idea due to enhancement failure")
      end

      context "when fallback save also fails" do
        before do
          allow(File).to receive(:write).with(output_path, anything).and_raise(Errno::ENOSPC, "No space left")
        end

        it "returns failure result" do
          result = subject.capture_idea(idea_text)

          expect(result.success?).to be false
          expect(result.error_message).to include("Failed to save fallback idea:")
        end
      end
    end

    context "unexpected errors during capture" do
      before do
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_raise(StandardError, "Unexpected system error")
      end

      it "returns failure result with error details" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be false
        expect(result.error_message).to include("Unexpected error during idea capture: Unexpected system error")
      end

      context "with debug enabled" do
        let(:debug) { true }

        it "includes backtrace in debug details" do
          result = subject.capture_idea(idea_text)

          expect(result.debug_info).to be_a(String)
          expect(result.debug_info).to include("spec/coding_agent_tools/organisms/idea_capture_spec.rb")
        end
      end
    end
  end

  describe "system prompt generation" do
    let(:project_root) { File.expand_path("../../../../../", __FILE__) }
    let(:template_path) { File.join(project_root, "dev-handbook/templates/idea-manager/system.prompt.md") }
    let(:idea_template_path) { File.join(project_root, "dev-handbook/templates/idea-manager/idea.template.md") }
    let(:system_path) { File.join(temp_dir, "system.md") }
    
    let(:context_result) do
      {
        success: true,
        context: "Project context information"
      }
    end

    let(:system_template) { "System prompt template content" }
    let(:idea_template) { "Idea template content" }

    before do
      FileUtils.mkdir_p(temp_dir)
    end

    context "with successful template loading" do
      before do
        allow(File).to receive(:exist?).with(template_path).and_return(true)
        allow(File).to receive(:exist?).with(idea_template_path).and_return(true)
        allow(File).to receive(:read).with(template_path).and_return(system_template)
        allow(File).to receive(:read).with(idea_template_path).and_return(idea_template)
        allow(File).to receive(:write).and_call_original
      end

      it "generates system prompt with project context" do
        expected_content = system_template
        expected_content += "\n\n## Project Context\n\n"
        expected_content += context_result[:context]
        expected_content += "\n\n## Template Format\n\nUse this exact template format:\n\n```markdown\n"
        expected_content += idea_template
        expected_content += "\n```"

        expect(File).to receive(:write).with(system_path, expected_content)

        result = subject.send(:generate_system_prompt, context_result, system_path)
        expect(result.success?).to be true
      end

      context "without project context" do
        let(:context_result) { { success: false, error: "No context" } }

        it "generates system prompt without context section" do
          expected_content = system_template
          expected_content += "\n\n## Template Format\n\nUse this exact template format:\n\n```markdown\n"
          expected_content += idea_template
          expected_content += "\n```"

          expect(File).to receive(:write).with(system_path, expected_content)

          result = subject.send(:generate_system_prompt, context_result, system_path)
          expect(result.success?).to be true
        end
      end

      context "without idea template" do
        before do
          allow(File).to receive(:exist?).with(idea_template_path).and_return(false)
        end

        it "generates system prompt without template format section" do
          expected_content = system_template
          expected_content += "\n\n## Project Context\n\n"
          expected_content += context_result[:context]

          expect(File).to receive(:write).with(system_path, expected_content)

          result = subject.send(:generate_system_prompt, context_result, system_path)
          expect(result.success?).to be true
        end
      end
    end

    context "with missing system template" do
      before do
        allow(File).to receive(:exist?).with(template_path).and_return(false)
      end

      it "returns failure result" do
        result = subject.send(:generate_system_prompt, context_result, system_path)

        expect(result.success?).to be false
        expect(result.error_message).to include("System prompt template not found:")
      end
    end

    context "with file write error" do
      before do
        allow(File).to receive(:exist?).with(template_path).and_return(true)
        allow(File).to receive(:read).with(template_path).and_return(system_template)
        allow(File).to receive(:write).with(system_path, anything).and_raise(Errno::EACCES, "Permission denied")
      end

      it "returns failure result" do
        result = subject.send(:generate_system_prompt, context_result, system_path)

        expect(result.success?).to be false
        expect(result.error_message).to include("Failed to generate system prompt:")
      end
    end
  end

  describe "minimum guarantee functionality" do
    let(:idea_text) { "Important idea that must be saved" }
    let(:output_path) { File.join(temp_dir, "saved-idea.md") }

    before do
      FileUtils.mkdir_p(temp_dir)
    end

    context "when all enhancement steps fail" do
      before do
        # Mock path generation to succeed but everything else to fail
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(
            success: true,
            input_path: File.join(temp_dir, "input.md"),
            system_path: File.join(temp_dir, "system.md"),
            output_path: output_path
          )
        
        # Mock raw idea save to succeed
        allow(File).to receive(:write).and_call_original
        
        # Mock system prompt generation to fail
        allow(File).to receive(:exist?).and_return(false)
      end

      it "still tries to capture the core idea" do
        result = subject.capture_idea(idea_text)

        # Should fail due to system prompt template not found, but raw idea should be saved
        expect(result.success?).to be false
        expect(File).to have_received(:write).with(anything, idea_text.strip)
      end
    end

    context "when LLM enhancement fails but fallback save succeeds" do
      let(:input_path) { File.join(temp_dir, "input.md") }
      let(:system_path) { File.join(temp_dir, "system.md") }

      before do
        # Mock all steps to succeed except LLM enhancement
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(
            success: true,
            input_path: input_path,
            system_path: system_path,
            output_path: output_path
          )

        allow(mock_context_loader).to receive(:load_docs_context)
          .and_return(success: true, context: "Context")

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return("template")
        allow(File).to receive(:write).and_call_original

        # Mock LLM to fail
        failed_llm_result = instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: false,
          error_message: "Service unavailable"
        )
        allow(mock_llm_client).to receive(:enhance_idea).and_return(failed_llm_result)
      end

      it "saves raw idea as fallback ensuring minimum guarantee" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        expect(result.output_path).to eq(output_path)
        
        # Verify fallback content structure
        expect(File).to have_received(:write).with(
          output_path,
          "# Raw Idea (Enhanced Version Failed)\n\n**Enhancement Error:** Service unavailable\n\n## Original Idea\n\n#{idea_text.strip}"
        )
      end
    end
  end

  describe "CaptureResult struct" do
    it "has success? predicate method" do
      success_result = described_class::CaptureResult.new(true, "/path", nil, nil)
      failure_result = described_class::CaptureResult.new(false, nil, "error", nil)

      expect(success_result.success?).to be true
      expect(failure_result.success?).to be false
    end

    it "provides access to all result fields" do
      result = described_class::CaptureResult.new(
        true,
        "/output/path",
        nil,
        "debug info"
      )

      expect(result.success).to be true
      expect(result.output_path).to eq("/output/path")
      expect(result.error_message).to be_nil
      expect(result.debug_info).to eq("debug info")
    end
  end

  describe "constants" do
    it "defines expected constants" do
      expect(described_class::DEFAULT_MAX_INPUT_SIZE).to eq(7000)
      expect(described_class::BIG_INPUT_THRESHOLD).to eq(7000)
    end
  end

  describe "orchestration behavior" do
    let(:idea_text) { "Test orchestration of all components" }

    context "with successful complete workflow" do
      before do
        # Setup complete successful mock chain
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(
            success: true,
            input_path: File.join(temp_dir, "input.md"),
            system_path: File.join(temp_dir, "system.md"),
            output_path: File.join(temp_dir, "output.md")
          )

        allow(mock_context_loader).to receive(:load_docs_context)
          .and_return(success: true, context: "Context")

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return("template")
        allow(File).to receive(:write).and_call_original

        success_llm_result = instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: true
        )
        allow(mock_llm_client).to receive(:enhance_idea).and_return(success_llm_result)

        FileUtils.mkdir_p(temp_dir)
      end

      it "orchestrates all molecules in correct sequence" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        
        # Verify orchestration sequence
        expect(mock_path_resolver).to have_received(:generate_capture_idea_paths).ordered
        expect(mock_context_loader).to have_received(:load_docs_context).ordered
        expect(mock_llm_client).to have_received(:enhance_idea).ordered
      end
    end

    context "with degraded functionality" do
      before do
        # Setup partial failure scenario
        allow(mock_path_resolver).to receive(:generate_capture_idea_paths)
          .and_return(
            success: true,
            input_path: File.join(temp_dir, "input.md"),
            system_path: File.join(temp_dir, "system.md"),
            output_path: File.join(temp_dir, "output.md")
          )

        # Context loading fails, but system prompt generation succeeds
        allow(mock_context_loader).to receive(:load_docs_context)
          .and_return(success: false, error: "Context unavailable")

        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:read).and_return("template")
        allow(File).to receive(:write).and_call_original

        success_llm_result = instance_double(
          CodingAgentTools::Molecules::LLMClient::LLMResult,
          success?: true
        )
        allow(mock_llm_client).to receive(:enhance_idea).and_return(success_llm_result)

        FileUtils.mkdir_p(temp_dir)
      end

      it "continues processing with degraded functionality" do
        result = subject.capture_idea(idea_text)

        expect(result.success?).to be true
        expect(mock_context_loader).to have_received(:load_docs_context)
        expect(mock_llm_client).to have_received(:enhance_idea)
      end
    end
  end
end
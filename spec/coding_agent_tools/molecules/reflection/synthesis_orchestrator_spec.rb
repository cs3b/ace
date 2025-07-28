# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "ostruct"

RSpec.describe CodingAgentTools::Molecules::Reflection::SynthesisOrchestrator do
  let(:orchestrator) { described_class.new }
  let(:mock_prompt_processor) { instance_double(CodingAgentTools::Organisms::PromptProcessor) }
  let(:temp_dir) { Dir.mktmpdir }
  let(:output_path) { File.join(temp_dir, "synthesis.md") }
  let(:system_prompt_path) { File.join(temp_dir, "system_prompt.txt") }

  before do
    allow(CodingAgentTools::Organisms::PromptProcessor).to receive(:new).and_return(mock_prompt_processor)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "initializes with a prompt processor" do
      expect(CodingAgentTools::Organisms::PromptProcessor).to receive(:new)
      described_class.new
    end
  end

  describe "#synthesize_reflections" do
    let(:reflections) { [reflection_file1, reflection_file2] }
    let(:reflection_file1) { File.join(temp_dir, "reflection1.md") }
    let(:reflection_file2) { File.join(temp_dir, "reflection2.md") }
    let(:timestamp_info) { OpenStruct.new(valid?: true, from_date: "2024-01-01", to_date: "2024-01-31", days_covered: 30) }
    let(:model) { "test-model" }
    let(:format) { "markdown" }
    let(:force) { false }
    let(:debug) { false }

    let(:base_params) do
      {
        reflections: reflections,
        timestamp_info: timestamp_info,
        model: model,
        output_path: output_path,
        format: format,
        system_prompt_path: system_prompt_path,
        force: force,
        debug: debug
      }
    end

    before do
      # Create test reflection files
      File.write(reflection_file1, "# Reflection 1\n\nThis is the first reflection.")
      File.write(reflection_file2, "# Reflection 2\n\nThis is the second reflection.")
      
      # Create system prompt file (unless nil)
      if system_prompt_path
        File.write(system_prompt_path, "You are a helpful assistant.")
      end
    end

    context "with valid inputs" do
      it "successfully synthesizes reflections" do
        result = orchestrator.synthesize_reflections(**base_params)

        expect(result.success?).to be true
        expect(result.data[:output_path]).to eq(output_path)
        expect(result.data[:metrics][:reflections_count]).to eq(2)
        expect(result.data[:metrics][:execution_time]).to be >= 0
        expect(result.data[:synthesis_result]).to include("Reflection Synthesis")
        
        # Check that output file was created
        expect(File.exist?(output_path)).to be true
      end

      it "includes correct metrics in the result" do
        result = orchestrator.synthesize_reflections(**base_params)

        metrics = result.data[:metrics]
        expect(metrics[:reflections_count]).to eq(2)
        expect(metrics[:execution_time]).to be_a(Float)
        expect(metrics[:output_tokens]).to eq(100)
        expect(metrics[:cost]).to eq(0.01)
      end

      it "writes synthesis content to output file" do
        orchestrator.synthesize_reflections(**base_params)

        content = File.read(output_path)
        expect(content).to include("# Reflection Synthesis")
        expect(content).to include("Synthesis of 2 reflection notes")
      end
    end

    context "when output file already exists" do
      before do
        File.write(output_path, "Existing content")
      end

      context "without force flag" do
        it "returns failure result" do
          result = orchestrator.synthesize_reflections(**base_params)

          expect(result.success?).to be false
          expect(result.error).to include("Output file already exists")
          expect(result.error).to include("Use --force to overwrite")
        end

        it "does not overwrite existing file" do
          orchestrator.synthesize_reflections(**base_params)

          content = File.read(output_path)
          expect(content).to eq("Existing content")
        end
      end

      context "with force flag" do
        let(:force) { true }

        it "overwrites existing file successfully" do
          result = orchestrator.synthesize_reflections(**base_params)

          expect(result.success?).to be true
          content = File.read(output_path)
          expect(content).to include("# Reflection Synthesis")
        end
      end
    end

    context "when system prompt file is missing" do
      before do
        File.delete(system_prompt_path)
      end

      it "returns failure result" do
        result = orchestrator.synthesize_reflections(**base_params)

        expect(result.success?).to be false
        expect(result.error).to include("Could not load system prompt")
      end
    end

    context "when system prompt path is nil" do
      let(:system_prompt_path) { nil }
      let(:base_params_no_prompt) do
        {
          reflections: reflections,
          timestamp_info: timestamp_info,
          model: model,
          output_path: output_path,
          format: format,
          system_prompt_path: system_prompt_path,
          force: force,
          debug: debug
        }
      end

      it "returns failure result" do
        result = orchestrator.synthesize_reflections(**base_params_no_prompt)

        expect(result.success?).to be false
        expect(result.error).to include("Could not load system prompt")
      end
    end

    context "when output directory does not exist" do
      let(:output_path) { "/nonexistent/directory/output.md" }

      it "returns failure result" do
        result = orchestrator.synthesize_reflections(**base_params)

        expect(result.success?).to be false
        expect(result.error).to include("Could not write output file")
      end
    end

    context "when output path is not writable" do
      let(:output_path) { "/root/synthesis.md" }

      it "returns failure result" do
        result = orchestrator.synthesize_reflections(**base_params)

        expect(result.success?).to be false
        expect(result.error).to include("Could not write output file")
      end
    end

    context "with empty reflections array" do
      let(:reflections) { [] }

      it "processes successfully with zero reflections" do
        result = orchestrator.synthesize_reflections(**base_params)

        expect(result.success?).to be true
        expect(result.data[:metrics][:reflections_count]).to eq(0)
      end
    end

    context "with invalid timestamp info" do
      let(:timestamp_info) { OpenStruct.new(valid?: false) }

      it "still processes successfully without timestamp details" do
        result = orchestrator.synthesize_reflections(**base_params)

        expect(result.success?).to be true
        content = File.read(output_path)
        expect(content).not_to include("Analysis Period")
      end
    end

    context "with many reflections" do
      let(:reflections) { (1..10).map { |i| File.join(temp_dir, "reflection#{i}.md") } }

      before do
        reflections.each_with_index do |file, index|
          File.write(file, "# Reflection #{index + 1}\n\nContent for reflection #{index + 1}.")
        end
      end

      it "processes all reflections correctly" do
        result = orchestrator.synthesize_reflections(**base_params)

        expect(result.success?).to be true
        expect(result.data[:metrics][:reflections_count]).to eq(10)
        
        content = File.read(output_path)
        expect(content).to include("Synthesis of 10 reflection notes")
      end
    end
  end

  describe "private methods" do
    describe "#load_system_prompt" do
      context "when file exists and is readable" do
        let(:prompt_content) { "You are a helpful assistant for reflection synthesis." }

        before do
          File.write(system_prompt_path, prompt_content)
        end

        it "loads the system prompt content" do
          result = orchestrator.send(:load_system_prompt, system_prompt_path)
          expect(result).to eq(prompt_content)
        end
      end

      context "when file does not exist" do
        it "returns nil" do
          result = orchestrator.send(:load_system_prompt, "/nonexistent/prompt.txt")
          expect(result).to be_nil
        end
      end

      context "when path is nil" do
        it "returns nil" do
          result = orchestrator.send(:load_system_prompt, nil)
          expect(result).to be_nil
        end
      end

      context "when file exists but is not readable" do
        before do
          File.write(system_prompt_path, "content")
          allow(File).to receive(:read).with(system_prompt_path, encoding: "utf-8").and_raise(Errno::EACCES, "Permission denied")
        end

        it "returns nil and handles the error gracefully" do
          result = orchestrator.send(:load_system_prompt, system_prompt_path)
          expect(result).to be_nil
        end
      end

      context "with different encodings" do
        it "reads file with UTF-8 encoding" do
          File.write(system_prompt_path, "test content")
          expect(File).to receive(:read).with(system_prompt_path, encoding: "utf-8").and_call_original
          result = orchestrator.send(:load_system_prompt, system_prompt_path)
          expect(result).to eq("test content")
        end
      end
    end

    describe "#prepare_reflection_content" do
      let(:reflection_file1) { File.join(temp_dir, "reflection1.md") }
      let(:reflection_file2) { File.join(temp_dir, "reflection2.md") }
      let(:reflections) { [reflection_file1, reflection_file2] }
      let(:timestamp_info) { OpenStruct.new(valid?: true, from_date: "2024-01-01", to_date: "2024-01-31", days_covered: 30) }

      before do
        File.write(reflection_file1, "# First Reflection\n\nFirst reflection content.")
        File.write(reflection_file2, "# Second Reflection\n\nSecond reflection content.")
      end

      context "with valid timestamp info" do
        let(:timestamp_info) do
          OpenStruct.new(
            valid?: true,
            from_date: "2024-01-01",
            to_date: "2024-01-31",
            days_covered: 30
          )
        end

        it "includes timestamp information in content" do
          content = orchestrator.send(:prepare_reflection_content, reflections, timestamp_info)

          expect(content).to include("# Reflection Notes for Synthesis")
          expect(content).to include("**Analysis Period**: 2024-01-01 to 2024-01-31")
          expect(content).to include("**Duration**: 30 days")
          expect(content).to include("**Total Reflections**: 2")
        end
      end

      context "with invalid timestamp info" do
        let(:timestamp_info) { OpenStruct.new(valid?: false) }

        it "excludes timestamp information but includes reflection count" do
          content = orchestrator.send(:prepare_reflection_content, reflections, timestamp_info)

          expect(content).to include("# Reflection Notes for Synthesis")
          expect(content).not_to include("**Analysis Period**")
          expect(content).not_to include("**Duration**")
          expect(content).to include("**Total Reflections**: 2")
        end
      end

      context "with reflection files" do
        it "includes reflection content with proper headers" do
          content = orchestrator.send(:prepare_reflection_content, reflections, timestamp_info)

          expect(content).to include("## Reflection 1: reflection1.md")
          expect(content).to include("## Reflection 2: reflection2.md")
          expect(content).to include("**Source**: `#{reflection_file1}`")
          expect(content).to include("**Source**: `#{reflection_file2}`")
          expect(content).to include("# First Reflection")
          expect(content).to include("# Second Reflection")
        end

        it "includes file modification timestamps" do
          content = orchestrator.send(:prepare_reflection_content, reflections, timestamp_info)

          # Check that modification time is included (format: YYYY-MM-DD HH:MM:SS)
          expect(content).to match(/\*\*Modified\*\*: \d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/)
        end

        it "separates reflections with horizontal rules" do
          content = orchestrator.send(:prepare_reflection_content, reflections, timestamp_info)

          expect(content.scan("---").length).to be >= 2  # At least separators between reflections
        end
      end

      context "when reflection file cannot be read" do
        before do
          allow(File).to receive(:read).with(reflection_file1, encoding: "utf-8").and_raise(Errno::ENOENT, "File not found")
          allow(File).to receive(:read).with(reflection_file2, encoding: "utf-8").and_return("# Second Reflection\n\nSecond reflection content.")
        end

        it "includes error message for unreadable files" do
          content = orchestrator.send(:prepare_reflection_content, reflections, timestamp_info)

          expect(content).to include("*Error reading reflection:")
          expect(content).to include("# Second Reflection")  # Other file should still be processed
        end
      end

      context "with empty reflections array" do
        let(:reflections) { [] }

        it "creates basic structure with zero reflections" do
          content = orchestrator.send(:prepare_reflection_content, reflections, timestamp_info)

          expect(content).to include("# Reflection Notes for Synthesis")
          expect(content).to include("**Total Reflections**: 0")
          expect(content).not_to include("## Reflection 1")
        end
      end

      context "reflection file paths and basenames" do
        let(:nested_reflection) { File.join(temp_dir, "nested", "deep", "reflection.md") }
        let(:reflections) { [nested_reflection] }

        before do
          FileUtils.mkdir_p(File.dirname(nested_reflection))
          File.write(nested_reflection, "# Nested Reflection\n\nContent.")
        end

        it "uses basename for reflection headers" do
          content = orchestrator.send(:prepare_reflection_content, reflections, timestamp_info)

          expect(content).to include("## Reflection 1: reflection.md")
          expect(content).to include("**Source**: `#{nested_reflection}`")
        end
      end
    end
  end

  describe "integration with dependencies" do
    it "initializes PromptProcessor correctly" do
      expect(CodingAgentTools::Organisms::PromptProcessor).to receive(:new).once
      described_class.new
    end
  end

  describe "error handling and edge cases" do
    let(:reflections) { [File.join(temp_dir, "reflection.md")] }
    let(:timestamp_info) { OpenStruct.new(valid?: true, from_date: "2024-01-01", to_date: "2024-01-31", days_covered: 30) }
    let(:base_params) do
      {
        reflections: reflections,
        timestamp_info: timestamp_info,
        model: "test-model",
        output_path: output_path,
        format: "markdown",
        system_prompt_path: system_prompt_path,
        force: false,
        debug: false
      }
    end

    before do
      File.write(reflections.first, "# Test Reflection\n\nContent.")
      File.write(system_prompt_path, "System prompt.")
    end

    context "when File.write raises an exception" do
      before do
        allow(File).to receive(:write).with(output_path, anything).and_raise(IOError, "Disk full")
      end

      it "handles write errors gracefully" do
        result = orchestrator.synthesize_reflections(**base_params)

        expect(result.success?).to be false
        expect(result.error).to include("Could not write output file: Disk full")
      end
    end

    context "with special characters in paths" do
      let(:special_output_path) { File.join(temp_dir, "output with spaces & symbols!.md") }
      let(:params_with_special_path) { base_params.merge(output_path: special_output_path) }

      it "handles paths with special characters" do
        result = orchestrator.synthesize_reflections(**params_with_special_path)

        expect(result.success?).to be true
        expect(File.exist?(special_output_path)).to be true
      end
    end

    context "performance with large content" do
      let(:large_reflection) { File.join(temp_dir, "large_reflection.md") }
      let(:reflections) { [large_reflection] }

      before do
        # Create a reflection with substantial content
        large_content = "# Large Reflection\n\n" + ("This is a large reflection with lots of content. " * 1000)
        File.write(large_reflection, large_content)
      end

      it "processes large reflections efficiently" do
        start_time = Time.now
        result = orchestrator.synthesize_reflections(**base_params)
        end_time = Time.now

        expect(result.success?).to be true
        expect(end_time - start_time).to be < 5  # Should complete within 5 seconds
      end
    end
  end
end
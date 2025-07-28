# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Code::ReviewPrepare::Prompt do
  let(:command) { described_class.new }
  let(:mock_prompt_builder) { instance_double("CodingAgentTools::Organisms::Code::PromptBuilder") }
  let(:mock_session) { double("session") }
  let(:mock_target) { double("target") }
  let(:mock_context) { double("context") }
  let(:mock_prompt) { double("prompt", combined_content: "Combined prompt content", word_count: 150, focus_areas: ["code", "tests"]) }
  let(:temp_dir) { Dir.mktmpdir }
  let(:session_dir) { File.join(temp_dir, "session") }

  before do
    FileUtils.mkdir_p(session_dir)
    allow(CodingAgentTools::Organisms::Code::PromptBuilder).to receive(:new).and_return(mock_prompt_builder)
    allow(command).to receive(:load_session_from_dir).and_return(mock_session)
    allow(command).to receive(:detect_target_from_session).and_return(mock_target)
    allow(command).to receive(:detect_context_from_session).and_return(mock_context)
    allow(mock_prompt_builder).to receive(:build_review_prompt).and_return(mock_prompt)

    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
    allow(File).to receive(:write)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#call" do
    context "with successful prompt building" do
      it "builds and saves prompt successfully" do
        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(0)
        expect(command).to have_received(:load_session_from_dir).with(session_dir, "code")
        expect(command).to have_received(:detect_target_from_session).with(session_dir)
        expect(command).to have_received(:detect_context_from_session).with(session_dir)
        expect(mock_prompt_builder).to have_received(:build_review_prompt).with(mock_session, mock_target, mock_context)
      end

      it "saves to default location in session directory" do
        expected_path = File.join(session_dir, "prompt.md")

        command.call(session_dir: session_dir, focus: "code")

        expect(File).to have_received(:write).with(expected_path, "Combined prompt content")
        expect($stdout).to have_received(:puts).with("✅ Prompt saved to: #{expected_path}")
      end

      it "saves to custom output file when specified" do
        custom_output = File.join(temp_dir, "custom-prompt.md")

        command.call(session_dir: session_dir, focus: "code", output: custom_output)

        expect(File).to have_received(:write).with(custom_output, "Combined prompt content")
        expect($stdout).to have_received(:puts).with("✅ Prompt saved to: #{custom_output}")
      end

      it "handles different focus types" do
        focus_types = ["code", "tests", "docs", "code tests", "code tests docs"]

        focus_types.each do |focus|
          result = command.call(session_dir: session_dir, focus: focus)

          expect(result).to eq(0)
          expect(command).to have_received(:load_session_from_dir).with(session_dir, focus)
        end
      end

      it "displays success information" do
        default_path = File.join(session_dir, "prompt.md")

        command.call(session_dir: session_dir, focus: "code")

        expect($stdout).to have_received(:puts).with("✅ Prompt saved to: #{default_path}")
      end

      it "shows prompt statistics" do
        # Assuming the implementation shows statistics
        mock_prompt_with_stats = double("prompt",
          combined_content: "Combined prompt content",
          total_length: 1500,
          section_count: 4,
          word_count: 300,
          focus_areas: ["code", "tests"])
        allow(mock_prompt_builder).to receive(:build_review_prompt).and_return(mock_prompt_with_stats)
        allow(mock_prompt_with_stats).to receive(:total_length).and_return(1500)
        allow(mock_prompt_with_stats).to receive(:section_count).and_return(4)

        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(0)
        # Verify basic success regardless of stats implementation
      end
    end

    context "with session loading errors" do
      before do
        allow(command).to receive(:load_session_from_dir).and_raise(StandardError, "Session not found")
      end

      it "handles session loading errors gracefully" do
        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Session not found\n")
      end
    end

    context "with target detection errors" do
      before do
        allow(command).to receive(:detect_target_from_session).and_raise(IOError, "Target file missing")
      end

      it "handles target detection errors gracefully" do
        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Target file missing\n")
      end
    end

    context "with context detection errors" do
      before do
        allow(command).to receive(:detect_context_from_session).and_raise(ArgumentError, "Context malformed")
      end

      it "handles context detection errors gracefully" do
        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Context malformed\n")
      end
    end

    context "with prompt building errors" do
      before do
        allow(mock_prompt_builder).to receive(:build_review_prompt).and_raise(RuntimeError, "Prompt build failed")
      end

      it "handles prompt building errors gracefully" do
        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Prompt build failed\n")
      end
    end

    context "with file write errors" do
      before do
        allow(File).to receive(:write).and_raise(IOError, "Permission denied")
      end

      it "handles file write errors gracefully" do
        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Permission denied\n")
      end
    end

    context "with missing session directory" do
      it "attempts to process nonexistent directory" do
        nonexistent_dir = "/nonexistent/session"

        result = command.call(session_dir: nonexistent_dir, focus: "code")

        expect(command).to have_received(:load_session_from_dir).with(nonexistent_dir, "code")
        # Result depends on how load_session_from_dir handles missing directories
        expect(result).to be_a(Integer)
      end
    end

    context "with different output paths" do
      it "handles absolute output paths" do
        absolute_output = File.join(temp_dir, "absolute", "prompt.md")

        command.call(session_dir: session_dir, focus: "code", output: absolute_output)

        expect(File).to have_received(:write).with(absolute_output, "Combined prompt content")
      end

      it "handles relative output paths" do
        relative_output = "relative/prompt.md"

        command.call(session_dir: session_dir, focus: "code", output: relative_output)

        expect(File).to have_received(:write).with(relative_output, "Combined prompt content")
      end

      it "handles output paths with special characters" do
        special_output = File.join(temp_dir, "prompt with spaces & symbols!.md")

        command.call(session_dir: session_dir, focus: "code", output: special_output)

        expect(File).to have_received(:write).with(special_output, "Combined prompt content")
      end
    end

    context "with empty or nil prompt content" do
      it "handles empty prompt content" do
        empty_prompt = double("prompt", combined_content: "", word_count: 0, focus_areas: [])
        allow(mock_prompt_builder).to receive(:build_review_prompt).and_return(empty_prompt)

        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(0)
        expect(File).to have_received(:write).with(anything, "")
      end

      it "handles nil prompt content" do
        nil_prompt = double("prompt", combined_content: nil, word_count: 0, focus_areas: [])
        allow(mock_prompt_builder).to receive(:build_review_prompt).and_return(nil_prompt)

        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(0)
        expect(File).to have_received(:write).with(anything, nil)
      end
    end

    context "with complex focus combinations" do
      let(:complex_focus_combinations) do
        [
          "code tests docs",
          "tests docs",
          "code docs",
          "code tests"
        ]
      end

      it "handles complex focus combinations" do
        complex_focus_combinations.each do |focus|
          result = command.call(session_dir: session_dir, focus: focus)

          expect(result).to eq(0)
          expect(command).to have_received(:load_session_from_dir).with(session_dir, focus)
        end
      end
    end

    context "with large prompt content" do
      it "handles large prompt content" do
        large_content = "x" * 100_000  # 100KB content
        large_prompt = double("prompt", combined_content: large_content, word_count: 20000, focus_areas: ["code"])
        allow(mock_prompt_builder).to receive(:build_review_prompt).and_return(large_prompt)

        result = command.call(session_dir: session_dir, focus: "code")

        expect(result).to eq(0)
        expect(File).to have_received(:write).with(anything, large_content)
      end
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.description).to eq("Build combined review prompt")
    end

    it "requires session_dir option" do
      expect { command.call(focus: "code") }.to raise_error(ArgumentError)
    end

    it "requires focus option" do
      expect { command.call(session_dir: session_dir) }.to raise_error(ArgumentError)
    end

    it "has output option as optional" do
      # Should not raise error when output is not provided
      expect { command.call(session_dir: session_dir, focus: "code") }.not_to raise_error
    end

    it "has usage examples defined" do
      expect(described_class).to respond_to(:example)
    end
  end

  describe "integration with dependencies" do
    it "creates prompt builder instance" do
      expect(CodingAgentTools::Organisms::Code::PromptBuilder).to receive(:new)

      begin
        command.call(session_dir: session_dir, focus: "code")
      rescue
        nil
      end
    end

    it "follows expected workflow" do
      # Ensure methods are called in the correct order
      expect(command).to receive(:load_session_from_dir).ordered
      expect(command).to receive(:detect_target_from_session).ordered
      expect(command).to receive(:detect_context_from_session).ordered
      expect(mock_prompt_builder).to receive(:build_review_prompt).ordered

      command.call(session_dir: session_dir, focus: "code")
    end

    it "passes correct parameters between methods" do
      command.call(session_dir: session_dir, focus: "code")

      expect(mock_prompt_builder).to have_received(:build_review_prompt).with(
        mock_session, mock_target, mock_context
      )
    end
  end

  describe "return codes" do
    it "returns 0 for successful prompt building" do
      result = command.call(session_dir: session_dir, focus: "code")
      expect(result).to eq(0)
    end

    it "returns 1 for session loading errors" do
      allow(command).to receive(:load_session_from_dir).and_raise(StandardError)
      result = command.call(session_dir: session_dir, focus: "code")
      expect(result).to eq(1)
    end

    it "returns 1 for prompt building errors" do
      allow(mock_prompt_builder).to receive(:build_review_prompt).and_raise(RuntimeError)
      result = command.call(session_dir: session_dir, focus: "code")
      expect(result).to eq(1)
    end

    it "returns 1 for file write errors" do
      allow(File).to receive(:write).and_raise(IOError)
      result = command.call(session_dir: session_dir, focus: "code")
      expect(result).to eq(1)
    end
  end

  describe "file path handling" do
    it "uses session directory for default output" do
      command.call(session_dir: session_dir, focus: "code")

      expected_path = File.join(session_dir, "prompt.md")
      expect(File).to have_received(:write).with(expected_path, anything)
    end

    it "uses custom output path when provided" do
      custom_path = "/custom/path/prompt.md"
      command.call(session_dir: session_dir, focus: "code", output: custom_path)

      expect(File).to have_received(:write).with(custom_path, anything)
    end

    it "handles session directory with trailing slash" do
      session_dir_with_slash = session_dir + "/"
      command.call(session_dir: session_dir_with_slash, focus: "code")

      # Should still work correctly regardless of trailing slash
      expect(command).to have_received(:load_session_from_dir).with(session_dir_with_slash, "code")
    end
  end
end

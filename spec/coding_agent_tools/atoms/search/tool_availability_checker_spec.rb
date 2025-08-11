# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::Search::ToolAvailabilityChecker do
  let(:checker) { described_class.new }

  describe "#check_all_tools" do
    context "when all tools are available" do
      before do
        allow(checker).to receive(:tool_available?).and_return(true)
      end

      it "returns success status" do
        result = checker.check_all_tools

        expect(result[:success]).to be true
        expect(result[:missing_required]).to be_empty
        expect(result[:missing_optional]).to be_empty
        expect(result[:available_tools]).to include("rg", "fd", "fzf", "git")
      end
    end

    context "when required tools are missing" do
      before do
        allow(checker).to receive(:tool_available?).with("rg").and_return(false)
        allow(checker).to receive(:tool_available?).with("fd").and_return(true)
        allow(checker).to receive(:tool_available?).with("fzf").and_return(true)
        allow(checker).to receive(:tool_available?).with("git").and_return(true)
      end

      it "returns failure status with missing tools" do
        result = checker.check_all_tools

        expect(result[:success]).to be false
        expect(result[:missing_required]).to include("rg")
        expect(result[:missing_required]).not_to include("fd")
        expect(result[:install_instructions]).to have_key("rg")
      end
    end
  end

  describe "#tool_available?" do
    let(:mock_executor) { instance_double(CodingAgentTools::Atoms::SystemCommandExecutor) }

    before do
      allow(CodingAgentTools::Atoms::SystemCommandExecutor).to receive(:new).and_return(mock_executor)
      allow(mock_executor).to receive(:command_available?).with("rg").and_return(true)
      allow(mock_executor).to receive(:command_available?).with("nonexistent").and_return(false)
    end

    it "returns true for available tools" do
      checker = described_class.new
      expect(checker.tool_available?("rg")).to be true
    end

    it "returns false for unavailable tools" do
      checker = described_class.new
      expect(checker.tool_available?("nonexistent")).to be false
    end
  end

  describe "#install_instruction" do
    it "returns installation instructions for ripgrep" do
      instruction = checker.install_instruction("rg")

      expect(instruction).to include("ripgrep")
      expect(instruction).to include("brew install ripgrep")
      expect(instruction).to include("apt install ripgrep")
    end

    it "returns installation instructions for fd" do
      instruction = checker.install_instruction("fd")

      expect(instruction).to include("fd")
      expect(instruction).to include("brew install fd")
      expect(instruction).to include("apt install fd-find")
    end

    it "returns installation instructions for fzf" do
      instruction = checker.install_instruction("fzf")

      expect(instruction).to include("fzf")
      expect(instruction).to include("brew install fzf")
    end

    it "returns generic message for unknown tools" do
      instruction = checker.install_instruction("unknown")

      expect(instruction).to include("not recognized")
      expect(instruction).to include("install manually")
    end
  end

  describe "#available_tools" do
    before do
      allow(checker).to receive(:tool_available?).with("rg").and_return(true)
      allow(checker).to receive(:tool_available?).with("fd").and_return(false)
      allow(checker).to receive(:tool_available?).with("fzf").and_return(true)
      allow(checker).to receive(:tool_available?).with("git").and_return(true)
    end

    it "returns list of available tools" do
      available = checker.available_tools

      expect(available).to include("rg", "fzf", "git")
      expect(available).not_to include("fd")
    end
  end

  describe "#check_required_tools" do
    before do
      allow(checker).to receive(:tool_available?).with("rg").and_return(true)
      allow(checker).to receive(:tool_available?).with("fd").and_return(false)
    end

    it "returns missing required tools" do
      missing = checker.check_required_tools

      expect(missing).to include("fd")
      expect(missing).not_to include("rg")
    end
  end

  describe "#check_optional_tools" do
    before do
      allow(checker).to receive(:tool_available?).with("fzf").and_return(false)
      allow(checker).to receive(:tool_available?).with("git").and_return(true)
    end

    it "returns missing optional tools" do
      missing = checker.check_optional_tools

      expect(missing).to include("fzf")
      expect(missing).not_to include("git")
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/editor/editor_detector"

RSpec.describe CodingAgentTools::Atoms::Editor::EditorDetector do
  let(:detector) { described_class.new }

  describe "#detect_editor" do
    context "when explicit editor is provided" do
      it "returns configuration for known editor" do
        result = detector.detect_editor(explicit_editor: "code")

        expect(result[:name]).to eq("Visual Studio Code")
        expect(result[:command]).to eq("code")
        expect(result[:line_support]).to be true
      end

      it "returns basic configuration for unknown editor" do
        result = detector.detect_editor(explicit_editor: "unknown_editor")

        expect(result[:name]).to eq("unknown_editor")
        expect(result[:command]).to eq("unknown_editor")
        expect(result[:line_support]).to be false
      end
    end

    context "when config provides default editor" do
      it "uses config default" do
        config = {"editor" => {"default" => "vim"}}
        result = detector.detect_editor(config: config)

        expect(result[:name]).to eq("Vim")
        expect(result[:command]).to eq("vim")
      end
    end

    context "when no explicit editor or config" do
      it "auto-detects available editor" do
        # This will depend on what's actually available on the system
        result = detector.detect_editor

        expect(result).to have_key(:name)
        expect(result).to have_key(:command)
        expect(result).to have_key(:line_support)
      end
    end
  end

  describe "#available?" do
    it "returns true for editors that exist on system" do
      # Test with 'echo' which should be available on most systems
      expect(detector.available?("echo")).to be true
    end

    it "returns false for non-existent editors" do
      expect(detector.available?("nonexistent_editor_xyz123")).to be false
    end

    it "returns false for nil or empty commands" do
      expect(detector.available?(nil)).to be false
      expect(detector.available?("")).to be false
    end
  end

  describe "#available_editors" do
    it "returns array of available editors with metadata" do
      editors = detector.available_editors

      expect(editors).to be_an(Array)
      editors.each do |editor|
        expect(editor).to have_key(:name)
        expect(editor).to have_key(:command)
        expect(editor).to have_key(:line_support)
      end
    end
  end
end

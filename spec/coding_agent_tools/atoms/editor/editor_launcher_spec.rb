# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/editor/editor_launcher"
require "tempfile"

RSpec.describe CodingAgentTools::Atoms::Editor::EditorLauncher do
  let(:launcher) { described_class.new }

  # Create a temporary test file
  let(:test_file) do
    file = Tempfile.new(['test_file', '.txt'])
    file.write("line 1\nline 2\nline 3\n")
    file.close
    file.path
  end

  after do
    # Clean up temp file if it still exists
    File.unlink(test_file) if File.exist?(test_file)
  end

  describe "#launch_file" do
    let(:editor_config) do
      {
        name: "Test Editor", 
        command: "echo",
        line_support: true,
        line_format: "opening %file at line %line"
      }
    end

    it "successfully launches file with valid configuration" do
      result = launcher.launch_file(test_file, editor_config)
      
      expect(result[:success]).to be true
      expect(result[:message]).to include("Test Editor")
    end

    it "handles non-existent files" do
      result = launcher.launch_file("/path/to/nonexistent/file.txt", editor_config)
      
      expect(result[:success]).to be false
      expect(result[:error]).to include("File does not exist")
    end

    it "requires valid file path" do
      result = launcher.launch_file(nil, editor_config)
      
      expect(result[:success]).to be false
      expect(result[:error]).to include("File path is required")
    end

    it "requires editor configuration" do
      result = launcher.launch_file(test_file, nil)
      
      expect(result[:success]).to be false
      expect(result[:error]).to include("Editor configuration is required")
    end

    it "supports line number positioning when available" do
      result = launcher.launch_file(test_file, editor_config, line: 42)
      
      expect(result[:success]).to be true
      # We can't test the actual command execution, but we can verify it completes
    end
  end

  describe "#launch_files" do
    let(:editor_config) do
      {
        name: "Test Editor", 
        command: "echo",
        line_support: false,
        line_format: "%file"
      }
    end

    it "launches multiple valid files" do
      files = [test_file]
      result = launcher.launch_files(files, editor_config)
      
      expect(result[:success]).to be true
      expect(result[:files_opened]).to eq(1)
    end

    it "handles empty file list" do
      result = launcher.launch_files([], editor_config)
      
      expect(result[:success]).to be false
      expect(result[:error]).to include("No files provided")
    end

    it "filters out non-existent files" do
      files = [test_file, "/nonexistent/file.txt"]
      result = launcher.launch_files(files, editor_config)
      
      expect(result[:success]).to be true
      expect(result[:files_opened]).to eq(1)
    end

    it "requires valid input" do
      result = launcher.launch_files(nil, editor_config)
      
      expect(result[:success]).to be false
      expect(result[:error]).to include("File paths array is required")
    end
  end

  describe "#supports_line_numbers?" do
    it "returns true when editor supports line numbers" do
      config = { line_support: true }
      expect(launcher.supports_line_numbers?(config)).to be true
    end

    it "returns false when editor doesn't support line numbers" do
      config = { line_support: false }
      expect(launcher.supports_line_numbers?(config)).to be false
    end
  end

  describe "#validate_availability" do
    it "validates editor command availability" do
      # Test with 'echo' which should be available
      config = { command: "echo" }
      expect(launcher.validate_availability(config)).to be true
    end

    it "returns false for non-existent commands" do
      config = { command: "nonexistent_command_xyz123" }
      expect(launcher.validate_availability(config)).to be false
    end

    it "handles invalid configurations" do
      expect(launcher.validate_availability(nil)).to be false
      expect(launcher.validate_availability({})).to be false
    end
  end
end
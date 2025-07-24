# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::StandardRbValidator do
  let(:validator) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#initialize" do
    it "uses default options" do
      validator = described_class.new
      expect(validator.options[:fix]).to be false
      expect(validator.options[:format]).to eq("json")
      expect(validator.options[:config_file]).to eq(".standard.yml")
    end

    it "merges custom options" do
      validator = described_class.new(fix: true, format: "simple")
      expect(validator.options[:fix]).to be true
      expect(validator.options[:format]).to eq("simple")
    end
  end

  describe "#validate" do
    let(:mock_json_output) do
      {
        "files" => [
          {
            "path" => "lib/test.rb",
            "offenses" => [
              {
                "location" => { "line" => 10, "column" => 5 },
                "severity" => "convention",
                "message" => "Layout/IndentationWidth: Use 2 spaces for indentation.",
                "cop_name" => "Layout/IndentationWidth",
                "correctable" => true
              }
            ]
          }
        ]
      }.to_json
    end

    before do
      # Mock system call to check if standardrb is available
      allow(validator).to receive(:system).with("which standardrb > /dev/null 2>&1").and_return(true)
      
      # Mock project root detection
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)
    end

    it "validates successfully with no issues" do
      # Mock Open3.capture3 to simulate successful run with no issues
      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', "", double(exitstatus: 0)])

      result = validator.validate(["lib/test.rb"])

      expect(result[:success]).to be true
      expect(result[:findings]).to be_empty
      expect(result[:exit_code]).to eq(0)
    end

    it "parses JSON output with offenses" do
      # Mock Open3.capture3 to return JSON with offenses
      allow(Open3).to receive(:capture3).and_return([mock_json_output, "", double(exitstatus: 1)])

      result = validator.validate(["lib/test.rb"])

      expect(result[:success]).to be false
      expect(result[:findings].size).to eq(1)
      
      finding = result[:findings].first
      expect(finding[:file]).to eq("lib/test.rb")
      expect(finding[:line]).to eq(10)
      expect(finding[:column]).to eq(5)
      expect(finding[:severity]).to eq("convention")
      expect(finding[:message]).to eq("Layout/IndentationWidth: Use 2 spaces for indentation.")
      expect(finding[:cop]).to eq("Layout/IndentationWidth")
      expect(finding[:correctable]).to be true
    end

    it "falls back to text parsing when JSON parsing fails" do
      text_output = "lib/test.rb:10:5: C: Layout/IndentationWidth: Use 2 spaces for indentation."
      
      # Mock Open3 to return malformed JSON in stdout, causing fallback to text parsing
      allow(Open3).to receive(:capture3).and_return([text_output, "", double(exitstatus: 1)])

      result = validator.validate(["lib/test.rb"])

      expect(result[:success]).to be false
      expect(result[:findings].size).to eq(1)
      
      finding = result[:findings].first
      expect(finding[:file]).to eq("lib/test.rb")
      expect(finding[:line]).to eq(10)
      expect(finding[:column]).to eq(5)
      expect(finding[:severity]).to eq("C")
      expect(finding[:message]).to eq("Layout/IndentationWidth: Use 2 spaces for indentation.")
    end

    it "raises error when StandardRB is not available" do
      allow(validator).to receive(:system).with("which standardrb > /dev/null 2>&1").and_return(false)

      expect { validator.validate }.to raise_error("StandardRB is not installed. Please add it to your Gemfile.")
    end

    it "uses custom project root when provided" do
      custom_root = "/custom/project/root"
      validator = described_class.new(project_root: custom_root)
      
      allow(validator).to receive(:system).and_return(true)
      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', "", double(exitstatus: 0)])

      validator.validate

      # Verify that Open3.capture3 was called with the custom root
      expect(Open3).to have_received(:capture3) do |*args, **kwargs|
        expect(kwargs[:chdir]).to eq(custom_root)
      end
    end

    it "prefers dev-tools subdirectory as working directory" do
      dev_tools_dir = File.join(temp_dir, "dev-tools")
      Dir.mkdir(dev_tools_dir)
      
      allow(validator).to receive(:system).and_return(true)
      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', "", double(exitstatus: 0)])

      validator.validate

      expect(Open3).to have_received(:capture3) do |*args, **kwargs|
        expect(kwargs[:chdir]).to eq(dev_tools_dir)
      end
    end
  end

  describe "#autofix" do
    before do
      allow(validator).to receive(:system).and_return(true)
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)
      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', "", double(exitstatus: 0)])
    end

    it "sets fix option to true" do
      validator.autofix(["lib/test.rb"])
      
      expect(validator.options[:fix]).to be true
    end

    it "includes --fix-unsafely in command" do
      validator.autofix(["lib/test.rb"])

      expect(Open3).to have_received(:capture3) do |*command, **kwargs|
        expect(command).to include("--fix-unsafely")
      end
    end

    it "returns result with fixed flag set" do
      result = validator.autofix(["lib/test.rb"])
      expect(result[:fixed]).to be true
    end
  end

  describe "command building" do
    before do
      allow(validator).to receive(:system).and_return(true)
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)
    end

    it "builds basic command" do
      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', "", double(exitstatus: 0)])

      validator.validate(["lib/test.rb"])

      expect(Open3).to have_received(:capture3) do |*command, **kwargs|
        expect(command).to include("bundle", "exec", "standardrb")
        expect(command).to include("--format", "json")
        expect(command).to include(File.expand_path("lib/test.rb"))
      end
    end

    it "includes config file when it exists" do
      config_file = File.join(temp_dir, ".standard.yml")
      File.write(config_file, "# StandardRB config")
      
      validator = described_class.new(config_file: config_file)
      allow(validator).to receive(:system).and_return(true)
      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', "", double(exitstatus: 0)])

      validator.validate(["lib/test.rb"])

      expect(Open3).to have_received(:capture3) do |*command, **kwargs|
        expect(command).to include("--config", config_file)
      end
    end

    it "expands relative paths to absolute" do
      allow(Open3).to receive(:capture3).and_return(['{"files":[]}', "", double(exitstatus: 0)])

      validator.validate(["lib/test.rb", "../other.rb"])

      expect(Open3).to have_received(:capture3) do |*command, **kwargs|
        command.each do |arg|
          next unless arg.include?(".rb")
          expect(Pathname.new(arg)).to be_absolute
        end
      end
    end
  end

  describe "path resolution" do
    let(:mock_offense) do
      {
        "files" => [
          {
            "path" => "/absolute/path/to/file.rb",
            "offenses" => [
              {
                "location" => { "line" => 1, "column" => 1 },
                "severity" => "warning",
                "message" => "Test message",
                "cop_name" => "TestCop",
                "correctable" => false
              }
            ]
          }
        ]
      }.to_json
    end

    before do
      allow(validator).to receive(:system).and_return(true)
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)
    end

    it "converts absolute paths to project-relative paths" do
      # Create a mock file path that can be made relative to temp_dir
      mock_file_path = File.join(temp_dir, "dev-tools", "lib", "test.rb")
      mock_output = {
        "files" => [
          {
            "path" => mock_file_path,
            "offenses" => [
              {
                "location" => { "line" => 1, "column" => 1 },
                "severity" => "warning",
                "message" => "Test message",
                "cop_name" => "TestCop",
                "correctable" => false
              }
            ]
          }
        ]
      }.to_json

      allow(Open3).to receive(:capture3).and_return([mock_output, "", double(exitstatus: 1)])

      result = validator.validate(["lib/test.rb"])

      expect(result[:findings].first[:file]).to eq("dev-tools/lib/test.rb")
    end

    it "handles paths that can't be made relative" do
      # Use a path outside the project
      outside_path = "/completely/different/path/file.rb"
      mock_output = {
        "files" => [
          {
            "path" => outside_path,
            "offenses" => [
              {
                "location" => { "line" => 1, "column" => 1 },
                "severity" => "warning",
                "message" => "Test message",
                "cop_name" => "TestCop",
                "correctable" => false
              }
            ]
          }
        ]
      }.to_json

      allow(Open3).to receive(:capture3).and_return([mock_output, "", double(exitstatus: 1)])

      result = validator.validate(["lib/test.rb"])

      # Since the path can't be made relative, it gets adjusted
      expect(result[:findings].first[:file]).to include("file.rb")
    end
  end

  describe "error handling" do
    before do
      allow(validator).to receive(:system).and_return(true)
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)
    end

    it "handles empty output gracefully" do
      allow(Open3).to receive(:capture3).and_return(["", "", double(exitstatus: 0)])

      result = validator.validate

      expect(result[:success]).to be true
      expect(result[:findings]).to be_empty
    end

    it "handles stderr output" do
      stderr_output = "StandardRB warning message"
      allow(Open3).to receive(:capture3).and_return(["", stderr_output, double(exitstatus: 1)])

      result = validator.validate

      expect(result[:output]).to eq(stderr_output)
    end

    it "prefers stdout over stderr when both present" do
      stdout_output = '{"files":[]}'
      stderr_output = "Warning message"
      allow(Open3).to receive(:capture3).and_return([stdout_output, stderr_output, double(exitstatus: 0)])

      result = validator.validate

      expect(result[:output]).to eq(stdout_output)
    end
  end
end
# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/all"
require "json"

RSpec.describe CodingAgentTools::Cli::Commands::All do
  let(:command) { described_class.new }
  let(:temp_exe_dir) { Dir.mktmpdir("test_exe") }

  # Create a temporary executable file for testing
  def create_test_executable(dir, name, content = "#!/bin/bash\necho 'test'")
    path = File.join(dir, name)
    File.write(path, content)
    File.chmod(0o755, path)
    path
  end

  before do
    # Create test executables
    create_test_executable(temp_exe_dir, "git-status")
    create_test_executable(temp_exe_dir, "llm-query")
    create_test_executable(temp_exe_dir, "nav-ls")
    
    # Mock ToolLister to use our test directory
    allow(CodingAgentTools::Organisms::ToolLister).to receive(:new)
      .and_return(CodingAgentTools::Organisms::ToolLister.new(temp_exe_dir))
  end

  after do
    FileUtils.rm_rf(temp_exe_dir)
  end

  describe "#call" do
    it "displays categorized tools by default" do
      output = capture_output { command.call }
      
      expect(output).to include("Available Coding Agent Tools:")
      expect(output).to include("Git Operations:")
      expect(output).to include("LLM Integration:")
      expect(output).to include("Navigation:")
      expect(output).to include("Total:")
    end

    it "displays tools in names format" do
      output = capture_output { command.call(format: "names") }
      
      expect(output).to include("git-status")
      expect(output).to include("llm-query")
      expect(output).to include("nav-ls")
      expect(output).not_to include("Available Coding Agent Tools:")
    end

    it "displays tools in JSON format" do
      output = capture_output { command.call(format: "json") }
      
      # Should be valid JSON
      parsed = JSON.parse(output)
      expect(parsed).to have_key("categories")
      expect(parsed).to have_key("total")
    end

    it "displays tools in plain format" do
      output = capture_output { command.call(format: "plain") }
      
      expect(output).to include("=== Git Operations ===")
      expect(output).to include("=== LLM Integration ===")
      expect(output).to include("git-status:")
      expect(output).to include("Total:")
    end

    it "filters by category" do
      output = capture_output { command.call(category: "Git Operations") }
      
      expect(output).to include("Git Operations:")
      expect(output).to include("git-status")
      expect(output).not_to include("LLM Integration:")
      expect(output).not_to include("llm-query")
    end

    it "handles invalid category" do
      output = capture_output { command.call(category: "Invalid Category") }
      
      expect(output).to include("Error: Category 'Invalid Category' not found")
      expect(output).to include("Available categories:")
    end

    it "handles no descriptions option" do
      output = capture_output { command.call(no_descriptions: true) }
      
      expect(output).to include("Available Coding Agent Tools:")
      expect(output).to include("git-status")
      # Should not include description separator " - "
      lines_with_descriptions = output.lines.select { |line| line.include?(" - ") }
      expect(lines_with_descriptions).to be_empty
    end

    it "handles no categories option" do
      output = capture_output { command.call(no_categories: true) }
      
      expect(output).to include("Available Coding Agent Tools:")
      expect(output).to include("git-status")
      expect(output).not_to include("Git Operations:")
      expect(output).not_to include("LLM Integration:")
    end
  end

  private

  def capture_output
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_error_output
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end
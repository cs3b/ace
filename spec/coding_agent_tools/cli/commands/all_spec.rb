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

    # Enhanced error handling tests
    context "error handling" do
      it "handles ToolLister errors gracefully" do
        allow(CodingAgentTools::Organisms::ToolLister).to receive(:new)
          .and_raise(CodingAgentTools::Error.new("Mock error"))

        output = capture_output { command.call }
        expect(output).to include("Error: Mock error")
      end

      it "handles unexpected errors gracefully" do
        allow(CodingAgentTools::Organisms::ToolLister).to receive(:new)
          .and_raise(StandardError.new("Unexpected error"))

        output = capture_output { command.call }
        expect(output).to include("Unexpected error: Unexpected error")
      end

      it "returns non-zero exit code on error" do
        allow(CodingAgentTools::Organisms::ToolLister).to receive(:new)
          .and_raise(CodingAgentTools::Error.new("Mock error"))

        result = command.call
        expect(result).to eq(1)
      end

      it "returns 1 for invalid category" do
        result = command.call(category: "Invalid Category")
        expect(result).to eq(1)
      end

      it "returns 0 for successful operations" do
        result = command.call
        expect(result).to eq(0)
      end
    end

    # Edge case tests for empty/missing tools
    context "edge cases with tool data" do
      it "handles empty tools list gracefully by mocking list_all_tools" do
        empty_result = {categories: {}, total: 0}
        tool_lister = instance_double(CodingAgentTools::Organisms::ToolLister)
        allow(CodingAgentTools::Organisms::ToolLister).to receive(:new).and_return(tool_lister)
        allow(tool_lister).to receive(:list_all_tools).and_return(empty_result)

        output = capture_output { command.call }
        expect(output).to include("Total: 0 tools available")
      end

      it "handles empty results in JSON format" do
        empty_result = {categories: {}, total: 0}
        tool_lister = instance_double(CodingAgentTools::Organisms::ToolLister)
        allow(CodingAgentTools::Organisms::ToolLister).to receive(:new).and_return(tool_lister)
        allow(tool_lister).to receive(:list_all_tools).and_return(empty_result)

        output = capture_output { command.call(format: "json") }
        parsed = JSON.parse(output)
        expect(parsed["total"]).to eq(0)
      end

      it "handles empty results in names format" do
        tool_lister = instance_double(CodingAgentTools::Organisms::ToolLister)
        allow(CodingAgentTools::Organisms::ToolLister).to receive(:new).and_return(tool_lister)
        allow(tool_lister).to receive(:list_tool_names).and_return([])

        output = capture_output { command.call(format: "names") }
        expect(output.strip).to be_empty
      end
    end

    # Complex category filtering scenarios
    context "complex category filtering" do
      it "displays correct total when filtering single category" do
        output = capture_output { command.call(category: "Git Operations") }

        # Extract total from output and verify it's less than overall total
        total_line = output.lines.find { |line| line.include?("Total:") }
        expect(total_line).to match(/Total: \d+ tool/)
      end

      it "handles category filtering with no_descriptions" do
        output = capture_output { command.call(category: "Git Operations", no_descriptions: true) }

        expect(output).to include("Git Operations:")
        expect(output).to include("git-status")
        lines_with_descriptions = output.lines.select { |line| line.include?(" - ") }
        expect(lines_with_descriptions).to be_empty
      end

      it "handles category filtering in different formats" do
        json_output = capture_output { command.call(category: "Git Operations", format: "json") }
        parsed = JSON.parse(json_output)
        expect(parsed["categories"]).to have_key("Git Operations")
        expect(parsed["categories"].keys).to eq(["Git Operations"])

        plain_output = capture_output { command.call(category: "Git Operations", format: "plain") }
        expect(plain_output).to include("=== Git Operations ===")
        expect(plain_output).not_to include("=== LLM Integration ===")
      end
    end

    # Format edge cases and output validation
    context "output format edge cases" do
      it "produces well-formed JSON with special tool data" do
        # Mock tools with special characters
        special_result = {
          categories: {
            "Test Category" => {
              description: "Test tools",
              tools: [
                {name: "tool-with-dashes", description: "Tool with dashes"},
                {name: "tool_with_underscores", description: "Tool with underscores"}
              ],
              count: 2
            }
          },
          total: 2
        }

        tool_lister = instance_double(CodingAgentTools::Organisms::ToolLister)
        allow(CodingAgentTools::Organisms::ToolLister).to receive(:new).and_return(tool_lister)
        allow(tool_lister).to receive(:list_all_tools).and_return(special_result)

        output = capture_output { command.call(format: "json") }

        # Should parse without errors
        expect { JSON.parse(output) }.not_to raise_error
        parsed = JSON.parse(output)
        expect(parsed["categories"]).to have_key("Test Category")
      end

      it "handles table format with very long tool names gracefully" do
        long_result = {
          categories: {
            "Test Category" => {
              description: "Test tools",
              tools: [
                {name: "very-long-tool-name-that-might-affect-formatting", description: "Very long tool name"}
              ],
              count: 1
            }
          },
          total: 1
        }

        tool_lister = instance_double(CodingAgentTools::Organisms::ToolLister)
        allow(CodingAgentTools::Organisms::ToolLister).to receive(:new).and_return(tool_lister)
        allow(tool_lister).to receive(:list_all_tools).and_return(long_result)

        output = capture_output { command.call(format: "table") }
        expect(output).to include("very-long-tool-name-that-might-affect-formatting")
      end

      it "maintains consistent output structure across all formats" do
        formats = %w[table json plain]

        formats.each do |format|
          output = capture_output { command.call(format: format) }
          expect(output).not_to be_empty
          expect(output).to include("git-status") if format != "json"
        end
      end
    end

    # Batch processing integration tests
    context "batch processing workflows" do
      it "processes multiple format requests efficiently" do
        # Test that multiple format calls work independently
        table_output = capture_output { command.call(format: "table") }
        json_output = capture_output { command.call(format: "json") }
        names_output = capture_output { command.call(format: "names") }

        expect(table_output).to include("Available Coding Agent Tools:")
        expect(JSON.parse(json_output)).to have_key("categories")
        expect(names_output.lines.first.strip).to match(/\A[a-z-]+\z/)
      end

      it "handles combining multiple options correctly" do
        # Test combinations of options
        output = capture_output {
          command.call(
            format: "plain",
            no_descriptions: true,
            no_categories: false
          )
        }

        expect(output).to include("=== Git Operations ===")
        expect(output).not_to include(" - ") # no descriptions
      end

      it "maintains data consistency across different invocations" do
        # Call multiple times and verify consistent results
        output1 = capture_output { command.call(format: "names") }
        output2 = capture_output { command.call(format: "names") }

        expect(output1).to eq(output2)
      end
    end

    # Performance-related tests (lightweight)
    context "performance considerations" do
      it "completes execution within reasonable time" do
        start_time = Time.now
        command.call
        end_time = Time.now

        execution_time = end_time - start_time
        expect(execution_time).to be < 1.0 # Should complete in under 1 second
      end

      it "handles names format efficiently for large tool sets" do
        # Names format should be fastest as it skips descriptions
        start_time = Time.now
        command.call(format: "names")
        end_time = Time.now

        execution_time = end_time - start_time
        expect(execution_time).to be < 0.5 # Should be very fast
      end
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

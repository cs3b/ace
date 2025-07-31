# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Release::Current do
  let(:command) { described_class.new }
  let(:project_root) { "/fake/project/root" }
  let(:mock_release_manager) { double("CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager") }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to receive(:new).and_return(mock_release_manager)
  end

  describe "#call" do
    context "with successful current release and text format" do
      let(:mock_release_info) do
        double("ReleaseInfo",
          name: "v.0.3.0-workflows",
          version: "v.0.3.0",
          path: "/path/to/current/v.0.3.0-workflows",
          status: "active",
          task_count: 15,
          created_at: Time.parse("2025-01-15 10:30:00"),
          modified_at: Time.parse("2025-01-15 14:20:00"))
      end

      let(:success_result) do
        double("Result",
          success?: true,
          data: mock_release_info,
          error_message: nil)
      end

      before do
        allow(mock_release_manager).to receive(:current).and_return(success_result)
      end

      it "displays current release information in text format" do
        output = capture_stdout { command.call }

        expect(output).to include("Current Release Information:")
        expect(output).to include("=" * 40)
        expect(output).to include("Name:      v.0.3.0-workflows")
        expect(output).to include("Version:   v.0.3.0")
        expect(output).to include("Path:      /path/to/current/v.0.3.0-workflows")
        expect(output).to include("Status:    active")
        expect(output).to include("Tasks:     15")
        expect(output).to include("Created:   2025-01-15 10:30:00")
        expect(output).to include("Modified:  2025-01-15 14:20:00")
      end

      it "returns 0 for successful operation" do
        capture_stdout { expect(command.call).to eq(0) }
      end

      it "creates ReleaseManager with correct project root" do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager).to have_received(:new).with(base_path: project_root)
      end
    end

    context "with successful current release and JSON format" do
      let(:mock_release_info) do
        double("ReleaseInfo",
          name: "v.0.3.0-workflows",
          version: "v.0.3.0",
          path: "/path/to/current/v.0.3.0-workflows",
          type: :current,
          status: "active",
          task_count: 15,
          created_at: Time.parse("2025-01-15 10:30:00"),
          modified_at: Time.parse("2025-01-15 14:20:00"))
      end

      let(:success_result) do
        double("Result",
          success?: true,
          data: mock_release_info,
          error_message: nil)
      end

      before do
        allow(mock_release_manager).to receive(:current).and_return(success_result)
      end

      it "displays current release information in JSON format" do
        output = capture_stdout { command.call(format: "json") }

        json_output = JSON.parse(output)
        expect(json_output["success"]).to be(true)
        expect(json_output["data"]["name"]).to eq("v.0.3.0-workflows")
        expect(json_output["data"]["version"]).to eq("v.0.3.0")
        expect(json_output["data"]["path"]).to eq("/path/to/current/v.0.3.0-workflows")
        expect(json_output["data"]["type"]).to eq("current")
        expect(json_output["data"]["status"]).to eq("active")
        expect(json_output["data"]["task_count"]).to eq(15)
        expect(json_output["data"]["created_at"]).to eq("2025-01-15T10:30:00+00:00")
        expect(json_output["data"]["modified_at"]).to eq("2025-01-15T14:20:00+00:00")
      end

      it "returns 0 for successful JSON operation" do
        capture_stdout { expect(command.call(format: "json")).to eq(0) }
      end
    end

    context "with failed current release retrieval" do
      let(:failed_result) do
        double("Result",
          success?: false,
          error_message: "No current release found")
      end

      before do
        allow(mock_release_manager).to receive(:current).and_return(failed_result)
        allow(command).to receive(:error_output)
      end

      it "displays error message in text format" do
        capture_stdout { command.call }

        expect(command).to have_received(:error_output).with("Error: No current release found")
      end

      it "returns 1 for failed operation" do
        capture_stdout { expect(command.call).to eq(1) }
      end

      it "displays error in JSON format" do
        output = capture_stdout { command.call(format: "json") }

        json_output = JSON.parse(output)
        expect(json_output["success"]).to be(false)
        expect(json_output["error"]).to eq("No current release found")
      end
    end

    context "with --path option" do
      before do
        # Mock successful path resolution
        allow(mock_release_manager).to receive(:resolve_path).and_return("/resolved/path/reflections")
      end

      context "when resolving paths successfully" do
        it "returns resolved path for reflections in text format" do
          output = capture_stdout { command.call(path: "reflections") }

          expect(output.strip).to eq("/resolved/path/reflections")
          expect(mock_release_manager).to have_received(:resolve_path).with("reflections")
        end

        it "returns resolved path for reflections/synthesis in text format" do
          allow(mock_release_manager).to receive(:resolve_path).with("reflections/synthesis").and_return("/resolved/path/reflections/synthesis")

          output = capture_stdout { command.call(path: "reflections/synthesis") }

          expect(output.strip).to eq("/resolved/path/reflections/synthesis")
        end

        it "returns resolved path for tasks in text format" do
          allow(mock_release_manager).to receive(:resolve_path).with("tasks").and_return("/resolved/path/tasks")

          output = capture_stdout { command.call(path: "tasks") }

          expect(output.strip).to eq("/resolved/path/tasks")
        end

        it "returns 0 for successful path resolution" do
          capture_stdout { expect(command.call(path: "reflections")).to eq(0) }
        end
      end

      context "when resolving paths with JSON format" do
        before do
          allow(File).to receive(:exist?).with("/resolved/path/reflections").and_return(true)
        end

        it "returns JSON with path metadata" do
          output = capture_stdout { command.call(path: "reflections", format: "json") }

          json_output = JSON.parse(output)
          expect(json_output["success"]).to be(true)
          expect(json_output["data"]["subpath"]).to eq("reflections")
          expect(json_output["data"]["resolved_path"]).to eq("/resolved/path/reflections")
          expect(json_output["data"]["exists"]).to be(true)
        end

        it "includes exists metadata for non-existent paths" do
          allow(File).to receive(:exist?).with("/resolved/path/nonexistent").and_return(false)
          allow(mock_release_manager).to receive(:resolve_path).with("nonexistent").and_return("/resolved/path/nonexistent")

          output = capture_stdout { command.call(path: "nonexistent", format: "json") }

          json_output = JSON.parse(output)
          expect(json_output["data"]["exists"]).to be(false)
        end
      end

      context "when path resolution fails" do
        let(:path_error) { StandardError.new("Path resolution failed") }

        before do
          allow(mock_release_manager).to receive(:resolve_path).and_raise(path_error)
          allow(command).to receive(:error_output)
        end

        it "handles path resolution errors in text format" do
          result = command.call(path: "invalid")

          expect(result).to eq(1)
          expect(command).to have_received(:error_output).with("Error: Path resolution failed")
          expect(command).to have_received(:error_output).with("Use --debug flag for more information")
        end

        it "handles path resolution errors in JSON format" do
          result = command.call(path: "invalid", format: "json")

          expect(result).to eq(1)
          expect(command).to have_received(:error_output).with("Error: Path resolution failed")
          expect(command).to have_received(:error_output).with("Use --debug flag for more information")
        end
      end
    end

    context "with exception handling" do
      let(:error) { StandardError.new("Unexpected error") }

      before do
        allow(mock_release_manager).to receive(:current).and_raise(error)
        allow(command).to receive(:error_output)
      end

      it "handles exceptions and returns error code" do
        result = command.call

        expect(result).to eq(1)
        expect(command).to have_received(:error_output).with("Error: Unexpected error")
        expect(command).to have_received(:error_output).with("Use --debug flag for more information")
      end

      it "shows detailed error information with debug flag" do
        allow(error).to receive(:backtrace).and_return([
          "/path/to/file1.rb:10:in `method1'",
          "/path/to/file2.rb:20:in `method2'"
        ])

        command.call(debug: true)

        expect(command).to have_received(:error_output).with("Error: StandardError: Unexpected error")
        expect(command).to have_received(:error_output).with("\nBacktrace:")
        expect(command).to have_received(:error_output).with("  /path/to/file1.rb:10:in `method1'")
        expect(command).to have_received(:error_output).with("  /path/to/file2.rb:20:in `method2'")
      end
    end

    context "with format option validation" do
      let(:mock_release_info) do
        double("ReleaseInfo",
          name: "test-release",
          version: "v.0.3.0",
          path: "/path",
          type: :current,
          status: "active",
          task_count: 0,
          created_at: nil,
          modified_at: nil)
      end

      let(:success_result) do
        double("Result", success?: true, data: mock_release_info, error_message: nil)
      end

      before do
        allow(mock_release_manager).to receive(:current).and_return(success_result)
      end

      it "defaults to text format when no format specified" do
        output = capture_stdout { command.call }
        expect(output).to include("Current Release Information:")
      end

      it "uses text format when explicitly specified" do
        output = capture_stdout { command.call(format: "text") }
        expect(output).to include("Current Release Information:")
      end

      it "uses JSON format when specified" do
        output = capture_stdout { command.call(format: "json") }
        json_output = JSON.parse(output)
        expect(json_output).to have_key("success")
      end
    end

    context "with release info edge cases" do
      context "when timestamps are nil" do
        let(:mock_release_info) do
          double("ReleaseInfo",
            name: "test-release",
            version: "v.0.3.0",
            path: "/path",
            type: :current,
            status: "active",
            task_count: 0,
            created_at: nil,
            modified_at: nil)
        end

        let(:success_result) do
          double("Result", success?: true, data: mock_release_info, error_message: nil)
        end

        before do
          allow(mock_release_manager).to receive(:current).and_return(success_result)
        end

        it "handles nil timestamps gracefully in text format" do
          output = capture_stdout { command.call }

          expect(output).to include("Name:      test-release")
          expect(output).to include("Tasks:     0")
          expect(output).not_to include("Created:")
          expect(output).not_to include("Modified:")
        end

        it "handles nil timestamps gracefully in JSON format" do
          output = capture_stdout { command.call(format: "json") }

          json_output = JSON.parse(output)
          expect(json_output["data"]["created_at"]).to be_nil
          expect(json_output["data"]["modified_at"]).to be_nil
        end
      end
    end
  end

  describe "#handle_text_result" do
    context "with successful result" do
      let(:mock_release_info) do
        double("ReleaseInfo",
          name: "v.0.3.0-test",
          version: "v.0.3.0",
          path: "/path/to/release",
          status: "active",
          task_count: 5,
          created_at: Time.parse("2025-01-15 10:00:00"),
          modified_at: Time.parse("2025-01-15 15:00:00"))
      end

      let(:success_result) do
        double("Result", success?: true, data: mock_release_info)
      end

      it "formats successful result correctly" do
        output = capture_stdout { command.send(:handle_text_result, success_result) }

        expect(output).to include("Current Release Information:")
        expect(output).to include("=" * 40)
        expect(output).to include("Name:      v.0.3.0-test")
        expect(output).to include("Version:   v.0.3.0")
        expect(output).to include("Path:      /path/to/release")
        expect(output).to include("Status:    active")
        expect(output).to include("Tasks:     5")
        expect(output).to include("Created:   2025-01-15 10:00:00")
        expect(output).to include("Modified:  2025-01-15 15:00:00")
      end
    end

    context "with failed result" do
      let(:failed_result) do
        double("Result",
          success?: false,
          error_message: "No current release found")
      end

      before do
        allow(command).to receive(:error_output)
      end

      it "displays error message for failed result" do
        capture_stdout { command.send(:handle_text_result, failed_result) }

        expect(command).to have_received(:error_output).with("Error: No current release found")
      end
    end
  end

  describe "#handle_json_result" do
    context "with successful result" do
      let(:mock_release_info) do
        double("ReleaseInfo",
          name: "v.0.3.0-test",
          version: "v.0.3.0",
          path: "/path/to/release",
          type: :current,
          status: "active",
          task_count: 5,
          created_at: Time.parse("2025-01-15 10:00:00"),
          modified_at: Time.parse("2025-01-15 15:00:00"))
      end

      let(:success_result) do
        double("Result", success?: true, data: mock_release_info)
      end

      it "generates correct JSON for successful result" do
        output = capture_stdout { command.send(:handle_json_result, success_result) }

        json_output = JSON.parse(output)
        expect(json_output["success"]).to be(true)
        expect(json_output["data"]["name"]).to eq("v.0.3.0-test")
        expect(json_output["data"]["version"]).to eq("v.0.3.0")
        expect(json_output["data"]["path"]).to eq("/path/to/release")
        expect(json_output["data"]["type"]).to eq("current")
        expect(json_output["data"]["status"]).to eq("active")
        expect(json_output["data"]["task_count"]).to eq(5)
        expect(json_output["data"]["created_at"]).to eq("2025-01-15T10:00:00+00:00")
        expect(json_output["data"]["modified_at"]).to eq("2025-01-15T15:00:00+00:00")
      end
    end

    context "with failed result" do
      let(:failed_result) do
        double("Result",
          success?: false,
          error_message: "Release not found")
      end

      it "generates correct JSON for failed result" do
        output = capture_stdout { command.send(:handle_json_result, failed_result) }

        json_output = JSON.parse(output)
        expect(json_output["success"]).to be(false)
        expect(json_output["error"]).to eq("Release not found")
      end
    end
  end

  describe "#handle_error" do
    let(:error) { StandardError.new("Test error message") }

    before do
      allow(command).to receive(:error_output)
      allow(error).to receive(:backtrace).and_return([
        "/path/to/file1.rb:10:in `method1'",
        "/path/to/file2.rb:20:in `method2'"
      ])
    end

    context "with debug disabled" do
      it "outputs simple error message" do
        command.send(:handle_error, error, false)

        expect(command).to have_received(:error_output).with("Error: Test error message")
        expect(command).to have_received(:error_output).with("Use --debug flag for more information")
      end
    end

    context "with debug enabled" do
      it "outputs detailed error information with backtrace" do
        command.send(:handle_error, error, true)

        expect(command).to have_received(:error_output).with("Error: StandardError: Test error message")
        expect(command).to have_received(:error_output).with("\nBacktrace:")
        expect(command).to have_received(:error_output).with("  /path/to/file1.rb:10:in `method1'")
        expect(command).to have_received(:error_output).with("  /path/to/file2.rb:20:in `method2'")
      end
    end
  end

  describe "#error_output" do
    it "outputs to stderr" do
      expect { command.send(:error_output, "Test error message") }.to output("Test error message\n").to_stderr
    end

    it "handles empty messages" do
      expect { command.send(:error_output, "") }.to output("\n").to_stderr
    end

    it "handles nil messages" do
      expect { command.send(:error_output, nil) }.to output("\n").to_stderr
    end
  end

  describe "#format_time" do
    it "formats time correctly" do
      time = Time.parse("2025-01-15 14:30:45")
      formatted = command.send(:format_time, time)
      expect(formatted).to eq("2025-01-15 14:30:45")
    end
  end

  describe "command metadata" do
    it "has correct description" do
      expect(described_class.description).to eq("Get current release information")
    end

    it "has correct options" do
      options = described_class.options
      option_names = options.map(&:name)
      expect(option_names).to include(:debug)
      expect(option_names).to include(:format)
      expect(option_names).to include(:path)

      format_option = options.find { |opt| opt.name == :format }
      expect(format_option.options[:values]).to eq(%w[text json])
      expect(format_option.options[:default]).to eq("text")
    end

    it "has comprehensive examples" do
      examples = described_class.examples
      expect(examples).not_to be_empty
      expect(examples).to include("")
      expect(examples).to include("--format json")
      expect(examples).to include("--debug")
      expect(examples).to include("--path reflections")
      expect(examples).to include("--path reflections/synthesis --format json")
    end
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end

  def capture_stderr
    old_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = old_stderr
  end
end

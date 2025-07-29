# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/nav/code_review_new"

RSpec.describe CodingAgentTools::CLI::Commands::Nav::CodeReviewNew do
  let(:mock_path_resolver) { double("PathResolver") }
  let(:command) { described_class.new(mock_path_resolver) }

  describe "#initialize" do
    context "with provided path resolver" do
      it "uses the provided path resolver" do
        expect(command.instance_variable_get(:@path_resolver)).to eq(mock_path_resolver)
      end
    end

    context "without provided path resolver" do
      it "creates a default PathResolver instance" do
        allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)

        default_command = described_class.new

        expect(CodingAgentTools::Molecules::PathResolver).to have_received(:new)
        expect(default_command.instance_variable_get(:@path_resolver)).to eq(mock_path_resolver)
      end
    end

    context "with nil path resolver" do
      it "creates a default PathResolver instance when nil is passed" do
        allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)

        nil_command = described_class.new(nil)

        expect(CodingAgentTools::Molecules::PathResolver).to have_received(:new)
        expect(nil_command.instance_variable_get(:@path_resolver)).to eq(mock_path_resolver)
      end
    end
  end

  describe "#call" do
    context "with missing session name" do
      it "returns false and shows error when session_name is nil" do
        output = capture_stdout { expect(command.call(session_name: nil)).to be(false) }

        expect(output).to include("Error: Session name is required")
        expect(output).to include("Usage: nav-path code-review-new \"session name\"")
        expect(output).to include("Example: nav-path code-review-new \"docs-handbook-workflows\"")
      end

      it "returns false and shows error when session_name is not provided" do
        output = capture_stdout { expect(command.call).to be(false) }

        expect(output).to include("Error: Session name is required")
        expect(output).to include("Usage: nav-path code-review-new \"session name\"")
        expect(output).to include("Example: nav-path code-review-new \"docs-handbook-workflows\"")
      end

      it "does not call path resolver when session name is missing" do
        allow(mock_path_resolver).to receive(:resolve_path)

        capture_stdout { command.call(session_name: nil) }

        expect(mock_path_resolver).not_to have_received(:resolve_path)
      end
    end

    context "with successful path resolution" do
      let(:session_name) { "feature-review-session" }
      let(:success_result) { {success: true, path: "dev-taskflow/current/v.0.3.0/reviews/feature-review-session.md"} }

      before do
        allow(mock_path_resolver).to receive(:resolve_path).and_return(success_result)
      end

      it "returns true when path resolution succeeds" do
        capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(true)
      end

      it "outputs the resolved path" do
        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("dev-taskflow/current/v.0.3.0/reviews/feature-review-session.md")
      end

      it "calls path resolver with correct arguments" do
        capture_stdout { command.call(session_name: session_name) }

        expect(mock_path_resolver).to have_received(:resolve_path).with(session_name, type: :code_review_new)
      end

      it "passes additional options to call method" do
        capture_stdout { command.call(session_name: session_name, some_option: "value") }

        expect(mock_path_resolver).to have_received(:resolve_path).with(session_name, type: :code_review_new)
      end
    end

    context "with failed path resolution" do
      let(:session_name) { "invalid-session" }
      let(:failure_result) { {success: false, error: "Unable to create path: insufficient permissions"} }

      before do
        allow(mock_path_resolver).to receive(:resolve_path).and_return(failure_result)
      end

      it "returns false when path resolution fails" do
        capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(false)
      end

      it "outputs the error message" do
        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("Error: Unable to create path: insufficient permissions")
      end

      it "calls path resolver with correct arguments" do
        capture_stdout { command.call(session_name: session_name) }

        expect(mock_path_resolver).to have_received(:resolve_path).with(session_name, type: :code_review_new)
      end
    end

    context "with exception handling" do
      let(:session_name) { "error-session" }

      before do
        allow(mock_path_resolver).to receive(:resolve_path).and_raise(StandardError, "Unexpected resolver error")
      end

      it "returns false when an exception occurs" do
        capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(false)
      end

      it "outputs a user-friendly error message" do
        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("Error generating code review session path: Unexpected resolver error")
      end

      it "still calls path resolver before exception" do
        capture_stdout { command.call(session_name: session_name) }

        expect(mock_path_resolver).to have_received(:resolve_path).with(session_name, type: :code_review_new)
      end
    end

    context "with different exception types" do
      let(:session_name) { "exception-session" }

      it "handles RuntimeError gracefully" do
        allow(mock_path_resolver).to receive(:resolve_path).and_raise(RuntimeError, "Runtime issue")

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output).to include("Error generating code review session path: Runtime issue")
        expect(command.call(session_name: session_name)).to be(false)
      end

      it "handles NoMethodError gracefully" do
        allow(mock_path_resolver).to receive(:resolve_path).and_raise(NoMethodError, "Method not found")

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output).to include("Error generating code review session path: Method not found")
        expect(command.call(session_name: session_name)).to be(false)
      end

      it "handles ArgumentError gracefully" do
        allow(mock_path_resolver).to receive(:resolve_path).and_raise(ArgumentError, "Invalid arguments")

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output).to include("Error generating code review session path: Invalid arguments")
        expect(command.call(session_name: session_name)).to be(false)
      end

      it "handles custom error classes gracefully" do
        custom_error = Class.new(StandardError)
        allow(mock_path_resolver).to receive(:resolve_path).and_raise(custom_error, "Custom error")

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output).to include("Error generating code review session path: Custom error")
        expect(command.call(session_name: session_name)).to be(false)
      end
    end

    context "with edge case session names" do
      it "handles empty string session name" do
        result = {success: true, path: "some/path.md"}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(result)

        output = capture_stdout { command.call(session_name: "") }

        expect(mock_path_resolver).to have_received(:resolve_path).with("", type: :code_review_new)
        expect(output.strip).to eq("some/path.md")
      end

      it "handles session names with special characters" do
        special_name = "session-with-special!@#$%^&*()characters"
        result = {success: true, path: "special/path.md"}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(result)

        output = capture_stdout { command.call(session_name: special_name) }

        expect(mock_path_resolver).to have_received(:resolve_path).with(special_name, type: :code_review_new)
        expect(output.strip).to eq("special/path.md")
      end

      it "handles very long session names" do
        long_name = "a" * 1000
        result = {success: true, path: "long/path.md"}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(result)

        output = capture_stdout { command.call(session_name: long_name) }

        expect(mock_path_resolver).to have_received(:resolve_path).with(long_name, type: :code_review_new)
        expect(output.strip).to eq("long/path.md")
      end

      it "handles session names with whitespace" do
        whitespace_name = "  session with spaces  "
        result = {success: true, path: "whitespace/path.md"}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(result)

        output = capture_stdout { command.call(session_name: whitespace_name) }

        expect(mock_path_resolver).to have_received(:resolve_path).with(whitespace_name, type: :code_review_new)
        expect(output.strip).to eq("whitespace/path.md")
      end

      it "handles session names with unicode characters" do
        unicode_name = "session-测试-🚀-émojis"
        result = {success: true, path: "unicode/path.md"}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(result)

        output = capture_stdout { command.call(session_name: unicode_name) }

        expect(mock_path_resolver).to have_received(:resolve_path).with(unicode_name, type: :code_review_new)
        expect(output.strip).to eq("unicode/path.md")
      end

      it "handles session names with newlines and tabs" do
        newline_name = "session\nwith\tnewlines"
        result = {success: true, path: "newline/path.md"}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(result)

        output = capture_stdout { command.call(session_name: newline_name) }

        expect(mock_path_resolver).to have_received(:resolve_path).with(newline_name, type: :code_review_new)
        expect(output.strip).to eq("newline/path.md")
      end
    end

    context "with different resolver response formats" do
      let(:session_name) { "test-session" }

      it "handles result with only success and path keys" do
        minimal_result = {success: true, path: "minimal/path.md"}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(minimal_result)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("minimal/path.md")
        expect(command.call(session_name: session_name)).to be(true)
      end

      it "handles result with additional metadata" do
        detailed_result = {
          success: true,
          path: "detailed/path.md",
          metadata: {created_at: Time.now, type: "review"},
          extra_info: "Additional information"
        }
        allow(mock_path_resolver).to receive(:resolve_path).and_return(detailed_result)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("detailed/path.md")
        expect(command.call(session_name: session_name)).to be(true)
      end

      it "handles result with nil path on success" do
        nil_path_result = {success: true, path: nil}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(nil_path_result)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("")
        expect(command.call(session_name: session_name)).to be(true)
      end

      it "handles result with missing error key on failure" do
        no_error_result = {success: false}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(no_error_result)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("Error:")
        expect(command.call(session_name: session_name)).to be(false)
      end

      it "handles result with nil error on failure" do
        nil_error_result = {success: false, error: nil}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(nil_error_result)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("Error:")
        expect(command.call(session_name: session_name)).to be(false)
      end

      it "handles result with detailed error information" do
        detailed_error_result = {
          success: false,
          error: "Path creation failed: directory permissions insufficient",
          error_code: "PERMISSION_DENIED",
          suggestion: "Check directory permissions"
        }
        allow(mock_path_resolver).to receive(:resolve_path).and_return(detailed_error_result)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(output.strip).to eq("Error: Path creation failed: directory permissions insufficient")
        expect(command.call(session_name: session_name)).to be(false)
      end
    end

    context "with concurrent execution" do
      let(:session_name) { "concurrent-session" }

      it "handles multiple concurrent calls safely" do
        result = {success: true, path: "concurrent/path.md"}
        allow(mock_path_resolver).to receive(:resolve_path).and_return(result)

        threads = Array.new(5) do
          Thread.new { capture_stdout { command.call(session_name: session_name) } }
        end

        outputs = threads.map(&:value)
        expect(outputs).to all(eq("concurrent/path.md\n"))
      end

      it "handles concurrent calls with different session names" do
        allow(mock_path_resolver).to receive(:resolve_path) do |name, _|
          {success: true, path: "concurrent/#{name}.md"}
        end

        threads = Array.new(3) do |i|
          Thread.new { capture_stdout { command.call(session_name: "session-#{i}") } }
        end

        outputs = threads.map(&:value)
        expect(outputs[0]).to eq("concurrent/session-0.md\n")
        expect(outputs[1]).to eq("concurrent/session-1.md\n")
        expect(outputs[2]).to eq("concurrent/session-2.md\n")
      end
    end

    context "with path resolver state changes" do
      let(:session_name) { "stateful-session" }

      it "handles path resolver returning different results on subsequent calls" do
        first_result = {success: true, path: "first/path.md"}
        second_result = {success: false, error: "Path already exists"}

        allow(mock_path_resolver).to receive(:resolve_path)
          .and_return(first_result, second_result)

        first_output = capture_stdout { command.call(session_name: session_name) }
        second_output = capture_stdout { command.call(session_name: session_name) }

        expect(first_output.strip).to eq("first/path.md")
        expect(second_output.strip).to eq("Error: Path already exists")
      end

      it "maintains resolver state between calls" do
        allow(mock_path_resolver).to receive(:resolve_path) do |name, _|
          {success: true, path: "stateful/#{name}.md"}
        end

        output1 = capture_stdout { command.call(session_name: "session1") }
        output2 = capture_stdout { command.call(session_name: "session2") }

        expect(output1.strip).to eq("stateful/session1.md")
        expect(output2.strip).to eq("stateful/session2.md")
        expect(mock_path_resolver).to have_received(:resolve_path).twice
      end
    end
  end

  describe "integration scenarios" do
    context "with real PathResolver behavior simulation" do
      let(:session_name) { "integration-test" }

      it "simulates successful path creation workflow" do
        workflow_result = {
          success: true,
          path: "dev-taskflow/current/v.0.3.0-workflows/reviews/integration-test.md"
        }
        allow(mock_path_resolver).to receive(:resolve_path).and_return(workflow_result)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(true)
        expect(output).to include("dev-taskflow/current/v.0.3.0-workflows/reviews/integration-test.md")
      end

      it "simulates path validation failure workflow" do
        validation_failure = {
          success: false,
          error: "Session name contains invalid characters: integration-test"
        }
        allow(mock_path_resolver).to receive(:resolve_path).and_return(validation_failure)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(false)
        expect(output).to include("Error: Session name contains invalid characters")
      end

      it "simulates directory creation failure workflow" do
        directory_failure = {
          success: false,
          error: "Failed to create directory: permission denied"
        }
        allow(mock_path_resolver).to receive(:resolve_path).and_return(directory_failure)

        output = capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(false)
        expect(output).to include("Error: Failed to create directory: permission denied")
      end
    end

    context "with error propagation scenarios" do
      let(:session_name) { "error-test" }

      it "propagates resolver initialization errors" do
        allow(mock_path_resolver).to receive(:resolve_path)
          .and_raise(ArgumentError, "Invalid resolver configuration")

        output = capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(false)
        expect(output).to include("Error generating code review session path: Invalid resolver configuration")
      end

      it "propagates file system errors" do
        allow(mock_path_resolver).to receive(:resolve_path)
          .and_raise(Errno::EACCES, "Permission denied")

        output = capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(false)
        expect(output).to include("Error generating code review session path: Permission denied")
      end

      it "propagates network-related errors" do
        allow(mock_path_resolver).to receive(:resolve_path)
          .and_raise(SocketError, "Network unreachable")

        output = capture_stdout { command.call(session_name: session_name) }

        expect(command.call(session_name: session_name)).to be(false)
        expect(output).to include("Error generating code review session path: Network unreachable")
      end
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
end

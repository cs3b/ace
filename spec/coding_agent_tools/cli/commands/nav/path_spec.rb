# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::Nav::Path do
  let(:command) { described_class.new }
  let(:mock_path_resolver) { double("PathResolver") }

  before do
    allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)
    # Default stubs - tests will override as needed
    allow(mock_path_resolver).to receive(:resolve_path).and_return(success: false, error: "Not configured")
    allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release).and_return(success: false, error: "Not configured")
    allow(mock_path_resolver).to receive(:prioritize_matches).and_return(best: "default", alternatives: [])
    allow(mock_path_resolver).to receive(:format_alternative_matches).and_return("")
  end

  describe "#call" do
    context "with task-new type" do
      it "creates new task path with input argument" do
        allow(mock_path_resolver).to receive(:resolve_path).with("New Task", type: :task_new)
          .and_return(success: true, type: :single, path: "dev-taskflow/current/v.1.0.0/tasks/new-task.md")

        output = capture_stdout { command.call(type: "task-new", input: "New Task") }

        expect(output.strip).to eq("dev-taskflow/current/v.1.0.0/tasks/new-task.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("New Task", type: :task_new)
      end

      it "creates new task path with title option" do
        allow(mock_path_resolver).to receive(:resolve_path).with("Another Task", type: :task_new)
          .and_return(success: true, type: :single, path: "dev-taskflow/current/v.1.0.0/tasks/another-task.md")

        output = capture_stdout { command.call(type: "task-new", title: "Another Task") }

        expect(output.strip).to eq("dev-taskflow/current/v.1.0.0/tasks/another-task.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("Another Task", type: :task_new)
      end

      it "shows error when no input provided" do
        output = capture_stdout { command.call(type: "task-new") }

        expect(output).to include("Error: Input required for path resolution")
        expect(output).to include("Usage: nav path TYPE INPUT [OPTIONS]")
        expect(mock_path_resolver).not_to have_received(:resolve_path)
      end

      it "shows error when empty input provided" do
        output = capture_stdout { command.call(type: "task-new", input: "   ") }

        expect(output).to include("Error: Input required for path resolution")
        expect(mock_path_resolver).not_to have_received(:resolve_path)
      end
    end

    context "with task_new type (underscore variant)" do
      it "handles underscore variant of task-new" do
        allow(mock_path_resolver).to receive(:resolve_path).with("Test Task", type: :task_new)
          .and_return(success: true, type: :single, path: "dev-taskflow/current/v.1.0.0/tasks/test-task.md")

        output = capture_stdout { command.call(type: "task_new", input: "Test Task") }

        expect(output.strip).to eq("dev-taskflow/current/v.1.0.0/tasks/test-task.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("Test Task", type: :task_new)
      end
    end

    context "with docs-new type" do
      it "creates new docs path" do
        allow(mock_path_resolver).to receive(:resolve_path).with("Documentation", type: :docs_new)
          .and_return(success: true, type: :single, path: "docs/documentation.md")

        output = capture_stdout { command.call(type: "docs-new", input: "Documentation") }

        expect(output.strip).to eq("docs/documentation.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("Documentation", type: :docs_new)
      end
    end

    context "with reflection-new type" do
      it "creates new reflection path" do
        allow(mock_path_resolver).to receive(:resolve_path).with("Session Reflection", type: :reflection_new)
          .and_return(success: true, type: :single, path: "dev-taskflow/current/v.1.0.0/reflections/session-reflection.md")

        output = capture_stdout { command.call(type: "reflection-new", input: "Session Reflection") }

        expect(output.strip).to eq("dev-taskflow/current/v.1.0.0/reflections/session-reflection.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("Session Reflection", type: :reflection_new)
      end
    end

    context "with reflection-list type" do
      it "lists reflection paths without requiring input" do
        reflection_paths = [
          "dev-taskflow/current/v.1.0.0/reflections/session1.md",
          "dev-taskflow/current/v.1.0.0/reflections/session2.md"
        ]
        allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release)
          .and_return(success: true, type: :list, paths: reflection_paths)

        output = capture_stdout { command.call(type: "reflection-list") }

        expect(output).to include("dev-taskflow/current/v.1.0.0/reflections/session1.md")
        expect(output).to include("dev-taskflow/current/v.1.0.0/reflections/session2.md")
        expect(mock_path_resolver).to have_received(:find_reflection_paths_in_current_release)
        expect(mock_path_resolver).not_to have_received(:resolve_path)
      end

      it "handles underscore variant reflection_list" do
        reflection_paths = ["reflection1.md"]
        allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release)
          .and_return(success: true, type: :list, paths: reflection_paths)

        output = capture_stdout { command.call(type: "reflection_list") }

        expect(output).to include("reflection1.md")
        expect(mock_path_resolver).to have_received(:find_reflection_paths_in_current_release)
      end
    end

    context "with code-review-new type" do
      it "creates new code review path" do
        allow(mock_path_resolver).to receive(:resolve_path).with("Feature Review", type: :code_review_new)
          .and_return(success: true, type: :single, path: "dev-taskflow/current/v.1.0.0/reviews/feature-review.md")

        output = capture_stdout { command.call(type: "code-review-new", input: "Feature Review") }

        expect(output.strip).to eq("dev-taskflow/current/v.1.0.0/reviews/feature-review.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("Feature Review", type: :code_review_new)
      end
    end

    context "with task type" do
      it "resolves existing task path" do
        allow(mock_path_resolver).to receive(:resolve_path).with("42", type: :task)
          .and_return(success: true, type: :single, path: "dev-taskflow/current/v.1.0.0/tasks/task-42.md")

        output = capture_stdout { command.call(type: "task", input: "42") }

        expect(output.strip).to eq("dev-taskflow/current/v.1.0.0/tasks/task-42.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("42", type: :task)
      end
    end

    context "with file type" do
      it "resolves file path" do
        allow(mock_path_resolver).to receive(:resolve_path).with("README", type: :file)
          .and_return(success: true, type: :single, path: "README.md")

        output = capture_stdout { command.call(type: "file", input: "README") }

        expect(output.strip).to eq("README.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("README", type: :file)
      end

      it "shows autocorrect message when provided" do
        allow(mock_path_resolver).to receive(:resolve_path).with("READM", type: :file)
          .and_return(
            success: true,
            type: :single,
            path: "README.md",
            autocorrect_message: "Autocorrected: 'READM' → 'README.md'"
          )

        output = capture_stdout { command.call(type: "file", input: "READM") }

        expect(output).to include("Autocorrected: 'READM' → 'README.md'")
        expect(output).to include("README.md")
      end
    end

    context "with multiple match results" do
      it "handles multiple matches with prioritization" do
        paths = ["file1.md", "file2.md", "file3.md"]
        prioritized_result = {
          best: "file1.md",
          alternatives: ["file2.md", "file3.md"]
        }

        allow(mock_path_resolver).to receive(:resolve_path).with("file", type: :file)
          .and_return(success: true, type: :multiple, paths: paths)
        allow(mock_path_resolver).to receive(:prioritize_matches).with(paths)
          .and_return(prioritized_result)
        allow(mock_path_resolver).to receive(:format_alternative_matches)
          .with(["file2.md", "file3.md"])
          .and_return("Alternative matches:\n  - file2.md\n  - file3.md")

        output = capture_stdout { command.call(type: "file", input: "file") }

        expect(output).to include("Autocorrected: 'file' → 'file1.md'")
        expect(output).to include("file1.md")
        expect(output).to include("Alternative matches:")
        expect(output).to include("file2.md")
        expect(output).to include("file3.md")
      end

      it "handles multiple matches without alternatives" do
        paths = ["only_file.md"]
        prioritized_result = {
          best: "only_file.md",
          alternatives: []
        }

        allow(mock_path_resolver).to receive(:resolve_path).with("only", type: :file)
          .and_return(success: true, type: :multiple, paths: paths)
        allow(mock_path_resolver).to receive(:prioritize_matches).with(paths)
          .and_return(prioritized_result)

        output = capture_stdout { command.call(type: "file", input: "only") }

        expect(output).to include("Autocorrected: 'only' → 'only_file.md'")
        expect(output).to include("only_file.md")
        expect(output).not_to include("Alternative matches:")
        expect(mock_path_resolver).not_to have_received(:format_alternative_matches)
      end
    end

    context "with scoped_multiple match results" do
      it "handles scoped multiple matches" do
        allow(mock_path_resolver).to receive(:resolve_path).with("scope:pattern", type: :file)
          .and_return(
            success: true,
            type: :scoped_multiple,
            path: "scoped/file.md",
            autocorrect_message: "Scope resolved: 'scope:pattern' → 'scoped/file.md'",
            alternative_message: "Additional matches in scope:\n  - scoped/file2.md"
          )

        output = capture_stdout { command.call(type: "file", input: "scope:pattern") }

        expect(output).to include("Scope resolved: 'scope:pattern' → 'scoped/file.md'")
        expect(output).to include("scoped/file.md")
        expect(output).to include("Additional matches in scope:")
        expect(output).to include("scoped/file2.md")
      end

      it "handles scoped multiple matches without alternative message" do
        allow(mock_path_resolver).to receive(:resolve_path).with("scope:unique", type: :file)
          .and_return(
            success: true,
            type: :scoped_multiple,
            path: "scoped/unique.md",
            autocorrect_message: "Scope resolved: 'scope:unique' → 'scoped/unique.md'",
            alternative_message: ""
          )

        output = capture_stdout { command.call(type: "file", input: "scope:unique") }

        expect(output).to include("Scope resolved: 'scope:unique' → 'scoped/unique.md'")
        expect(output).to include("scoped/unique.md")
        expect(output).not_to include("Additional matches")
      end
    end

    context "with unknown path type" do
      it "shows error for unknown type" do
        output = capture_stdout { command.call(type: "unknown-type", input: "test") }

        expect(output).to include("Error: Unknown path type 'unknown-type'")
        expect(output).to include("Valid types: task-new, task, docs-new, reflection-new, reflection-list, code-review-new, file")
        expect(mock_path_resolver).not_to have_received(:resolve_path)
      end
    end

    context "when path resolution fails" do
      it "shows error message" do
        allow(mock_path_resolver).to receive(:resolve_path).with("nonexistent", type: :file)
          .and_return(success: false, error: "File not found")

        output = capture_stdout { command.call(type: "file", input: "nonexistent") }

        expect(output).to include("Error: File not found")
      end
    end

    context "when an exception occurs" do
      it "handles exceptions gracefully" do
        allow(mock_path_resolver).to receive(:resolve_path)
          .and_raise(StandardError, "Unexpected error")

        output = capture_stdout { command.call(type: "file", input: "test") }

        expect(output).to include("Error: Unexpected error")
      end
    end

    context "input precedence" do
      it "prioritizes input argument over title option" do
        allow(mock_path_resolver).to receive(:resolve_path).with("input_arg", type: :task_new)
          .and_return(success: true, type: :single, path: "task-from-input.md")

        output = capture_stdout { command.call(type: "task-new", input: "input_arg", title: "title_option") }

        expect(output.strip).to eq("task-from-input.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("input_arg", type: :task_new)
      end

      it "uses title option when input argument is nil" do
        allow(mock_path_resolver).to receive(:resolve_path).with("title_option", type: :task_new)
          .and_return(success: true, type: :single, path: "task-from-title.md")

        output = capture_stdout { command.call(type: "task-new", input: nil, title: "title_option") }

        expect(output.strip).to eq("task-from-title.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("title_option", type: :task_new)
      end
    end

    context "edge cases" do
      it "handles empty string input gracefully" do
        output = capture_stdout { command.call(type: "file", input: "") }

        expect(output).to include("Error: Input required for path resolution")
        expect(mock_path_resolver).not_to have_received(:resolve_path)
      end

      it "handles whitespace-only input" do
        output = capture_stdout { command.call(type: "task", input: "   \t\n   ") }

        expect(output).to include("Error: Input required for path resolution")
        expect(mock_path_resolver).not_to have_received(:resolve_path)
      end

      it "passes input as-is without trimming whitespace" do
        allow(mock_path_resolver).to receive(:resolve_path).with("  trimmed  ", type: :file)
          .and_return(success: true, type: :single, path: "trimmed.md")

        output = capture_stdout { command.call(type: "file", input: "  trimmed  ") }

        expect(output.strip).to eq("trimmed.md")
        expect(mock_path_resolver).to have_received(:resolve_path).with("  trimmed  ", type: :file)
      end
    end

    context "type normalization" do
      it "handles all hyphenated type variants" do
        types_mapping = {
          "task-new" => :task_new,
          "docs-new" => :docs_new,
          "reflection-new" => :reflection_new,
          "reflection-list" => :reflection_list,
          "code-review-new" => :code_review_new
        }

        types_mapping.each do |input_type, expected_type|
          if expected_type == :reflection_list
            allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release)
              .and_return(success: true, type: :list, paths: ["test.md"])

            output = capture_stdout { command.call(type: input_type) }

            expect(output.strip).to eq("test.md")
            expect(mock_path_resolver).to have_received(:find_reflection_paths_in_current_release)
          else
            allow(mock_path_resolver).to receive(:resolve_path).with("test", type: expected_type)
              .and_return(success: true, type: :single, path: "test.md")

            output = capture_stdout { command.call(type: input_type, input: "test") }

            expect(output.strip).to eq("test.md")
            expect(mock_path_resolver).to have_received(:resolve_path).with("test", type: expected_type)
          end
        end
      end

      it "handles all underscore type variants" do
        types_mapping = {
          "task_new" => :task_new,
          "docs_new" => :docs_new,
          "reflection_new" => :reflection_new,
          "reflection_list" => :reflection_list,
          "code_review_new" => :code_review_new
        }

        types_mapping.each do |input_type, expected_type|
          if expected_type == :reflection_list
            allow(mock_path_resolver).to receive(:find_reflection_paths_in_current_release)
              .and_return(success: true, type: :list, paths: ["test.md"])

            output = capture_stdout { command.call(type: input_type) }

            expect(output.strip).to eq("test.md")
            expect(mock_path_resolver).to have_received(:find_reflection_paths_in_current_release)
          else
            allow(mock_path_resolver).to receive(:resolve_path).with("test", type: expected_type)
              .and_return(success: true, type: :single, path: "test.md")

            output = capture_stdout { command.call(type: input_type, input: "test") }

            expect(output.strip).to eq("test.md")
            expect(mock_path_resolver).to have_received(:resolve_path).with("test", type: expected_type)
          end
        end
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

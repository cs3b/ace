# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/cli/commands/ideas/capture"
require "stringio"
require "tmpdir"
require "tempfile"

RSpec.describe "Capture-It CLI" do
  let(:capture_command) { CodingAgentTools::Cli::Commands::Ideas::Capture.new }
  let(:mock_idea_capture) { instance_double(CodingAgentTools::Organisms::IdeaCapture) }
  let(:success_result) do
    CodingAgentTools::Organisms::IdeaCapture::CaptureResult.new(
      true,
      "/fake/path/to/captured_idea.md",
      nil,
      nil
    )
  end
  let(:failure_result) do
    CodingAgentTools::Organisms::IdeaCapture::CaptureResult.new(
      false,
      nil,
      "Input too large: 10.5 KB, 1500 words. Use --big-user-input-allowed to proceed",
      nil
    )
  end

  before do
    # Mock the IdeaCapture organism
    allow(CodingAgentTools::Organisms::IdeaCapture).to receive(:new).and_return(mock_idea_capture)
    allow(mock_idea_capture).to receive(:capture_idea).and_return(success_result)
  end

  describe "capture command" do
    context "with valid text input" do
      let(:idea_text) { "This is a great idea for implementing user authentication" }

      it "captures idea successfully" do
        output = capture_stdout { capture_command.call(idea_text: idea_text) }

        expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
          model: nil,
          debug: nil,
          big_user_input_allowed: nil,
          commit_after_capture: nil
        )
        expect(mock_idea_capture).to have_received(:capture_idea).with(idea_text)
        expect(output).to include("Created: /fake/path/to/captured_idea.md")
      end

      it "passes custom model option" do
        capture_stdout { capture_command.call(idea_text: idea_text, model: "anthropic:claude-3.5-sonnet") }

        expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
          model: "anthropic:claude-3.5-sonnet",
          debug: nil,
          big_user_input_allowed: nil,
          commit_after_capture: nil
        )
      end

      it "enables debug mode" do
        capture_stdout { capture_command.call(idea_text: idea_text, debug: true) }

        expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
          model: nil,
          debug: true,
          big_user_input_allowed: nil,
          commit_after_capture: nil
        )
      end

      it "allows big user input" do
        capture_stdout { capture_command.call(idea_text: idea_text, big_user_input_allowed: true) }

        expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
          model: nil,
          debug: nil,
          big_user_input_allowed: true,
          commit_after_capture: nil
        )
      end

      it "combines multiple options" do
        capture_stdout do
          capture_command.call(
            idea_text: idea_text,
            model: "openai:gpt-4o",
            debug: true,
            big_user_input_allowed: true
          )
        end

        expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
          model: "openai:gpt-4o",
          debug: true,
          big_user_input_allowed: true,
          commit_after_capture: nil
        )
      end
    end

    context "with clipboard input" do
      before do
        # Mock clipboard commands for different platforms
        allow(capture_command).to receive(:`).with("pbpaste 2>/dev/null").and_return("Clipboard content from macOS")
        allow($?).to receive(:exitstatus).and_return(0)
      end

      it "reads from clipboard successfully" do
        output = capture_stdout { capture_command.call(clipboard: true) }

        expect(mock_idea_capture).to have_received(:capture_idea).with("Clipboard content from macOS")
        expect(output).to include("Created: /fake/path/to/captured_idea.md")
      end

      it "combines clipboard with other options" do
        capture_stdout { capture_command.call(clipboard: true, model: "mistral:mistral-large") }

        expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
          model: "mistral:mistral-large",
          debug: nil,
          big_user_input_allowed: nil,
          commit_after_capture: nil
        )
      end

      context "when clipboard is empty" do
        before do
          # Mock pbpaste to succeed but return empty content (first command in the list)
          allow(capture_command).to receive(:`).with("pbpaste 2>/dev/null").and_return("")
          # Mock other commands to fail
          allow(capture_command).to receive(:`).with("xclip -selection clipboard -o 2>/dev/null").and_return("")
          allow(capture_command).to receive(:`).with("xsel --clipboard --output 2>/dev/null").and_return("")
          allow(capture_command).to receive(:`).with("powershell.exe Get-Clipboard 2>/dev/null").and_return("")
          allow($?).to receive(:exitstatus).and_return(0)
        end

        it "shows clipboard error message" do
          output = capture_stdout { capture_command.call(clipboard: true) }

          expect(output).to include("Error: Could not read from clipboard")
          expect(output).to include("Please install pbpaste (macOS), xclip/xsel (Linux)")
        end
      end

      context "when clipboard command fails" do
        before do
          allow(capture_command).to receive(:`).and_return("")
          allow($?).to receive(:exitstatus).and_return(1)
        end

        it "shows clipboard error message" do
          output = capture_stdout { capture_command.call(clipboard: true) }

          expect(output).to include("Error: Could not read from clipboard")
          expect(output).to include("Please install pbpaste (macOS), xclip/xsel (Linux)")
        end
      end
    end

    context "with file input" do
      let(:temp_file) { Tempfile.new("test_idea") }
      let(:file_content) { "This is content from a file\nWith multiple lines" }

      before do
        temp_file.write(file_content)
        temp_file.close
      end

      after do
        temp_file.unlink
      end

      it "reads from file successfully" do
        output = capture_stdout { capture_command.call(file: temp_file.path) }

        expect(mock_idea_capture).to have_received(:capture_idea).with(file_content.strip)
        expect(output).to include("Created: /fake/path/to/captured_idea.md")
      end

      it "combines file input with other options" do
        capture_stdout do
          capture_command.call(
            file: temp_file.path,
            debug: true,
            big_user_input_allowed: true
          )
        end

        expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
          model: nil,
          debug: true,
          big_user_input_allowed: true,
          commit_after_capture: nil
        )
      end

      context "when file does not exist" do
        it "shows file not found error" do
          output = capture_stdout { capture_command.call(file: "/nonexistent/file.txt") }

          expect(output).to include("Error: File not found: /nonexistent/file.txt")
        end
      end

      context "when file is empty" do
        let(:empty_file) { Tempfile.new("empty_idea") }

        before { empty_file.close }
        after { empty_file.unlink }

        it "shows empty file error" do
          output = capture_stdout { capture_command.call(file: empty_file.path) }

          expect(output).to include("Error: File is empty: #{empty_file.path}")
        end
      end

      context "when file is not readable" do
        before do
          File.chmod(0o000, temp_file.path) # Remove all permissions
        end

        after do
          File.chmod(0o644, temp_file.path) # Restore permissions for cleanup
        end

        it "shows file not readable error" do
          output = capture_stdout { capture_command.call(file: temp_file.path) }

          expect(output).to include("Error: File not readable: #{temp_file.path}")
        end
      end
    end

    context "with input validation errors" do
      before do
        allow(mock_idea_capture).to receive(:capture_idea).and_return(failure_result)
      end

      it "shows error message and exits with status 1" do
        expect do
          capture_stdout { capture_command.call(idea_text: "test idea") }
        end.to raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      end

      it "displays the specific error message" do
        output = capture_stdout do
          expect { capture_command.call(idea_text: "test idea") }.to raise_error(SystemExit)
        end

        expect(output).to include("Error: Input too large: 10.5 KB, 1500 words. Use --big-user-input-allowed to proceed")
      end
    end

    context "with no input provided" do
      it "shows usage information for no arguments" do
        output = capture_stdout { capture_command.call }

        expect(output).to include("Error: No input provided")
        expect(output).to include("Usage: capture-it 'your idea text'")
        expect(output).to include("capture-it --clipboard")
        expect(output).to include("capture-it --file path/to/file.txt")
      end

      it "shows usage information for empty string" do
        output = capture_stdout { capture_command.call(idea_text: "") }

        expect(output).to include("Error: No input provided")
        expect(output).to include("Usage: capture-it 'your idea text'")
      end

      it "shows usage information for whitespace-only string" do
        output = capture_stdout { capture_command.call(idea_text: "   \n  \t  ") }

        expect(output).to include("Error: No input provided")
        expect(output).to include("Usage: capture-it 'your idea text'")
      end
    end

    context "error handling" do
      context "without debug mode" do
        before do
          allow(mock_idea_capture).to receive(:capture_idea).and_raise(StandardError, "Unexpected error occurred")
        end

        it "shows basic error message" do
          output = capture_stdout do
            expect { capture_command.call(idea_text: "test idea") }.to raise_error(SystemExit)
          end

          expect(output).to include("Error: Unexpected error occurred")
          expect(output).not_to include("Debug:")
        end

        it "exits with status 1" do
          expect do
            capture_stdout { capture_command.call(idea_text: "test idea") }
          end.to raise_error(SystemExit) do |error|
            expect(error.status).to eq(1)
          end
        end
      end

      context "with debug mode" do
        before do
          error = StandardError.new("Unexpected error occurred")
          error.set_backtrace(["line 1", "line 2", "line 3"])
          allow(mock_idea_capture).to receive(:capture_idea).and_raise(error)
        end

        it "shows detailed error information including backtrace" do
          output = capture_stdout do
            expect { capture_command.call(idea_text: "test idea", debug: true) }.to raise_error(SystemExit)
          end

          expect(output).to include("Debug: Full error details:")
          expect(output).to include("Unexpected error occurred")
          expect(output).to include("line 1")
          expect(output).to include("line 2")
          expect(output).to include("line 3")
        end
      end
    end

    context "input size validation" do
      let(:large_input) { "word " * 2000 } # Create a very large input

      context "without big-user-input-allowed flag" do
        before do
          large_input_result = CodingAgentTools::Organisms::IdeaCapture::CaptureResult.new(
            false,
            nil,
            "Input too large: #{(large_input.length / 1024.0).round(1)} KB, #{large_input.split.length} words. Use --big-user-input-allowed to proceed",
            nil
          )
          allow(mock_idea_capture).to receive(:capture_idea).and_return(large_input_result)
        end

        it "rejects large input" do
          output = capture_stdout do
            expect { capture_command.call(idea_text: large_input) }.to raise_error(SystemExit)
          end

          expect(output).to include("Input too large")
          expect(output).to include("Use --big-user-input-allowed to proceed")
        end
      end

      context "with big-user-input-allowed flag" do
        it "accepts large input" do
          output = capture_stdout { capture_command.call(idea_text: large_input, big_user_input_allowed: true) }

          expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
            model: nil,
            debug: nil,
            big_user_input_allowed: true,
            commit_after_capture: nil
          )
          expect(output).to include("Created: /fake/path/to/captured_idea.md")
        end
      end
    end

    context "with --commit flag" do
      context "when --commit flag is provided" do
        it "passes commit_after_capture: true to IdeaCapture organism" do
          capture_stdout { capture_command.call(idea_text: "test idea", commit: true) }

          expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
            model: nil,
            debug: nil,
            big_user_input_allowed: nil,
            commit_after_capture: true
          )
        end
      end

      context "when --commit flag is not provided" do
        it "passes commit_after_capture: false to IdeaCapture organism" do
          capture_stdout { capture_command.call(idea_text: "test idea") }

          expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
            model: nil,
            debug: nil,
            big_user_input_allowed: nil,
            commit_after_capture: nil
          )
        end
      end

      context "when --commit flag is used with other options" do
        it "combines --commit with --model flag correctly" do
          capture_stdout do
            capture_command.call(
              idea_text: "test idea",
              commit: true,
              model: "anthropic:claude-3.5-sonnet"
            )
          end

          expect(CodingAgentTools::Organisms::IdeaCapture).to have_received(:new).with(
            model: "anthropic:claude-3.5-sonnet",
            debug: nil,
            big_user_input_allowed: nil,
            commit_after_capture: true
          )
        end
      end
    end
  end

  describe "command metadata" do
    it "has correct description" do
      expect(CodingAgentTools::Cli::Commands::Ideas::Capture.description).to eq("Capture and enhance raw ideas for the project")
    end

    it "has correct arguments" do
      arguments = CodingAgentTools::Cli::Commands::Ideas::Capture.arguments
      argument_names = arguments.map(&:name)
      expect(argument_names).to include(:idea_text)

      idea_text_arg = arguments.find { |arg| arg.name == :idea_text }
      expect(idea_text_arg.options[:desc]).to eq("Raw idea text to capture and enhance")
    end

    it "has correct options" do
      options = CodingAgentTools::Cli::Commands::Ideas::Capture.options
      option_names = options.map(&:name)

      expect(option_names).to include(:clipboard)
      expect(option_names).to include(:file)
      expect(option_names).to include(:model)
      expect(option_names).to include(:debug)
      expect(option_names).to include(:big_user_input_allowed)
      expect(option_names).to include(:commit)

      # Check option defaults and types
      clipboard_option = options.find { |opt| opt.name == :clipboard }
      expect(clipboard_option.options[:type]).to eq(:boolean)
      expect(clipboard_option.options[:default]).to be false

      model_option = options.find { |opt| opt.name == :model }
      expect(model_option.options[:type]).to eq(:string)
      expect(model_option.options[:default]).to eq("gflash")

      debug_option = options.find { |opt| opt.name == :debug }
      expect(debug_option.options[:type]).to eq(:boolean)
      expect(debug_option.options[:default]).to be false

      big_input_option = options.find { |opt| opt.name == :big_user_input_allowed }
      expect(big_input_option.options[:type]).to eq(:boolean)
      expect(big_input_option.options[:default]).to be false

      commit_option = options.find { |opt| opt.name == :commit }
      expect(commit_option.options[:type]).to eq(:boolean)
      expect(commit_option.options[:default]).to be false
    end
  end

  describe "output formatting" do
    it "displays success message with output path" do
      output = capture_stdout { capture_command.call(idea_text: "test idea") }

      expect(output.strip).to eq("Created: /fake/path/to/captured_idea.md")
    end

    it "displays error message on failure" do
      allow(mock_idea_capture).to receive(:capture_idea).and_return(failure_result)

      output = capture_stdout do
        expect { capture_command.call(idea_text: "test idea") }.to raise_error(SystemExit)
      end

      expect(output).to include("Error: Input too large")
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

  def with_env(new_env)
    old_env = ENV.to_h
    new_env.each { |key, value| ENV[key] = value }
    yield
  ensure
    ENV.replace(old_env)
  end
end

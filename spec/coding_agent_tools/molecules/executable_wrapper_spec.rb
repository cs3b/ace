# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/executable_wrapper"

RSpec.describe CodingAgentTools::Molecules::ExecutableWrapper do
  let(:command_path) { ["llm", "models"] }
  let(:registration_method) { :register_llm_commands }
  let(:executable_name) { "llm-gemini-models" }

  let(:wrapper) do
    described_class.new(
      command_path: command_path,
      registration_method: registration_method,
      executable_name: executable_name
    )
  end

  describe "#initialize" do
    it "initializes with required parameters" do
      expect(wrapper).to be_instance_of(described_class)
    end

    it "stores configuration correctly" do
      expect(wrapper.send(:command_path)).to eq(command_path)
      expect(wrapper.send(:registration_method)).to eq(registration_method)
      expect(wrapper.send(:executable_name)).to eq(executable_name)
    end
  end

  describe "#call" do
    let(:original_argv) { ARGV.dup }
    let(:original_stdout) { $stdout }
    let(:original_stderr) { $stderr }

    before do
      # Store original values
      @original_argv = ARGV.dup
      @original_stdout = $stdout
      @original_stderr = $stderr
    end

    after do
      # Restore original values
      ARGV.clear
      ARGV.concat(@original_argv)
      $stdout = @original_stdout
      $stderr = @original_stderr
    end

    context "with mocked CLI execution" do
      let(:cli_instance) { instance_double("Dry::CLI") }
      let(:commands_class) { class_double("CodingAgentTools::Cli::Commands") }
      let(:cli_class) { class_double("Dry::CLI", new: cli_instance) }

      before do
        # Mock the CLI components to avoid actual execution
        allow_any_instance_of(described_class).to receive(:setup_bundler)
        allow_any_instance_of(described_class).to receive(:setup_load_path)
        allow_any_instance_of(described_class).to receive(:require_dependencies)

        # Mock command registration
        allow(commands_class).to receive(registration_method)
        stub_const("CodingAgentTools::Cli::Commands", commands_class)

        # Mock CLI execution
        allow(cli_instance).to receive(:call)
        stub_const("Dry::CLI", cli_class)
      end

      it "modifies ARGV with command path" do
        original_args = ["--help"]
        ARGV.clear
        ARGV.concat(original_args)

        wrapper.call

        expect(ARGV).to eq(["llm", "models", "--help"])
      end

      it "calls command registration method" do
        expect(CodingAgentTools::Cli::Commands).to receive(registration_method)
        wrapper.call
      end

      it "executes CLI" do
        expect(cli_class).to receive(:new).and_return(cli_instance)
        expect(cli_instance).to receive(:call)
        wrapper.call
      end

      it "restores streams after execution" do
        wrapper.call
        expect($stdout).to eq(original_stdout)
        expect($stderr).to eq(original_stderr)
      end
    end

    context "when CLI execution raises SystemExit" do
      let(:exit_code) { 1 }
      let(:system_exit) { SystemExit.new(exit_code) }

      before do
        allow_any_instance_of(described_class).to receive(:setup_bundler)
        allow_any_instance_of(described_class).to receive(:setup_load_path)
        allow_any_instance_of(described_class).to receive(:require_dependencies)

        commands_class = class_double("CodingAgentTools::Cli::Commands")
        allow(commands_class).to receive(registration_method)
        stub_const("CodingAgentTools::Cli::Commands", commands_class)

        cli_instance = instance_double("Dry::CLI")
        allow(cli_instance).to receive(:call).and_raise(system_exit)
        cli_class = class_double("Dry::CLI", new: cli_instance)
        stub_const("Dry::CLI", cli_class)
      end

      it "re-raises SystemExit" do
        expect { wrapper.call }.to raise_error(SystemExit)
      end

      it "restores streams before re-raising" do
        expect { wrapper.call }.to raise_error(SystemExit)
        expect($stdout).to eq(original_stdout)
        expect($stderr).to eq(original_stderr)
      end
    end

    context "when an unexpected error occurs" do
      let(:error) { StandardError.new("Test error") }

      before do
        allow_any_instance_of(described_class).to receive(:setup_bundler).and_raise(error)

        # Mock ErrorReporter
        error_reporter = class_double("CodingAgentTools::ErrorReporter")
        allow(error_reporter).to receive(:call)
        stub_const("CodingAgentTools::ErrorReporter", error_reporter)

        # Mock exit to prevent actual exit
        allow_any_instance_of(described_class).to receive(:exit)
      end

      it "handles error through ErrorReporter" do
        expect(CodingAgentTools::ErrorReporter).to receive(:call).with(error, debug: false)
        wrapper.call
      end

      it "exits with code 1" do
        expect_any_instance_of(described_class).to receive(:exit).with(1)
        wrapper.call
      end

      it "restores streams after error" do
        wrapper.call
        expect($stdout).to eq(original_stdout)
        expect($stderr).to eq(original_stderr)
      end
    end
  end

  describe "output modification" do
    let(:content) do
      {
        stdout: "llm-gemini-models llm models --help",
        stderr: 'Usage: "some-path llm models"'
      }
    end

    it "modifies stdout content correctly" do
      modified = wrapper.send(:modify_output_messages, content)
      expect(modified[:stdout]).to eq("llm-gemini-models --help")
    end

    it "modifies stderr content with command references" do
      modified = wrapper.send(:modify_output_messages, content)
      expect(modified[:stderr]).to eq('Usage: "llm-gemini-models"')
    end

    context "for query commands" do
      let(:command_path) { ["llm", "query"] }
      let(:executable_name) { "llm-gemini-query" }
      let(:content) do
        {
          stdout: "",
          stderr: 'Usage: "some-path llm query PROMPT"'
        }
      end

      it "handles query command usage patterns" do
        modified = wrapper.send(:modify_output_messages, content)
        expect(modified[:stderr]).to eq('Usage: "llm-gemini-query PROMPT"')
      end
    end

    context "when content doesn't contain command string" do
      let(:content) do
        {
          stdout: "Regular output",
          stderr: "Regular error"
        }
      end

      it "returns content unchanged" do
        modified = wrapper.send(:modify_output_messages, content)
        expect(modified).to eq(content)
      end
    end
  end

  describe "private methods" do
    describe "#bundler_environment?" do
      it "returns true when BUNDLE_GEMFILE is set" do
        allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return("/path/to/Gemfile")
        expect(wrapper.send(:bundler_environment?)).to be true
      end

      it "returns true when Gemfile exists" do
        allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return(nil)
        allow(File).to receive(:exist?).and_return(true)
        expect(wrapper.send(:bundler_environment?)).to be true
      end

      it "returns false when neither condition is met" do
        allow(ENV).to receive(:[]).with("BUNDLE_GEMFILE").and_return(nil)
        allow(File).to receive(:exist?).and_return(false)
        expect(wrapper.send(:bundler_environment?)).to be false
      end
    end

    describe "#prepare_arguments" do
      let(:original_argv) { ["--help", "--verbose"] }

      before do
        ARGV.clear
        ARGV.concat(original_argv)
      end

      after do
        ARGV.clear
        ARGV.concat(original_argv)
      end

      it "prepends command path to ARGV" do
        wrapper.send(:prepare_arguments)
        expect(ARGV).to eq(["llm", "models", "--help", "--verbose"])
      end
    end

    describe "#get_captured_content" do
      it "returns captured stdout and stderr" do
        wrapper.instance_variable_set(:@captured_stdout, StringIO.new("stdout content"))
        wrapper.instance_variable_set(:@captured_stderr, StringIO.new("stderr content"))

        content = wrapper.send(:get_captured_content)

        expect(content[:stdout]).to eq("stdout content")
        expect(content[:stderr]).to eq("stderr content")
      end
    end
  end

  describe "integration with different command configurations" do
    context "with LMS commands" do
      let(:command_path) { ["lms", "models"] }
      let(:registration_method) { :register_lms_commands }
      let(:executable_name) { "llm-lmstudio-models" }

      it "works with different command configurations" do
        expect(wrapper.send(:command_path)).to eq(["lms", "models"])
        expect(wrapper.send(:registration_method)).to eq(:register_lms_commands)
        expect(wrapper.send(:executable_name)).to eq("llm-lmstudio-models")
      end
    end

    context "with query commands" do
      let(:command_path) { ["lms", "query"] }
      let(:registration_method) { :register_lms_commands }
      let(:executable_name) { "llm-lmstudio-query" }

      it "works with query command configurations" do
        expect(wrapper.send(:command_path)).to eq(["lms", "query"])
        expect(wrapper.send(:registration_method)).to eq(:register_lms_commands)
        expect(wrapper.send(:executable_name)).to eq("llm-lmstudio-query")
      end
    end
  end
end

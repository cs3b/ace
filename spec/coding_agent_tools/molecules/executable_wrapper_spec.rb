# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/molecules/executable_wrapper'

RSpec.describe CodingAgentTools::Molecules::ExecutableWrapper do
  let(:command_path) { ['llm', 'models'] }
  let(:registration_method) { :register_llm_commands }
  let(:executable_name) { 'llm-gemini-models' }

  let(:wrapper) do
    described_class.new(
      command_path: command_path,
      registration_method: registration_method,
      executable_name: executable_name
    )
  end

  describe '#initialize' do
    it 'initializes with required parameters' do
      expect(wrapper).to be_instance_of(described_class)
    end

    it 'stores configuration correctly' do
      expect(wrapper.send(:command_path)).to eq(command_path)
      expect(wrapper.send(:registration_method)).to eq(registration_method)
      expect(wrapper.send(:executable_name)).to eq(executable_name)
    end
  end

  describe '#call' do
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

    context 'with mocked CLI execution' do
      let(:cli_instance) { instance_double('Dry::CLI') }
      let(:commands_class) { class_double('CodingAgentTools::Cli::Commands') }
      let(:cli_class) { class_double('Dry::CLI', new: cli_instance) }

      before do
        # Mock the CLI components to avoid actual execution
        allow_any_instance_of(described_class).to receive(:setup_bundler)
        allow_any_instance_of(described_class).to receive(:setup_load_path)
        allow_any_instance_of(described_class).to receive(:require_dependencies)

        # Mock command registration
        allow(commands_class).to receive(registration_method)
        stub_const('CodingAgentTools::Cli::Commands', commands_class)

        # Mock CLI execution
        allow(cli_instance).to receive(:call)
        stub_const('Dry::CLI', cli_class)
      end

      it 'modifies ARGV with command path' do
        original_args = ['--help']
        ARGV.clear
        ARGV.concat(original_args)

        wrapper.call

        expect(ARGV).to eq(['llm', 'models', '--help'])
      end

      it 'calls command registration method' do
        expect(CodingAgentTools::Cli::Commands).to receive(registration_method)
        wrapper.call
      end

      it 'executes CLI' do
        expect(cli_class).to receive(:new).and_return(cli_instance)
        expect(cli_instance).to receive(:call)
        wrapper.call
      end

      it 'restores streams after execution' do
        wrapper.call
        expect($stdout).to eq(original_stdout)
        expect($stderr).to eq(original_stderr)
      end
    end

    context 'when CLI execution raises SystemExit' do
      let(:exit_code) { 1 }
      let(:system_exit) { SystemExit.new(exit_code) }

      before do
        allow_any_instance_of(described_class).to receive(:setup_bundler)
        allow_any_instance_of(described_class).to receive(:setup_load_path)
        allow_any_instance_of(described_class).to receive(:require_dependencies)

        commands_class = class_double('CodingAgentTools::Cli::Commands')
        allow(commands_class).to receive(registration_method)
        stub_const('CodingAgentTools::Cli::Commands', commands_class)

        cli_instance = instance_double('Dry::CLI')
        allow(cli_instance).to receive(:call).and_raise(system_exit)
        cli_class = class_double('Dry::CLI', new: cli_instance)
        stub_const('Dry::CLI', cli_class)
      end

      it 're-raises SystemExit' do
        expect { wrapper.call }.to raise_error(SystemExit)
      end

      it 'restores streams before re-raising' do
        expect { wrapper.call }.to raise_error(SystemExit)
        expect($stdout).to eq(original_stdout)
        expect($stderr).to eq(original_stderr)
      end
    end

    context 'when an unexpected error occurs' do
      let(:error) { StandardError.new('Test error') }

      before do
        allow_any_instance_of(described_class).to receive(:setup_bundler).and_raise(error)

        # Mock ErrorReporter
        error_reporter = class_double('CodingAgentTools::ErrorReporter')
        allow(error_reporter).to receive(:call)
        stub_const('CodingAgentTools::ErrorReporter', error_reporter)

        # Mock exit to prevent actual exit
        allow_any_instance_of(described_class).to receive(:exit)
      end

      it 'handles error through ErrorReporter' do
        expect(CodingAgentTools::ErrorReporter).to receive(:call).with(error, debug: false)
        wrapper.call
      end

      it 'exits with code 1' do
        expect_any_instance_of(described_class).to receive(:exit).with(1)
        wrapper.call
      end

      it 'restores streams after error' do
        wrapper.call
        expect($stdout).to eq(original_stdout)
        expect($stderr).to eq(original_stderr)
      end
    end
  end

  describe 'output modification' do
    let(:content) do
      {
        stdout: 'llm-gemini-models llm models --help',
        stderr: 'Usage: "some-path llm models"'
      }
    end

    it 'modifies stdout content correctly' do
      modified = wrapper.send(:modify_output_messages, content)
      expect(modified[:stdout]).to eq('llm-gemini-models --help')
    end

    it 'modifies stderr content with command references' do
      modified = wrapper.send(:modify_output_messages, content)
      expect(modified[:stderr]).to eq('Usage: "llm-gemini-models"')
    end

    context 'for query commands' do
      let(:command_path) { ['llm', 'query'] }
      let(:executable_name) { 'llm-gemini-query' }
      let(:content) do
        {
          stdout: '',
          stderr: 'Usage: "some-path llm query PROMPT"'
        }
      end

      it 'handles query command usage patterns' do
        modified = wrapper.send(:modify_output_messages, content)
        expect(modified[:stderr]).to eq('Usage: "llm-gemini-query PROMPT"')
      end
    end

    context "when content doesn't contain command string" do
      let(:content) do
        {
          stdout: 'Regular output',
          stderr: 'Regular error'
        }
      end

      it 'returns content unchanged' do
        modified = wrapper.send(:modify_output_messages, content)
        expect(modified).to eq(content)
      end
    end
  end

  describe 'private methods' do
    describe '#bundler_environment?' do
      it 'returns true when BUNDLE_GEMFILE is set' do
        allow(ENV).to receive(:[]).with('BUNDLE_GEMFILE').and_return('/path/to/Gemfile')
        expect(wrapper.send(:bundler_environment?)).to be true
      end

      it 'returns true when Gemfile exists' do
        allow(ENV).to receive(:[]).with('BUNDLE_GEMFILE').and_return(nil)
        allow(File).to receive(:exist?).and_return(true)
        expect(wrapper.send(:bundler_environment?)).to be true
      end

      it 'returns false when neither condition is met' do
        allow(ENV).to receive(:[]).with('BUNDLE_GEMFILE').and_return(nil)
        allow(File).to receive(:exist?).and_return(false)
        expect(wrapper.send(:bundler_environment?)).to be false
      end
    end

    describe '#setup_bundler' do
      context 'when bundler is already defined' do
        before do
          stub_const('Bundler', double('Bundler'))
        end

        it 'returns early without setup' do
          expect(wrapper.send(:setup_bundler)).to be_nil
        end
      end

      context 'when not in bundler environment' do
        before do
          allow(wrapper).to receive(:bundler_environment?).and_return(false)
        end

        it 'returns early without setup' do
          expect(wrapper.send(:setup_bundler)).to be_nil
        end
      end

      context 'when in bundler environment and Gemfile exists' do
        before do
          # Remove Bundler constant to avoid early return
          hide_const('Bundler') if defined?(Bundler)
          allow(wrapper).to receive(:bundler_environment?).and_return(true)
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:expand_path).and_return('/path/to/Gemfile')
        end

        it 'sets BUNDLE_GEMFILE environment variable' do
          expect(ENV).to receive(:[]=).with('BUNDLE_GEMFILE', '/path/to/Gemfile')
          allow_any_instance_of(Kernel).to receive(:require).with('bundler/setup')
          wrapper.send(:setup_bundler)
        end

        it 'requires bundler/setup' do
          allow(ENV).to receive(:[]=)
          expect_any_instance_of(Kernel).to receive(:require).with('bundler/setup')
          wrapper.send(:setup_bundler)
        end
      end

      context 'when bundler/setup fails to load' do
        before do
          # Remove Bundler constant to avoid early return
          hide_const('Bundler') if defined?(Bundler)
          allow(wrapper).to receive(:bundler_environment?).and_return(true)
          allow(File).to receive(:exist?).and_return(true)
          allow(File).to receive(:expand_path).and_return('/path/to/Gemfile')
          allow(ENV).to receive(:[]=)
          allow_any_instance_of(Kernel).to receive(:require).with('bundler/setup').and_raise(LoadError)
        end

        it 'continues without error' do
          expect { wrapper.send(:setup_bundler) }.not_to raise_error
        end
      end
    end

    describe '#setup_load_path' do
      it 'adds lib path to $LOAD_PATH if not present' do
        lib_path = '/path/to/lib'
        allow(File).to receive(:expand_path).with('../../../../lib', anything).and_return(lib_path)
        allow($LOAD_PATH).to receive(:include?).with(lib_path).and_return(false)

        expect($LOAD_PATH).to receive(:unshift).with(lib_path)
        wrapper.send(:setup_load_path)
      end

      it 'does not add lib path to $LOAD_PATH if already present' do
        lib_path = '/path/to/lib'
        allow(File).to receive(:expand_path).with('../../../../lib', anything).and_return(lib_path)
        allow($LOAD_PATH).to receive(:include?).with(lib_path).and_return(true)

        expect($LOAD_PATH).not_to receive(:unshift)
        wrapper.send(:setup_load_path)
      end
    end

    describe '#require_dependencies' do
      it 'requires all necessary dependencies' do
        expect_any_instance_of(Kernel).to receive(:require).with('coding_agent_tools')
        expect_any_instance_of(Kernel).to receive(:require).with('coding_agent_tools/cli')
        expect_any_instance_of(Kernel).to receive(:require).with('coding_agent_tools/error_reporter')
        wrapper.send(:require_dependencies)
      end
    end

    describe '#prepare_arguments' do
      let(:original_argv) { ['--help', '--verbose'] }

      before do
        ARGV.clear
        ARGV.concat(original_argv)
      end

      after do
        ARGV.clear
        ARGV.concat(original_argv)
      end

      it 'prepends command path to ARGV' do
        wrapper.send(:prepare_arguments)
        expect(ARGV).to eq(['llm', 'models', '--help', '--verbose'])
      end
    end

    describe '#get_captured_content' do
      it 'returns captured stdout and stderr' do
        wrapper.instance_variable_set(:@captured_stdout, StringIO.new('stdout content'))
        wrapper.instance_variable_set(:@captured_stderr, StringIO.new('stderr content'))

        content = wrapper.send(:get_captured_content)

        expect(content[:stdout]).to eq('stdout content')
        expect(content[:stderr]).to eq('stderr content')
      end
    end

    describe '#execute_cli' do
      let(:cli_instance) { instance_double('Dry::CLI') }
      let(:commands_class) { class_double('CodingAgentTools::Cli::Commands') }

      before do
        wrapper.instance_variable_set(:@captured_stdout, StringIO.new)
        wrapper.instance_variable_set(:@captured_stderr, StringIO.new)

        # Mock Dry::CLI and its instantiation
        allow(Dry::CLI).to receive(:new).with(commands_class).and_return(cli_instance)
        stub_const('CodingAgentTools::Cli::Commands', commands_class)
      end

      context 'when CLI returns nil' do
        before do
          allow(cli_instance).to receive(:call).and_return(nil)
        end

        it 'returns 0 for successful completion' do
          expect(wrapper.send(:execute_cli)).to eq(0)
        end
      end

      context 'when CLI returns integer status code' do
        before do
          allow(cli_instance).to receive(:call).and_return(1)
        end

        it 'returns the integer status code' do
          expect(wrapper.send(:execute_cli)).to eq(1)
        end
      end

      context 'when CLI returns unexpected type' do
        let(:captured_stderr) { StringIO.new }

        before do
          allow(cli_instance).to receive(:call).and_return(Set.new)
          wrapper.instance_variable_set(:@captured_stderr, captured_stderr)
        end

        context 'with error messages in stderr' do
          before do
            captured_stderr.write('Error: Something went wrong')
            captured_stderr.rewind
          end

          it 'returns 1 to indicate failure' do
            expect(wrapper.send(:execute_cli)).to eq(1)
          end
        end

        context 'without error messages in stderr' do
          it 'returns 0 to indicate success' do
            expect(wrapper.send(:execute_cli)).to eq(0)
          end
        end
      end
    end

    describe '#setup_output_capture' do
      it 'captures original streams and sets up StringIO' do
        original_stdout = $stdout
        original_stderr = $stderr

        wrapper.send(:setup_output_capture)

        expect(wrapper.instance_variable_get(:@original_stdout)).to eq(original_stdout)
        expect(wrapper.instance_variable_get(:@original_stderr)).to eq(original_stderr)
        expect($stdout).to be_a(StringIO)
        expect($stderr).to be_a(StringIO)
      end
    end

    describe '#process_output_and_exit' do
      let(:content) { { stdout: 'output', stderr: 'error' } }

      before do
        wrapper.instance_variable_set(:@original_stdout, StringIO.new)
        wrapper.instance_variable_set(:@original_stderr, StringIO.new)
        wrapper.instance_variable_set(:@captured_stdout, StringIO.new('output'))
        wrapper.instance_variable_set(:@captured_stderr, StringIO.new('error'))

        allow(wrapper).to receive(:modify_output_messages).and_return(content)
        allow(wrapper).to receive(:exit)
      end

      context 'with status code 0' do
        it 'does not exit' do
          expect(wrapper).not_to receive(:exit)
          wrapper.send(:process_output_and_exit, 0)
        end
      end

      context 'with non-zero status code' do
        it 'exits with the status code' do
          expect(wrapper).to receive(:exit).with(1)
          wrapper.send(:process_output_and_exit, 1)
        end
      end

      context 'with non-integer status code' do
        it 'assumes success and does not exit' do
          expect(wrapper).not_to receive(:exit)
          wrapper.send(:process_output_and_exit, 'unexpected')
        end
      end
    end

    describe '#restore_streams' do
      it 'restores original stdout and stderr' do
        original_stdout = StringIO.new
        original_stderr = StringIO.new

        wrapper.instance_variable_set(:@original_stdout, original_stdout)
        wrapper.instance_variable_set(:@original_stderr, original_stderr)

        wrapper.send(:restore_streams)

        expect($stdout).to eq(original_stdout)
        expect($stderr).to eq(original_stderr)
      end

      it 'handles nil original streams gracefully' do
        wrapper.instance_variable_set(:@original_stdout, nil)
        wrapper.instance_variable_set(:@original_stderr, nil)

        expect { wrapper.send(:restore_streams) }.not_to raise_error
      end
    end

    describe '#print_modified_output' do
      let(:content) { { stdout: 'output content', stderr: 'error content' } }
      let(:original_stdout) { StringIO.new }
      let(:original_stderr) { StringIO.new }

      before do
        $stdout = original_stdout
        $stderr = original_stderr
        allow(wrapper).to receive(:modify_output_messages).and_return(content)
      end

      it 'prints stdout content to stdout' do
        wrapper.send(:print_modified_output, content)
        expect(original_stdout.string).to eq('output content')
      end

      it 'prints stderr content to stderr' do
        wrapper.send(:print_modified_output, content)
        expect(original_stderr.string).to eq('error content')
      end

      it 'does not print empty content' do
        empty_content = { stdout: '', stderr: '' }
        allow(wrapper).to receive(:modify_output_messages).and_return(empty_content)

        wrapper.send(:print_modified_output, empty_content)
        expect(original_stdout.string).to be_empty
        expect(original_stderr.string).to be_empty
      end
    end

    describe '#modify_stdout_content' do
      let(:command_string) { 'llm models' }
      let(:content) { 'llm-gemini-models llm models --help' }

      it 'replaces command string with executable name' do
        result = wrapper.send(:modify_stdout_content, content, command_string)
        expect(result).to eq('llm-gemini-models --help')
      end
    end

    describe '#modify_stderr_content' do
      let(:command_string) { 'llm models' }

      it 'replaces quoted command string with executable name' do
        content = 'Usage: "some-path llm models --option"'
        result = wrapper.send(:modify_stderr_content, content, command_string)
        expect(result).to eq('Usage: "llm-gemini-models --option"')
      end

      it 'handles content without command string' do
        content = 'Regular error message'
        result = wrapper.send(:modify_stderr_content, content, command_string)
        expect(result).to eq('Regular error message')
      end

      it 'escapes regex special characters in command string' do
        special_command = 'test[command]'
        content = '"path test[command] args"'
        result = wrapper.send(:modify_stderr_content, content, special_command)
        expect(result).to eq('"llm-gemini-models args"')
      end
    end

    describe '#handle_error' do
      let(:error) { StandardError.new('Test error') }
      let(:error_reporter) { class_double('CodingAgentTools::ErrorReporter') }

      before do
        stub_const('CodingAgentTools::ErrorReporter', error_reporter)
        allow(error_reporter).to receive(:call)
        allow(wrapper).to receive(:exit)
      end

      it 'calls ErrorReporter with the error' do
        expect(error_reporter).to receive(:call).with(error, debug: false)
        wrapper.send(:handle_error, error)
      end

      it 'uses debug mode when DEBUG env var is true' do
        allow(ENV).to receive(:[]).with('DEBUG').and_return('true')
        expect(error_reporter).to receive(:call).with(error, debug: true)
        wrapper.send(:handle_error, error)
      end

      it 'exits with code 1' do
        expect(wrapper).to receive(:exit).with(1)
        wrapper.send(:handle_error, error)
      end
    end
  end

  describe 'integration with different command configurations' do
    context 'with LMS commands' do
      let(:command_path) { ['lms', 'models'] }
      let(:registration_method) { :register_lms_commands }
      let(:executable_name) { 'llm-lmstudio-models' }

      it 'works with different command configurations' do
        expect(wrapper.send(:command_path)).to eq(['lms', 'models'])
        expect(wrapper.send(:registration_method)).to eq(:register_lms_commands)
        expect(wrapper.send(:executable_name)).to eq('llm-lmstudio-models')
      end
    end

    context 'with query commands' do
      let(:command_path) { ['lms', 'query'] }
      let(:registration_method) { :register_lms_commands }
      let(:executable_name) { 'llm-lmstudio-query' }

      it 'works with query command configurations' do
        expect(wrapper.send(:command_path)).to eq(['lms', 'query'])
        expect(wrapper.send(:registration_method)).to eq(:register_lms_commands)
        expect(wrapper.send(:executable_name)).to eq('llm-lmstudio-query')
      end
    end
  end
end

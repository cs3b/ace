# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe CodingAgentTools::Cli::Commands::Git::Mv do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_orchestrator) { instance_double('CodingAgentTools::Organisms::Git::GitOrchestrator') }
  let(:source_and_destination) { ['old_file.rb', 'new_file.rb'] }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe '#call' do
    context 'with successful move operation' do
      let(:success_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: 'old_file.rb -> new_file.rb' },
            'dev-tools' => { success: true, stdout: '' }
          },
          repositories_processed: ['main-repo', 'dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:mv).and_return(success_result)
      end

      it 'executes mv operation and displays formatted output' do
        output = capture_stdout { command.call(source_and_destination: source_and_destination) }

        expect(output).to include('[main-repo] old_file.rb -> new_file.rb')
        expect(output).to include('[dev-tools] Move completed successfully')
        expect(output).to include('Move operations completed across repositories: main-repo, dev-tools')
        expect(mock_orchestrator).to have_received(:mv).with(['old_file.rb'], 'new_file.rb', hash_including(capture_output: true))
      end

      it 'returns 0 for successful execution' do
        capture_stdout { command.call(source_and_destination: source_and_destination) }
        expect(mock_orchestrator).to have_received(:mv)
      end

      it 'passes sources, destination and default options to orchestrator' do
        capture_stdout { command.call(source_and_destination: source_and_destination) }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:mv).with(
          ['old_file.rb'],
          'new_file.rb',
          hash_including(capture_output: true)
        )
      end
    end

    context 'with multiple sources' do
      let(:multiple_sources) { ['file1.rb', 'file2.rb', 'directory/'] }

      before do
        allow(mock_orchestrator).to receive(:mv).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Move completed' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'handles multiple source files correctly' do
        capture_stdout { command.call(source_and_destination: multiple_sources) }

        expect(mock_orchestrator).to have_received(:mv).with(
          ['file1.rb', 'file2.rb'],
          'directory/',
          hash_including(capture_output: true)
        )
      end
    end

    context 'with insufficient arguments' do
      it 'returns error when less than 2 arguments provided' do
        output = capture_stderr { command.call(source_and_destination: ['single_file.rb']) }

        expect(output).to include('Error: git mv requires at least a source and destination')
      end

      it 'returns error when no arguments provided' do
        output = capture_stderr { command.call(source_and_destination: []) }

        expect(output).to include('Error: git mv requires at least a source and destination')
      end
    end

    context 'with options' do
      before do
        allow(mock_orchestrator).to receive(:mv).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Move completed' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'passes repository option' do
        capture_stdout { command.call(source_and_destination: source_and_destination, repository: 'dev-tools') }

        expect(mock_orchestrator).to have_received(:mv).with(
          ['old_file.rb'],
          'new_file.rb',
          hash_including(repository: 'dev-tools')
        )
      end

      it 'passes main_only option' do
        capture_stdout { command.call(source_and_destination: source_and_destination, main_only: true) }

        expect(mock_orchestrator).to have_received(:mv).with(
          ['old_file.rb'],
          'new_file.rb',
          hash_including(main_only: true)
        )
      end

      it 'passes submodules_only option' do
        capture_stdout { command.call(source_and_destination: source_and_destination, submodules_only: true) }

        expect(mock_orchestrator).to have_received(:mv).with(
          ['old_file.rb'],
          'new_file.rb',
          hash_including(submodules_only: true)
        )
      end

      it 'passes mv-specific options' do
        capture_stdout do
          command.call(
            source_and_destination: source_and_destination,
            force: true,
            dry_run: true,
            verbose: true,
            concurrent: true
          )
        end

        expect(mock_orchestrator).to have_received(:mv).with(
          ['old_file.rb'],
          'new_file.rb',
          hash_including(
            force: true,
            dry_run: true,
            verbose: true,
            concurrent: true
          )
        )
      end
    end

    context 'with move failure' do
      let(:error_result) do
        {
          success: false,
          error: 'Move failed: fatal: bad source, source=old_file.rb, destination=new_file.rb',
          errors: [
            { repository: 'main-repo', message: 'fatal: bad source, source=old_file.rb, destination=new_file.rb' },
            { repository: 'dev-tools', message: 'fatal: bad source, source=old_file.rb, destination=new_file.rb' }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:mv).and_return(error_result)
      end

      it 'displays error messages and returns 1' do
        output = capture_stderr { command.call(source_and_destination: source_and_destination) }

        expect(output).to include('Move failed: fatal: bad source, source=old_file.rb, destination=new_file.rb')
        expect(output).to include('[main-repo] Error: fatal: bad source, source=old_file.rb, destination=new_file.rb')
        expect(output).to include('[dev-tools] Error: fatal: bad source, source=old_file.rb, destination=new_file.rb')
        expect(output).to include('Use --debug flag for more information')
      end
    end

    context 'with partial success' do
      let(:partial_result) do
        {
          success: false,
          results: {
            'main-repo' => { success: true, stdout: 'old_file.rb -> new_file.rb' },
            'dev-tools' => { success: false, error: 'fatal: bad source' }
          },
          errors: [
            { repository: 'dev-tools', message: 'fatal: bad source' }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:mv).and_return(partial_result)
      end

      it 'shows partial successes and errors' do
        output = capture_output { command.call(source_and_destination: source_and_destination) }

        expect(output).to include('Partial success: Move completed in repositories: main-repo')
        expect(output).to include('[dev-tools] Error: fatal: bad source')
      end
    end

    context 'with debug option' do
      let(:error_with_debug) do
        {
          success: false,
          errors: [
            {
              repository: 'main-repo',
              message: 'fatal: bad source',
              error: StandardError.new('detailed error')
            }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:mv).and_return(error_with_debug)
        allow(error_with_debug[:errors][0][:error]).to receive(:backtrace).and_return(['line1', 'line2'])
      end

      it 'shows detailed error information when debug is enabled' do
        output = capture_stderr { command.call(source_and_destination: source_and_destination, debug: true) }

        expect(output).to include('Error: StandardError: fatal: bad source')
        expect(output).to include('line1')
        expect(output).to include('line2')
      end
    end

    context 'with concurrent execution results' do
      let(:concurrent_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              commands: [
                { success: true, stdout: 'old_file.rb -> new_file.rb' },
                { success: true, stdout: 'Updated index' }
              ]
            }
          },
          repositories_processed: ['main-repo']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:mv).and_return(concurrent_result)
      end

      it 'handles multiple commands from concurrent execution' do
        output = capture_stdout { command.call(source_and_destination: source_and_destination, concurrent: true) }

        expect(output).to include('[main-repo] old_file.rb -> new_file.rb')
        expect(output).to include('[main-repo] Updated index')
      end
    end

    context 'with empty stdout results' do
      let(:empty_stdout_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: '' },
            'dev-tools' => { success: true, output: '' }
          },
          repositories_processed: ['main-repo', 'dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:mv).and_return(empty_stdout_result)
      end

      it 'displays default success message when stdout is empty' do
        output = capture_stdout { command.call(source_and_destination: source_and_destination) }

        expect(output).to include('[main-repo] Move completed successfully')
        expect(output).to include('[dev-tools] Move completed successfully')
      end
    end

    context 'when exception occurs' do
      before do
        allow(mock_orchestrator).to receive(:mv).and_raise(StandardError.new('Unexpected error'))
      end

      it 'handles exceptions and returns 1' do
        output = capture_stderr { command.call(source_and_destination: source_and_destination) }

        expect(output).to include('Error: Unexpected error')
        expect(output).to include('Use --debug flag for more information')
      end

      it 'shows detailed error with debug flag' do
        allow_any_instance_of(StandardError).to receive(:backtrace).and_return(['line1', 'line2'])

        output = capture_stderr { command.call(source_and_destination: source_and_destination, debug: true) }

        expect(output).to include('Error: StandardError: Unexpected error')
        expect(output).to include('Backtrace:')
        expect(output).to include('line1')
        expect(output).to include('line2')
      end
    end
  end

  describe '#build_mv_options' do
    let(:sources) { ['old_file.rb'] }
    let(:destination) { 'new_file.rb' }
    let(:options) do
      {
        repository: 'dev-tools',
        main_only: true,
        force: true,
        dry_run: true
      }
    end

    it 'builds correct options hash' do
      result = command.send(:build_mv_options, sources, destination, options)

      expect(result).to include(
        capture_output: true,
        repository: 'dev-tools',
        main_only: true,
        force: true,
        dry_run: true
      )
    end

    it 'only includes truthy options' do
      minimal_options = { force: false, main_only: true }
      result = command.send(:build_mv_options, sources, destination, minimal_options)

      expect(result).to include(main_only: true)
      expect(result).not_to include(:force)
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

  def capture_output
    old_stdout = $stdout
    old_stderr = $stderr

    stdout_capture = StringIO.new
    stderr_capture = StringIO.new

    $stdout = stdout_capture
    $stderr = stderr_capture

    yield

    stdout_capture.string + stderr_capture.string
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end
end

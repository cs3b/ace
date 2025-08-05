# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Git::Add do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_orchestrator) { instance_double('CodingAgentTools::Organisms::Git::GitOrchestrator') }
  let(:files) { ['file1.rb', 'file2.rb'] }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe '#call' do
    context 'with successful add operation' do
      let(:success_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: 'Added file1.rb, file2.rb' },
            'dev-tools' => { success: true, stdout: '' }
          },
          repositories_processed: ['main-repo', 'dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:add).and_return(success_result)
      end

      it 'executes add operation and displays formatted output' do
        output = capture_stdout { command.call(files: files) }

        expect(output).to include('[main-repo] Added file1.rb, file2.rb')
        expect(output).to include('[dev-tools] Files added successfully')
        expect(output).to include('Files added across repositories: main-repo, dev-tools')
        expect(mock_orchestrator).to have_received(:add).with(files, hash_including(capture_output: true))
      end

      it 'returns 0 for successful execution' do
        capture_stdout { command.call(files: files) }
        expect(mock_orchestrator).to have_received(:add)
      end

      it 'passes files and default options to orchestrator' do
        capture_stdout { command.call(files: files) }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:add).with(
          files,
          hash_including(capture_output: true)
        )
      end
    end

    context 'with options' do
      before do
        allow(mock_orchestrator).to receive(:add).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Files added' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'passes repository option' do
        capture_stdout { command.call(files: files, repository: 'dev-tools') }

        expect(mock_orchestrator).to have_received(:add).with(
          files,
          hash_including(repository: 'dev-tools')
        )
      end

      it 'passes main_only option' do
        capture_stdout { command.call(files: files, main_only: true) }

        expect(mock_orchestrator).to have_received(:add).with(
          files,
          hash_including(main_only: true)
        )
      end

      it 'passes submodules_only option' do
        capture_stdout { command.call(files: files, submodules_only: true) }

        expect(mock_orchestrator).to have_received(:add).with(
          files,
          hash_including(submodules_only: true)
        )
      end

      it 'passes add-specific options' do
        capture_stdout do
          command.call(
            files: files,
            all: true,
            update: true,
            patch: true,
            force: true,
            concurrent: true
          )
        end

        expect(mock_orchestrator).to have_received(:add).with(
          files,
          hash_including(
            all: true,
            update: true,
            patch: true,
            force: true,
            concurrent: true
          )
        )
      end

      it 'filters out false boolean options' do
        capture_stdout { command.call(files: files, all: false, patch: false) }

        expect(mock_orchestrator).to have_received(:add).with(
          files,
          hash_not_including(:all, :patch)
        )
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
                { success: true, stdout: 'Added file1.rb' },
                { success: true, stdout: 'Added file2.rb' }
              ]
            }
          },
          repositories_processed: ['main-repo']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:add).and_return(concurrent_result)
      end

      it 'displays results from concurrent commands' do
        output = capture_stdout { command.call(files: files, concurrent: true) }

        expect(output).to include('[main-repo] Added file1.rb')
        expect(output).to include('[main-repo] Added file2.rb')
        expect(output).to include('Files added across repositories: main-repo')
      end
    end

    context 'with empty output' do
      let(:empty_result) do
        {
          success: true,
          results: {
            'dev-tools' => { success: true, stdout: '' }
          },
          repositories_processed: ['dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:add).and_return(empty_result)
      end

      it 'displays success message for empty output' do
        output = capture_stdout { command.call(files: files) }

        expect(output).to include('[dev-tools] Files added successfully')
      end
    end

    context 'with errors' do
      let(:error_result) do
        {
          success: false,
          errors: [
            { repository: 'main-repo', message: 'File not found' },
            { repository: 'dev-tools', message: 'Permission denied', error: StandardError.new('Access denied') }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:add).and_return(error_result)
      end

      it 'displays error messages' do
        stderr_output = capture_stderr { command.call(files: files) }

        expect(stderr_output).to include('[main-repo] Error: File not found')
        expect(stderr_output).to include('[dev-tools] Error: Permission denied')
      end

      it 'shows debug information when debug enabled' do
        stderr_output = capture_stderr { command.call(files: files, debug: true) }

        expect(stderr_output).to include('StandardError: Permission denied')
      end

      it 'suggests debug flag when not enabled' do
        stderr_output = capture_stderr { command.call(files: files) }

        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'returns 1 for failed execution' do
        capture_stderr { command.call(files: files) }
        expect(mock_orchestrator).to have_received(:add)
      end
    end

    context 'with partial success' do
      let(:partial_result) do
        {
          success: false,
          errors: [
            { repository: 'dev-tools', message: 'Permission denied' }
          ],
          results: {
            'main-repo' => { success: true, stdout: 'Files added' },
            'dev-tools' => { success: false }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:add).and_return(partial_result)
      end

      it 'shows partial success information' do
        output = capture_stdout do
          capture_stderr { command.call(files: files) }
        end

        expect(output).to include('Partial success: Files added in repositories: main-repo')
      end
    end

    context 'with orchestrator error' do
      let(:orchestrator_error_result) do
        {
          success: false,
          error: 'Invalid files specified'
        }
      end

      before do
        allow(mock_orchestrator).to receive(:add).and_return(orchestrator_error_result)
      end

      it 'displays orchestrator error' do
        stderr_output = capture_stderr { command.call(files: files) }

        expect(stderr_output).to include('Add failed: Invalid files specified')
      end
    end

    context 'with exceptions' do
      it 'handles unexpected errors gracefully' do
        allow(mock_orchestrator).to receive(:add).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call(files: files) }

        expect(stderr_output).to include('Error: Unexpected error')
        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'shows backtrace in debug mode' do
        allow(mock_orchestrator).to receive(:add).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call(files: files, debug: true) }

        expect(stderr_output).to include('StandardError: Unexpected error')
        expect(stderr_output).to include('Backtrace:')
      end
    end
  end

  describe 'option building' do
    it 'builds minimal options for default call' do
      allow(mock_orchestrator).to receive(:add).and_return({ success: true, results: {} })

      capture_stdout { command.call(files: files) }

      expect(mock_orchestrator).to have_received(:add).with(
        files,
        hash_including(capture_output: true)
      )
    end

    it 'filters out false boolean options' do
      allow(mock_orchestrator).to receive(:add).and_return({ success: true, results: {} })

      capture_stdout { command.call(files: files, all: false, patch: false) }

      expect(mock_orchestrator).to have_received(:add).with(
        files,
        hash_not_including(:all, :patch)
      )
    end

    it 'includes true boolean options' do
      allow(mock_orchestrator).to receive(:add).and_return({ success: true, results: {} })

      capture_stdout { command.call(files: files, all: true, patch: true) }

      expect(mock_orchestrator).to have_received(:add).with(
        files,
        hash_including(all: true, patch: true)
      )
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

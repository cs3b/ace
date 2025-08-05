# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Git::Fetch do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_orchestrator) { instance_double('CodingAgentTools::Organisms::Git::GitOrchestrator') }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe '#call' do
    context 'with successful fetch operation' do
      let(:success_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: "From github.com:user/repo\n   abc1234..def5678  main       -> origin/main\n * [new branch]      feature    -> origin/feature"
            },
            'dev-tools' => {
              success: true,
              stdout: ''
            }
          },
          repositories_processed: ['main-repo', 'dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:fetch).and_return(success_result)
      end

      it 'executes fetch operation and displays formatted output' do
        output = capture_stdout { command.call }

        expect(output).to include('[main-repo] Fetch completed:')
        expect(output).to include('From github.com:user/repo')
        expect(output).to include('[dev-tools] Fetch completed (no new changes)')
        expect(output).to include('Fetch completed across repositories: main-repo, dev-tools')
        expect(mock_orchestrator).to have_received(:fetch)
      end

      it 'returns 0 for successful execution' do
        capture_stdout { command.call }
        expect(mock_orchestrator).to have_received(:fetch)
      end

      it 'passes default options to orchestrator' do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:fetch).with(
          hash_including(capture_output: true)
        )
      end
    end

    context 'with remote argument' do
      before do
        allow(mock_orchestrator).to receive(:fetch).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Fetch completed' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'passes remote to orchestrator' do
        capture_stdout { command.call(remote: 'origin') }

        expect(mock_orchestrator).to have_received(:fetch).with(
          hash_including(remote: 'origin')
        )
      end
    end

    context 'with options' do
      before do
        allow(mock_orchestrator).to receive(:fetch).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Fetch completed' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'passes repository option' do
        capture_stdout { command.call(repository: 'dev-tools') }

        expect(mock_orchestrator).to have_received(:fetch).with(
          hash_including(repository: 'dev-tools')
        )
      end

      it 'passes main_only option' do
        capture_stdout { command.call(main_only: true) }

        expect(mock_orchestrator).to have_received(:fetch).with(
          hash_including(main_only: true)
        )
      end

      it 'passes submodules_only option' do
        capture_stdout { command.call(submodules_only: true) }

        expect(mock_orchestrator).to have_received(:fetch).with(
          hash_including(submodules_only: true)
        )
      end

      it 'passes fetch-specific options' do
        capture_stdout do
          command.call(
            all: true,
            prune: true,
            tags: true
          )
        end

        expect(mock_orchestrator).to have_received(:fetch).with(
          hash_including(
            all: true,
            prune: true,
            tags: true
          )
        )
      end

      it 'filters out false boolean options' do
        capture_stdout { command.call(all: false, prune: false) }

        expect(mock_orchestrator).to have_received(:fetch).with(
          hash_not_including(:all, :prune)
        )
      end
    end

    context 'with no changes fetched' do
      let(:no_changes_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: '' },
            'dev-tools' => { success: true, stdout: '' }
          },
          repositories_processed: ['main-repo', 'dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:fetch).and_return(no_changes_result)
      end

      it 'displays no new changes message' do
        output = capture_stdout { command.call }

        expect(output).to include('[main-repo] Fetch completed (no new changes)')
        expect(output).to include('[dev-tools] Fetch completed (no new changes)')
      end
    end

    context 'with detailed fetch output' do
      let(:detailed_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: "From github.com:user/repo\n   abc1234..def5678  main       -> origin/main\n * [new tag]         v1.0.0     -> v1.0.0"
            }
          },
          repositories_processed: ['main-repo']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:fetch).and_return(detailed_result)
      end

      it 'displays detailed fetch information' do
        output = capture_stdout { command.call }

        expect(output).to include('[main-repo] Fetch completed:')
        expect(output).to include('  From github.com:user/repo')
        expect(output).to include('  abc1234..def5678  main       -> origin/main')
        expect(output).to include('  * [new tag]         v1.0.0     -> v1.0.0')
      end
    end

    context 'with errors' do
      let(:error_result) do
        {
          success: false,
          errors: [
            { repository: 'main-repo', message: 'Remote repository not found' },
            { repository: 'dev-tools', message: 'Network error', error: StandardError.new('Connection failed') }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:fetch).and_return(error_result)
      end

      it 'displays error messages' do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('[main-repo] Error: Remote repository not found')
        expect(stderr_output).to include('[dev-tools] Error: Network error')
      end

      it 'shows debug information when debug enabled' do
        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include('StandardError: Network error')
      end

      it 'suggests debug flag when not enabled' do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'returns 1 for failed execution' do
        capture_stderr { command.call }
        expect(mock_orchestrator).to have_received(:fetch)
      end
    end

    context 'with partial success' do
      let(:partial_result) do
        {
          success: false,
          errors: [
            { repository: 'dev-tools', message: 'Network error' }
          ],
          results: {
            'main-repo' => { success: true, stdout: 'Fetch completed' },
            'dev-tools' => { success: false }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:fetch).and_return(partial_result)
      end

      it 'shows partial success information' do
        output = capture_stdout do
          capture_stderr { command.call }
        end

        expect(output).to include('Partial success: Fetch completed in repositories: main-repo')
      end
    end

    context 'with exceptions' do
      it 'handles unexpected errors gracefully' do
        allow(mock_orchestrator).to receive(:fetch).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('Error: Unexpected error')
        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'shows backtrace in debug mode' do
        allow(mock_orchestrator).to receive(:fetch).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include('StandardError: Unexpected error')
        expect(stderr_output).to include('Backtrace:')
      end
    end
  end

  describe 'option building' do
    it 'builds minimal options for default call' do
      allow(mock_orchestrator).to receive(:fetch).and_return({ success: true, results: {} })

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:fetch).with(
        hash_including(capture_output: true)
      )
    end

    it 'filters out false boolean options' do
      allow(mock_orchestrator).to receive(:fetch).and_return({ success: true, results: {} })

      capture_stdout { command.call(all: false, prune: false) }

      expect(mock_orchestrator).to have_received(:fetch).with(
        hash_not_including(:all, :prune)
      )
    end

    it 'includes true boolean options' do
      allow(mock_orchestrator).to receive(:fetch).and_return({ success: true, results: {} })

      capture_stdout { command.call(all: true, prune: true) }

      expect(mock_orchestrator).to have_received(:fetch).with(
        hash_including(all: true, prune: true)
      )
    end

    it 'includes remote when provided' do
      allow(mock_orchestrator).to receive(:fetch).and_return({ success: true, results: {} })

      capture_stdout { command.call(remote: 'upstream') }

      expect(mock_orchestrator).to have_received(:fetch).with(
        hash_including(remote: 'upstream')
      )
    end

    it 'excludes remote when not provided' do
      allow(mock_orchestrator).to receive(:fetch).and_return({ success: true, results: {} })

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:fetch).with(
        hash_not_including(:remote)
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

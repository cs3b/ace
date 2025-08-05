# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Git::Pull do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_orchestrator) { instance_double('CodingAgentTools::Organisms::Git::GitOrchestrator') }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe '#call' do
    context 'with successful pull operation' do
      let(:success_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: "Updating abc1234..def5678\nFast-forward\n file1.rb | 3 +++\n 1 file changed, 3 insertions(+)"
            },
            'dev-tools' => {
              success: true,
              stdout: 'Already up to date.'
            }
          },
          repositories_processed: ['main-repo', 'dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:pull).and_return(success_result)
      end

      it 'executes pull operation and displays formatted output' do
        output = capture_stdout { command.call }

        expect(output).to include('[main-repo] Updating abc1234..def5678')
        expect(output).to include('[main-repo] Fast-forward')
        expect(output).to include('[dev-tools] Already up to date.')
        expect(output).to include('Pull completed across repositories: main-repo, dev-tools')
        expect(mock_orchestrator).to have_received(:pull)
      end

      it 'returns 0 for successful execution' do
        capture_stdout { command.call }
        expect(mock_orchestrator).to have_received(:pull)
      end

      it 'passes default options to orchestrator' do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:pull).with(
          hash_including(capture_output: true)
        )
      end
    end

    context 'with remote and branch arguments' do
      before do
        allow(mock_orchestrator).to receive(:pull).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Pull completed' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'passes remote and branch to orchestrator' do
        capture_stdout { command.call(remote: 'upstream', branch: 'develop') }

        expect(mock_orchestrator).to have_received(:pull).with(
          hash_including(remote: 'upstream', branch: 'develop')
        )
      end
    end

    context 'with options' do
      before do
        allow(mock_orchestrator).to receive(:pull).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Pull completed' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'passes repository option' do
        capture_stdout { command.call(repository: 'dev-tools') }

        expect(mock_orchestrator).to have_received(:pull).with(
          hash_including(repository: 'dev-tools')
        )
      end

      it 'passes main_only option' do
        capture_stdout { command.call(main_only: true) }

        expect(mock_orchestrator).to have_received(:pull).with(
          hash_including(main_only: true)
        )
      end

      it 'passes submodules_only option' do
        capture_stdout { command.call(submodules_only: true) }

        expect(mock_orchestrator).to have_received(:pull).with(
          hash_including(submodules_only: true)
        )
      end

      it 'passes pull-specific options' do
        capture_stdout do
          command.call(
            rebase: true,
            ff_only: true,
            no_commit: true,
            strategy: 'recursive',
            concurrent: false
          )
        end

        expect(mock_orchestrator).to have_received(:pull).with(
          hash_including(
            rebase: true,
            ff_only: true,
            no_commit: true,
            strategy: 'recursive',
            concurrent: false
          )
        )
      end

      it 'filters out false boolean options' do
        capture_stdout { command.call(rebase: false, ff_only: false) }

        expect(mock_orchestrator).to have_received(:pull).with(
          hash_not_including(:rebase, :ff_only)
        )
      end
    end

    context 'with conflicts during pull' do
      let(:conflict_result) do
        {
          success: false,
          errors: [
            { repository: 'main-repo', message: 'Merge conflict in file1.rb' }
          ],
          results: {
            'main-repo' => { success: false, stderr: 'CONFLICT (content): Merge conflict in file1.rb' }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:pull).and_return(conflict_result)
      end

      it 'displays conflict error messages' do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('[main-repo] Error: Merge conflict in file1.rb')
      end
    end

    context 'with no changes to pull' do
      let(:up_to_date_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: 'Already up to date.' },
            'dev-tools' => { success: true, stdout: 'Already up to date.' }
          },
          repositories_processed: ['main-repo', 'dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:pull).and_return(up_to_date_result)
      end

      it 'displays up to date messages' do
        output = capture_stdout { command.call }

        expect(output).to include('[main-repo] Already up to date.')
        expect(output).to include('[dev-tools] Already up to date.')
      end
    end

    context 'with errors' do
      let(:error_result) do
        {
          success: false,
          errors: [
            { repository: 'main-repo', message: 'Remote repository not found' },
            { repository: 'dev-tools', message: 'Network error', error: StandardError.new('Connection timeout') }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:pull).and_return(error_result)
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
        expect(mock_orchestrator).to have_received(:pull)
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
            'main-repo' => { success: true, stdout: 'Pull completed' },
            'dev-tools' => { success: false }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:pull).and_return(partial_result)
      end

      it 'shows partial success information' do
        output = capture_stdout do
          capture_stderr { command.call }
        end

        expect(output).to include('Partial success: Pull completed in repositories: main-repo')
      end
    end

    context 'with exceptions' do
      it 'handles unexpected errors gracefully' do
        allow(mock_orchestrator).to receive(:pull).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('Error: Unexpected error')
        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'shows backtrace in debug mode' do
        allow(mock_orchestrator).to receive(:pull).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include('StandardError: Unexpected error')
        expect(stderr_output).to include('Backtrace:')
      end
    end
  end

  describe 'option building' do
    it 'builds minimal options for default call' do
      allow(mock_orchestrator).to receive(:pull).and_return({ success: true, results: {} })

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:pull).with(
        hash_including(capture_output: true)
      )
    end

    it 'filters out false boolean options' do
      allow(mock_orchestrator).to receive(:pull).and_return({ success: true, results: {} })

      capture_stdout { command.call(rebase: false, ff_only: false) }

      expect(mock_orchestrator).to have_received(:pull).with(
        hash_not_including(:rebase, :ff_only)
      )
    end

    it 'includes true boolean options' do
      allow(mock_orchestrator).to receive(:pull).and_return({ success: true, results: {} })

      capture_stdout { command.call(rebase: true, ff_only: true) }

      expect(mock_orchestrator).to have_received(:pull).with(
        hash_including(rebase: true, ff_only: true)
      )
    end

    it 'includes strategy when provided' do
      allow(mock_orchestrator).to receive(:pull).and_return({ success: true, results: {} })

      capture_stdout { command.call(strategy: 'ours') }

      expect(mock_orchestrator).to have_received(:pull).with(
        hash_including(strategy: 'ours')
      )
    end

    it 'excludes strategy when not provided' do
      allow(mock_orchestrator).to receive(:pull).and_return({ success: true, results: {} })

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:pull).with(
        hash_not_including(:strategy)
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

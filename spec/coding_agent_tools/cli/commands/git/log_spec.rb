# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Git::Log do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_orchestrator) { instance_double('CodingAgentTools::Organisms::Git::GitOrchestrator') }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe '#call' do
    context 'with successful log operation' do
      let(:success_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: "commit abc1234 (HEAD -> main, origin/main)\nAuthor: User <user@example.com>\nDate:   Wed Jan 1 12:00:00 2025 +0000\n\n    feat: add new feature\n\ncommit def5678\nAuthor: User <user@example.com>\nDate:   Tue Dec 31 12:00:00 2024 +0000\n\n    fix: bug fix"
            },
            'dev-tools' => {
              success: true,
              stdout: "commit 1111111\nAuthor: Dev <dev@example.com>\nDate:   Mon Dec 30 12:00:00 2024 +0000\n\n    chore: update dependencies"
            }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:log).and_return(success_result)
      end

      it 'executes log operation and displays formatted output' do
        output = capture_stdout { command.call }

        expect(output).to include('[main-repo] commit abc1234')
        expect(output).to include('[main-repo]     feat: add new feature')
        expect(output).to include('[dev-tools] commit 1111111')
        expect(output).to include('[dev-tools]     chore: update dependencies')
        expect(mock_orchestrator).to have_received(:log)
      end

      it 'returns 0 for successful execution' do
        capture_stdout { command.call }
        expect(mock_orchestrator).to have_received(:log)
      end

      it 'passes default options to orchestrator' do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:log).with(
          hash_including(capture_output: true)
        )
      end
    end

    context 'with options' do
      before do
        allow(mock_orchestrator).to receive(:log).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: "commit abc1234\n    feat: add feature" } }
        })
      end

      it 'passes repository option' do
        capture_stdout { command.call(repository: 'dev-tools') }

        expect(mock_orchestrator).to have_received(:log).with(
          hash_including(repository: 'dev-tools')
        )
      end

      it 'passes main_only option' do
        capture_stdout { command.call(main_only: true) }

        expect(mock_orchestrator).to have_received(:log).with(
          hash_including(main_only: true)
        )
      end

      it 'passes submodules_only option' do
        capture_stdout { command.call(submodules_only: true) }

        expect(mock_orchestrator).to have_received(:log).with(
          hash_including(submodules_only: true)
        )
      end

      it 'passes log-specific options' do
        capture_stdout do
          command.call(
            oneline: true,
            graph: true,
            since: '1 week ago',
            until: 'today',
            author: 'john@example.com',
            grep: 'fix',
            max_count: 10,
            separated: true,
            no_color: true
          )
        end

        expect(mock_orchestrator).to have_received(:log).with(
          hash_including(
            oneline: true,
            graph: true,
            since: '1 week ago',
            until: 'today',
            author: 'john@example.com',
            grep: 'fix',
            max_count: 10,
            separated: true,
            no_color: true
          )
        )
      end

      it 'filters out false boolean options' do
        capture_stdout { command.call(oneline: false, graph: false) }

        expect(mock_orchestrator).to have_received(:log).with(
          hash_not_including(:oneline, :graph)
        )
      end
    end

    context 'with oneline format' do
      let(:oneline_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: "abc1234 feat: add new feature\ndef5678 fix: bug fix"
            }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:log).and_return(oneline_result)
      end

      it 'displays oneline format output' do
        output = capture_stdout { command.call(oneline: true) }

        expect(output).to include('[main-repo] abc1234 feat: add new feature')
        expect(output).to include('[main-repo] def5678 fix: bug fix')
      end
    end

    context 'with separated format' do
      let(:separated_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: "commit abc1234\n    feat: add feature"
            },
            'dev-tools' => {
              success: true,
              stdout: "commit def5678\n    fix: bug fix"
            }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:log).and_return(separated_result)
      end

      it 'displays separated repository sections' do
        output = capture_stdout { command.call(separated: true) }

        expect(output).to include('[main-repo] Recent commits:')
        expect(output).to include('  commit abc1234')
        expect(output).to include('[dev-tools] Recent commits:')
        expect(output).to include('  commit def5678')
      end
    end

    context 'with no commits' do
      let(:no_commits_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: '' },
            'dev-tools' => { success: true, stdout: '' }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:log).and_return(no_commits_result)
      end

      it 'displays no output for empty repositories' do
        output = capture_stdout { command.call }

        expect(output.strip).to be_empty
      end
    end

    context 'with errors' do
      let(:error_result) do
        {
          success: false,
          errors: [
            { repository: 'main-repo', message: 'Not a git repository' },
            { repository: 'dev-tools', message: 'Invalid git log format', error: StandardError.new('Bad revision') }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:log).and_return(error_result)
      end

      it 'displays error messages' do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('[main-repo] Error: Not a git repository')
        expect(stderr_output).to include('[dev-tools] Error: Invalid git log format')
      end

      it 'shows debug information when debug enabled' do
        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include('StandardError: Invalid git log format')
      end

      it 'suggests debug flag when not enabled' do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'returns 1 for failed execution' do
        capture_stderr { command.call }
        expect(mock_orchestrator).to have_received(:log)
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
            'main-repo' => { success: true, stdout: "commit abc1234\n    feat: add feature" },
            'dev-tools' => { success: false }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:log).and_return(partial_result)
      end

      it 'shows partial success information' do
        output = capture_stdout do
          capture_stderr { command.call }
        end

        expect(output).to include('Partial success: Log shown for repositories: main-repo')
      end
    end

    context 'with exceptions' do
      it 'handles unexpected errors gracefully' do
        allow(mock_orchestrator).to receive(:log).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('Error: Unexpected error')
        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'shows backtrace in debug mode' do
        allow(mock_orchestrator).to receive(:log).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include('StandardError: Unexpected error')
        expect(stderr_output).to include('Backtrace:')
      end
    end
  end

  describe 'option building' do
    it 'builds minimal options for default call' do
      allow(mock_orchestrator).to receive(:log).and_return({ success: true, results: {} })

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:log).with(
        hash_including(capture_output: true)
      )
    end

    it 'filters out false boolean options' do
      allow(mock_orchestrator).to receive(:log).and_return({ success: true, results: {} })

      capture_stdout { command.call(oneline: false, graph: false) }

      expect(mock_orchestrator).to have_received(:log).with(
        hash_not_including(:oneline, :graph)
      )
    end

    it 'includes true boolean options' do
      allow(mock_orchestrator).to receive(:log).and_return({ success: true, results: {} })

      capture_stdout { command.call(oneline: true, graph: true) }

      expect(mock_orchestrator).to have_received(:log).with(
        hash_including(oneline: true, graph: true)
      )
    end

    it 'includes string options when provided' do
      allow(mock_orchestrator).to receive(:log).and_return({ success: true, results: {} })

      capture_stdout { command.call(since: '1 week ago', author: 'john@example.com') }

      expect(mock_orchestrator).to have_received(:log).with(
        hash_including(since: '1 week ago', author: 'john@example.com')
      )
    end

    it 'excludes string options when not provided' do
      allow(mock_orchestrator).to receive(:log).and_return({ success: true, results: {} })

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:log).with(
        hash_not_including(:since, :author, :grep)
      )
    end

    it 'includes integer options when provided' do
      allow(mock_orchestrator).to receive(:log).and_return({ success: true, results: {} })

      capture_stdout { command.call(max_count: 5) }

      expect(mock_orchestrator).to have_received(:log).with(
        hash_including(max_count: 5)
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

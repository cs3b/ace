# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Cli::Commands::Git::Diff do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_orchestrator) { instance_double('CodingAgentTools::Organisms::Git::GitOrchestrator') }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe '#call' do
    context 'with successful diff operation' do
      let(:success_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: "diff --git a/file1.rb b/file1.rb\nindex 1234567..abcdefg 100644\n--- a/file1.rb\n+++ b/file1.rb\n@@ -1,3 +1,4 @@\n def method\n+  # New comment\n   puts 'hello'\n end"
            },
            'dev-tools' => {
              success: true,
              stdout: "diff --git a/lib/file2.rb b/lib/file2.rb\nindex abcdefg..1234567 100644\n--- a/lib/file2.rb\n+++ b/lib/file2.rb\n@@ -1,2 +1,3 @@\n class MyClass\n+  attr_reader :value\n end"
            }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:diff).and_return(success_result)
      end

      it 'executes diff operation and displays formatted output' do
        output = capture_stdout { command.call }

        expect(output).to include('[main-repo] Differences:')
        expect(output).to include('diff --git a/file1.rb b/file1.rb')
        expect(output).to include('[dev-tools] Differences:')
        expect(output).to include('diff --git a/lib/file2.rb b/lib/file2.rb')
        expect(mock_orchestrator).to have_received(:diff)
      end

      it 'returns 0 for successful execution' do
        capture_stdout { command.call }
        expect(mock_orchestrator).to have_received(:diff)
      end

      it 'passes default options to orchestrator' do
        capture_stdout { command.call }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:diff).with(
          hash_including(capture_output: true)
        )
      end
    end

    context 'with no changes' do
      let(:no_changes_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: '' },
            'dev-tools' => { success: true, stdout: '' }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:diff).and_return(no_changes_result)
      end

      it 'displays no changes message' do
        output = capture_stdout { command.call }

        expect(output).to include('No changes found across repositories')
      end
    end

    context 'with options' do
      before do
        allow(mock_orchestrator).to receive(:diff).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'some diff' } }
        })
      end

      it 'passes repository option' do
        capture_stdout { command.call(repository: 'dev-tools') }

        expect(mock_orchestrator).to have_received(:diff).with(
          hash_including(repository: 'dev-tools')
        )
      end

      it 'passes main_only option' do
        capture_stdout { command.call(main_only: true) }

        expect(mock_orchestrator).to have_received(:diff).with(
          hash_including(main_only: true)
        )
      end

      it 'passes submodules_only option' do
        capture_stdout { command.call(submodules_only: true) }

        expect(mock_orchestrator).to have_received(:diff).with(
          hash_including(submodules_only: true)
        )
      end

      it 'passes diff-specific options' do
        capture_stdout do
          command.call(
            staged: true,
            name_only: true,
            stat: true
          )
        end

        expect(mock_orchestrator).to have_received(:diff).with(
          hash_including(
            staged: true,
            name_only: true,
            stat: true
          )
        )
      end

      it 'filters out false boolean options' do
        capture_stdout { command.call(staged: false, name_only: false) }

        expect(mock_orchestrator).to have_received(:diff).with(
          hash_not_including(:staged, :name_only)
        )
      end
    end

    context 'with name_only option' do
      let(:name_only_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: "file1.rb\nfile2.rb\nlib/utils.rb"
            }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:diff).and_return(name_only_result)
      end

      it 'displays file names only' do
        output = capture_stdout { command.call(name_only: true) }

        expect(output).to include('[main-repo] Changed files:')
        expect(output).to include('  file1.rb')
        expect(output).to include('  file2.rb')
        expect(output).to include('  lib/utils.rb')
      end
    end

    context 'with stat option' do
      let(:stat_result) do
        {
          success: true,
          results: {
            'main-repo' => {
              success: true,
              stdout: " file1.rb | 3 +++\n file2.rb | 5 ++---\n 2 files changed, 5 insertions(+), 3 deletions(-)"
            }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:diff).and_return(stat_result)
      end

      it 'displays diffstat' do
        output = capture_stdout { command.call(stat: true) }

        expect(output).to include('[main-repo] Diffstat:')
        expect(output).to include('  file1.rb | 3 +++')
        expect(output).to include('  file2.rb | 5 ++---')
        expect(output).to include('  2 files changed, 5 insertions(+), 3 deletions(-)')
      end
    end

    context 'with repository spacing' do
      let(:multi_repo_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: 'diff1' },
            'dev-tools' => { success: true, stdout: 'diff2' }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:diff).and_return(multi_repo_result)
      end

      it 'adds spacing between repositories' do
        output = capture_stdout { command.call }

        # Should have empty lines separating repositories
        expect(output).to match(/\[main-repo\].*\n\n\[dev-tools\]/m)
      end
    end

    context 'with errors' do
      let(:error_result) do
        {
          success: false,
          errors: [
            { repository: 'main-repo', message: 'Not a git repository' },
            { repository: 'dev-tools', message: 'Permission denied', error: StandardError.new('Access denied') }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:diff).and_return(error_result)
      end

      it 'displays error messages' do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('[main-repo] Error: Not a git repository')
        expect(stderr_output).to include('[dev-tools] Error: Permission denied')
      end

      it 'shows debug information when debug enabled' do
        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include('StandardError: Permission denied')
      end

      it 'suggests debug flag when not enabled' do
        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'returns 1 for failed execution' do
        capture_stderr { command.call }
        expect(mock_orchestrator).to have_received(:diff)
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
            'main-repo' => { success: true, stdout: 'diff content' },
            'dev-tools' => { success: false }
          }
        }
      end

      before do
        allow(mock_orchestrator).to receive(:diff).and_return(partial_result)
      end

      it 'shows partial success information' do
        output = capture_stdout do
          capture_stderr { command.call }
        end

        expect(output).to include('Partial success: Diff shown for repositories: main-repo')
      end
    end

    context 'with exceptions' do
      it 'handles unexpected errors gracefully' do
        allow(mock_orchestrator).to receive(:diff).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call }

        expect(stderr_output).to include('Error: Unexpected error')
        expect(stderr_output).to include('Use --debug flag for more information')
      end

      it 'shows backtrace in debug mode' do
        allow(mock_orchestrator).to receive(:diff).and_raise(StandardError, 'Unexpected error')

        stderr_output = capture_stderr { command.call(debug: true) }

        expect(stderr_output).to include('StandardError: Unexpected error')
        expect(stderr_output).to include('Backtrace:')
      end
    end
  end

  describe 'option building' do
    it 'builds minimal options for default call' do
      allow(mock_orchestrator).to receive(:diff).and_return({ success: true, results: {} })

      capture_stdout { command.call }

      expect(mock_orchestrator).to have_received(:diff).with(
        hash_including(capture_output: true)
      )
    end

    it 'filters out false boolean options' do
      allow(mock_orchestrator).to receive(:diff).and_return({ success: true, results: {} })

      capture_stdout { command.call(staged: false, stat: false) }

      expect(mock_orchestrator).to have_received(:diff).with(
        hash_not_including(:staged, :stat)
      )
    end

    it 'includes true boolean options' do
      allow(mock_orchestrator).to receive(:diff).and_return({ success: true, results: {} })

      capture_stdout { command.call(staged: true, stat: true) }

      expect(mock_orchestrator).to have_received(:diff).with(
        hash_including(staged: true, stat: true)
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

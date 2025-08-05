# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe CodingAgentTools::Cli::Commands::Git::Checkout do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_orchestrator) { instance_double('CodingAgentTools::Organisms::Git::GitOrchestrator') }
  let(:branch_or_paths) { ['main'] }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe '#call' do
    context 'with successful checkout operation' do
      let(:success_result) do
        {
          success: true,
          results: {
            'main-repo' => { success: true, stdout: "Switched to branch 'main'" },
            'dev-tools' => { success: true, stdout: "Already on 'main'" }
          },
          repositories_processed: ['main-repo', 'dev-tools']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:checkout).and_return(success_result)
      end

      it 'executes checkout operation and displays formatted output' do
        output = capture_stdout { command.call(branch_or_paths: branch_or_paths) }

        expect(output).to include("[main-repo] Switched to branch 'main'")
        expect(output).to include("[dev-tools] Already on 'main'")
        expect(output).to include('Checkout completed across repositories: main-repo, dev-tools')
        expect(mock_orchestrator).to have_received(:checkout).with(branch_or_paths, hash_including(capture_output: true))
      end

      it 'returns 0 for successful execution' do
        capture_stdout { command.call(branch_or_paths: branch_or_paths) }
        expect(mock_orchestrator).to have_received(:checkout)
      end

      it 'passes branch_or_paths and default options to orchestrator' do
        capture_stdout { command.call(branch_or_paths: branch_or_paths) }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:checkout).with(
          branch_or_paths,
          hash_including(capture_output: true)
        )
      end
    end

    context 'with empty branch_or_paths' do
      before do
        allow(mock_orchestrator).to receive(:checkout).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'HEAD is now at 1234567' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'handles empty branch_or_paths argument' do
        capture_stdout { command.call(branch_or_paths: []) }

        expect(mock_orchestrator).to have_received(:checkout).with(
          [],
          hash_including(capture_output: true)
        )
      end
    end

    context 'with options' do
      before do
        allow(mock_orchestrator).to receive(:checkout).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Checkout completed' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'passes repository option' do
        capture_stdout { command.call(branch_or_paths: branch_or_paths, repository: 'dev-tools') }

        expect(mock_orchestrator).to have_received(:checkout).with(
          branch_or_paths,
          hash_including(repository: 'dev-tools')
        )
      end

      it 'passes main_only option' do
        capture_stdout { command.call(branch_or_paths: branch_or_paths, main_only: true) }

        expect(mock_orchestrator).to have_received(:checkout).with(
          branch_or_paths,
          hash_including(main_only: true)
        )
      end

      it 'passes submodules_only option' do
        capture_stdout { command.call(branch_or_paths: branch_or_paths, submodules_only: true) }

        expect(mock_orchestrator).to have_received(:checkout).with(
          branch_or_paths,
          hash_including(submodules_only: true)
        )
      end

      it 'passes checkout-specific options' do
        capture_stdout do
          command.call(
            branch_or_paths: branch_or_paths,
            quiet: true,
            force: true,
            merge: true,
            detach: true,
            create_branch: 'new-feature',
            force_create_branch: 'hotfix',
            orphan: 'empty-branch',
            track: true,
            no_track: false,
            concurrent: true
          )
        end

        expect(mock_orchestrator).to have_received(:checkout).with(
          branch_or_paths,
          hash_including(
            quiet: true,
            force: true,
            merge: true,
            detach: true,
            create_branch: 'new-feature',
            force_create_branch: 'hotfix',
            orphan: 'empty-branch',
            track: true,
            concurrent: true
          )
        )
      end
    end

    context 'with quiet option' do
      before do
        allow(mock_orchestrator).to receive(:checkout).and_return({
          success: true,
          results: {
            'main-repo' => { success: true, stdout: "Switched to branch 'main'" }
          },
          repositories_processed: ['main-repo']
        })
      end

      it 'suppresses feedback messages when quiet is true' do
        output = capture_stdout { command.call(branch_or_paths: branch_or_paths, quiet: true) }

        expect(output).not_to include('Checkout completed across repositories')
      end
    end

    context 'with checkout failure' do
      let(:error_result) do
        {
          success: false,
          error: "Checkout failed: error: pathspec 'nonexistent-branch' did not match any file(s) known to git",
          errors: [
            { repository: 'main-repo', message: "pathspec 'nonexistent-branch' did not match any file(s) known to git" },
            { repository: 'dev-tools', message: "pathspec 'nonexistent-branch' did not match any file(s) known to git" }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:checkout).and_return(error_result)
      end

      it 'displays error messages and returns 1' do
        output = capture_stderr { command.call(branch_or_paths: ['nonexistent-branch']) }

        expect(output).to include("Checkout failed: error: pathspec 'nonexistent-branch' did not match any file(s) known to git")
        expect(output).to include("[main-repo] Error: pathspec 'nonexistent-branch' did not match any file(s) known to git")
        expect(output).to include("[dev-tools] Error: pathspec 'nonexistent-branch' did not match any file(s) known to git")
        expect(output).to include('Use --debug flag for more information')
      end
    end

    context 'with partial success' do
      let(:partial_result) do
        {
          success: false,
          results: {
            'main-repo' => { success: true, stdout: "Switched to branch 'main'" },
            'dev-tools' => { success: false, error: "pathspec 'main' did not match any file(s) known to git" }
          },
          errors: [
            { repository: 'dev-tools', message: "pathspec 'main' did not match any file(s) known to git" }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:checkout).and_return(partial_result)
      end

      it 'shows partial successes and errors' do
        output = capture_output { command.call(branch_or_paths: ['main']) }

        expect(output).to include('Partial success: Checkout completed in repositories: main-repo')
        expect(output).to include("[dev-tools] Error: pathspec 'main' did not match any file(s) known to git")
      end
    end

    context 'with debug option' do
      let(:error_with_debug) do
        {
          success: false,
          errors: [
            {
              repository: 'main-repo',
              message: "pathspec 'nonexistent-branch' did not match any file(s) known to git",
              error: StandardError.new('detailed error')
            }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:checkout).and_return(error_with_debug)
        allow(error_with_debug[:errors][0][:error]).to receive(:backtrace).and_return(['line1', 'line2'])
      end

      it 'shows detailed error information when debug is enabled' do
        output = capture_stderr { command.call(branch_or_paths: ['nonexistent-branch'], debug: true) }

        expect(output).to include("Error: StandardError: pathspec 'nonexistent-branch' did not match any file(s) known to git")
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
                { success: true, stdout: "Switched to branch 'main'" },
                { success: true, stdout: 'Updated 3 paths from the index' }
              ]
            }
          },
          repositories_processed: ['main-repo']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:checkout).and_return(concurrent_result)
      end

      it 'handles multiple commands from concurrent execution' do
        output = capture_stdout { command.call(branch_or_paths: branch_or_paths, concurrent: true) }

        expect(output).to include("[main-repo] Switched to branch 'main'")
        expect(output).to include('[main-repo] Updated 3 paths from the index')
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
        allow(mock_orchestrator).to receive(:checkout).and_return(empty_stdout_result)
      end

      it 'displays default success message when stdout is empty' do
        output = capture_stdout { command.call(branch_or_paths: branch_or_paths) }

        expect(output).to include('[main-repo] Checkout completed successfully')
        expect(output).to include('[dev-tools] Checkout completed successfully')
      end
    end

    context 'when exception occurs' do
      before do
        allow(mock_orchestrator).to receive(:checkout).and_raise(StandardError.new('Unexpected error'))
      end

      it 'handles exceptions and returns 1' do
        output = capture_stderr { command.call(branch_or_paths: branch_or_paths) }

        expect(output).to include('Error: Unexpected error')
        expect(output).to include('Use --debug flag for more information')
      end

      it 'shows detailed error with debug flag' do
        allow_any_instance_of(StandardError).to receive(:backtrace).and_return(['line1', 'line2'])

        output = capture_stderr { command.call(branch_or_paths: branch_or_paths, debug: true) }

        expect(output).to include('Error: StandardError: Unexpected error')
        expect(output).to include('Backtrace:')
        expect(output).to include('line1')
        expect(output).to include('line2')
      end
    end
  end

  describe '#build_checkout_options' do
    let(:branch_or_paths) { ['main'] }
    let(:options) do
      {
        repository: 'dev-tools',
        main_only: true,
        force: true,
        create_branch: 'new-feature'
      }
    end

    it 'builds correct options hash' do
      result = command.send(:build_checkout_options, branch_or_paths, options)

      expect(result).to include(
        capture_output: true,
        repository: 'dev-tools',
        main_only: true,
        force: true,
        create_branch: 'new-feature'
      )
    end

    it 'only includes truthy options' do
      minimal_options = { force: false, main_only: true }
      result = command.send(:build_checkout_options, branch_or_paths, minimal_options)

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

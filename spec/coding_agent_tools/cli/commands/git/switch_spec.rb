# frozen_string_literal: true

require 'spec_helper'
require 'stringio'

RSpec.describe CodingAgentTools::Cli::Commands::Git::Switch do
  let(:command) { described_class.new }
  let(:project_root) { '/fake/project/root' }
  let(:mock_orchestrator) { instance_double('CodingAgentTools::Organisms::Git::GitOrchestrator') }
  let(:branch) { 'main' }

  before do
    allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(project_root)
    allow(CodingAgentTools::Organisms::Git::GitOrchestrator).to receive(:new).and_return(mock_orchestrator)
  end

  describe '#call' do
    context 'with successful switch operation' do
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
        allow(mock_orchestrator).to receive(:switch).and_return(success_result)
      end

      it 'executes switch operation and displays formatted output' do
        output = capture_stdout { command.call(branch: branch) }

        expect(output).to include("[main-repo] Switched to branch 'main'")
        expect(output).to include("[dev-tools] Already on 'main'")
        expect(output).to include('Switch completed across repositories: main-repo, dev-tools')
        expect(mock_orchestrator).to have_received(:switch).with(branch, hash_including(capture_output: true))
      end

      it 'returns 0 for successful execution' do
        capture_stdout { command.call(branch: branch) }
        expect(mock_orchestrator).to have_received(:switch)
      end

      it 'passes branch and default options to orchestrator' do
        capture_stdout { command.call(branch: branch) }

        expect(CodingAgentTools::Organisms::Git::GitOrchestrator).to have_received(:new).with(
          project_root,
          {}
        )
        expect(mock_orchestrator).to have_received(:switch).with(
          branch,
          hash_including(capture_output: true)
        )
      end
    end

    context 'with nil branch' do
      before do
        allow(mock_orchestrator).to receive(:switch).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'HEAD is now at 1234567' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'handles nil branch argument' do
        capture_stdout { command.call(branch: nil) }

        expect(mock_orchestrator).to have_received(:switch).with(
          nil,
          hash_including(capture_output: true)
        )
      end
    end

    context 'with options' do
      before do
        allow(mock_orchestrator).to receive(:switch).and_return({
          success: true,
          results: { 'main-repo' => { success: true, stdout: 'Switch completed' } },
          repositories_processed: ['main-repo']
        })
      end

      it 'passes repository option' do
        capture_stdout { command.call(branch: branch, repository: 'dev-tools') }

        expect(mock_orchestrator).to have_received(:switch).with(
          branch,
          hash_including(repository: 'dev-tools')
        )
      end

      it 'passes main_only option' do
        capture_stdout { command.call(branch: branch, main_only: true) }

        expect(mock_orchestrator).to have_received(:switch).with(
          branch,
          hash_including(main_only: true)
        )
      end

      it 'passes submodules_only option' do
        capture_stdout { command.call(branch: branch, submodules_only: true) }

        expect(mock_orchestrator).to have_received(:switch).with(
          branch,
          hash_including(submodules_only: true)
        )
      end

      it 'passes switch-specific options' do
        capture_stdout do
          command.call(
            branch: branch,
            quiet: true,
            force: true,
            merge: true,
            detach: true,
            create: 'new-feature',
            force_create: 'hotfix',
            orphan: 'empty-branch',
            guess: false,
            no_guess: true,
            track: true,
            no_track: false,
            concurrent: true
          )
        end

        expect(mock_orchestrator).to have_received(:switch).with(
          branch,
          hash_including(
            quiet: true,
            force: true,
            merge: true,
            detach: true,
            create: 'new-feature',
            force_create: 'hotfix',
            orphan: 'empty-branch',
            no_guess: true,
            track: true,
            concurrent: true
          )
        )
      end

      it 'handles guess/no_guess option logic correctly' do
        capture_stdout { command.call(branch: branch, no_guess: true) }

        expect(mock_orchestrator).to have_received(:switch).with(
          branch,
          hash_including(no_guess: true)
        )
        expect(mock_orchestrator).to have_received(:switch).with(
          branch,
          hash_not_including(:guess)
        )
      end

      it 'includes guess option when no_guess is false' do
        capture_stdout { command.call(branch: branch, guess: true, no_guess: false) }

        expect(mock_orchestrator).to have_received(:switch).with(
          branch,
          hash_including(guess: true)
        )
      end
    end

    context 'with quiet option' do
      before do
        allow(mock_orchestrator).to receive(:switch).and_return({
          success: true,
          results: {
            'main-repo' => { success: true, stdout: "Switched to branch 'main'" }
          },
          repositories_processed: ['main-repo']
        })
      end

      it 'suppresses feedback messages when quiet is true' do
        output = capture_stdout { command.call(branch: branch, quiet: true) }

        expect(output).not_to include('Switch completed across repositories')
      end
    end

    context 'with switch failure' do
      let(:error_result) do
        {
          success: false,
          error: "Switch failed: error: pathspec 'nonexistent-branch' did not match any file(s) known to git",
          errors: [
            { repository: 'main-repo', message: "pathspec 'nonexistent-branch' did not match any file(s) known to git" },
            { repository: 'dev-tools', message: "pathspec 'nonexistent-branch' did not match any file(s) known to git" }
          ]
        }
      end

      before do
        allow(mock_orchestrator).to receive(:switch).and_return(error_result)
      end

      it 'displays error messages and returns 1' do
        output = capture_stderr { command.call(branch: 'nonexistent-branch') }

        expect(output).to include("Switch failed: error: pathspec 'nonexistent-branch' did not match any file(s) known to git")
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
        allow(mock_orchestrator).to receive(:switch).and_return(partial_result)
      end

      it 'shows partial successes and errors' do
        output = capture_output { command.call(branch: branch) }

        expect(output).to include('Partial success: Switch completed in repositories: main-repo')
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
        allow(mock_orchestrator).to receive(:switch).and_return(error_with_debug)
        allow(error_with_debug[:errors][0][:error]).to receive(:backtrace).and_return(['line1', 'line2'])
      end

      it 'shows detailed error information when debug is enabled' do
        output = capture_stderr { command.call(branch: 'nonexistent-branch', debug: true) }

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
                { success: true, stdout: "Your branch is up to date with 'origin/main'" }
              ]
            }
          },
          repositories_processed: ['main-repo']
        }
      end

      before do
        allow(mock_orchestrator).to receive(:switch).and_return(concurrent_result)
      end

      it 'handles multiple commands from concurrent execution' do
        output = capture_stdout { command.call(branch: branch, concurrent: true) }

        expect(output).to include("[main-repo] Switched to branch 'main'")
        expect(output).to include("[main-repo] Your branch is up to date with 'origin/main'")
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
        allow(mock_orchestrator).to receive(:switch).and_return(empty_stdout_result)
      end

      it 'displays default success message when stdout is empty' do
        output = capture_stdout { command.call(branch: branch) }

        expect(output).to include('[main-repo] Switch completed successfully')
        expect(output).to include('[dev-tools] Switch completed successfully')
      end
    end

    context 'when exception occurs' do
      before do
        allow(mock_orchestrator).to receive(:switch).and_raise(StandardError.new('Unexpected error'))
      end

      it 'handles exceptions and returns 1' do
        output = capture_stderr { command.call(branch: branch) }

        expect(output).to include('Error: Unexpected error')
        expect(output).to include('Use --debug flag for more information')
      end

      it 'shows detailed error with debug flag' do
        allow_any_instance_of(StandardError).to receive(:backtrace).and_return(['line1', 'line2'])

        output = capture_stderr { command.call(branch: branch, debug: true) }

        expect(output).to include('Error: StandardError: Unexpected error')
        expect(output).to include('Backtrace:')
        expect(output).to include('line1')
        expect(output).to include('line2')
      end
    end
  end

  describe '#build_switch_options' do
    let(:branch) { 'main' }
    let(:options) do
      {
        repository: 'dev-tools',
        main_only: true,
        force: true,
        create: 'new-feature',
        guess: true,
        no_guess: false
      }
    end

    it 'builds correct options hash' do
      result = command.send(:build_switch_options, branch, options)

      expect(result).to include(
        capture_output: true,
        repository: 'dev-tools',
        main_only: true,
        force: true,
        create: 'new-feature',
        guess: true
      )
    end

    it 'only includes truthy options' do
      minimal_options = { force: false, main_only: true }
      result = command.send(:build_switch_options, branch, minimal_options)

      expect(result).to include(main_only: true)
      expect(result).not_to include(:force)
    end

    it 'handles guess option logic correctly when no_guess is true' do
      options_with_no_guess = { guess: true, no_guess: true }
      result = command.send(:build_switch_options, branch, options_with_no_guess)

      expect(result).to include(no_guess: true)
      expect(result).not_to include(:guess)
    end

    it 'includes guess option when no_guess is false' do
      options_with_guess = { guess: true, no_guess: false }
      result = command.send(:build_switch_options, branch, options_with_guess)

      expect(result).to include(guess: true)
      expect(result).not_to include(:no_guess)
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

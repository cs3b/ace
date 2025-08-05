# frozen_string_literal: true

require 'spec_helper'
require 'concurrent-ruby'

RSpec.describe CodingAgentTools::Molecules::Git::ConcurrentExecutor do
  let(:executor) { described_class.new(options) }
  let(:options) { {} }
  let(:mock_git_executor) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }

  before do
    allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(mock_git_executor)
    allow(mock_git_executor).to receive(:execute).and_return({ stdout: 'success', stderr: '' })
  end

  describe '.execute_concurrently' do
    it 'creates an instance and delegates to instance method' do
      commands_by_repo = { 'repo1' => ['status'] }
      expect(described_class).to receive(:new).with({}).and_return(executor)
      expect(executor).to receive(:execute_concurrently).with(commands_by_repo)
      described_class.execute_concurrently(commands_by_repo)
    end

    it 'passes options to constructor' do
      commands_by_repo = { 'repo1' => ['status'] }
      options = { thread_pool_size: 2, timeout: 10 }
      expect(described_class).to receive(:new).with(options).and_return(executor)
      expect(executor).to receive(:execute_concurrently).with(commands_by_repo)
      described_class.execute_concurrently(commands_by_repo, options)
    end
  end

  describe '#initialize' do
    context 'with default options' do
      it 'sets default values' do
        expect(executor.send(:thread_pool_size)).to eq(4)
        expect(executor.send(:timeout)).to eq(30)
        expect(executor.send(:capture_output)).to be true
      end
    end

    context 'with custom options' do
      let(:options) { { thread_pool_size: 8, timeout: 60, capture_output: false } }

      it 'uses provided values' do
        expect(executor.send(:thread_pool_size)).to eq(8)
        expect(executor.send(:timeout)).to eq(60)
        expect(executor.send(:capture_output)).to be false
      end
    end
  end

  describe '#execute_concurrently' do
    context 'with empty commands' do
      it 'returns successful result with empty data' do
        result = executor.execute_concurrently({})
        expect(result).to eq({
          success: true,
          results: {},
          errors: []
        })
      end
    end

    context 'with only submodule commands' do
      let(:commands_by_repo) { { 'repo1' => ['status'], 'repo2' => ['log'] } }

      it 'executes submodules concurrently' do
        allow(executor).to receive(:execute_submodules_concurrently)
          .with(commands_by_repo)
          .and_return({
            results: { 'repo1' => { success: true }, 'repo2' => { success: true } },
            errors: []
          })

        result = executor.execute_concurrently(commands_by_repo)

        expect(result[:success]).to be true
        expect(result[:results]).to include('repo1', 'repo2')
        expect(result[:errors]).to be_empty
      end
    end

    context 'with only main repository commands' do
      let(:commands_by_repo) { { 'main' => ['status', 'log'] } }

      it 'executes main repository sequentially' do
        allow(executor).to receive(:execute_main_repository)
          .with(['status', 'log'])
          .and_return({ success: true, repository: 'main' })

        result = executor.execute_concurrently(commands_by_repo)

        expect(result[:success]).to be true
        expect(result[:results]['main']).to eq({ success: true, repository: 'main' })
        expect(result[:errors]).to be_empty
      end
    end

    context 'with both main and submodule commands' do
      let(:commands_by_repo) { { 'main' => ['status'], 'repo1' => ['log'] } }

      it 'executes submodules first, then main' do
        allow(executor).to receive(:execute_submodules_concurrently)
          .with({ 'repo1' => ['log'] })
          .and_return({
            results: { 'repo1' => { success: true } },
            errors: []
          })

        allow(executor).to receive(:execute_main_repository)
          .with(['status'])
          .and_return({ success: true, repository: 'main' })

        result = executor.execute_concurrently(commands_by_repo)

        expect(result[:success]).to be true
        expect(result[:results]).to include('main', 'repo1')
        expect(result[:errors]).to be_empty
      end
    end

    context 'when main repository execution fails' do
      let(:commands_by_repo) { { 'main' => ['invalid-command'] } }

      it 'captures the error and marks as unsuccessful' do
        error = StandardError.new('Command failed')
        allow(executor).to receive(:execute_main_repository).and_raise(error)

        result = executor.execute_concurrently(commands_by_repo)

        expect(result[:success]).to be false
        expect(result[:errors].size).to eq(1)
        expect(result[:errors].first[:repository]).to eq('main')
        expect(result[:errors].first[:error]).to be error
        expect(result[:results]['main']).to eq({ success: false, error: 'Command failed' })
      end
    end
  end

  describe '#execute_submodules_concurrently' do
    let(:submodule_commands) { { 'repo1' => ['status'], 'repo2' => ['log'] } }

    it 'executes commands for each repository concurrently' do
      # Mock successful execution for both repos
      allow(executor).to receive(:execute_repository_commands)
        .with('repo1', ['status'])
        .and_return({ success: true, repository: 'repo1' })

      allow(executor).to receive(:execute_repository_commands)
        .with('repo2', ['log'])
        .and_return({ success: true, repository: 'repo2' })

      result = executor.send(:execute_submodules_concurrently, submodule_commands)

      expect(result[:results]).to include('repo1', 'repo2')
      expect(result[:errors]).to be_empty
    end

    context 'when a repository execution times out' do
      let(:options) { { timeout: 0.1 } }

      it 'handles timeout gracefully' do
        # Mock a future that will timeout
        mock_future = instance_double(Concurrent::Future)
        allow(Concurrent::Future).to receive(:execute).and_return(mock_future)
        allow(mock_future).to receive(:value).with(0.1).and_raise(Concurrent::TimeoutError)

        result = executor.send(:execute_submodules_concurrently, submodule_commands)

        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first[:repository]).to eq('repo1')
        expect(result[:errors].first[:error]).to eq('Timeout after 0.1 seconds')
        expect(result[:results]['repo1'][:success]).to be false
      end
    end

    context 'when a repository execution raises an error' do
      it 'captures the error' do
        error = StandardError.new('Repository error')

        # Mock futures that will raise an error
        error_future = instance_double(Concurrent::Future)
        success_future = instance_double(Concurrent::Future)

        allow(Concurrent::Future).to receive(:execute)
          .and_return(error_future, success_future)

        allow(error_future).to receive(:value).with(30).and_raise(error)
        allow(success_future).to receive(:value).with(30).and_return({ success: true, repository: 'repo2' })

        result = executor.send(:execute_submodules_concurrently, submodule_commands)

        expect(result[:errors].size).to eq(1)
        expect(result[:errors].first[:repository]).to eq('repo1')
        expect(result[:errors].first[:error]).to be error
        expect(result[:results]['repo1'][:success]).to be false
        expect(result[:results]['repo2'][:success]).to be true
      end
    end
  end

  describe '#execute_main_repository' do
    it "delegates to execute_repository_commands with 'main'" do
      commands = ['status', 'log']
      expected_result = { success: true, repository: 'main' }

      expect(executor).to receive(:execute_repository_commands)
        .with('main', commands)
        .and_return(expected_result)

      result = executor.send(:execute_main_repository, commands)
      expect(result).to eq(expected_result)
    end
  end

  describe '#execute_repository_commands' do
    let(:repo_name) { 'test-repo' }
    let(:commands) { ['status', 'log --oneline'] }

    context 'with empty commands' do
      it 'returns successful result with empty command list' do
        result = executor.send(:execute_repository_commands, repo_name, [])
        expect(result).to eq({
          success: true,
          commands: [],
          outputs: []
        })
      end
    end

    context 'with successful commands' do
      it 'executes all commands and returns results' do
        allow(mock_git_executor).to receive(:execute)
          .with('status', capture_output: true)
          .and_return({ stdout: 'Clean working directory', stderr: '' })

        allow(mock_git_executor).to receive(:execute)
          .with('log --oneline', capture_output: true)
          .and_return({ stdout: 'abc123 Initial commit', stderr: '' })

        result = executor.send(:execute_repository_commands, repo_name, commands)

        expect(result[:success]).to be true
        expect(result[:repository]).to eq(repo_name)
        expect(result[:total_commands]).to eq(2)
        expect(result[:successful_commands]).to eq(2)
        expect(result[:commands].size).to eq(2)

        expect(result[:commands][0][:command]).to eq('status')
        expect(result[:commands][0][:success]).to be true
        expect(result[:commands][0][:output]).to eq('Clean working directory')

        expect(result[:commands][1][:command]).to eq('log --oneline')
        expect(result[:commands][1][:success]).to be true
        expect(result[:commands][1][:output]).to eq('abc123 Initial commit')
      end
    end

    context 'when a command fails' do
      it 'stops processing further commands and returns error details' do
        allow(mock_git_executor).to receive(:execute)
          .with('status', capture_output: true)
          .and_return({ stdout: 'Clean working directory', stderr: '' })

        error = CodingAgentTools::Atoms::Git::GitCommandError.new(
          'Command failed',
          command: 'invalid-command',
          stderr_output: 'fatal: not a git repository'
        )

        allow(mock_git_executor).to receive(:execute)
          .with('invalid-command', capture_output: true)
          .and_raise(error)

        result = executor.send(:execute_repository_commands, repo_name, ['status', 'invalid-command', 'log'])

        expect(result[:success]).to be false
        expect(result[:total_commands]).to eq(3)
        expect(result[:successful_commands]).to eq(1)
        expect(result[:commands].size).to eq(2) # Should stop after the failed command

        expect(result[:commands][0][:success]).to be true
        expect(result[:commands][1][:success]).to be false
        expect(result[:commands][1][:error]).to eq('Command failed')
        expect(result[:commands][1][:stderr]).to eq('fatal: not a git repository')
      end
    end

    context 'for main repository' do
      it 'creates GitCommandExecutor with nil repository_path' do
        expect(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new)
          .with(repository_path: nil)
          .and_return(mock_git_executor)

        executor.send(:execute_repository_commands, 'main', ['status'])
      end
    end

    context 'for submodule repository' do
      it 'creates GitCommandExecutor with repository path' do
        expect(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new)
          .with(repository_path: repo_name)
          .and_return(mock_git_executor)

        executor.send(:execute_repository_commands, repo_name, ['status'])
      end
    end

    context 'with capture_output option' do
      let(:options) { { capture_output: false } }

      it 'passes capture_output option to GitCommandExecutor' do
        expect(mock_git_executor).to receive(:execute)
          .with('status', capture_output: false)
          .and_return({ stdout: '', stderr: '' })

        executor.send(:execute_repository_commands, repo_name, ['status'])
      end
    end
  end

  describe 'thread pool management' do
    let(:options) { { thread_pool_size: 2 } }
    let(:submodule_commands) { { 'repo1' => ['status'], 'repo2' => ['log'] } }

    it 'creates and properly shuts down thread pool' do
      mock_pool = instance_double(Concurrent::FixedThreadPool)
      mock_future = instance_double(Concurrent::Future)

      expect(Concurrent::FixedThreadPool).to receive(:new).with(2).and_return(mock_pool)
      expect(Concurrent::Future).to receive(:execute).twice.and_return(mock_future)
      expect(mock_future).to receive(:value).twice.and_return({ success: true })
      expect(mock_pool).to receive(:shutdown)
      expect(mock_pool).to receive(:wait_for_termination).with(30).and_return(true)

      executor.send(:execute_submodules_concurrently, submodule_commands)
    end

    it 'kills thread pool if shutdown takes too long' do
      mock_pool = instance_double(Concurrent::FixedThreadPool)
      mock_future = instance_double(Concurrent::Future)

      expect(Concurrent::FixedThreadPool).to receive(:new).with(2).and_return(mock_pool)
      expect(Concurrent::Future).to receive(:execute).twice.and_return(mock_future)
      expect(mock_future).to receive(:value).twice.and_return({ success: true })
      expect(mock_pool).to receive(:shutdown)
      expect(mock_pool).to receive(:wait_for_termination).with(30).and_return(false)
      expect(mock_pool).to receive(:kill)

      executor.send(:execute_submodules_concurrently, submodule_commands)
    end
  end

  describe 'error types' do
    it 'defines ConcurrentExecutionError' do
      expect(CodingAgentTools::Molecules::Git::ConcurrentExecutionError).to be < StandardError
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/molecules/taskflow_management/release_path_resolver'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::ReleasePathResolver do
  let(:test_dir) { Dir.mktmpdir }
  
  # Helper to create a standard dev-taskflow structure
  def setup_taskflow_structure
    ['current', 'backlog', 'done'].each do |dir|
      FileUtils.mkdir_p(File.join(test_dir, 'dev-taskflow', dir))
    end
  end

  # Helper to create a release directory
  def create_release(location, release_name)
    release_path = File.join(test_dir, 'dev-taskflow', location, release_name)
    FileUtils.mkdir_p(release_path)
    FileUtils.mkdir_p(File.join(release_path, 'tasks'))
    release_path
  end
  
  after do
    FileUtils.rm_rf(test_dir) if Dir.exist?(test_dir)
  end

  describe '.get_current_release' do
    context 'when current release exists' do
      before do
        setup_taskflow_structure
        create_release('current', 'v.0.3.0-workflows')
        create_release('current', 'v.0.4.0-features')
      end

      it 'returns the current release information' do
        # Mock DirectoryNavigator to return a specific release
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:get_current_release_directory)
          .with(base_path: test_dir)
          .and_return({
            path: File.join(test_dir, 'dev-taskflow/current/v.0.4.0-features'),
            version: 'v.0.4.0'
          })
        
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_tasks_directory)
          .and_return(File.join(test_dir, 'dev-taskflow/current/v.0.4.0-features/tasks'))

        result = described_class.get_current_release(base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.version).to eq('v.0.4.0')
        expect(result.release_info.name).to eq('v.0.4.0-features')
        expect(result.release_info.type).to eq(:current)
        expect(result.release_info.path).to include('v.0.4.0-features')
        expect(result.release_info.tasks_directory).to include('tasks')
      end
    end

    context 'when no current release exists' do
      before do
        setup_taskflow_structure
      end

      it 'returns failure result' do
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:get_current_release_directory)
          .with(base_path: test_dir)
          .and_return(nil)

        result = described_class.get_current_release(base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to eq('No current release directory found')
        expect(result.release_info).to be_nil
      end
    end

    context 'when exception occurs' do
      it 'returns failure result with error message' do
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:get_current_release_directory)
          .and_raise('Test error')

        result = described_class.get_current_release(base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('Error resolving current release')
        expect(result.error_message).to include('Test error')
      end
    end

    context 'with default base path' do
      it 'uses current directory as default' do
        expect(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:get_current_release_directory)
          .with(base_path: '.')
          .and_return(nil)

        described_class.get_current_release
      end
    end
  end

  describe '.find_release_by_version' do
    before do
      setup_taskflow_structure
      create_release('current', 'v.0.3.0-workflows')
      create_release('backlog', 'v.0.4.0-features')
      create_release('done', 'v.0.2.0-foundation')
    end

    context 'when release exists in current' do
      it 'finds release in current directory' do
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_release_directory)
          .and_return({
            path: File.join(test_dir, 'dev-taskflow/current/v.0.3.0-workflows'),
            version: 'v.0.3.0'
          })
        
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_tasks_directory)
          .and_return(File.join(test_dir, 'dev-taskflow/current/v.0.3.0-workflows/tasks'))

        result = described_class.find_release_by_version('v.0.3.0', base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.version).to eq('v.0.3.0')
        expect(result.release_info.type).to eq(:current)
      end
    end

    context 'when release exists in backlog' do
      it 'finds release in backlog directory' do
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_release_directory)
          .and_return({
            path: File.join(test_dir, 'dev-taskflow/backlog/v.0.4.0-features'),
            version: 'v.0.4.0'
          })
        
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_tasks_directory)
          .and_return(File.join(test_dir, 'dev-taskflow/backlog/v.0.4.0-features/tasks'))

        result = described_class.find_release_by_version('v.0.4.0', base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.version).to eq('v.0.4.0')
        expect(result.release_info.type).to eq(:backlog)
      end
    end

    context 'with search options' do
      it 'searches only in current when search_backlog is false' do
        expect(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_release_directory)
          .with(
            'v.0.4.0',
            search_paths: [File.join(test_dir, 'dev-taskflow/current')],
            base_path: test_dir
          )
          .and_return(nil)

        result = described_class.find_release_by_version('v.0.4.0', 
                                                        base_path: test_dir, 
                                                        search_backlog: false)
        
        expect(result).not_to be_success
      end

      it 'searches only in backlog when search_current is false' do
        expect(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_release_directory)
          .with(
            'v.0.3.0',
            search_paths: [File.join(test_dir, 'dev-taskflow/backlog')],
            base_path: test_dir
          )
          .and_return(nil)

        result = described_class.find_release_by_version('v.0.3.0', 
                                                        base_path: test_dir, 
                                                        search_current: false)
        
        expect(result).not_to be_success
      end
    end

    context 'when release not found' do
      it 'returns failure result' do
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_release_directory)
          .and_return(nil)

        result = described_class.find_release_by_version('v.9.9.9', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to eq("Release directory for version 'v.9.9.9' not found")
      end
    end

    context 'when exception occurs' do
      it 'returns failure result with error message' do
        allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
          .to receive(:find_release_directory)
          .and_raise('Search error')

        result = described_class.find_release_by_version('v.0.3.0', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('Error finding release by version')
        expect(result.error_message).to include('Search error')
      end
    end
  end

  describe '.get_current_tasks_directory' do
    context 'when current release exists' do
      it 'returns the tasks directory path' do
        mock_release_info = described_class::ReleaseInfo.new(
          File.join(test_dir, 'dev-taskflow/current/v.0.3.0-workflows'),
          'v.0.3.0',
          File.join(test_dir, 'dev-taskflow/current/v.0.3.0-workflows/tasks'),
          'v.0.3.0-workflows',
          :current
        )
        
        allow(described_class)
          .to receive(:get_current_release)
          .with(base_path: test_dir)
          .and_return(described_class::ResolutionResult.new(mock_release_info, true, nil))

        result = described_class.get_current_tasks_directory(base_path: test_dir)
        
        expect(result).to eq(File.join(test_dir, 'dev-taskflow/current/v.0.3.0-workflows/tasks'))
      end
    end

    context 'when current release does not exist' do
      it 'returns nil' do
        allow(described_class)
          .to receive(:get_current_release)
          .with(base_path: test_dir)
          .and_return(described_class::ResolutionResult.new(nil, false, 'No current release'))

        result = described_class.get_current_tasks_directory(base_path: test_dir)
        
        expect(result).to be_nil
      end
    end

    context 'with default base path' do
      it 'uses current directory as default' do
        expect(described_class)
          .to receive(:get_current_release)
          .with(base_path: '.')
          .and_return(described_class::ResolutionResult.new(nil, false, 'No current release'))

        described_class.get_current_tasks_directory
      end
    end
  end

  describe 'ReleaseInfo struct' do
    it 'stores all release information' do
      info = described_class::ReleaseInfo.new(
        '/path/to/release',
        'v.0.3.0',
        '/path/to/release/tasks',
        'v.0.3.0-workflows',
        :current
      )
      
      expect(info.path).to eq('/path/to/release')
      expect(info.version).to eq('v.0.3.0')
      expect(info.tasks_directory).to eq('/path/to/release/tasks')
      expect(info.name).to eq('v.0.3.0-workflows')
      expect(info.type).to eq(:current)
    end
  end

  describe 'ResolutionResult struct' do
    it 'provides success? method' do
      success_result = described_class::ResolutionResult.new(nil, true, nil)
      failure_result = described_class::ResolutionResult.new(nil, false, 'Error')
      
      expect(success_result).to be_success
      expect(failure_result).not_to be_success
    end

    it 'stores release info and error message' do
      release_info = described_class::ReleaseInfo.new('path', 'v.0.1.0', 'tasks', 'name', :current)
      result = described_class::ResolutionResult.new(release_info, true, 'Some message')
      
      expect(result.release_info).to eq(release_info)
      expect(result.success).to be true
      expect(result.error_message).to eq('Some message')
    end
  end
end
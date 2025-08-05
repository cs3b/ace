# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/molecules/taskflow_management/release_resolver'
require 'coding_agent_tools/molecules/taskflow_management/release_path_resolver'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Molecules::TaskflowManagement::ReleaseResolver do
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

  describe '.resolve_release' do
    before do
      setup_taskflow_structure
      create_release('current', 'v.0.3.0-workflows')
      create_release('current', 'v.0.4.0-features')
      create_release('backlog', 'v.0.5.0-improvements')
      create_release('done', 'v.0.2.0-foundation')
    end

    context 'when identifier is nil or empty' do
      it 'resolves to current release' do
        # Mock the ReleasePathResolver response
        mock_release_info = double('ReleaseInfo', 
          path: File.join(test_dir, 'dev-taskflow/current/v.0.4.0-features'))
        
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleasePathResolver)
          .to receive(:get_current_release)
          .and_return(described_class::ResolutionResult.new(mock_release_info, true, nil))

        result = described_class.resolve_release(nil, base_path: test_dir)
        expect(result).to be_success
        expect(result.release_info.path).to include('v.0.4.0-features')
      end

      it 'handles empty string identifier' do
        mock_release_info = double('ReleaseInfo', 
          path: File.join(test_dir, 'dev-taskflow/current/v.0.4.0-features'))
        
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleasePathResolver)
          .to receive(:get_current_release)
          .and_return(described_class::ResolutionResult.new(mock_release_info, true, nil))

        result = described_class.resolve_release('', base_path: test_dir)
        expect(result).to be_success
      end
    end

    context 'when resolving by path' do
      it 'resolves absolute paths' do
        release_path = create_release('current', 'v.0.6.0-absolute')
        result = described_class.resolve_release(release_path, base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.path).to eq(release_path)
        expect(result.release_info.version).to eq('v.0.6.0')
      end

      it 'resolves relative paths' do
        result = described_class.resolve_release('dev-taskflow/current/v.0.3.0-workflows', base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.path).to include('v.0.3.0-workflows')
        expect(result.release_info.version).to eq('v.0.3.0')
      end

      it 'returns error for non-existent paths' do
        result = described_class.resolve_release('dev-taskflow/current/nonexistent', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('not found')
      end
    end

    context 'when resolving by version' do
      it 'resolves exact version matches' do
        result = described_class.resolve_release('v.0.3.0', base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.path).to include('v.0.3.0-workflows')
        expect(result.release_info.name).to eq('v.0.3.0-workflows')
      end

      it 'handles multiple matches by showing options' do
        # Create another v.0.3.0 release in backlog
        create_release('backlog', 'v.0.3.0-alternative')
        
        result = described_class.resolve_release('v.0.3.0', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('Multiple releases found')
        expect(result.error_message).to include('v.0.3.0-workflows')
        expect(result.error_message).to include('v.0.3.0-alternative')
      end

      it 'returns error for non-existent version' do
        result = described_class.resolve_release('v.9.9.9', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('not found')
      end
    end

    context 'when resolving by fullname' do
      it 'resolves exact fullname matches' do
        result = described_class.resolve_release('v.0.4.0-features', base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.path).to include('v.0.4.0-features')
        expect(result.release_info.version).to eq('v.0.4.0')
      end

      it 'searches across all taskflow directories' do
        result = described_class.resolve_release('v.0.5.0-improvements', base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.path).to include('backlog')
        expect(result.release_info.path).to include('v.0.5.0-improvements')
      end

      it 'returns error for non-existent fullname' do
        result = described_class.resolve_release('v.0.9.0-nonexistent', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('not found')
      end
    end

    context 'when resolving by codename' do
      it 'resolves exact codename matches' do
        result = described_class.resolve_release('workflows', base_path: test_dir)
        
        expect(result).to be_success
        expect(result.release_info.path).to include('v.0.3.0-workflows')
      end

      it 'handles multiple codename matches' do
        # Create another release with same codename
        create_release('backlog', 'v.0.7.0-workflows')
        
        result = described_class.resolve_release('workflows', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('Multiple releases found')
        expect(result.error_message).to include('v.0.3.0-workflows')
        expect(result.error_message).to include('v.0.7.0-workflows')
      end

      it 'returns error for non-existent codename' do
        result = described_class.resolve_release('nonexistent', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('not found')
      end
    end

    context 'with error handling' do
      it 'handles exceptions gracefully' do
        # Mock a method to raise an error
        allow(described_class).to receive(:resolve_by_path).and_raise('Test error')
        
        result = described_class.resolve_release('some/path', base_path: test_dir)
        
        expect(result).not_to be_success
        expect(result.error_message).to include('Error resolving release')
        expect(result.error_message).to include('Test error')
      end
    end
  end

  describe '.resolve_current_release' do
    it 'delegates to ReleasePathResolver' do
      expect(CodingAgentTools::Molecules::TaskflowManagement::ReleasePathResolver)
        .to receive(:get_current_release)
        .with(base_path: test_dir)
        .and_return(described_class::ResolutionResult.new(nil, true, nil))

      described_class.resolve_current_release(base_path: test_dir)
    end
  end

  describe '.resolve_by_path' do
    before do
      setup_taskflow_structure
      create_release('current', 'v.0.3.0-workflows')
    end

    it 'returns error for non-path identifiers' do
      result = described_class.resolve_by_path('v.0.3.0', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Not a path')
    end

    it 'resolves absolute paths' do
      release_path = File.join(test_dir, 'dev-taskflow/current/v.0.3.0-workflows')
      result = described_class.resolve_by_path(release_path, test_dir)
      
      expect(result).to be_success
      expect(result.release_info.path).to eq(release_path)
    end

    it 'resolves relative paths' do
      result = described_class.resolve_by_path('dev-taskflow/current/v.0.3.0-workflows', test_dir)
      
      expect(result).to be_success
      expect(result.release_info.path).to include('v.0.3.0-workflows')
    end

    it 'returns error for non-existent paths' do
      result = described_class.resolve_by_path('dev-taskflow/current/nonexistent', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Path not found')
    end

    it 'returns error for file paths' do
      # Create a file instead of directory
      file_path = File.join(test_dir, 'test.txt')
      File.write(file_path, 'test')
      
      result = described_class.resolve_by_path(file_path, test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Path not found')
    end
  end

  describe '.resolve_by_version' do
    before do
      setup_taskflow_structure
      create_release('current', 'v.0.3.0-workflows')
      create_release('done', 'v.0.2.0-foundation')
    end

    it 'returns error for non-version identifiers' do
      result = described_class.resolve_by_version('workflows', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Not a version')
    end

    it 'returns error for invalid version formats' do
      result = described_class.resolve_by_version('v.0.3', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Not a version')
    end

    it 'finds single matching version' do
      result = described_class.resolve_by_version('v.0.3.0', test_dir)
      
      expect(result).to be_success
      expect(result.release_info.version).to eq('v.0.3.0')
    end

    it 'handles multiple matches' do
      create_release('backlog', 'v.0.3.0-alternative')
      
      result = described_class.resolve_by_version('v.0.3.0', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to include('Multiple releases found')
    end
  end

  describe '.resolve_by_fullname' do
    before do
      setup_taskflow_structure
      create_release('current', 'v.0.3.0-workflows')
    end

    it 'returns error for path-like identifiers' do
      result = described_class.resolve_by_fullname('dev/v.0.3.0-workflows', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Not a fullname')
    end

    it 'searches in current directory' do
      result = described_class.resolve_by_fullname('v.0.3.0-workflows', test_dir)
      
      expect(result).to be_success
      expect(result.release_info.type).to eq(:current)
    end

    it 'searches in backlog directory' do
      create_release('backlog', 'v.0.5.0-future')
      result = described_class.resolve_by_fullname('v.0.5.0-future', test_dir)
      
      expect(result).to be_success
      expect(result.release_info.type).to eq(:backlog)
    end

    it 'searches in done directory' do
      create_release('done', 'v.0.1.0-past')
      result = described_class.resolve_by_fullname('v.0.1.0-past', test_dir)
      
      expect(result).to be_success
      expect(result.release_info.type).to eq(:done)
    end

    it 'returns error when not found' do
      result = described_class.resolve_by_fullname('v.9.9.9-missing', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Fullname not found')
    end
  end

  describe '.resolve_by_codename' do
    before do
      setup_taskflow_structure
      create_release('current', 'v.0.3.0-workflows')
    end

    it 'returns error for version-like identifiers' do
      result = described_class.resolve_by_codename('v.0.3.0', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Not a codename')
    end

    it 'returns error for path-like identifiers' do
      result = described_class.resolve_by_codename('dev/workflows', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Not a codename')
    end

    it 'finds matching codename' do
      result = described_class.resolve_by_codename('workflows', test_dir)
      
      expect(result).to be_success
      expect(result.release_info.name).to eq('v.0.3.0-workflows')
    end

    it 'handles multiple matches' do
      create_release('done', 'v.0.1.0-workflows')
      
      result = described_class.resolve_by_codename('workflows', test_dir)
      
      expect(result).not_to be_success
      expect(result.error_message).to include('Multiple releases found')
    end
  end

  describe '.find_all_matching_releases' do
    before do
      setup_taskflow_structure
      create_release('current', 'v.0.3.0-workflows')
      create_release('backlog', 'v.0.3.0-alternative')
      create_release('done', 'v.0.2.0-workflows')
    end

    it 'finds all releases matching version' do
      matches = described_class.find_all_matching_releases('v.0.3.0', test_dir, :version)
      
      expect(matches.size).to eq(2)
      expect(matches.all? { |m| File.basename(m).start_with?('v.0.3.0') }).to be true
    end

    it 'finds all releases matching codename' do
      matches = described_class.find_all_matching_releases('workflows', test_dir, :codename)
      
      expect(matches.size).to eq(2)
      expect(matches.all? { |m| File.basename(m).end_with?('-workflows') }).to be true
    end

    it 'returns empty array when no matches' do
      matches = described_class.find_all_matching_releases('v.9.9.9', test_dir, :version)
      
      expect(matches).to be_empty
    end

    it 'skips non-existent directories' do
      # Remove backlog directory
      FileUtils.rm_rf(File.join(test_dir, 'dev-taskflow/backlog'))
      
      matches = described_class.find_all_matching_releases('v.0.3.0', test_dir, :version)
      
      expect(matches.size).to eq(1)
    end

    it 'skips non-directory entries' do
      # Create a file in current
      File.write(File.join(test_dir, 'dev-taskflow/current/v.0.3.0-file.txt'), 'test')
      
      matches = described_class.find_all_matching_releases('v.0.3.0', test_dir, :version)
      
      expect(matches.none? { |m| m.end_with?('.txt') }).to be true
    end
  end

  describe '.handle_multiple_matches' do
    it 'returns not found for zero matches' do
      result = described_class.handle_multiple_matches([], 'v.0.3.0')
      
      expect(result).not_to be_success
      expect(result.error_message).to eq("No releases found matching 'v.0.3.0'")
    end

    it 'resolves single match' do
      release_path = create_release('current', 'v.0.3.0-single')
      result = described_class.handle_multiple_matches([release_path], 'v.0.3.0')
      
      expect(result).to be_success
      expect(result.release_info.path).to eq(release_path)
    end

    it 'returns informative error for multiple matches' do
      paths = [
        File.join(test_dir, 'dev-taskflow/current/v.0.3.0-workflows'),
        File.join(test_dir, 'dev-taskflow/backlog/v.0.3.0-alternative'),
        File.join(test_dir, 'dev-taskflow/done/v.0.3.0-old')
      ]
      
      result = described_class.handle_multiple_matches(paths, 'v.0.3.0')
      
      expect(result).not_to be_success
      expect(result.error_message).to include('Multiple releases found')
      expect(result.error_message).to include('v.0.3.0-workflows (current)')
      expect(result.error_message).to include('v.0.3.0-alternative (backlog)')
      expect(result.error_message).to include('v.0.3.0-old (done)')
      expect(result.error_message).to include('Example: task-manager recent --release v.0.3.0-workflows')
    end

    it 'handles unknown release types in multiple matches' do
      # Create multiple releases including one in an unknown location
      FileUtils.mkdir_p(File.join(test_dir, 'other'))
      unknown_path = File.join(test_dir, 'other/v.0.3.0-unknown')
      FileUtils.mkdir_p(unknown_path)
      FileUtils.mkdir_p(File.join(unknown_path, 'tasks'))
      
      # Create another match to trigger multiple matches error
      current_path = File.join(test_dir, 'dev-taskflow/current/v.0.3.0-current')
      FileUtils.mkdir_p(File.dirname(current_path))
      FileUtils.mkdir_p(current_path)
      
      paths = [unknown_path, current_path]
      
      result = described_class.handle_multiple_matches(paths, 'v.0.3.0')
      
      expect(result).not_to be_success
      expect(result.error_message).to include('Multiple releases found')
      expect(result.error_message).to include('v.0.3.0-unknown (unknown)')
      expect(result.error_message).to include('v.0.3.0-current (current)')
    end
  end

  describe '.resolve_directory_path' do
    before do
      setup_taskflow_structure
    end

    it 'resolves valid release directory' do
      release_path = create_release('current', 'v.0.3.0-workflows')
      result = described_class.resolve_directory_path(release_path)
      
      expect(result).to be_success
      expect(result.release_info.path).to eq(release_path)
      expect(result.release_info.version).to eq('v.0.3.0')
      expect(result.release_info.name).to eq('v.0.3.0-workflows')
      expect(result.release_info.type).to eq(:current)
      expect(result.release_info.tasks_directory).to eq(File.join(release_path, 'tasks'))
    end

    it 'handles release without codename' do
      release_path = create_release('current', 'v.0.4.0')
      result = described_class.resolve_directory_path(release_path)
      
      expect(result).to be_success
      expect(result.release_info.version).to eq('v.0.4.0')
    end

    it 'handles non-standard release names' do
      release_path = create_release('current', 'custom-release')
      result = described_class.resolve_directory_path(release_path)
      
      expect(result).to be_success
      expect(result.release_info.version).to eq('custom-release')
    end

    it 'returns error for non-existent directory' do
      result = described_class.resolve_directory_path('/nonexistent/path')
      
      expect(result).not_to be_success
      expect(result.error_message).to eq('Directory does not exist')
    end

    it 'determines release type from path' do
      backlog_path = create_release('backlog', 'v.0.5.0-future')
      done_path = create_release('done', 'v.0.1.0-past')
      
      backlog_result = described_class.resolve_directory_path(backlog_path)
      done_result = described_class.resolve_directory_path(done_path)
      
      expect(backlog_result.release_info.type).to eq(:backlog)
      expect(done_result.release_info.type).to eq(:done)
    end

    it 'handles exceptions gracefully' do
      # Mock DirectoryNavigator to raise error
      allow(CodingAgentTools::Atoms::TaskflowManagement::DirectoryNavigator)
        .to receive(:find_tasks_directory)
        .and_raise('Test error')
      
      release_path = create_release('current', 'v.0.3.0-error')
      result = described_class.resolve_directory_path(release_path)
      
      expect(result).not_to be_success
      expect(result.error_message).to include('Error processing directory')
      expect(result.error_message).to include('Test error')
    end
  end

  describe 'ResolutionResult' do
    it 'provides success? method' do
      success_result = described_class::ResolutionResult.new(nil, true, nil)
      failure_result = described_class::ResolutionResult.new(nil, false, 'Error')
      
      expect(success_result).to be_success
      expect(failure_result).not_to be_success
    end

    it 'stores release info and error message' do
      release_info = double('ReleaseInfo')
      result = described_class::ResolutionResult.new(release_info, true, 'Some message')
      
      expect(result.release_info).to eq(release_info)
      expect(result.success).to be true
      expect(result.error_message).to eq('Some message')
    end
  end
end
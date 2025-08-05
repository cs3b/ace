# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'json'

RSpec.describe 'Release path resolution integration', type: :integration do
  include CliHelpers

  let(:temp_dir) { Dir.mktmpdir }
  let(:release_manager) { CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager.new(base_path: temp_dir) }

  after do
    safe_directory_cleanup(temp_dir)
  end

  def create_release_structure(release_name)
    current_path = File.join(temp_dir, 'dev-taskflow', 'current')
    release_path = File.join(current_path, release_name)
    FileUtils.mkdir_p(File.join(release_path, 'tasks'))
    FileUtils.mkdir_p(File.join(release_path, 'reflections'))

    # Create sample task file
    File.write(File.join(release_path, 'tasks', "#{release_name}+task.1-sample.md"), '# Sample task')

    # Create sample reflection files
    File.write(File.join(release_path, 'reflections', 'reflection-2024-01-15.md'),
      "# Reflection 2024-01-15\n\n**Date**: 2024-01-15\n\n## What Went Well\n- Tests passed")
    File.write(File.join(release_path, 'reflections', 'reflection-2024-01-16.md'),
      "# Reflection 2024-01-16\n\n**Date**: 2024-01-16\n\n## Key Learnings\n- Integration tests are valuable")

    release_path
  end

  describe 'release-manager current --path integration' do
    let(:release_name) { 'v.0.3.0-workflows' }

    before do
      create_release_structure(release_name)
    end

    it 'resolves paths through full stack (text format)' do
      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        # Test CLI to ReleaseManager flow
        result = execute_cli_command('release-manager', ['current', '--path', 'reflections'])

        expect(result).to be_success
        expect(result.stdout.strip).to end_with("dev-taskflow/current/#{release_name}/reflections")
        expect(result.stderr).to be_empty
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it 'resolves paths through full stack (json format)' do
      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        result = execute_cli_command('release-manager', ['current', '--path', 'reflections', '--format', 'json'])

        expect(result).to be_success

        output = JSON.parse(result.stdout)
        expect(output['success']).to be true
        expect(output['data']['subpath']).to eq('reflections')
        expect(output['data']['resolved_path']).to end_with("dev-taskflow/current/#{release_name}/reflections")
        expect(output['data']['exists']).to be true
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it 'returns correct format in different modes' do
      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        # Test both text and JSON outputs
        text_result = execute_cli_command('release-manager', ['current', '--path', 'tasks'])
        json_result = execute_cli_command('release-manager', ['current', '--path', 'tasks', '--format', 'json'])

        expect(text_result).to be_success
        expect(json_result).to be_success

        # Text format should just return the path
        expect(text_result.stdout.strip).to end_with("dev-taskflow/current/#{release_name}/tasks")

        # JSON format should return structured data
        json_output = JSON.parse(json_result.stdout)
        expect(json_output['success']).to be true
        expect(json_output['data']['subpath']).to eq('tasks')
        expect(json_output['data']['exists']).to be true
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it 'handles nested path resolution' do
      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        # Create nested directory structure
        nested_path = File.join(temp_dir, 'dev-taskflow', 'current', release_name, 'reflections', 'synthesis')
        FileUtils.mkdir_p(nested_path)

        result = execute_cli_command('release-manager', ['current', '--path', 'reflections/synthesis', '--format', 'json'])

        expect(result).to be_success

        output = JSON.parse(result.stdout)
        expect(output['success']).to be true
        expect(output['data']['subpath']).to eq('reflections/synthesis')
        expect(output['data']['resolved_path']).to end_with("dev-taskflow/current/#{release_name}/reflections/synthesis")
        expect(output['data']['exists']).to be true
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it 'handles non-existent paths gracefully' do
      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        result = execute_cli_command('release-manager', ['current', '--path', 'nonexistent', '--format', 'json'])

        expect(result).to be_success

        output = JSON.parse(result.stdout)
        expect(output['success']).to be true
        expect(output['data']['subpath']).to eq('nonexistent')
        expect(output['data']['resolved_path']).to end_with("dev-taskflow/current/#{release_name}/nonexistent")
        expect(output['data']['exists']).to be false
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end
  end

  describe 'error handling across components' do
    it 'propagates no release errors correctly' do
      # Test when no current release exists
      FileUtils.mkdir_p(File.join(temp_dir, 'dev-taskflow', 'current'))

      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        result = execute_cli_command('release-manager', ['current', '--path', 'reflections', '--format', 'json'])

        # The CLI command catches and handles the error but still exits with error status
        expect(result.exitstatus).to eq(1)

        # Should output JSON error format even when an exception occurs
        if result.stdout.strip.start_with?('{')
          output = JSON.parse(result.stdout)
          expect(output['success']).to be false
          expect(output['error']).to include('current release')
          expect(output['data']['subpath']).to eq('reflections')
        else
          # If JSON parsing fails, check stderr for error message
          expect(result.stderr).to include('Error resolving path')
        end
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it 'handles invalid subpath arguments' do
      create_release_structure('v.0.3.0-workflows')

      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        # Test empty subpath
        result = execute_cli_command('release-manager', ['current', '--path', '', '--format', 'json'])

        expect(result.exitstatus).to eq(1)

        # Check both stdout and stderr for error information
        if result.stdout.strip.start_with?('{')
          output = JSON.parse(result.stdout)
          expect(output['success']).to be false
          expect(output['error']).to include('subpath cannot be nil or empty')
        else
          expect(result.stderr).to include('subpath cannot be nil or empty')
        end
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it 'provides clear error messages in text format' do
      # Test with no current release in text format
      FileUtils.mkdir_p(File.join(temp_dir, 'dev-taskflow', 'current'))

      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        result = execute_cli_command('release-manager', ['current', '--path', 'reflections'])

        expect(result.exitstatus).to eq(1)
        expect(result.stderr).to include("Error resolving path 'reflections'")
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end
  end

  describe 'complete workflow integration' do
    let(:release_name) { 'v.0.3.0-workflows' }

    before do
      create_release_structure(release_name)
    end

    it 'completes full path resolution workflow' do
      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        # Test the complete flow: CLI -> ReleaseManager -> PathResolver -> DirectoryNavigator
        result = execute_cli_command('release-manager', ['current', '--path', 'reflections', '--format', 'json'])

        expect(result).to be_success

        output = JSON.parse(result.stdout)
        resolved_path = output['data']['resolved_path']

        # Verify the resolved path actually exists and is accessible
        expect(File.exist?(resolved_path)).to be true
        expect(File.directory?(resolved_path)).to be true

        # Verify we can list contents of the resolved directory
        # Only look for .md files that we created in the test
        reflection_files = Dir.glob(File.join(resolved_path, 'reflection-*.md'))
        expect(reflection_files).not_to be_empty
        expect(reflection_files.length).to eq(2)
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end

    it 'verifies security validation through the stack' do
      # Override project root detection to use our temp directory
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      begin
        # Test that path traversal attempts are blocked
        result = execute_cli_command('release-manager', ['current', '--path', '../../../etc', '--format', 'json'])

        expect(result.exitstatus).to eq(1)

        # For this test, we expect the command to return exit code 1 due to security violation
        # The important thing is that the security check works (exit code 1)
        # rather than the specific error message format
        expect(result.exitstatus).to eq(1)
      ensure
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      end
    end
  end

  describe 'ReleaseManager API integration' do
    let(:release_name) { 'v.0.3.0-workflows' }

    before do
      create_release_structure(release_name)
    end

    it 'integrates with ReleaseManager.resolve_path directly' do
      # Test direct API usage that CLI commands rely on
      resolved_path = release_manager.resolve_path('reflections')

      expect(resolved_path).to end_with("dev-taskflow/current/#{release_name}/reflections")
      expect(File.exist?(resolved_path)).to be true
    end

    it 'supports create_if_missing functionality' do
      # Test creating directories through the API
      new_subdir_path = release_manager.resolve_path('reports/weekly', create_if_missing: true)

      expect(File.exist?(new_subdir_path)).to be true
      expect(File.directory?(new_subdir_path)).to be true
      expect(new_subdir_path).to end_with("dev-taskflow/current/#{release_name}/reports/weekly")
    end

    it 'raises appropriate errors for invalid paths' do
      expect do
        release_manager.resolve_path('')
      end.to raise_error(ArgumentError, /subpath cannot be nil or empty/)

      expect do
        release_manager.resolve_path(nil)
      end.to raise_error(ArgumentError, /subpath cannot be nil or empty/)
    end
  end
end

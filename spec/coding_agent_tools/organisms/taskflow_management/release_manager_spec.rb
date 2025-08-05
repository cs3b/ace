# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'
require 'coding_agent_tools/organisms/taskflow_management/release_manager'

RSpec.describe CodingAgentTools::Organisms::TaskflowManagement::ReleaseManager do
  let(:base_path) { '/tmp/test_release_manager' }
  let(:manager) { described_class.new(base_path: base_path) }

  before do
    # Create test directory structure
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/current")
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/done")
    FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog")
  end

  after do
    # Clean up test directories
    FileUtils.rm_rf(base_path) if File.exist?(base_path)
  end

  describe '#current' do
    context 'when current release exists' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks/task1.md", '# Task 1')
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks/task2.md", '# Task 2')
      end

      it 'returns current release information' do
        result = manager.current

        expect(result.success?).to be true
        expect(result.data).to be_a(described_class::ReleaseInfo)
        expect(result.data.type).to eq(:current)
        expect(result.data.current?).to be true
      end
    end

    context 'when no current release exists' do
      it 'returns an error' do
        result = manager.current

        expect(result.success?).to be false
        expect(result.error_message).to include('No current release directory found')
      end
    end

    context 'error scenarios' do
      it 'handles file system permission errors' do
        # Create a current release directory
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")

        # Mock the release resolver class method to throw an error
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleasePathResolver)
          .to receive(:get_current_release).and_raise(Errno::EACCES, 'Permission denied')

        result = manager.current

        expect(result.success?).to be false
        expect(result.error_message).to include('Error getting current release')
      end

      it 'handles release resolver returning failure' do
        # Mock the release resolver class method to return failure
        allow(CodingAgentTools::Molecules::TaskflowManagement::ReleasePathResolver)
          .to receive(:get_current_release).and_return(
            OpenStruct.new(success?: false, error_message: 'Resolver failed')
          )

        result = manager.current

        expect(result.success?).to be false
        expect(result.error_message).to include('Resolver failed')
      end
    end
  end

  describe '#next' do
    context 'when backlog has versioned releases' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/v.0.4.0-future")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/v.0.5.0-later")
      end

      it 'returns the lowest version release' do
        result = manager.next

        expect(result.success?).to be true
        expect(result.data).to be_a(described_class::ReleaseInfo)
        expect(result.data.version).to eq('v.0.4.0')
        expect(result.data.type).to eq(:backlog)
      end
    end

    context 'when backlog has no versioned releases' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/ideas")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/future-considerations")
      end

      it 'returns success with no releases message' do
        result = manager.next

        expect(result.success?).to be true
        expect(result.error_message).to include('No versioned releases found in backlog')
      end
    end

    context "when backlog directory doesn't exist" do
      before do
        FileUtils.rm_rf("#{base_path}/dev-taskflow/backlog")
      end

      it 'returns an error' do
        result = manager.next

        expect(result.success?).to be false
        expect(result.error_message).to include('Backlog directory not found')
      end
    end
  end

  describe '#generate_id' do
    context 'when releases exist' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-foundation")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.2.0-synapse")
      end

      it 'generates next task ID for current release' do
        result = manager.generate_id

        expect(result.success?).to be true
        expect(result.data).to eq('v.0.3.0+task.001')
      end
    end

    context 'when no releases exist' do
      it 'returns error when no current release exists' do
        result = manager.generate_id

        expect(result.success?).to be false
        expect(result.error_message).to include('No current release directory found')
      end
    end

    context 'error scenarios' do
      it 'handles failure from current method' do
        # Mock the current method to fail
        allow(manager).to receive(:current).and_return(
          described_class::ManagerResult.new(nil, false, 'Failed to get current release')
        )

        result = manager.generate_id

        expect(result.success?).to be false
        expect(result.error_message).to include('Failed to get current release')
      end

      it 'handles malformed version parsing errors' do
        # Create current release
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.1.0-test")
        # Create releases with malformed versions that could cause parsing issues
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/malformed-version")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.x.y.z-invalid")

        result = manager.generate_id

        expect(result.success?).to be true
        expect(result.data).to eq('v.0.1.0+task.001')  # Should use current release version
      end
    end
  end

  describe '#all' do
    context 'when multiple releases exist across directories' do
      before do
        # Create done releases
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-foundation/tasks")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.2.0-synapse/tasks")
        File.write("#{base_path}/dev-taskflow/done/v.0.1.0-foundation/tasks/task1.md", '# Task 1')
        File.write("#{base_path}/dev-taskflow/done/v.0.2.0-synapse/tasks/task1.md", '# Task 1')
        File.write("#{base_path}/dev-taskflow/done/v.0.2.0-synapse/tasks/task2.md", '# Task 2')

        # Create current release
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks/task1.md", '# Task 1')

        # Create backlog release
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog/v.0.4.0-future/tasks")
      end

      it 'returns all releases sorted by version' do
        result = manager.all

        expect(result.success?).to be true
        expect(result.data).to be_an(Array)
        expect(result.data.length).to eq(4)

        # Check sorting by version
        versions = result.data.map(&:version)
        expect(versions).to eq(['v.0.1.0', 'v.0.2.0', 'v.0.3.0', 'v.0.4.0'])

        # Check types
        types = result.data.map(&:type)
        expect(types).to contain_exactly(:done, :done, :current, :backlog)

        # Check task counts
        foundation_release = result.data.find { |r| r.name.include?('foundation') }
        synapse_release = result.data.find { |r| r.name.include?('synapse') }
        migration_release = result.data.find { |r| r.name.include?('migration') }

        expect(foundation_release.task_count).to eq(1)
        expect(synapse_release.task_count).to eq(2)
        expect(migration_release.task_count).to eq(1)
      end

      it 'includes metadata for each release' do
        result = manager.all

        expect(result.success?).to be true

        result.data.each do |release|
          expect(release.path).to be_a(String)
          expect(release.version).to be_a(String)
          expect(release.name).to be_a(String)
          expect(release.type).to be_a(Symbol)
          expect(release.status).to be_a(String)
          expect(release.task_count).to be_a(Integer)
          expect(release.created_at).to be_a(Time) if release.created_at
          expect(release.modified_at).to be_a(Time) if release.modified_at
        end
      end
    end

    context 'when no releases exist' do
      it 'returns empty array' do
        result = manager.all

        expect(result.success?).to be true
        expect(result.data).to eq([])
      end
    end

    context 'error scenarios' do
      it 'handles missing taskflow directory gracefully' do
        # Remove the entire taskflow directory
        FileUtils.rm_rf("#{base_path}/dev-taskflow")

        result = manager.all

        expect(result.success?).to be true
        expect(result.data).to eq([])
      end
    end
  end

  describe 'ReleaseInfo' do
    let(:release_info) do
      described_class::ReleaseInfo.new(
        '/path/to/release',
        'v.0.3.0',
        'v.0.3.0-migration',
        :current,
        'active',
        5,
        Time.now,
        Time.now
      )
    end

    describe '#current?' do
      it 'returns true for current releases' do
        expect(release_info.current?).to be true
      end

      it 'returns false for non-current releases' do
        release_info.type = :done
        expect(release_info.current?).to be false
      end
    end

    describe '#completed?' do
      it 'returns true for done releases' do
        release_info.type = :done
        expect(release_info.completed?).to be true
      end

      it 'returns false for non-done releases' do
        expect(release_info.completed?).to be false
      end
    end

    describe '#backlog?' do
      it 'returns true for backlog releases' do
        release_info.type = :backlog
        expect(release_info.backlog?).to be true
      end

      it 'returns false for non-backlog releases' do
        expect(release_info.backlog?).to be false
      end
    end
  end

  describe 'ManagerResult' do
    describe '#success?' do
      it 'returns true when success is true' do
        result = described_class::ManagerResult.new('data', true, nil)
        expect(result.success?).to be true
      end

      it 'returns false when success is false' do
        result = described_class::ManagerResult.new(nil, false, 'error')
        expect(result.success?).to be false
      end
    end

    describe '#failed?' do
      it 'returns false when success is true' do
        result = described_class::ManagerResult.new('data', true, nil)
        expect(result.failed?).to be false
      end

      it 'returns true when success is false' do
        result = described_class::ManagerResult.new(nil, false, 'error')
        expect(result.failed?).to be true
      end
    end
  end

  describe '#resolve_path' do
    context 'when current release exists' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/reflections")
      end

      it 'resolves reflections path' do
        result = manager.resolve_path('reflections')

        expect(result).to be_a(String)
        expect(result).to end_with('v.0.3.0-migration/reflections')
        expect(File.absolute_path?(result)).to be true
      end

      it 'resolves nested paths like reflections/synthesis' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/reflections/synthesis")

        result = manager.resolve_path('reflections/synthesis')

        expect(result).to be_a(String)
        expect(result).to end_with('v.0.3.0-migration/reflections/synthesis')
        expect(File.absolute_path?(result)).to be true
      end

      it 'resolves tasks path' do
        result = manager.resolve_path('tasks')

        expect(result).to be_a(String)
        expect(result).to end_with('v.0.3.0-migration/tasks')
        expect(File.absolute_path?(result)).to be true
      end

      it 'resolves arbitrary subpaths' do
        result = manager.resolve_path('documents/reviews')

        expect(result).to be_a(String)
        expect(result).to end_with('v.0.3.0-migration/documents/reviews')
        expect(File.absolute_path?(result)).to be true
      end
    end

    context 'directory creation behavior' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks")
      end

      it 'creates directory when create_if_missing is true' do
        target_path = manager.resolve_path('new-directory', create_if_missing: true)

        expect(File.exist?(target_path)).to be true
        expect(File.directory?(target_path)).to be true
      end

      it 'does not create directory when create_if_missing is false' do
        target_path = manager.resolve_path('non-existent-directory', create_if_missing: false)

        expect(File.exist?(target_path)).to be false
      end

      it 'creates nested directories when create_if_missing is true' do
        target_path = manager.resolve_path('deeply/nested/directory', create_if_missing: true)

        expect(File.exist?(target_path)).to be true
        expect(File.directory?(target_path)).to be true
      end

      it 'does not fail when directory already exists' do
        existing_path = "#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks"
        FileUtils.mkdir_p(existing_path)

        expect { manager.resolve_path('tasks', create_if_missing: true) }.not_to raise_error

        result = manager.resolve_path('tasks', create_if_missing: true)
        expect(File.exist?(result)).to be true
        expect(File.directory?(result)).to be true
      end
    end

    context 'error scenarios' do
      it 'returns error when no current release exists' do
        # Ensure no current release exists
        FileUtils.rm_rf("#{base_path}/dev-taskflow/current")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current")

        expect { manager.resolve_path('reflections') }.to raise_error(StandardError, /Cannot resolve path/)
      end

      it 'handles ArgumentError for nil subpath' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")

        expect { manager.resolve_path(nil) }.to raise_error(ArgumentError, /subpath cannot be nil or empty/)
      end

      it 'handles ArgumentError for empty subpath' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")

        expect { manager.resolve_path('') }.to raise_error(ArgumentError, /subpath cannot be nil or empty/)
      end

      it 'handles file system permission errors during directory creation' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")

        # Mock directory navigator to simulate permission error
        allow(manager.instance_variable_get(:@directory_navigator))
          .to receive(:ensure_directory_exists).and_raise(Errno::EACCES, 'Permission denied')

        expect { manager.resolve_path('restricted-dir', create_if_missing: true) }
          .to raise_error(Errno::EACCES, /Permission denied/)
      end
    end

    context 'path validation and security' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")
      end

      it 'prevents path traversal attempts' do
        # Mock directory navigator to fail safety validation
        allow(manager.instance_variable_get(:@directory_navigator))
          .to receive(:safe_directory_path?).and_return(false)

        expect { manager.resolve_path('../../../etc/passwd') }
          .to raise_error(SecurityError, /Resolved path failed safety validation/)
      end

      it 'validates subpath format through directory navigator' do
        # Mock directory navigator to validate the path properly
        navigator = manager.instance_variable_get(:@directory_navigator)
        allow(navigator).to receive(:safe_directory_path?).and_return(true)

        result = manager.resolve_path('valid/subpath')

        expect(navigator).to have_received(:safe_directory_path?).with(String)
        expect(result).to be_a(String)
      end

      it 'passes absolute paths through safety validation' do
        navigator = manager.instance_variable_get(:@directory_navigator)
        allow(navigator).to receive(:safe_directory_path?).and_return(true)

        result = manager.resolve_path('documents')

        # Verify that the path passed to safety validation is absolute
        expect(navigator).to have_received(:safe_directory_path?) do |path_arg|
          expect(File.absolute_path?(path_arg)).to be true
        end

        expect(File.absolute_path?(result)).to be true
      end
    end

    context 'integration with current method' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks/task1.md", '# Task 1')
      end

      it 'uses current release path from current() method' do
        # Ensure the current method works correctly
        current_result = manager.current
        expect(current_result.success?).to be true

        # Now test that resolve_path uses the same base path
        resolved_path = manager.resolve_path('tasks')
        expected_base = current_result.data.path

        expect(resolved_path).to start_with(expected_base)
        expect(resolved_path).to end_with('tasks')
      end

      it 'propagates current method errors appropriately' do
        # Mock current method to fail
        allow(manager).to receive(:current).and_return(
          manager.class::ManagerResult.new(nil, false, 'Current detection failed')
        )

        expect { manager.resolve_path('tasks') }
          .to raise_error(StandardError, /Cannot resolve path: Current detection failed/)
      end
    end
  end

  describe 'version parsing and sorting' do
    before do
      FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-foundation")
      FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.10.0-major")
      FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.2.0-synapse")
      FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")
    end

    it 'sorts versions correctly using semantic versioning' do
      result = manager.all

      expect(result.success?).to be true
      versions = result.data.map(&:version)
      expect(versions).to eq(['v.0.1.0', 'v.0.2.0', 'v.0.3.0', 'v.0.10.0'])
    end

    context 'edge cases for version handling' do
      before do
        # Clear existing releases for clean edge case testing
        FileUtils.rm_rf("#{base_path}/dev-taskflow")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog")
      end

      it 'handles mixed semantic and non-semantic versions' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.1.0.0-release")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.10.0-major")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/ideas")  # Non-semantic
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/future-work")  # Non-semantic
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.2.0.0-next")

        result = manager.all

        expect(result.success?).to be true
        semantic_versions = result.data.select { |r| r.version.match?(/^v\.\d+\.\d+\.\d+/) }.map(&:version)
        expect(semantic_versions).to eq(['v.0.10.0', 'v.1.0.0', 'v.2.0.0'])
      end

      it 'handles very large version numbers' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.999.999.999-huge")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.1000.0.0-thousand")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-small")

        result = manager.all

        expect(result.success?).to be true
        versions = result.data.map(&:version)
        expect(versions).to eq(['v.0.1.0', 'v.999.999.999', 'v.1000.0.0'])
      end

      it 'handles zero versions correctly' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.0.0-initial")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.0.1-patch")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-minor")

        result = manager.all

        expect(result.success?).to be true
        versions = result.data.map(&:version)
        expect(versions).to eq(['v.0.0.0', 'v.0.0.1', 'v.0.1.0'])
      end

      it 'handles malformed version directories gracefully' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.1.0.0-valid")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.1.0-incomplete")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.a.b.c-invalid")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/version-1.0-different-format")

        result = manager.all

        expect(result.success?).to be true
        # Should only include valid semantic versions
        semantic_releases = result.data.select { |r| r.version&.match?(/^v\.\d+\.\d+\.\d+/) }
        expect(semantic_releases.length).to eq(1)
        expect(semantic_releases.first.version).to eq('v.1.0.0')
      end

      it 'finds correct latest version with edge cases' do
        # Create current release
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.1.0.0-current")
        # Create mix of versions with various edge cases
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.0.1-tiny")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.10.0-double-digit")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.1.0.0-major")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/non-semantic-release")

        result = manager.generate_id

        expect(result.success?).to be true
        expect(result.data).to eq('v.1.0.0+task.001')  # Should use current release version
      end

      it 'handles empty and whitespace-only directory names' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.1.0.0-valid")
        # Create directories with problematic names (as much as filesystem allows)
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/   ")  # Spaces only
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/-empty-codename")

        result = manager.all

        expect(result.success?).to be true
        # Should handle edge cases gracefully without crashing
        expect(result.data.length).to be >= 1  # At least the valid one
      end
    end
  end

  describe '#generate_release' do
    context 'when releases exist' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-foundation")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog")
      end

      it 'generates a new release with automatic codename' do
        # Mock the LLM call for codename generation
        allow_any_instance_of(described_class).to receive(:`).with(/bundle exec llm-query/).and_return('automation')

        result = manager.generate_release

        expect(result.success?).to be true
        expect(result.data[:version]).to eq('v.0.4.0')
        expect(result.data[:codename]).to eq('automation')
        expect(result.data[:path]).to include('v.0.4.0-automation')

        # Verify directory structure was created
        expect(File.exist?(result.data[:path])).to be true
        expect(File.exist?(File.join(result.data[:path], 'tasks'))).to be true
        expect(File.exist?(File.join(result.data[:path], 'README.md'))).to be true
      end

      it 'generates a new release with provided codename' do
        result = manager.generate_release(codename: 'workflows')

        expect(result.success?).to be true
        expect(result.data[:version]).to eq('v.0.4.0')
        expect(result.data[:codename]).to eq('workflows')
        expect(result.data[:path]).to include('v.0.4.0-workflows')

        # Verify directory structure was created
        expect(File.exist?(result.data[:path])).to be true
        expect(File.exist?(File.join(result.data[:path], 'tasks'))).to be true
        expect(File.exist?(File.join(result.data[:path], 'README.md'))).to be true
      end

      it 'creates proper README.md file with release info' do
        result = manager.generate_release(codename: 'testing')

        readme_path = File.join(result.data[:path], 'README.md')
        readme_content = File.read(readme_path)

        expect(readme_content).to include('Release v.0.4.0 - testing')
        expect(readme_content).to include('Status: PLANNED')
        expect(readme_content).to include('Type: BACKLOG')
        expect(readme_content).to include('## Tasks')
      end

      it 'handles existing directories gracefully' do
        result = manager.generate_release(codename: 'existing')

        expect(result.success?).to be true
        expect(result.data[:codename]).to eq('existing')
        expect(result.data[:version]).to match(/^v\.\d+\.\d+\.\d+$/)

        # Verify the directory exists
        expect(File.exist?(result.data[:path])).to be true
        expect(File.exist?(File.join(result.data[:path], 'tasks'))).to be true
        expect(File.exist?(File.join(result.data[:path], 'README.md'))).to be true
      end
    end

    context 'when no releases exist' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog")
      end

      it 'generates first release starting with v.0.1.0' do
        # Mock the LLM call for codename generation
        allow_any_instance_of(described_class).to receive(:`).with(/bundle exec llm-query/).and_return('foundation')

        result = manager.generate_release

        expect(result.success?).to be true
        expect(result.data[:version]).to eq('v.0.1.0')
        expect(result.data[:codename]).to eq('foundation')
        expect(result.data[:path]).to include('v.0.1.0-foundation')
      end
    end

    context 'when LLM codename generation fails' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-foundation")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog")
      end

      it 'falls back to timestamp-based codename' do
        # Mock LLM failure
        allow_any_instance_of(described_class).to receive(:`).with(/bundle exec llm-query/).and_return('')

        result = manager.generate_release

        expect(result.success?).to be true
        expect(result.data[:version]).to eq('v.0.2.0')
        expect(result.data[:codename]).to match(/^release-\d{12}$/)
      end

      it 'falls back to timestamp-based codename when LLM returns error' do
        # Mock LLM error response
        allow_any_instance_of(described_class).to receive(:`).with(/bundle exec llm-query/).and_return('Error: API limit exceeded')

        result = manager.generate_release

        expect(result.success?).to be true
        expect(result.data[:version]).to eq('v.0.2.0')
        expect(result.data[:codename]).to match(/^release-\d{12}$/)
      end
    end

    context 'when codename conflicts exist' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.1.0-automation")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/done/v.0.2.0-release-202501281300")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/backlog")
      end

      it 'generates unique timestamp-based codename when conflicts exist' do
        # Mock LLM failure to trigger fallback
        allow_any_instance_of(described_class).to receive(:`).with(/bundle exec llm-query/).and_return('')

        # Mock Time.now to control timestamp generation
        allow(Time).to receive(:now).and_return(Time.new(2025, 1, 28, 13, 0, 0))

        result = manager.generate_release

        expect(result.success?).to be true
        expect(result.data[:version]).to eq('v.0.3.0')
        expect(result.data[:codename]).to match(/^release-202501281300-\d+$/)
      end
    end

    context 'error scenarios' do
      it 'returns error when unable to get all releases' do
        # Mock the all method to fail
        allow(manager).to receive(:all).and_return(
          described_class::ManagerResult.new(nil, false, 'Failed to scan releases')
        )

        result = manager.generate_release

        expect(result.success?).to be false
        expect(result.error_message).to include('Failed to scan releases')
      end

      it 'handles general error conditions' do
        # Mock Dir.mkdir to raise an error
        allow(Dir).to receive(:mkdir).and_raise(StandardError, 'File system error')

        result = manager.generate_release(codename: 'test')

        expect(result.success?).to be false
        expect(result.error_message).to include('Error generating release')
      end
    end
  end

  describe '#validate_release_context_consistency' do
    context 'when release context is consistent' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks")
        File.write("#{base_path}/dev-taskflow/current/v.0.3.0-migration/tasks/task1.md", '# Task 1')
      end

      it 'validates successfully' do
        result = manager.validate_release_context_consistency

        expect(result.success?).to be true
        expect(result.data[:current_release]).to include('migration')
        expect(result.data[:validation_status]).to eq('consistent')
        expect(result.error_message).to include('validation passed')
      end
    end

    context 'when no current release exists' do
      it 'returns error for empty current directory' do
        result = manager.validate_release_context_consistency

        expect(result.success?).to be false
        expect(result.error_message).to include('No current release directory found')
      end
    end

    context 'when multiple releases exist in current' do
      before do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.4.0-workflows")
      end

      it 'detects inconsistency with multiple releases' do
        result = manager.validate_release_context_consistency

        expect(result.success?).to be false
        expect(result.error_message).to include('Multiple releases in current directory')
        expect(result.error_message).to include('migration')
        expect(result.error_message).to include('workflows')
      end
    end

    context 'when current directory is completely empty' do
      before do
        # Ensure current directory exists but is empty
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current")
      end

      it 'returns specific error for empty current directory' do
        result = manager.validate_release_context_consistency

        expect(result.success?).to be false
        expect(result.error_message).to include('No current release directory found')
      end
    end

    context "when current directory doesn't exist" do
      before do
        FileUtils.rm_rf("#{base_path}/dev-taskflow/current")
      end

      it 'returns error about missing current directory' do
        result = manager.validate_release_context_consistency

        expect(result.success?).to be false
        expect(result.error_message).to include('No current release directory found')
      end
    end

    context "when directory name doesn't match detected release name" do
      before do
        # This test would require mocking the current method to return different name
        # than what's actually in the directory, but that's a complex scenario
        # that's unlikely in practice
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")

        # Mock the current method to return a different name
        allow(manager).to receive(:current).and_return(
          described_class::ManagerResult.new(
            described_class::ReleaseInfo.new(
              "#{base_path}/dev-taskflow/current/v.0.3.0-different",
              'v.0.3.0',
              'v.0.3.0-different',
              :current,
              'active',
              0,
              Time.now,
              Time.now
            ),
            true,
            nil
          )
        )
      end

      it 'detects name inconsistency' do
        result = manager.validate_release_context_consistency

        expect(result.success?).to be false
        expect(result.error_message).to include('Inconsistency detected')
        expect(result.error_message).to include('migration')
        expect(result.error_message).to include('different')
      end
    end

    context 'error scenarios' do
      it 'handles errors from current method gracefully' do
        # Mock current method to fail
        allow(manager).to receive(:current).and_return(
          described_class::ManagerResult.new(nil, false, 'Current detection failed')
        )

        result = manager.validate_release_context_consistency

        expect(result.success?).to be false
        expect(result.error_message).to include('Current detection failed')
      end

      it 'handles file system errors gracefully' do
        FileUtils.mkdir_p("#{base_path}/dev-taskflow/current/v.0.3.0-migration")

        # Mock Dir.entries to raise an error
        allow(Dir).to receive(:entries).and_raise(Errno::EACCES, 'Permission denied')

        result = manager.validate_release_context_consistency

        expect(result.success?).to be false
        expect(result.error_message).to include('Permission denied')
      end
    end
  end
end

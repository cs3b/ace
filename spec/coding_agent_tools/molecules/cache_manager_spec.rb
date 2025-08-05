# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Molecules::CacheManager do
  let(:env) { { 'XDG_CACHE_HOME' => nil, 'HOME' => nil } }
  let(:xdg_resolver) { CodingAgentTools::Atoms::XDGDirectoryResolver.new(env) }

  # Ensure clean test isolation by preventing real cache directory interference
  before do
    allow(File).to receive(:expand_path).and_call_original
    allow(File).to receive(:expand_path).with('~/.coding-agent-tools-cache').and_return('/tmp/non-existent-legacy-cache')
  end

  after do
    # Clean up mocks after each test
    RSpec::Mocks.space.reset_all
  end

  # Helper method to create cache manager with no legacy cache
  def create_cache_manager_with_xdg_only(tmpdir)
    test_env = { 'XDG_CACHE_HOME' => tmpdir }
    test_resolver = CodingAgentTools::Atoms::XDGDirectoryResolver.new(test_env)
    described_class.new(xdg_resolver: test_resolver)
  end

  describe '#initialize' do
    it 'creates cache manager with custom XDG resolver' do
      cache_manager = described_class.new(xdg_resolver: xdg_resolver)
      expect(cache_manager.xdg_resolver).to eq(xdg_resolver)
    end

    it 'creates cache manager with default XDG resolver' do
      cache_manager = described_class.new(env_reader: env)
      expect(cache_manager.xdg_resolver).to be_a(CodingAgentTools::Atoms::XDGDirectoryResolver)
    end

    it 'sets up legacy cache path' do
      cache_manager = described_class.new(xdg_resolver: xdg_resolver)
      expected_legacy = File.expand_path('~/.coding-agent-tools-cache')
      expect(cache_manager.legacy_cache_path).to eq(expected_legacy)
    end
  end

  describe 'cache directory resolution' do
    context 'with no existing cache' do
      it 'uses XDG-compliant directory' do
        Dir.mktmpdir do |tmpdir|
          cache_manager = create_cache_manager_with_xdg_only(tmpdir)

          expected = File.join(tmpdir, 'coding-agent-tools')
          expect(cache_manager.cache_directory).to eq(expected)
          expect(File.directory?(expected)).to be true
        end
      end
    end

    context 'with existing legacy cache' do
      it 'uses legacy cache directory for backward compatibility' do
        Dir.mktmpdir do |tmpdir|
          # Create legacy cache directory
          legacy_cache = File.join(tmpdir, 'legacy-cache')
          FileUtils.mkdir_p(legacy_cache)

          # Mock legacy cache path during initialization
          test_env = { 'XDG_CACHE_HOME' => File.join(tmpdir, 'xdg') }
          test_resolver = CodingAgentTools::Atoms::XDGDirectoryResolver.new(test_env)

          # We need to stub the LEGACY_CACHE_DIR constant's expansion
          allow(File).to receive(:expand_path).and_call_original
          allow(File).to receive(:expand_path).with('~/.coding-agent-tools-cache').and_return(legacy_cache)

          cache_manager = described_class.new(xdg_resolver: test_resolver)

          # Should use legacy if it exists
          expect(cache_manager.send(:use_legacy_cache?)).to be true
        end
      end
    end
  end

  describe '#cache_file_path' do
    it 'returns file path in cache directory' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        result = cache_manager.cache_file_path('test.yml')
        expected = File.join(tmpdir, 'coding-agent-tools', 'test.yml')
        expect(result).to eq(expected)
      end
    end

    it 'returns file path in subdirectory' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        result = cache_manager.cache_file_path('test.yml', subdirectory: 'models')
        expected = File.join(tmpdir, 'coding-agent-tools', 'models', 'test.yml')
        expect(result).to eq(expected)
      end
    end
  end

  describe '#cache_subdirectory' do
    it 'returns XDG subdirectory path' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        result = cache_manager.cache_subdirectory('models')
        expected = File.join(tmpdir, 'coding-agent-tools', 'models')
        expect(result).to eq(expected)
      end
    end
  end

  describe '#write_cache and #read_cache' do
    it 'writes and reads cache data' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        test_data = { 'models' => [{ 'id' => 'test', 'name' => 'Test Model' }] }

        # Write cache
        cache_manager.write_cache('test.yml', test_data)

        # Read cache
        result = cache_manager.read_cache('test.yml')
        expect(result).to eq(test_data)
      end
    end

    it 'writes cache to subdirectory' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        test_data = { 'test' => 'data' }

        # Write to subdirectory
        cache_manager.write_cache('test.yml', test_data, subdirectory: 'models')

        # Verify file exists in subdirectory
        file_path = File.join(tmpdir, 'coding-agent-tools', 'models', 'test.yml')
        expect(File.exist?(file_path)).to be true

        # Read from subdirectory
        result = cache_manager.read_cache('test.yml', subdirectory: 'models')
        expect(result).to eq(test_data)
      end
    end

    it 'handles corrupted cache files gracefully' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        # Create corrupted cache file
        cache_file = cache_manager.cache_file_path('corrupted.yml')
        FileUtils.mkdir_p(File.dirname(cache_file))
        File.write(cache_file, 'invalid: yaml: content: [')

        # Should return nil for corrupted file and output warning
        result = nil
        expect { result = cache_manager.read_cache('corrupted.yml') }.to output(/Warning.*Failed to read cache file/).to_stderr
        expect(result).to be_nil
      end
    end
  end

  describe '#cache_exists?' do
    it 'returns true for existing cache' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        cache_manager.write_cache('test.yml', { 'test' => 'data' })
        expect(cache_manager.cache_exists?('test.yml')).to be true
      end
    end

    it 'returns false for non-existing cache' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        expect(cache_manager.cache_exists?('nonexistent.yml')).to be false
      end
    end
  end

  describe '#delete_cache' do
    it 'deletes existing cache file' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        # Create cache file
        cache_manager.write_cache('test.yml', { 'test' => 'data' })
        expect(cache_manager.cache_exists?('test.yml')).to be true

        # Delete cache file
        result = cache_manager.delete_cache('test.yml')
        expect(result).to be true
        expect(cache_manager.cache_exists?('test.yml')).to be false
      end
    end

    it 'returns true for non-existing file' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        result = cache_manager.delete_cache('nonexistent.yml')
        expect(result).to be true
      end
    end
  end

  describe '#clear_cache' do
    it 'requires confirmation to clear cache' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        cache_manager.write_cache('test.yml', { 'test' => 'data' })

        # Should not clear without confirmation
        result = cache_manager.clear_cache(confirm: false)
        expect(result).to be false
        expect(cache_manager.cache_exists?('test.yml')).to be true
      end
    end

    it 'clears cache with confirmation' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        cache_manager.write_cache('test.yml', { 'test' => 'data' })
        expect(cache_manager.cache_exists?('test.yml')).to be true

        # Should clear with confirmation
        result = cache_manager.clear_cache(confirm: true)
        expect(result).to be true
        expect(cache_manager.cache_exists?('test.yml')).to be false
      end
    end
  end

  describe '#migrate_cache_data' do
    it 'migrates data from legacy to XDG cache' do
      Dir.mktmpdir do |tmpdir|
        # Create legacy cache with data
        legacy_cache = File.join(tmpdir, 'legacy-cache')
        FileUtils.mkdir_p(legacy_cache)
        File.write(File.join(legacy_cache, 'google_models.yml'), 'test: data')

        # Set up XDG cache
        xdg_cache = File.join(tmpdir, 'xdg-cache')
        test_env = { 'XDG_CACHE_HOME' => xdg_cache }
        test_resolver = CodingAgentTools::Atoms::XDGDirectoryResolver.new(test_env)

        # Mock File.expand_path to point to our test legacy cache during initialization
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with('~/.coding-agent-tools-cache').and_return(legacy_cache)

        cache_manager = described_class.new(xdg_resolver: test_resolver)

        expect { cache_manager.migrate_cache_data }.to output(/INFO: Migrated cache.*INFO: Legacy cache preserved/m).to_stdout

        # Verify file was migrated
        migrated_file = File.join(xdg_cache, 'coding-agent-tools', 'models', 'google_models.yml')
        expect(File.exist?(migrated_file)).to be true
        expect(File.read(migrated_file)).to eq('test: data')

        # Verify migration marker exists
        marker_file = File.join(xdg_cache, 'coding-agent-tools', '.migration_complete')
        expect(File.exist?(marker_file)).to be true
      end
    end

    it 'skips migration if already completed' do
      Dir.mktmpdir do |tmpdir|
        test_env = { 'XDG_CACHE_HOME' => tmpdir }
        test_resolver = CodingAgentTools::Atoms::XDGDirectoryResolver.new(test_env)
        cache_manager = described_class.new(xdg_resolver: test_resolver)

        # Mark migration as completed
        cache_manager.instance_variable_set(:@migration_completed, true)

        result = cache_manager.migrate_cache_data
        expect(result).to be true
      end
    end

    it 'handles migration errors gracefully' do
      Dir.mktmpdir do |tmpdir|
        # Create legacy cache
        legacy_cache = File.join(tmpdir, 'legacy-cache')
        FileUtils.mkdir_p(legacy_cache)

        # Mock to create invalid scenario - force a migration error by using read-only path
        test_env = { 'XDG_CACHE_HOME' => '/invalid/readonly/path' }
        test_resolver = CodingAgentTools::Atoms::XDGDirectoryResolver.new(test_env)

        # Mock File.expand_path to point to our test legacy cache
        allow(File).to receive(:expand_path).and_call_original
        allow(File).to receive(:expand_path).with('~/.coding-agent-tools-cache').and_return(legacy_cache)

        # Create cache manager (this should succeed even with invalid XDG path)
        cache_manager = described_class.new(xdg_resolver: test_resolver)

        # Now manually trigger migration which should fail and output error
        result = nil
        expect do
          result = cache_manager.migrate_cache_data
        end.to output(/Error: Cache migration failed/).to_stderr

        expect(result).to be false
      end
    end
  end

  describe '#cache_info' do
    it 'returns comprehensive cache information' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        # Add some cache data
        cache_manager.write_cache('test.yml', { 'test' => 'data' })

        info = cache_manager.cache_info

        expect(info).to include(
          :current_cache_directory,
          :uses_legacy_cache,
          :legacy_cache_exists,
          :xdg_cache_exists,
          :migration_completed,
          :cache_size,
          :xdg_info
        )

        expect(info[:cache_size]).to be > 0
        expect(info[:xdg_cache_exists]).to be true
        expect(info[:xdg_info]).to be_a(Hash)
      end
    end
  end

  describe '#show_deprecation_warning' do
    it 'shows warning when using legacy cache' do
      Dir.mktmpdir do |tmpdir|
        # Create legacy cache
        legacy_cache = File.join(tmpdir, 'legacy-cache')
        FileUtils.mkdir_p(legacy_cache)

        test_env = { 'XDG_CACHE_HOME' => File.join(tmpdir, 'xdg') }
        test_resolver = CodingAgentTools::Atoms::XDGDirectoryResolver.new(test_env)
        cache_manager = described_class.new(xdg_resolver: test_resolver)

        # Override to use legacy cache
        allow(cache_manager).to receive(:legacy_cache_path).and_return(legacy_cache)
        allow(cache_manager).to receive(:use_legacy_cache?).and_return(true)

        expect { cache_manager.show_deprecation_warning }.to output(/DEPRECATION WARNING/).to_stderr
      end
    end

    it 'does not show warning when using XDG cache' do
      Dir.mktmpdir do |tmpdir|
        cache_manager = create_cache_manager_with_xdg_only(tmpdir)

        expect { cache_manager.show_deprecation_warning }.not_to output.to_stderr
      end
    end
  end

  describe 'cache structure creation' do
    it 'creates XDG cache subdirectories' do
      Dir.mktmpdir do |tmpdir|
        create_cache_manager_with_xdg_only(tmpdir)

        # Verify subdirectories were created
        ['models', 'http', 'temp'].each do |subdir|
          subdir_path = File.join(tmpdir, 'coding-agent-tools', subdir)
          expect(File.directory?(subdir_path)).to be true
        end
      end
    end
  end
end

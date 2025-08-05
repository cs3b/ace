# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Atoms::XDGDirectoryResolver do
  describe '.cache_directory' do
    context 'when XDG_CACHE_HOME is set' do
      it 'uses XDG_CACHE_HOME with app name' do
        env = { 'XDG_CACHE_HOME' => '/custom/cache', 'HOME' => '/home/user' }
        result = described_class.cache_directory(env)
        expect(result).to eq('/custom/cache/coding-agent-tools')
      end

      it 'handles XDG_CACHE_HOME with trailing whitespace' do
        env = { 'XDG_CACHE_HOME' => '  /custom/cache  ', 'HOME' => '/home/user' }
        result = described_class.cache_directory(env)
        expect(result).to eq('/custom/cache/coding-agent-tools')
      end

      it 'falls back to HOME/.cache when XDG_CACHE_HOME is empty string' do
        env = { 'XDG_CACHE_HOME' => '', 'HOME' => '/home/user' }
        result = described_class.cache_directory(env)
        expect(result).to eq('/home/user/.cache/coding-agent-tools')
      end

      it 'falls back to HOME/.cache when XDG_CACHE_HOME is whitespace' do
        env = { 'XDG_CACHE_HOME' => '   ', 'HOME' => '/home/user' }
        result = described_class.cache_directory(env)
        expect(result).to eq('/home/user/.cache/coding-agent-tools')
      end
    end

    context 'when XDG_CACHE_HOME is not set' do
      it 'uses HOME/.cache with app name' do
        env = { 'HOME' => '/home/user' }
        result = described_class.cache_directory(env)
        expect(result).to eq('/home/user/.cache/coding-agent-tools')
      end

      it 'handles HOME with trailing whitespace' do
        env = { 'HOME' => '  /home/user  ' }
        result = described_class.cache_directory(env)
        expect(result).to eq('/home/user/.cache/coding-agent-tools')
      end
    end

    context 'when neither XDG_CACHE_HOME nor HOME is set' do
      it 'uses current directory .cache as fallback' do
        env = {}
        result = described_class.cache_directory(env)
        expected = File.expand_path('.cache/coding-agent-tools')
        expect(result).to eq(expected)
      end
    end

    context 'when HOME is empty' do
      it 'uses current directory .cache as fallback' do
        env = { 'HOME' => '' }
        result = described_class.cache_directory(env)
        expected = File.expand_path('.cache/coding-agent-tools')
        expect(result).to eq(expected)
      end
    end
  end

  describe '.ensure_cache_directory' do
    it 'creates directory with default permissions' do
      Dir.mktmpdir do |tmpdir|
        cache_dir = File.join(tmpdir, 'test-cache')

        result = described_class.ensure_cache_directory(cache_dir)

        expect(result).to eq(cache_dir)
        expect(File.directory?(cache_dir)).to be true
        expect(File.stat(cache_dir).mode & 0o777).to eq(0o700)
      end
    end

    it 'creates directory with custom permissions' do
      Dir.mktmpdir do |tmpdir|
        cache_dir = File.join(tmpdir, 'test-cache')

        result = described_class.ensure_cache_directory(cache_dir, 0o755)

        expect(result).to eq(cache_dir)
        expect(File.directory?(cache_dir)).to be true
        expect(File.stat(cache_dir).mode & 0o777).to eq(0o755)
      end
    end

    it 'creates nested directories' do
      Dir.mktmpdir do |tmpdir|
        cache_dir = File.join(tmpdir, 'nested', 'deep', 'cache')

        result = described_class.ensure_cache_directory(cache_dir)

        expect(result).to eq(cache_dir)
        expect(File.directory?(cache_dir)).to be true
      end
    end

    it 'handles existing directory' do
      Dir.mktmpdir do |tmpdir|
        cache_dir = File.join(tmpdir, 'existing-cache')
        FileUtils.mkdir_p(cache_dir)

        expect { described_class.ensure_cache_directory(cache_dir) }.not_to raise_error
        expect(File.directory?(cache_dir)).to be true
      end
    end
  end

  describe '.xdg_compliant_cache_path?' do
    it 'returns true for XDG-compliant paths' do
      env = { 'XDG_CACHE_HOME' => '/custom/cache' }
      path = '/custom/cache/coding-agent-tools'

      result = described_class.xdg_compliant_cache_path?(path, env)
      expect(result).to be true
    end

    it 'returns false for non-XDG-compliant paths' do
      env = { 'XDG_CACHE_HOME' => '/custom/cache' }
      path = '/different/cache/coding-agent-tools'

      result = described_class.xdg_compliant_cache_path?(path, env)
      expect(result).to be false
    end

    it 'handles relative paths correctly' do
      env = { 'HOME' => Dir.pwd }
      path = '.cache/coding-agent-tools'

      result = described_class.xdg_compliant_cache_path?(path, env)
      expect(result).to be true
    end
  end

  describe '.cache_subdirectory' do
    it 'returns path to cache subdirectory' do
      env = { 'XDG_CACHE_HOME' => '/custom/cache' }

      result = described_class.cache_subdirectory('models', env)
      expect(result).to eq('/custom/cache/coding-agent-tools/models')
    end

    it 'handles string and symbol cache types' do
      env = { 'XDG_CACHE_HOME' => '/custom/cache' }

      string_result = described_class.cache_subdirectory('models', env)
      symbol_result = described_class.cache_subdirectory(:models, env)

      expect(string_result).to eq(symbol_result)
      expect(string_result).to eq('/custom/cache/coding-agent-tools/models')
    end
  end

  describe '.ensure_cache_subdirectory' do
    it 'creates cache subdirectory' do
      Dir.mktmpdir do |tmpdir|
        env = { 'XDG_CACHE_HOME' => tmpdir }

        result = described_class.ensure_cache_subdirectory('models', env)
        expected = File.join(tmpdir, 'coding-agent-tools', 'models')

        expect(result).to eq(expected)
        expect(File.directory?(result)).to be true
      end
    end

    it 'creates nested cache subdirectories' do
      Dir.mktmpdir do |tmpdir|
        env = { 'XDG_CACHE_HOME' => tmpdir }

        result = described_class.ensure_cache_subdirectory('http/responses', env)
        expected = File.join(tmpdir, 'coding-agent-tools', 'http/responses')

        expect(result).to eq(expected)
        expect(File.directory?(result)).to be true
      end
    end
  end

  describe '.cache_directory_info' do
    it 'returns comprehensive cache directory information' do
      env = { 'XDG_CACHE_HOME' => '/custom/cache', 'HOME' => '/home/user' }

      result = described_class.cache_directory_info(env)

      expect(result).to include(
        xdg_cache_home: '/custom/cache',
        home_directory: '/home/user',
        resolved_path: '/custom/cache/coding-agent-tools',
        uses_xdg_cache_home: true,
        uses_home_fallback: false,
        app_name: 'coding-agent-tools'
      )
    end

    it 'indicates home fallback when XDG_CACHE_HOME is not set' do
      env = { 'HOME' => '/home/user' }

      result = described_class.cache_directory_info(env)

      expect(result).to include(
        uses_xdg_cache_home: false,
        uses_home_fallback: true
      )
    end
  end

  describe '.safe_directory_path?' do
    it 'accepts safe absolute paths' do
      expect(described_class.safe_directory_path?('/home/user/cache')).to be true
    end

    it 'accepts safe relative paths when expanded' do
      expect(described_class.safe_directory_path?('./cache')).to be true
    end

    it 'rejects paths with parent directory traversal' do
      expect(described_class.safe_directory_path?('/home/user/../etc')).to be false
      expect(described_class.safe_directory_path?('../etc')).to be false
    end

    it 'rejects paths with null bytes' do
      expect(described_class.safe_directory_path?("/home/user\0/cache")).to be false
    end

    it 'rejects nil paths' do
      expect(described_class.safe_directory_path?(nil)).to be false
    end

    it 'rejects empty paths' do
      expect(described_class.safe_directory_path?('')).to be false
    end
  end

  describe 'instance methods' do
    let(:env) { { 'XDG_CACHE_HOME' => '/custom/cache', 'HOME' => '/home/user' } }
    let(:resolver) { described_class.new(env) }

    describe '#cache_directory' do
      it 'uses provided environment reader' do
        expect(resolver.cache_directory).to eq('/custom/cache/coding-agent-tools')
      end
    end

    describe '#ensure_cache_directory' do
      it 'creates cache directory using instance environment' do
        Dir.mktmpdir do |tmpdir|
          instance_env = { 'XDG_CACHE_HOME' => tmpdir }
          instance_resolver = described_class.new(instance_env)

          result = instance_resolver.ensure_cache_directory
          expected = File.join(tmpdir, 'coding-agent-tools')

          expect(result).to eq(expected)
          expect(File.directory?(expected)).to be true
        end
      end
    end

    describe '#cache_subdirectory' do
      it 'uses instance environment reader' do
        result = resolver.cache_subdirectory('models')
        expect(result).to eq('/custom/cache/coding-agent-tools/models')
      end
    end

    describe '#ensure_cache_subdirectory' do
      it 'creates subdirectory using instance environment' do
        Dir.mktmpdir do |tmpdir|
          instance_env = { 'XDG_CACHE_HOME' => tmpdir }
          instance_resolver = described_class.new(instance_env)

          result = instance_resolver.ensure_cache_subdirectory('models')
          expected = File.join(tmpdir, 'coding-agent-tools', 'models')

          expect(result).to eq(expected)
          expect(File.directory?(expected)).to be true
        end
      end
    end

    describe '#cache_directory_info' do
      it 'uses instance environment reader' do
        result = resolver.cache_directory_info
        expect(result[:xdg_cache_home]).to eq('/custom/cache')
        expect(result[:resolved_path]).to eq('/custom/cache/coding-agent-tools')
      end
    end
  end

  describe 'default environment usage' do
    it 'uses ENV when no environment reader provided' do
      # Mock ENV for this test
      allow(ENV).to receive(:[]).with('XDG_CACHE_HOME').and_return('/test/cache')
      allow(ENV).to receive(:[]).with('HOME').and_return('/home/test')

      result = described_class.cache_directory
      expect(result).to eq('/test/cache/coding-agent-tools')
    end
  end
end

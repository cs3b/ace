# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Atoms::Claude::CommandExistenceChecker do
  let(:temp_dir) { Pathname.new(Dir.mktmpdir) }
  let(:custom_dir) { temp_dir / 'custom' }
  let(:generated_dir) { temp_dir / 'generated' }
  let(:search_paths) { [custom_dir, generated_dir] }

  before do
    custom_dir.mkpath
    generated_dir.mkpath
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe '.find' do
    context 'when command exists' do
      before do
        (custom_dir / 'commit.md').write('custom command')
        (generated_dir / 'create-adr.md').write('generated command')
      end

      it 'returns path from first matching directory' do
        result = described_class.find('commit', search_paths)
        expect(result).to eq(custom_dir / 'commit.md')
      end

      it 'returns path from later directory if not in first' do
        result = described_class.find('create-adr', search_paths)
        expect(result).to eq(generated_dir / 'create-adr.md')
      end
    end

    context 'when command does not exist' do
      it 'returns nil' do
        result = described_class.find('non-existent', search_paths)
        expect(result).to be_nil
      end
    end

    context 'with invalid inputs' do
      it 'returns nil for nil command name' do
        result = described_class.find(nil, search_paths)
        expect(result).to be_nil
      end

      it 'returns nil for empty command name' do
        result = described_class.find('', search_paths)
        expect(result).to be_nil
      end

      it 'returns nil for nil search paths' do
        result = described_class.find('commit', nil)
        expect(result).to be_nil
      end

      it 'returns nil for empty search paths' do
        result = described_class.find('commit', [])
        expect(result).to be_nil
      end
    end

    context 'when search path does not exist' do
      it 'skips non-existent paths' do
        non_existent = temp_dir / 'non-existent'
        (custom_dir / 'commit.md').write('test')

        result = described_class.find('commit', [non_existent, custom_dir])
        expect(result).to eq(custom_dir / 'commit.md')
      end
    end
  end

  describe '.exists?' do
    before do
      (custom_dir / 'commit.md').write('test command')
    end

    it 'returns true when command exists' do
      expect(described_class.exists?('commit', search_paths)).to be true
    end

    it 'returns false when command does not exist' do
      expect(described_class.exists?('non-existent', search_paths)).to be false
    end
  end

  describe '.find_all' do
    context 'with multiple commands' do
      before do
        (custom_dir / 'commit.md').write('custom')
        (custom_dir / 'README.md').write('readme')
        (generated_dir / 'create-adr.md').write('generated')
        (generated_dir / 'update-blueprint.md').write('generated')
      end

      it 'returns all commands excluding README files' do
        result = described_class.find_all(search_paths)

        expect(result.size).to eq(3)
        names = result.map { |cmd| cmd[:name] }
        expect(names).to contain_exactly('commit', 'create-adr', 'update-blueprint')
      end

      it 'includes path information' do
        result = described_class.find_all(search_paths)
        commit_cmd = result.find { |cmd| cmd[:name] == 'commit' }

        expect(commit_cmd[:path]).to eq(custom_dir / 'commit.md')
      end
    end

    context 'with duplicate commands' do
      before do
        (custom_dir / 'commit.md').write('custom version')
        (generated_dir / 'commit.md').write('generated version')
      end

      it 'returns unique commands by name' do
        result = described_class.find_all(search_paths)

        expect(result.size).to eq(1)
        expect(result.first[:name]).to eq('commit')
      end
    end

    context 'with invalid inputs' do
      it 'returns empty array for nil search paths' do
        result = described_class.find_all(nil)
        expect(result).to eq([])
      end

      it 'returns empty array for empty search paths' do
        result = described_class.find_all([])
        expect(result).to eq([])
      end
    end
  end
end

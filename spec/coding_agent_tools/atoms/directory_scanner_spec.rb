# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'fileutils'

RSpec.describe CodingAgentTools::Atoms::DirectoryScanner do
  subject(:scanner) { described_class }

  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe '.scan_files' do
    context 'with basic directory scanning' do
      before do
        # Create test files
        FileUtils.touch(File.join(temp_dir, 'test1.txt'))
        FileUtils.touch(File.join(temp_dir, 'test2.rb'))
        FileUtils.touch(File.join(temp_dir, 'script.sh'))

        # Make some files executable
        File.chmod(0o755, File.join(temp_dir, 'test2.rb'))
        File.chmod(0o755, File.join(temp_dir, 'script.sh'))
      end

      it 'scans directory and returns only executable files' do
        result = scanner.scan_files(temp_dir)

        expect(result).to be_an(Array)
        expect(result.length).to eq(2)
        expect(result).to include(File.join(temp_dir, 'test2.rb'))
        expect(result).to include(File.join(temp_dir, 'script.sh'))
        expect(result).not_to include(File.join(temp_dir, 'test1.txt'))
      end

      it 'returns sorted results' do
        result = scanner.scan_files(temp_dir)

        expect(result).to eq(result.sort)
      end

      it 'handles pattern matching' do
        result = scanner.scan_files(temp_dir, pattern: '*.rb')

        expect(result).to include(File.join(temp_dir, 'test2.rb'))
        expect(result).not_to include(File.join(temp_dir, 'script.sh'))
      end

      it 'applies exclusion patterns with exact match' do
        result = scanner.scan_files(temp_dir, exclude_patterns: ['test2.rb'])

        expect(result).not_to include(File.join(temp_dir, 'test2.rb'))
        expect(result).to include(File.join(temp_dir, 'script.sh'))
      end

      it 'applies exclusion patterns with shell glob' do
        result = scanner.scan_files(temp_dir, exclude_patterns: ['*.rb'])

        expect(result).not_to include(File.join(temp_dir, 'test2.rb'))
        expect(result).to include(File.join(temp_dir, 'script.sh'))
      end

      it 'applies multiple exclusion patterns' do
        result = scanner.scan_files(temp_dir, exclude_patterns: ['*.rb', 'script.sh'])

        expect(result).to be_empty
      end
    end

    context 'with subdirectories' do
      before do
        # Create subdirectory with files
        subdir = File.join(temp_dir, 'subdir')
        FileUtils.mkdir_p(subdir)
        FileUtils.touch(File.join(subdir, 'nested.sh'))
        File.chmod(0o755, File.join(subdir, 'nested.sh'))
      end

      it 'does not return directories themselves' do
        result = scanner.scan_files(temp_dir)

        directories = result.select { |path| File.directory?(path) }
        expect(directories).to be_empty
      end

      it 'can scan with recursive patterns' do
        result = scanner.scan_files(temp_dir, pattern: '**/*.sh')

        expect(result).to include(File.join(temp_dir, 'subdir', 'nested.sh'))
      end
    end

    context 'with error handling' do
      it 'raises ArgumentError for non-existent directory' do
        non_existent = '/path/that/does/not/exist'

        expect do
          scanner.scan_files(non_existent)
        end.to raise_error(ArgumentError, "Directory does not exist: #{non_existent}")
      end

      it 'raises ArgumentError for file path instead of directory' do
        file_path = File.join(temp_dir, 'test.txt')
        FileUtils.touch(file_path)

        expect do
          scanner.scan_files(file_path)
        end.to raise_error(ArgumentError, "Directory does not exist: #{file_path}")
      end
    end

    context 'with empty directory' do
      it 'returns empty array for empty directory' do
        result = scanner.scan_files(temp_dir)

        expect(result).to eq([])
      end
    end

    context 'with files of different permissions' do
      before do
        # Create files with different permissions
        FileUtils.touch(File.join(temp_dir, 'readable.txt'))
        FileUtils.touch(File.join(temp_dir, 'executable.sh'))

        File.chmod(0o644, File.join(temp_dir, 'readable.txt'))
        File.chmod(0o755, File.join(temp_dir, 'executable.sh'))
      end

      it 'only returns executable files' do
        result = scanner.scan_files(temp_dir)

        expect(result).to include(File.join(temp_dir, 'executable.sh'))
        expect(result).not_to include(File.join(temp_dir, 'readable.txt'))
      end
    end
  end

  describe '.scan_with_info' do
    before do
      # Create test files with different properties
      FileUtils.touch(File.join(temp_dir, 'small.sh'))
      FileUtils.touch(File.join(temp_dir, 'large.rb'))

      File.chmod(0o755, File.join(temp_dir, 'small.sh'))
      File.chmod(0o755, File.join(temp_dir, 'large.rb'))

      # Write different amounts of content
      File.write(File.join(temp_dir, 'small.sh'), "#!/bin/bash\necho hello")
      File.write(File.join(temp_dir, 'large.rb'), "# Ruby script\n" + "puts 'hello world'\n" * 100)
    end

    it 'returns array of file info hashes' do
      result = scanner.scan_with_info(temp_dir)

      expect(result).to be_an(Array)
      expect(result.length).to eq(2)

      result.each do |file_info|
        expect(file_info).to be_a(Hash)
        expect(file_info).to have_key(:name)
        expect(file_info).to have_key(:path)
        expect(file_info).to have_key(:size)
        expect(file_info).to have_key(:modified)
        expect(file_info).to have_key(:executable)
      end
    end

    it 'includes correct file information' do
      result = scanner.scan_with_info(temp_dir)

      small_file = result.find { |f| f[:name] == 'small.sh' }
      large_file = result.find { |f| f[:name] == 'large.rb' }

      expect(small_file).not_to be_nil
      expect(large_file).not_to be_nil

      expect(small_file[:path]).to eq(File.join(temp_dir, 'small.sh'))
      expect(small_file[:executable]).to be true
      expect(small_file[:size]).to be > 0
      expect(small_file[:modified]).to be_a(Time)

      expect(large_file[:size]).to be > small_file[:size]
    end

    it 'respects pattern parameter' do
      result = scanner.scan_with_info(temp_dir, pattern: '*.sh')

      expect(result.length).to eq(1)
      expect(result.first[:name]).to eq('small.sh')
    end
  end
end

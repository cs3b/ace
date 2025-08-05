# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe CodingAgentTools::Molecules::Code::FilePatternExtractor do
  let(:extractor) { described_class.new }
  let(:file_reader_mock) { instance_double(CodingAgentTools::Atoms::Code::FileContentReader) }
  let(:file_scanner_mock) { class_double(CodingAgentTools::Atoms::TaskflowManagement::FileSystemScanner) }

  before do
    # Mock the atoms dependencies
    allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_return(file_reader_mock)
    allow(CodingAgentTools::Atoms::TaskflowManagement::FileSystemScanner).to receive(:find_files_with_pattern).and_return(file_scanner_mock)

    # Set up the instance variable mock
    extractor.instance_variable_set(:@file_reader, file_reader_mock)
    extractor.instance_variable_set(:@file_scanner, file_scanner_mock)
  end

  describe '#initialize' do
    it 'initializes with file reader and scanner atoms' do
      # Test initialization without global mocks interfering
      allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_call_original

      new_extractor = described_class.new

      expect(new_extractor.instance_variable_get(:@file_reader)).to be_a(CodingAgentTools::Atoms::Code::FileContentReader)
      expect(new_extractor.instance_variable_get(:@file_scanner)).to eq(CodingAgentTools::Atoms::TaskflowManagement::FileSystemScanner)
    end
  end

  describe '#extract_files' do
    context 'when extracting a single file' do
      let(:file_path) { '/path/to/test.rb' }
      let(:file_content) { "puts 'Hello World'" }

      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:directory?).with(file_path).and_return(false)
        allow(file_reader_mock).to receive(:read).with(file_path).and_return(
          success: true,
          content: file_content
        )
      end

      it 'returns successful result with XML content for single file' do
        result = extractor.extract_files(file_path)

        expect(result[:success]).to be true
        expect(result[:file_list]).to eq([file_path])
        expect(result[:xml_content]).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(result[:xml_content]).to include("<document path='#{file_path}'>")
        expect(result[:xml_content]).to include(file_content)
        expect(result[:error]).to be_nil
      end

      it 'handles file read errors' do
        allow(file_reader_mock).to receive(:read).with(file_path).and_return(
          success: false,
          error: 'Permission denied'
        )

        result = extractor.extract_files(file_path)

        expect(result[:success]).to be false
        expect(result[:file_list]).to eq([])
        expect(result[:xml_content]).to be_nil
        expect(result[:error]).to eq('Permission denied')
      end
    end

    context 'when extracting files with glob pattern' do
      let(:pattern) { '*.rb' }
      let(:matching_files) { ['/path/test1.rb', '/path/test2.rb'] }

      before do
        allow(File).to receive(:exist?).with(pattern).and_return(false)
        allow(Dir).to receive(:glob).with(pattern).and_return(matching_files)
        allow(File).to receive(:file?).and_return(true)

        matching_files.each do |file|
          allow(file_reader_mock).to receive(:read).with(file).and_return(
            success: true,
            content: "# Content of #{File.basename(file)}"
          )
        end
      end

      it 'returns XML with multiple documents' do
        result = extractor.extract_files(pattern)

        expect(result[:success]).to be true
        expect(result[:file_list]).to eq(matching_files)
        expect(result[:xml_content]).to include('test1.rb')
        expect(result[:xml_content]).to include('test2.rb')
      end

      it 'handles mixed file types in glob results' do
        mixed_files = ['/path/test.rb', '/path/dir/nested.rb']
        allow(Dir).to receive(:glob).with(pattern).and_return(mixed_files + ['/path/directory'])
        allow(File).to receive(:file?).with('/path/test.rb').and_return(true)
        allow(File).to receive(:file?).with('/path/dir/nested.rb').and_return(true)
        allow(File).to receive(:file?).with('/path/directory').and_return(false)

        mixed_files.each do |file|
          allow(file_reader_mock).to receive(:read).with(file).and_return(
            success: true,
            content: "# Content of #{File.basename(file)}"
          )
        end

        result = extractor.extract_files(pattern)

        expect(result[:success]).to be true
        expect(result[:file_list]).to eq(mixed_files)  # Should exclude directories
      end
    end

    context 'when extracting files with file scanner' do
      let(:pattern) { 'ruby_files' }
      let(:matching_files) { ['/src/main.rb', '/src/helper.rb'] }

      before do
        allow(File).to receive(:exist?).with(pattern).and_return(false)
        allow(file_scanner_mock).to receive(:find_files_with_pattern).with('.', pattern).and_return(
          files: matching_files
        )

        matching_files.each do |file|
          allow(file_reader_mock).to receive(:read).with(file).and_return(
            success: true,
            content: "# Content of #{File.basename(file)}"
          )
        end
      end

      it 'uses file scanner for non-glob patterns' do
        result = extractor.extract_files(pattern)

        expect(result[:success]).to be true
        expect(result[:file_list]).to eq(matching_files)
        expect(file_scanner_mock).to have_received(:find_files_with_pattern).with('.', pattern)
      end
    end

    context 'when no files match pattern' do
      let(:pattern) { '*.xyz' }

      before do
        allow(File).to receive(:exist?).with(pattern).and_return(false)
        allow(Dir).to receive(:glob).with(pattern).and_return([])
      end

      it 'returns failure with appropriate error message' do
        result = extractor.extract_files(pattern)

        expect(result[:success]).to be false
        expect(result[:file_list]).to eq([])
        expect(result[:xml_content]).to be_nil
        expect(result[:error]).to eq("No files found matching pattern: #{pattern}")
      end
    end

    context 'with complex glob patterns' do
      let(:question_pattern) { 'test?.rb' }
      let(:bracket_pattern) { 'test[123].rb' }

      it 'handles question mark patterns' do
        allow(File).to receive(:exist?).with(question_pattern).and_return(false)
        allow(Dir).to receive(:glob).with(question_pattern).and_return(['/path/test1.rb'])
        allow(File).to receive(:file?).and_return(true)
        allow(file_reader_mock).to receive(:read).and_return(success: true, content: 'test')

        result = extractor.extract_files(question_pattern)

        expect(result[:success]).to be true
        expect(Dir).to have_received(:glob).with(question_pattern)
      end

      it 'handles bracket patterns' do
        allow(File).to receive(:exist?).with(bracket_pattern).and_return(false)
        allow(Dir).to receive(:glob).with(bracket_pattern).and_return(['/path/test1.rb', '/path/test2.rb'])
        allow(File).to receive(:file?).and_return(true)
        allow(file_reader_mock).to receive(:read).and_return(success: true, content: 'test')

        result = extractor.extract_files(bracket_pattern)

        expect(result[:success]).to be true
        expect(Dir).to have_received(:glob).with(bracket_pattern)
      end
    end

    context 'when dealing with directories' do
      let(:dir_path) { '/path/to/dir' }

      before do
        allow(File).to receive(:exist?).with(dir_path).and_return(true)
        allow(File).to receive(:directory?).with(dir_path).and_return(true)
      end

      it 'handles directory paths by using file scanner' do
        allow(file_scanner_mock).to receive(:find_files_with_pattern).with('.', dir_path).and_return(
          files: ['/path/to/dir/file.rb']
        )
        allow(file_reader_mock).to receive(:read).and_return(success: true, content: 'content')

        result = extractor.extract_files(dir_path)

        expect(result[:success]).to be true
        expect(file_scanner_mock).to have_received(:find_files_with_pattern).with('.', dir_path)
      end
    end
  end

  describe '#extract_and_save' do
    let(:pattern) { '/path/to/test.rb' }
    let(:session_dir) { '/tmp/session' }
    let(:file_content) { "puts 'Hello World'" }

    before do
      allow(File).to receive(:exist?).with(pattern).and_return(true)
      allow(File).to receive(:directory?).with(pattern).and_return(false)
      allow(file_reader_mock).to receive(:read).with(pattern).and_return(
        success: true,
        content: file_content
      )
      allow(File).to receive(:write)
      allow(File).to receive(:readlines).with(pattern).and_return(["line1\n", "line2\n"])
    end

    it 'saves XML and metadata files' do
      xml_file = File.join(session_dir, 'input.xml')
      meta_file = File.join(session_dir, 'input.meta')

      result = extractor.extract_and_save(pattern, session_dir)

      expect(result[:success]).to be true
      expect(result[:xml_file]).to eq(xml_file)
      expect(result[:meta_file]).to eq(meta_file)

      expect(File).to have_received(:write).with(xml_file, anything)
      expect(File).to have_received(:write).with(meta_file, anything)
    end

    it 'includes line count for single file in metadata' do
      meta_content = "target: #{pattern}\ntype: single_file\nfiles: 1\nsize: 2 lines\n"

      extractor.extract_and_save(pattern, session_dir)

      expect(File).to have_received(:write).with(
        File.join(session_dir, 'input.meta'),
        meta_content
      )
    end

    it 'handles file write errors' do
      allow(File).to receive(:write).and_raise(StandardError.new('Disk full'))

      result = extractor.extract_and_save(pattern, session_dir)

      expect(result[:success]).to be false
      expect(result[:error]).to include('Failed to save files: Disk full')
    end

    context 'with file pattern extraction' do
      let(:pattern) { '*.rb' }
      let(:matching_files) { ['/path/test1.rb', '/path/test2.rb'] }

      before do
        allow(File).to receive(:exist?).with(pattern).and_return(false)
        allow(Dir).to receive(:glob).with(pattern).and_return(matching_files)
        allow(File).to receive(:file?).and_return(true)

        matching_files.each do |file|
          allow(file_reader_mock).to receive(:read).with(file).and_return(
            success: true,
            content: "# Content of #{File.basename(file)}"
          )
        end
      end

      it 'creates metadata for multiple files without line count' do
        meta_content = "target: #{pattern}\ntype: file_pattern\nfiles: 2\n"

        extractor.extract_and_save(pattern, session_dir)

        expect(File).to have_received(:write).with(
          File.join(session_dir, 'input.meta'),
          meta_content
        )
      end
    end

    context 'when extraction fails' do
      let(:failing_pattern) { '*.xyz' }

      before do
        allow(File).to receive(:exist?).with(failing_pattern).and_return(false)
        allow(Dir).to receive(:glob).with(failing_pattern).and_return([])
      end

      it 'returns extraction failure without saving files' do
        result = extractor.extract_and_save(failing_pattern, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include('No files found matching pattern')
        expect(File).not_to have_received(:write)
      end
    end
  end

  describe 'private methods' do
    describe '#build_xml_content' do
      let(:files) { ['/path/test1.rb', '/path/test2.rb'] }

      before do
        files.each_with_index do |file, index|
          allow(file_reader_mock).to receive(:read).with(file).and_return(
            success: true,
            content: "Content #{index + 1}"
          )
        end
      end

      it 'builds valid XML with CDATA sections' do
        xml_content = extractor.send(:build_xml_content, files)

        expect(xml_content).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(xml_content).to include('<documents>')
        expect(xml_content).to include('Content 1')
        expect(xml_content).to include('Content 2')
        expect(xml_content).to include('CDATA')
      end

      it 'skips files that fail to read' do
        allow(file_reader_mock).to receive(:read).with(files.first).and_return(success: false)

        xml_content = extractor.send(:build_xml_content, files)

        expect(xml_content).to include('Content 2')
        expect(xml_content).not_to include('Content 1')
      end

      it 'handles empty file list' do
        xml_content = extractor.send(:build_xml_content, [])

        expect(xml_content).to include('<?xml version="1.0" encoding="UTF-8"?>')
        expect(xml_content).to include('<documents')
      end

      it 'handles files with special characters in content' do
        special_content = "<script>alert('test');</script>\n&amp; special chars"
        allow(file_reader_mock).to receive(:read).with(files.first).and_return(
          success: true,
          content: special_content
        )
        allow(file_reader_mock).to receive(:read).with(files.last).and_return(success: false)

        xml_content = extractor.send(:build_xml_content, files)

        expect(xml_content).to include(special_content)
        expect(xml_content).to include('CDATA')
      end

      it 'properly formats XML structure' do
        xml_content = extractor.send(:build_xml_content, files)

        # Parse the XML to ensure it's valid
        doc = REXML::Document.new(xml_content)
        expect(doc.root.name).to eq('documents')
        expect(doc.root.elements.count).to eq(2)

        doc.root.elements.each_with_index do |element, index|
          expect(element.name).to eq('document')
          expect(element.attributes['path']).to eq(files[index])
        end
      end
    end

    describe '#find_matching_files' do
      context 'with glob patterns' do
        it 'uses Dir.glob for wildcard patterns' do
          allow(Dir).to receive(:glob).with('*.rb').and_return(['/test.rb'])
          allow(File).to receive(:file?).and_return(true)

          result = extractor.send(:find_matching_files, '*.rb')

          expect(result).to eq(['/test.rb'])
          expect(Dir).to have_received(:glob).with('*.rb')
        end

        it 'filters out directories from glob results' do
          allow(Dir).to receive(:glob).with('*').and_return(['/file.rb', '/directory'])
          allow(File).to receive(:file?).with('/file.rb').and_return(true)
          allow(File).to receive(:file?).with('/directory').and_return(false)

          result = extractor.send(:find_matching_files, '*')

          expect(result).to eq(['/file.rb'])
        end
      end

      context 'with non-glob patterns' do
        it 'uses file scanner for directory traversal' do
          allow(file_scanner_mock).to receive(:find_files_with_pattern).and_return(files: ['/found.rb'])

          result = extractor.send(:find_matching_files, 'ruby_files')

          expect(result).to eq(['/found.rb'])
          expect(file_scanner_mock).to have_received(:find_files_with_pattern)
        end

        it 'handles file scanner returning nil files' do
          allow(file_scanner_mock).to receive(:find_files_with_pattern).and_return({})

          result = extractor.send(:find_matching_files, 'ruby_files')

          expect(result).to eq([])
        end

        it 'handles file scanner returning empty files array' do
          allow(file_scanner_mock).to receive(:find_files_with_pattern).and_return(files: [])

          result = extractor.send(:find_matching_files, 'ruby_files')

          expect(result).to eq([])
        end
      end
    end

    describe '#extract_single_file' do
      let(:file_path) { '/path/to/single.rb' }
      let(:file_content) { "def hello\n  puts 'world'\nend" }

      it 'extracts single file successfully' do
        allow(file_reader_mock).to receive(:read).with(file_path).and_return(
          success: true,
          content: file_content
        )

        result = extractor.send(:extract_single_file, file_path)

        expect(result[:success]).to be true
        expect(result[:file_list]).to eq([file_path])
        expect(result[:xml_content]).to include(file_content)
        expect(result[:error]).to be_nil
      end

      it 'handles file read failure' do
        allow(file_reader_mock).to receive(:read).with(file_path).and_return(
          success: false,
          error: 'File not readable'
        )

        result = extractor.send(:extract_single_file, file_path)

        expect(result[:success]).to be false
        expect(result[:file_list]).to eq([])
        expect(result[:xml_content]).to be_nil
        expect(result[:error]).to eq('File not readable')
      end
    end
  end
end

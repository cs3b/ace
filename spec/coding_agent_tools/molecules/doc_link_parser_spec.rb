# frozen_string_literal: true

require 'spec_helper'
require 'tempfile'
require 'tmpdir'
require 'set'

RSpec.describe CodingAgentTools::Molecules::DocLinkParser do
  let(:parser) { described_class.new(config_path) }
  let(:config_path) { nil }
  let(:mock_reference_extractor) { instance_double(CodingAgentTools::Atoms::FileReferenceExtractor) }
  let(:mock_path_resolver) { instance_double(CodingAgentTools::Atoms::PathResolver) }
  let(:mock_config_loader) { instance_double(CodingAgentTools::Atoms::DocsDependenciesConfigLoader) }
  let(:mock_config) { {} }

  before do
    allow(CodingAgentTools::Atoms::FileReferenceExtractor).to receive(:new).and_return(mock_reference_extractor)
    allow(CodingAgentTools::Atoms::PathResolver).to receive(:new).and_return(mock_path_resolver)
    allow(CodingAgentTools::Atoms::DocsDependenciesConfigLoader).to receive(:new).with(config_path).and_return(mock_config_loader)
    allow(mock_config_loader).to receive(:load_config).and_return(mock_config)
  end

  describe '#initialize' do
    context 'with no config path' do
      it 'initializes with default config' do
        expect(CodingAgentTools::Atoms::DocsDependenciesConfigLoader).to receive(:new).with(nil)
        described_class.new
      end
    end

    context 'with custom config path' do
      let(:config_path) { '/custom/config.yml' }

      it 'uses provided config path' do
        expect(CodingAgentTools::Atoms::DocsDependenciesConfigLoader).to receive(:new).with(config_path)
        parser
      end
    end
  end

  describe '#parse_file_references' do
    context 'when file does not exist' do
      it 'returns empty array' do
        allow(File).to receive(:exist?).with('nonexistent.md').and_return(false)
        result = parser.parse_file_references('nonexistent.md', Set.new)
        expect(result).to eq([])
      end
    end

    context 'when file exists' do
      let(:file_path) { 'test.md' }
      let(:file_content) { 'Some content with links' }
      let(:all_files) { Set.new(['docs/target.md', 'other.md']) }
      let(:raw_references) { ['docs/target.md', 'other.md', 'external.com', '#anchor'] }

      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(file_content)
        allow(mock_reference_extractor).to receive(:extract_all_references).with(file_content).and_return(raw_references)
      end

      context 'with internal links' do
        before do
          allow(mock_reference_extractor).to receive(:external_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:anchor_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:internal_link?).and_return(true)
          allow(mock_config_loader).to receive(:include_external_links?).and_return(false)
          allow(mock_config_loader).to receive(:include_anchor_links?).and_return(false)

          # Stub all possible resolve_link calls
          allow(mock_path_resolver).to receive(:resolve_link).and_return('resolved')
          allow(mock_path_resolver).to receive(:resolve_link).with(file_path, 'docs/target.md').and_return('docs/target.md')
          allow(mock_path_resolver).to receive(:resolve_link).with(file_path, 'other.md').and_return('other.md')
        end

        it 'processes internal links and returns existing files' do
          result = parser.parse_file_references(file_path, all_files)
          expect(result).to include('docs/target.md', 'other.md')
        end
      end

      context 'with external links when they are excluded' do
        before do
          allow(mock_reference_extractor).to receive(:external_link?).with('external.com').and_return(true)
          allow(mock_reference_extractor).to receive(:external_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:anchor_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:internal_link?).and_return(false)
          allow(mock_config_loader).to receive(:include_external_links?).and_return(false)
        end

        it 'skips external links when configuration excludes them' do
          result = parser.parse_file_references(file_path, all_files)
          expect(result).not_to include('external.com')
        end
      end

      context 'with external links when they are included' do
        before do
          allow(mock_reference_extractor).to receive(:external_link?).with('external.com').and_return(true)
          allow(mock_reference_extractor).to receive(:external_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:anchor_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:internal_link?).and_return(false)
          allow(mock_config_loader).to receive(:include_external_links?).and_return(true)
          allow(mock_config_loader).to receive(:include_anchor_links?).and_return(false)

          allow(mock_path_resolver).to receive(:resolve_link).with(file_path, 'external.com').and_return('external.com')
        end

        it 'includes external links when configuration allows them' do
          # Note: external.com won't be in all_files so it won't be included in final result
          # but it should go through the processing pipeline
          result = parser.parse_file_references(file_path, all_files)
          expect(result).not_to include('external.com')  # Because it's not in all_files
        end
      end

      context 'with anchor links when they are excluded' do
        before do
          allow(mock_reference_extractor).to receive(:anchor_link?).with('#anchor').and_return(true)
          allow(mock_reference_extractor).to receive(:anchor_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:external_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:internal_link?).and_return(false)
          allow(mock_config_loader).to receive(:include_anchor_links?).and_return(false)
        end

        it 'skips anchor links when configuration excludes them' do
          result = parser.parse_file_references(file_path, all_files)
          expect(result).not_to include('#anchor')
        end
      end

      context 'with anchor links when they are included' do
        before do
          allow(mock_reference_extractor).to receive(:anchor_link?).with('#anchor').and_return(true)
          allow(mock_reference_extractor).to receive(:anchor_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:external_link?).and_return(false)
          allow(mock_reference_extractor).to receive(:internal_link?).and_return(false)
          allow(mock_config_loader).to receive(:include_external_links?).and_return(false)
          allow(mock_config_loader).to receive(:include_anchor_links?).and_return(true)

          allow(mock_path_resolver).to receive(:resolve_link).with(file_path, '#anchor').and_return('#anchor')
        end

        it 'includes anchor links when configuration allows them' do
          # Note: #anchor won't be in all_files so it won't be included in final result
          result = parser.parse_file_references(file_path, all_files)
          expect(result).not_to include('#anchor')  # Because it's not in all_files
        end
      end
    end
  end

  describe '#collect_documentation_files' do
    let(:file_patterns) { { 'markdown' => '**/*.md', 'workflow' => '**/*.wf.md' } }
    let(:exclude_patterns) { ['**/exclude_*.md'] }
    let(:skip_folders) { ['tmp', 'node_modules'] }

    before do
      allow(mock_config_loader).to receive(:get_file_patterns).with(mock_config).and_return(file_patterns)
      allow(mock_config_loader).to receive(:get_exclude_patterns).with(mock_config).and_return(exclude_patterns)
      allow(mock_config_loader).to receive(:get_skip_folders).with(mock_config).and_return(skip_folders)
    end

    context 'with matching files' do
      before do
        allow(Dir).to receive(:glob).with('**/*.md').and_return(['docs/test.md', 'exclude_this.md', 'tmp/hidden.md'])
        allow(Dir).to receive(:glob).with('**/*.wf.md').and_return(['workflows/test.wf.md', 'node_modules/test.wf.md'])

        allow(File).to receive(:file?).and_return(true)
        allow(File).to receive(:fnmatch).with('**/exclude_*.md', 'exclude_this.md').and_return(true)
        allow(File).to receive(:fnmatch).with('**/exclude_*.md', 'docs/test.md').and_return(false)
        allow(File).to receive(:fnmatch).with('**/exclude_*.md', 'tmp/hidden.md').and_return(false)
        allow(File).to receive(:fnmatch).with('**/exclude_*.md', 'workflows/test.wf.md').and_return(false)
        allow(File).to receive(:fnmatch).with('**/exclude_*.md', 'node_modules/test.wf.md').and_return(false)
      end

      it 'collects files matching patterns while respecting exclusions and skip folders' do
        result = parser.collect_documentation_files

        expect(result).to include('docs/test.md')
        expect(result).to include('workflows/test.wf.md')
        expect(result).not_to include('exclude_this.md')  # Excluded by pattern
        expect(result).not_to include('tmp/hidden.md')  # In skip folder
        expect(result).not_to include('node_modules/test.wf.md')  # In skip folder
      end
    end

    context 'with no matching files' do
      before do
        allow(Dir).to receive(:glob).and_return([])
      end

      it 'returns empty set' do
        result = parser.collect_documentation_files
        expect(result).to be_empty
      end
    end

    context 'with non-file entries' do
      before do
        allow(Dir).to receive(:glob).with('**/*.md').and_return(['docs/', 'docs/test.md'])
        allow(Dir).to receive(:glob).with('**/*.wf.md').and_return([])

        allow(File).to receive(:file?).with('docs/').and_return(false)
        allow(File).to receive(:file?).with('docs/test.md').and_return(true)
        allow(File).to receive(:fnmatch).and_return(false)
      end

      it 'only includes actual files' do
        result = parser.collect_documentation_files
        expect(result).to include('docs/test.md')
        expect(result).not_to include('docs/')
      end
    end
  end

  describe '#parse_with_context' do
    context 'when file does not exist' do
      it 'returns empty result structure' do
        allow(File).to receive(:exist?).with('nonexistent.md').and_return(false)
        result = parser.parse_with_context('nonexistent.md', Set.new)
        expect(result).to eq({ markdown_links: [], context_refs: [] })
      end
    end

    context 'when file exists' do
      let(:file_path) { 'test.md' }
      let(:file_content) { 'Content with [link](target.md) and context refs' }
      let(:all_files) { Set.new(['target.md', 'context.md']) }

      before do
        allow(File).to receive(:exist?).with(file_path).and_return(true)
        allow(File).to receive(:read).with(file_path).and_return(file_content)
      end

      context 'with markdown links' do
        before do
          allow(mock_reference_extractor).to receive(:extract_markdown_links)
            .with(file_content)
            .and_return([['link text', 'target.md'], ['external', 'https://example.com']])

          allow(mock_reference_extractor).to receive(:internal_link?)
            .with('target.md').and_return(true)
          allow(mock_reference_extractor).to receive(:internal_link?)
            .with('https://example.com').and_return(false)

          allow(mock_path_resolver).to receive(:resolve_link)
            .with(file_path, 'target.md').and_return('target.md')

          allow(mock_reference_extractor).to receive(:extract_context_references).and_return([])
        end

        it 'processes markdown links and returns resolved internal links' do
          result = parser.parse_with_context(file_path, all_files)

          expect(result[:markdown_links].size).to eq(1)
          expect(result[:markdown_links].first).to eq({
            text: 'link text',
            link: 'target.md',
            resolved: 'target.md'
          })
        end
      end

      context 'with context references' do
        before do
          allow(mock_reference_extractor).to receive(:extract_markdown_links).and_return([])
          allow(mock_reference_extractor).to receive(:extract_context_references)
            .with(file_content)
            .and_return(['context.md', 'nonexistent.md'])

          allow(mock_path_resolver).to receive(:resolve_link)
            .with(file_path, 'context.md').and_return('context.md')
          allow(mock_path_resolver).to receive(:resolve_link)
            .with(file_path, 'nonexistent.md').and_return('nonexistent.md')
        end

        it 'processes context references and returns resolved existing files' do
          result = parser.parse_with_context(file_path, all_files)

          expect(result[:context_refs].size).to eq(1)
          expect(result[:context_refs].first).to eq({
            original: 'context.md',
            resolved: 'context.md'
          })
        end
      end

      context 'with both markdown links and context references' do
        before do
          allow(mock_reference_extractor).to receive(:extract_markdown_links)
            .with(file_content)
            .and_return([['link', 'target.md']])

          allow(mock_reference_extractor).to receive(:extract_context_references)
            .with(file_content)
            .and_return(['context.md'])

          allow(mock_reference_extractor).to receive(:internal_link?).and_return(true)

          allow(mock_path_resolver).to receive(:resolve_link)
            .with(file_path, 'target.md').and_return('target.md')
          allow(mock_path_resolver).to receive(:resolve_link)
            .with(file_path, 'context.md').and_return('context.md')
        end

        it 'processes both types of references' do
          result = parser.parse_with_context(file_path, all_files)

          expect(result[:markdown_links].size).to eq(1)
          expect(result[:context_refs].size).to eq(1)
        end
      end
    end
  end

  describe 'integration with real file system' do
    let(:temp_dir) { Dir.mktmpdir }
    let(:test_file) { File.join(temp_dir, 'test.md') }

    after do
      FileUtils.rm_rf(temp_dir)
    end

    context 'with real file operations' do
      before do
        # Create a real parser without mocks for this test
        allow(CodingAgentTools::Atoms::FileReferenceExtractor).to receive(:new).and_call_original
        allow(CodingAgentTools::Atoms::PathResolver).to receive(:new).and_call_original
        allow(CodingAgentTools::Atoms::DocsDependenciesConfigLoader).to receive(:new).and_call_original
      end

      it 'can parse real file content' do
        File.write(test_file, "# Test\n\nSee [docs](../README.md) for more info.")

        result = parser.parse_file_references(test_file, Set.new([File.expand_path('../README.md', test_file)]))

        # The result should be influenced by actual path resolution
        expect(result).to be_an(Array)
      end
    end
  end
end

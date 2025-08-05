# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Atoms::FileReferenceExtractor do
  let(:extractor) { described_class.new }

  describe '#extract_markdown_links' do
    it 'extracts markdown links' do
      content = <<~MARKDOWN
        # Documentation
        See [architecture](docs/architecture.md) for details.
        Also check [README](../README.md).
      MARKDOWN

      links = extractor.extract_markdown_links(content)

      expect(links).to include(['architecture', 'docs/architecture.md'])
      expect(links).to include(['README', '../README.md'])
    end

    it 'extracts image references' do
      content = <<~MARKDOWN
        ![Diagram](images/diagram.png)
        ![Icon](./icons/icon.svg)
      MARKDOWN

      links = extractor.extract_markdown_links(content)

      expect(links).to include(['Diagram', 'images/diagram.png'])
      expect(links).to include(['Icon', './icons/icon.svg'])
    end

    it 'handles complex link text' do
      content = '[Link with spaces and symbols!](file.md)'

      links = extractor.extract_markdown_links(content)

      expect(links).to include(['Link with spaces and symbols!', 'file.md'])
    end

    it 'handles empty content' do
      links = extractor.extract_markdown_links('')
      expect(links).to be_empty
    end
  end

  describe '#extract_context_references' do
    it 'extracts context loading patterns' do
      content = <<~TEXT
        Load project objectives: `docs/what-we-build.md`
        Check architecture overview: `docs/architecture.md`
        Read project structure: `docs/blueprint.md`
      TEXT

      refs = extractor.extract_context_references(content)

      expect(refs).to include('docs/what-we-build.md')
      expect(refs).to include('docs/architecture.md')
      expect(refs).to include('docs/blueprint.md')
    end

    it 'handles different patterns' do
      content = <<~TEXT
        Load tools documentation: `docs/tools.md`
        see workflow instructions: `guide.wf.md`
        Check guide: `reference.g.md`
      TEXT

      refs = extractor.extract_context_references(content)

      expect(refs).to include('docs/tools.md')
      expect(refs).to include('guide.wf.md')
      expect(refs).to include('reference.g.md')
    end

    it 'ignores non-matching patterns' do
      content = 'This is just regular text with `code blocks` but no file references.'

      refs = extractor.extract_context_references(content)

      expect(refs).to be_empty
    end
  end

  describe '#extract_all_references' do
    it 'combines markdown links and context references' do
      content = <<~TEXT
        # Project Documentation
        
        See [architecture](docs/architecture.md) for details.
        Load project objectives: `docs/what-we-build.md`
        
        [External link](https://example.com) should be ignored.
        [Anchor](#section) should be ignored.
      TEXT

      references = extractor.extract_all_references(content)

      expect(references).to include('docs/architecture.md')
      expect(references).to include('docs/what-we-build.md')
      expect(references).not_to include('https://example.com')
      expect(references).not_to include('#section')
    end

    it 'returns a Set to avoid duplicates' do
      content = <<~TEXT
        [Link1](file.md)
        [Link2](file.md)
        Load file: `file.md`
      TEXT

      references = extractor.extract_all_references(content)

      expect(references).to be_a(Set)
      expect(references.size).to eq(1)
      expect(references).to include('file.md')
    end

    it 'handles empty content' do
      references = extractor.extract_all_references('')
      expect(references).to be_empty
    end
  end

  describe '#external_link?' do
    it 'identifies external HTTP links' do
      expect(extractor.external_link?('http://example.com')).to be true
      expect(extractor.external_link?('https://example.com')).to be true
      expect(extractor.external_link?('file.md')).to be false
      expect(extractor.external_link?('../file.md')).to be false
    end
  end

  describe '#anchor_link?' do
    it 'identifies anchor links' do
      expect(extractor.anchor_link?('#section')).to be true
      expect(extractor.anchor_link?('#top')).to be true
      expect(extractor.anchor_link?('file.md')).to be false
      expect(extractor.anchor_link?('file.md#section')).to be false
    end
  end

  describe '#internal_link?' do
    it 'identifies internal links correctly' do
      expect(extractor.internal_link?('file.md')).to be true
      expect(extractor.internal_link?('../README.md')).to be true
      expect(extractor.internal_link?('docs/guide.md')).to be true
      expect(extractor.internal_link?('https://example.com')).to be false
      expect(extractor.internal_link?('#section')).to be false
    end
  end

  describe 'integration' do
    it 'processes complex document with mixed reference types' do
      content = <<~TEXT
        # Workflow Instructions
        
        **Essential project context:**
        
        - Load project objectives: `docs/what-do-we-build.md`
        - Load architecture overview: `docs/architecture.md`
        - See [blueprint](docs/blueprint.md) for structure
        
        **External resources:**
        - [Ruby docs](https://ruby-doc.org)
        - [GitHub](https://github.com)
        
        **Navigation:**
        - [Top](#top)
        - [Section](#section)
      TEXT

      references = extractor.extract_all_references(content)

      expect(references).to be_a(Set)
      expect(references.size).to eq(3)

      # Check that it filters out external and anchor links
      expect(references).not_to include('https://ruby-doc.org')
      expect(references).not_to include('https://github.com')
      expect(references).not_to include('#top')
      expect(references).not_to include('#section')
    end
  end
end

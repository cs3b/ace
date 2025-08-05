# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/models/code/review_context'

RSpec.describe CodingAgentTools::Models::Code::ReviewContext do
  let(:sample_documents) do
    [
      { type: 'blueprint', path: 'docs/blueprint.md', content: 'Blueprint content' },
      { type: 'vision', path: 'docs/vision.md', content: 'Vision content' },
      { type: 'architecture', path: 'docs/architecture.md', content: 'Architecture content' }
    ]
  end

  describe '#initialize' do
    it 'creates a new review context with valid attributes' do
      context = described_class.new(
        mode: 'auto',
        documents: sample_documents,
        loaded_at: Time.now
      )

      expect(context.mode).to eq('auto')
      expect(context.documents).to eq(sample_documents)
      expect(context.loaded_at).to be_a(Time)
    end

    it 'accepts minimal attributes' do
      context = described_class.new(mode: 'none')
      expect(context.mode).to eq('none')
      expect(context.documents).to be_nil
      expect(context.loaded_at).to be_nil
    end
  end

  describe '#validate!' do
    it 'validates successfully with auto mode and documents' do
      context = described_class.new(mode: 'auto', documents: sample_documents)
      expect { context.validate! }.not_to raise_error
    end

    it 'validates successfully with none mode and no documents' do
      context = described_class.new(mode: 'none')
      expect { context.validate! }.not_to raise_error
    end

    it 'validates successfully with custom mode and documents' do
      context = described_class.new(mode: 'custom', documents: sample_documents)
      expect { context.validate! }.not_to raise_error
    end

    it 'raises error when mode is nil' do
      context = described_class.new(mode: nil)
      expect { context.validate! }.to raise_error(ArgumentError, 'mode is required')
    end

    it 'raises error when mode is empty' do
      context = described_class.new(mode: '')
      expect { context.validate! }.to raise_error(ArgumentError, 'mode is required')
    end

    it 'raises error when mode is invalid' do
      context = described_class.new(mode: 'invalid')
      expect { context.validate! }.to raise_error(ArgumentError, 'mode must be one of: auto, none, custom')
    end

    it 'raises error when custom mode has no documents' do
      context = described_class.new(mode: 'custom', documents: nil)
      expect { context.validate! }.to raise_error(ArgumentError, 'documents required for custom mode')
    end

    it 'raises error when custom mode has empty documents' do
      context = described_class.new(mode: 'custom', documents: [])
      expect { context.validate! }.to raise_error(ArgumentError, 'documents required for custom mode')
    end
  end

  describe '#loaded?' do
    it 'returns true when mode is not none and has documents' do
      context = described_class.new(mode: 'auto', documents: sample_documents)
      expect(context.loaded?).to be(true)
    end

    it 'returns false when mode is none' do
      context = described_class.new(mode: 'none')
      expect(context.loaded?).to be(false)
    end

    it 'returns false when documents are nil' do
      context = described_class.new(mode: 'auto', documents: nil)
      expect(context.loaded?).to be(false)
    end

    it 'returns false when documents are empty' do
      context = described_class.new(mode: 'auto', documents: [])
      expect(context.loaded?).to be(false)
    end
  end

  describe '#document_count' do
    it 'returns correct count when documents are present' do
      context = described_class.new(mode: 'auto', documents: sample_documents)
      expect(context.document_count).to eq(3)
    end

    it 'returns 0 when documents are nil' do
      context = described_class.new(mode: 'none', documents: nil)
      expect(context.document_count).to eq(0)
    end

    it 'returns 0 when documents are empty' do
      context = described_class.new(mode: 'auto', documents: [])
      expect(context.document_count).to eq(0)
    end
  end

  describe '#total_size' do
    it 'calculates total content size correctly' do
      context = described_class.new(mode: 'auto', documents: sample_documents)
      expected_size = 'Blueprint content'.size + 'Vision content'.size + 'Architecture content'.size
      expect(context.total_size).to eq(expected_size)
    end

    it 'returns 0 when documents are nil' do
      context = described_class.new(mode: 'none', documents: nil)
      expect(context.total_size).to eq(0)
    end

    it 'handles documents with nil content' do
      docs_with_nil = [
        { type: 'blueprint', path: 'docs/blueprint.md', content: nil },
        { type: 'vision', path: 'docs/vision.md', content: 'Vision content' }
      ]
      context = described_class.new(mode: 'auto', documents: docs_with_nil)
      expect(context.total_size).to eq('Vision content'.size)
    end
  end

  describe '#document_by_type' do
    it 'finds document by type' do
      context = described_class.new(mode: 'auto', documents: sample_documents)
      blueprint_doc = context.document_by_type('blueprint')
      expect(blueprint_doc[:type]).to eq('blueprint')
      expect(blueprint_doc[:content]).to eq('Blueprint content')
    end

    it 'returns nil when type not found' do
      context = described_class.new(mode: 'auto', documents: sample_documents)
      expect(context.document_by_type('nonexistent')).to be_nil
    end

    it 'returns nil when documents are nil' do
      context = described_class.new(mode: 'none', documents: nil)
      expect(context.document_by_type('blueprint')).to be_nil
    end
  end

  describe '#document_types' do
    it 'returns all document types' do
      context = described_class.new(mode: 'auto', documents: sample_documents)
      expect(context.document_types).to eq(['blueprint', 'vision', 'architecture'])
    end

    it 'returns unique types only' do
      duplicate_docs = [
        { type: 'blueprint', path: 'docs/blueprint1.md', content: 'Content 1' },
        { type: 'blueprint', path: 'docs/blueprint2.md', content: 'Content 2' },
        { type: 'vision', path: 'docs/vision.md', content: 'Vision content' }
      ]
      context = described_class.new(mode: 'auto', documents: duplicate_docs)
      expect(context.document_types).to eq(['blueprint', 'vision'])
    end

    it 'returns empty array when documents are nil' do
      context = described_class.new(mode: 'none', documents: nil)
      expect(context.document_types).to eq([])
    end
  end

  describe '.auto_document_types' do
    it 'returns standard auto document types' do
      expect(described_class.auto_document_types).to eq(['blueprint', 'vision', 'architecture'])
    end
  end

  describe '#using_auto_defaults?' do
    it 'returns true when using auto mode with default document types' do
      context = described_class.new(mode: 'auto', documents: sample_documents)
      expect(context.using_auto_defaults?).to be(true)
    end

    it 'returns false when using custom mode' do
      context = described_class.new(mode: 'custom', documents: sample_documents)
      expect(context.using_auto_defaults?).to be(false)
    end

    it "returns false when document types don't match defaults" do
      custom_docs = [
        { type: 'custom', path: 'docs/custom.md', content: 'Custom content' }
      ]
      context = described_class.new(mode: 'auto', documents: custom_docs)
      expect(context.using_auto_defaults?).to be(false)
    end

    it 'returns false when missing some default types' do
      partial_docs = [
        { type: 'blueprint', path: 'docs/blueprint.md', content: 'Blueprint content' }
      ]
      context = described_class.new(mode: 'auto', documents: partial_docs)
      expect(context.using_auto_defaults?).to be(false)
    end
  end

  describe 'edge cases', :edge_cases do
    it 'handles empty document content' do
      empty_docs = [
        { type: 'blueprint', path: 'docs/blueprint.md', content: '' }
      ]
      context = described_class.new(mode: 'auto', documents: empty_docs)
      expect(context.total_size).to eq(0)
      expect(context.loaded?).to be(true)
    end

    it 'handles very large document sets' do
      large_docs = Array.new(1000) do |i|
        { type: "doc#{i}", path: "docs/doc#{i}.md", content: "Content #{i}" }
      end
      context = described_class.new(mode: 'custom', documents: large_docs)
      expect(context.document_count).to eq(1000)
      expect(context.document_types.size).to eq(1000)
    end

    it 'handles documents with special characters in content' do
      special_docs = [
        { type: 'unicode', path: 'docs/unicode.md', content: "Content with émojis 🚀 and ñéẅlíñés\n\t" }
      ]
      context = described_class.new(mode: 'custom', documents: special_docs)
      expect(context.total_size).to be > 0
      expect(context.document_by_type('unicode')[:content]).to include('🚀')
    end

    it 'handles documents with malformed structure' do
      malformed_docs = [
        { type: 'good', path: 'docs/good.md', content: 'Good content' },
        { path: 'docs/no_type.md', content: 'No type' }, # Missing type
        { type: 'no_content', path: 'docs/no_content.md' } # Missing content
      ]
      context = described_class.new(mode: 'custom', documents: malformed_docs)
      expect(context.document_count).to eq(3)
      expect(context.document_types).to include('good')
    end
  end
end

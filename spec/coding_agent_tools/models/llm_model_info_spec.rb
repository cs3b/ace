# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Models::LlmModelInfo do
  describe '#initialize' do
    it 'creates model with basic fields' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false
      )

      expect(model.id).to eq('test-model')
      expect(model.name).to eq('Test Model')
      expect(model.description).to eq('A test model')
      expect(model.default).to be false
      expect(model.context_size).to be_nil
      expect(model.max_output_tokens).to be_nil
    end

    it 'creates model with context size information' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000,
        max_output_tokens: 4_096
      )

      expect(model.context_size).to eq(128_000)
      expect(model.max_output_tokens).to eq(4_096)
    end

    it 'creates model with keyword arguments' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: true,
        context_size: 200_000
      )

      expect(model.id).to eq('test-model')
      expect(model.default).to be true
      expect(model.context_size).to eq(200_000)
    end
  end

  describe '#default?' do
    it 'returns true for default model' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: true
      )

      expect(model.default?).to be true
    end

    it 'returns false for non-default model' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false
      )

      expect(model.default?).to be false
    end
  end

  describe '#to_s' do
    it 'formats basic model information' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false
      )

      output = model.to_s
      expect(output).to include('ID: test-model')
      expect(output).to include('Name: Test Model')
      expect(output).to include('Description: A test model')
      expect(output).not_to include('Status: Default model')
    end

    it 'includes default model status' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: true
      )

      output = model.to_s
      expect(output).to include('Status: Default model')
    end

    it 'includes context size when available' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000
      )

      output = model.to_s
      expect(output).to include('Context Size: 128.0K tokens')
    end

    it 'includes max output tokens when available' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        max_output_tokens: 4_096
      )

      output = model.to_s
      expect(output).to include('Max Output: 4.1K tokens')
    end

    it 'includes both context size and max output' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: true,
        context_size: 2_000_000,
        max_output_tokens: 8_192
      )

      output = model.to_s
      expect(output).to include('Context Size: 2.0M tokens')
      expect(output).to include('Max Output: 8.2K tokens')
      expect(output).to include('Status: Default model')
    end
  end

  describe '#format_context_size' do
    it 'formats small numbers as tokens' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        context_size: 512
      )

      expect(model.format_context_size).to eq('512 tokens')
    end

    it 'formats thousands as K tokens' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        context_size: 128_000
      )

      expect(model.format_context_size).to eq('128.0K tokens')
    end

    it 'formats millions as M tokens' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        context_size: 2_000_000
      )

      expect(model.format_context_size).to eq('2.0M tokens')
    end

    it 'handles fractional formatting' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        context_size: 1_048_576
      )

      expect(model.format_context_size).to eq('1.0M tokens')
    end

    it 'returns Unknown for nil values' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        context_size: nil
      )

      expect(model.format_context_size).to eq('Unknown')
    end
  end

  describe '#format_max_output_tokens' do
    it 'formats small numbers as tokens' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        max_output_tokens: 512
      )

      expect(model.format_max_output_tokens).to eq('512 tokens')
    end

    it 'formats thousands as K tokens' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        max_output_tokens: 4_096
      )

      expect(model.format_max_output_tokens).to eq('4.1K tokens')
    end

    it 'returns Unknown for nil values' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        max_output_tokens: nil
      )

      expect(model.format_max_output_tokens).to eq('Unknown')
    end
  end

  describe '#to_h' do
    it 'returns hash representation with all fields' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: true,
        context_size: 128_000,
        max_output_tokens: 4_096
      )

      hash = model.to_h
      expect(hash).to eq({
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: true,
        context_size: 128_000,
        max_output_tokens: 4_096
      })
    end

    it 'includes nil values in hash' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false
      )

      hash = model.to_h
      expect(hash).to include(
        context_size: nil,
        max_output_tokens: nil
      )
    end
  end

  describe '#to_json_hash' do
    it 'returns same as to_h' do
      model = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000
      )

      expect(model.to_json_hash).to eq(model.to_h)
    end
  end

  describe '#==' do
    let(:model1) do
      described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000,
        max_output_tokens: 4_096
      )
    end

    it 'returns true for identical models' do
      model2 = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000,
        max_output_tokens: 4_096
      )

      expect(model1).to eq(model2)
    end

    it 'returns false for different IDs' do
      model2 = described_class.new(
        id: 'different-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000,
        max_output_tokens: 4_096
      )

      expect(model1).not_to eq(model2)
    end

    it 'returns false for different context sizes' do
      model2 = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 200_000,
        max_output_tokens: 4_096
      )

      expect(model1).not_to eq(model2)
    end

    it 'returns false for different max output tokens' do
      model2 = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000,
        max_output_tokens: 8_192
      )

      expect(model1).not_to eq(model2)
    end

    it 'returns false for non-LlmModelInfo objects' do
      expect(model1).not_to eq('not a model')
      expect(model1).not_to eq(nil)
    end
  end

  describe '#hash' do
    it 'returns same hash for equal models' do
      model1 = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000,
        max_output_tokens: 4_096
      )

      model2 = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false,
        context_size: 128_000,
        max_output_tokens: 4_096
      )

      expect(model1.hash).to eq(model2.hash)
    end

    it 'returns different hash for different models' do
      model1 = described_class.new(
        id: 'test-model-1',
        name: 'Test Model',
        description: 'A test model',
        default: false
      )

      model2 = described_class.new(
        id: 'test-model-2',
        name: 'Test Model',
        description: 'A test model',
        default: false
      )

      expect(model1.hash).not_to eq(model2.hash)
    end
  end

  describe '#eql?' do
    it 'behaves same as ==' do
      model1 = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false
      )

      model2 = described_class.new(
        id: 'test-model',
        name: 'Test Model',
        description: 'A test model',
        default: false
      )

      expect(model1.eql?(model2)).to eq(model1 == model2)
      expect(model1.eql?(model2)).to be true
    end
  end

  describe 'backward compatibility' do
    it "works with existing code that doesn't use context size" do
      # Test that existing code can create models without context size
      model = described_class.new(
        id: 'legacy-model',
        name: 'Legacy Model',
        description: 'Works without context size',
        default: true
      )

      expect(model.id).to eq('legacy-model')
      expect(model.context_size).to be_nil
      expect(model.max_output_tokens).to be_nil
      expect(model.default?).to be true
    end

    it 'to_s works without context size' do
      model = described_class.new(
        id: 'legacy-model',
        name: 'Legacy Model',
        description: 'Works without context size',
        default: false
      )

      output = model.to_s
      expect(output).to include('ID: legacy-model')
      expect(output).not_to include('Context Size:')
      expect(output).not_to include('Max Output:')
    end

    it 'hash representation includes new fields as nil' do
      model = described_class.new(
        id: 'legacy-model',
        name: 'Legacy Model',
        description: 'Works without context size',
        default: false
      )

      hash = model.to_h
      expect(hash[:context_size]).to be_nil
      expect(hash[:max_output_tokens]).to be_nil
    end
  end
end

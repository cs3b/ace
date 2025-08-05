# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Models::Result do
  describe '#initialize' do
    context 'with valid attributes' do
      it 'creates successful result' do
        result = described_class.new(
          success: true,
          data: { message: 'Operation completed' },
          error: nil
        )

        expect(result.success?).to be true
        expect(result.data).to eq({ message: 'Operation completed' })
        expect(result.error).to be_nil
      end

      it 'creates failed result' do
        result = described_class.new(
          success: false,
          data: nil,
          error: 'Operation failed'
        )

        expect(result.success?).to be false
        expect(result.data).to eq({})
        expect(result.error).to eq('Operation failed')
      end

      it 'creates result with data hash' do
        result = described_class.new(
          success: true,
          data: { count: 42, items: ['a', 'b'] },
          error: nil
        )

        expect(result.success?).to be true
        expect(result.data).to eq({ count: 42, items: ['a', 'b'] })
        expect(result.error).to be_nil
      end
    end

    context 'with nil data' do
      it 'defaults data to empty hash' do
        result = described_class.new(
          success: true,
          data: nil,
          error: nil
        )

        expect(result.data).to eq({})
      end
    end
  end

  describe '#success?' do
    it 'returns true for successful results' do
      result = described_class.new(success: true, data: {}, error: nil)
      expect(result.success?).to be true
    end

    it 'returns false for failed results' do
      result = described_class.new(success: false, data: {}, error: 'Error')
      expect(result.success?).to be false
    end
  end

  describe '#failure?' do
    it 'returns false for successful results' do
      result = described_class.new(success: true, data: {}, error: nil)
      expect(result.failure?).to be false
    end

    it 'returns true for failed results' do
      result = described_class.new(success: false, data: {}, error: 'Error')
      expect(result.failure?).to be true
    end
  end

  describe '#valid?' do
    it 'returns same as success?' do
      success_result = described_class.new(success: true, data: {}, error: nil)
      expect(success_result.valid?).to eq(success_result.success?)

      failure_result = described_class.new(success: false, data: {}, error: 'Error')
      expect(failure_result.valid?).to eq(failure_result.success?)
    end
  end

  describe '#to_h' do
    it 'converts result to hash' do
      result = described_class.new(
        success: true,
        data: { message: 'Done' },
        error: nil
      )

      expected_hash = {
        success: true,
        data: { message: 'Done' }
      }

      expect(result.to_h).to eq(expected_hash)
    end

    it 'includes error when present' do
      result = described_class.new(
        success: false,
        data: {},
        error: 'Something went wrong'
      )

      expected_hash = {
        success: false,
        data: {},
        error: 'Something went wrong'
      }

      expect(result.to_h).to eq(expected_hash)
    end
  end

  describe '#to_json' do
    it 'can be serialized to JSON' do
      result = described_class.new(
        success: true,
        data: { count: 5 },
        error: nil
      )

      json_result = result.to_json
      parsed = JSON.parse(json_result)

      expect(parsed['success']).to be true
      expect(parsed['data']['count']).to eq(5)
      expect(parsed.key?('error')).to be false
    end
  end

  describe 'class methods' do
    describe '.success' do
      it 'creates successful result without data' do
        result = described_class.success

        expect(result.success?).to be true
        expect(result.data).to eq({})
        expect(result.error).to be_nil
      end

      it 'creates successful result with data' do
        result = described_class.success(message: 'Done', count: 3)

        expect(result.success?).to be true
        expect(result.data).to eq({ message: 'Done', count: 3 })
        expect(result.error).to be_nil
      end
    end

    describe '.failure' do
      it 'creates failed result with error message' do
        result = described_class.failure('Something went wrong')

        expect(result.success?).to be false
        expect(result.data).to eq({})
        expect(result.error).to eq('Something went wrong')
      end
    end
  end

  describe 'method_missing for data access' do
    it 'allows accessing data keys as methods' do
      result = described_class.new(
        success: true,
        data: { message: 'Hello', count: 42 },
        error: nil
      )

      expect(result.message).to eq('Hello')
      expect(result.count).to eq(42)
    end

    it 'raises NoMethodError for non-existent keys' do
      result = described_class.new(success: true, data: {}, error: nil)

      expect { result.nonexistent }.to raise_error(NoMethodError)
    end
  end

  describe 'respond_to_missing?' do
    it 'returns true for data keys' do
      result = described_class.new(
        success: true,
        data: { message: 'Hello' },
        error: nil
      )

      expect(result.respond_to?(:message)).to be true
      expect(result.respond_to?(:nonexistent)).to be false
    end
  end

  describe 'immutability' do
    it 'prevents modification of result attributes' do
      result = described_class.new(success: true, data: { count: 1 }, error: nil)

      expect(result.frozen?).to be true
    end

    it 'allows safe access to nested data' do
      result = described_class.new(
        success: true,
        data: { items: ['a', 'b', 'c'] },
        error: nil
      )

      # Data itself is still mutable (this is expected behavior)
      expect { result.items << 'd' }.not_to raise_error
      expect(result.items).to eq(['a', 'b', 'c', 'd'])
    end
  end
end

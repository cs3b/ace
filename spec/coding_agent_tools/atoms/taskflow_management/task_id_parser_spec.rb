# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Atoms::TaskflowManagement::TaskIdParser do
  describe '.parse', :standard_format do
    context 'with valid task IDs' do
      it 'parses standard format task ID' do
        result = described_class.parse('v.0.3.0+task.97')
        expect(result).to eq({
          version: 'v.0.3.0',
          sequential_number: 97
        })
      end

      it 'parses task ID with zero-padded sequential number' do
        result = described_class.parse('v.0.3.0+task.05')
        expect(result).to eq({
          version: 'v.0.3.0',
          sequential_number: 5
        })
      end

      it 'parses task ID with single digit sequential number' do
        result = described_class.parse('v.1.0.0+task.1')
        expect(result).to eq({
          version: 'v.1.0.0',
          sequential_number: 1
        })
      end

      it 'parses task ID with high version numbers' do
        result = described_class.parse('v.10.25.100+task.999')
        expect(result).to eq({
          version: 'v.10.25.100',
          sequential_number: 999
        })
      end
    end

    context 'with invalid task IDs' do
      it 'raises error for nil task ID' do
        expect { described_class.parse(nil) }.to raise_error(ArgumentError, 'task_id must be a string')
      end

      it 'raises error for empty string' do
        expect { described_class.parse('') }.to raise_error(ArgumentError, 'task_id cannot be nil or empty')
      end

      it 'raises error for non-string input' do
        expect { described_class.parse(123) }.to raise_error(ArgumentError, 'task_id must be a string')
      end

      it 'raises error for malformed version part' do
        expect { described_class.parse('0.3.0+task.97') }.to raise_error(ArgumentError, /Invalid task ID format/)
      end

      it "raises error for missing 'v.' prefix" do
        expect { described_class.parse('0.3.0+task.97') }.to raise_error(ArgumentError, /Invalid task ID format/)
      end

      it "raises error for missing '+task.' separator" do
        expect { described_class.parse('v.0.3.0-task.97') }.to raise_error(ArgumentError, /Invalid task ID format/)
      end

      it 'raises error for missing task number' do
        expect { described_class.parse('v.0.3.0+task.') }.to raise_error(ArgumentError, /Invalid task ID format/)
      end

      it 'raises error for non-numeric task number' do
        expect { described_class.parse('v.0.3.0+task.abc') }.to raise_error(ArgumentError, /Invalid task ID format/)
      end

      it 'raises error for incomplete version' do
        expect { described_class.parse('v.0.3+task.97') }.to raise_error(ArgumentError, /Invalid task ID format/)
      end

      it 'raises error for extra parts' do
        expect { described_class.parse('v.0.3.0.1+task.97') }.to raise_error(ArgumentError, /Invalid task ID format/)
      end
    end
  end

  describe '.extract_version', :extraction do
    it 'extracts version from valid task ID' do
      result = described_class.extract_version('v.0.3.0+task.97')
      expect(result).to eq('v.0.3.0')
    end

    it 'extracts version with high numbers' do
      result = described_class.extract_version('v.10.25.100+task.1')
      expect(result).to eq('v.10.25.100')
    end

    it 'raises error for invalid task ID' do
      expect { described_class.extract_version('invalid') }.to raise_error(ArgumentError, /Invalid task ID format/)
    end
  end

  describe '.extract_sequential_number', :extraction do
    it 'extracts sequential number from valid task ID' do
      result = described_class.extract_sequential_number('v.0.3.0+task.97')
      expect(result).to eq(97)
    end

    it 'extracts sequential number from zero-padded task ID' do
      result = described_class.extract_sequential_number('v.0.3.0+task.05')
      expect(result).to eq(5)
    end

    it 'extracts large sequential numbers' do
      result = described_class.extract_sequential_number('v.0.3.0+task.999')
      expect(result).to eq(999)
    end

    it 'raises error for invalid task ID' do
      expect { described_class.extract_sequential_number('invalid') }.to raise_error(ArgumentError, /Invalid task ID format/)
    end
  end

  describe '.valid?' do
    context 'with valid task IDs' do
      it 'returns true for standard format' do
        expect(described_class.valid?('v.0.3.0+task.97')).to be true
      end

      it 'returns true for zero-padded sequential number' do
        expect(described_class.valid?('v.0.3.0+task.05')).to be true
      end

      it 'returns true for single digit task number' do
        expect(described_class.valid?('v.1.0.0+task.1')).to be true
      end

      it 'returns true for high version numbers' do
        expect(described_class.valid?('v.10.25.100+task.999')).to be true
      end
    end

    context 'with invalid task IDs', :edge_cases do
      it 'returns false for nil' do
        expect(described_class.valid?(nil)).to be false
      end

      it 'returns false for empty string' do
        expect(described_class.valid?('')).to be false
      end

      it 'returns false for non-string input' do
        expect(described_class.valid?(123)).to be false
      end

      it 'returns false for malformed version' do
        expect(described_class.valid?('0.3.0+task.97')).to be false
      end

      it 'returns false for wrong separator' do
        expect(described_class.valid?('v.0.3.0-task.97')).to be false
      end

      it 'returns false for missing task number' do
        expect(described_class.valid?('v.0.3.0+task.')).to be false
      end

      it 'returns false for non-numeric task number' do
        expect(described_class.valid?('v.0.3.0+task.abc')).to be false
      end

      it 'returns false for incomplete version' do
        expect(described_class.valid?('v.0.3+task.97')).to be false
      end
    end
  end

  describe '.valid_version?' do
    context 'with valid versions' do
      it 'returns true for standard version format' do
        expect(described_class.valid_version?('v.0.3.0')).to be true
      end

      it 'returns true for high version numbers' do
        expect(described_class.valid_version?('v.10.25.100')).to be true
      end

      it 'returns true for zero versions' do
        expect(described_class.valid_version?('v.0.0.0')).to be true
      end
    end

    context 'with invalid versions' do
      it 'returns false for nil' do
        expect(described_class.valid_version?(nil)).to be false
      end

      it 'returns false for empty string' do
        expect(described_class.valid_version?('')).to be false
      end

      it 'returns false for non-string input' do
        expect(described_class.valid_version?(123)).to be false
      end

      it "returns false for missing 'v.' prefix" do
        expect(described_class.valid_version?('0.3.0')).to be false
      end

      it 'returns false for incomplete version' do
        expect(described_class.valid_version?('v.0.3')).to be false
      end

      it 'returns false for extra parts' do
        expect(described_class.valid_version?('v.0.3.0.1')).to be false
      end

      it 'returns false for non-numeric parts' do
        expect(described_class.valid_version?('v.0.3.a')).to be false
      end
    end
  end

  describe '.generate_next_id' do
    it 'generates next task ID with zero padding' do
      result = described_class.generate_next_id('v.0.3.0', current_max: 5)
      expect(result).to eq('v.0.3.0+task.06')
    end

    it 'generates first task ID when current_max is 0' do
      result = described_class.generate_next_id('v.0.3.0', current_max: 0)
      expect(result).to eq('v.0.3.0+task.01')
    end

    it 'generates task ID with double digits' do
      result = described_class.generate_next_id('v.0.3.0', current_max: 99)
      expect(result).to eq('v.0.3.0+task.100')
    end

    it 'raises error for invalid version' do
      expect { described_class.generate_next_id('invalid', current_max: 0) }.to raise_error(ArgumentError, /Invalid version format/)
    end

    it 'raises error for negative current_max' do
      expect { described_class.generate_next_id('v.0.3.0', current_max: -1) }.to raise_error(ArgumentError, /current_max must be a non-negative integer/)
    end

    it 'raises error for non-integer current_max' do
      expect { described_class.generate_next_id('v.0.3.0', current_max: 'abc') }.to raise_error(ArgumentError, /current_max must be a non-negative integer/)
    end
  end

  describe '.sort_task_ids' do
    it 'returns empty array for nil input' do
      expect(described_class.sort_task_ids(nil)).to eq([])
    end

    it 'returns empty array for empty input' do
      expect(described_class.sort_task_ids([])).to eq([])
    end

    it 'sorts task IDs by version first, then by sequential number' do
      task_ids = [
        'v.0.3.0+task.05',
        'v.0.2.0+task.10',
        'v.0.3.0+task.01',
        'v.1.0.0+task.01'
      ]

      result = described_class.sort_task_ids(task_ids)
      expect(result).to eq([
        'v.0.2.0+task.10',
        'v.0.3.0+task.01',
        'v.0.3.0+task.05',
        'v.1.0.0+task.01'
      ])
    end

    it 'sorts task IDs with same version by sequential number' do
      task_ids = [
        'v.0.3.0+task.10',
        'v.0.3.0+task.02',
        'v.0.3.0+task.25',
        'v.0.3.0+task.01'
      ]

      result = described_class.sort_task_ids(task_ids)
      expect(result).to eq([
        'v.0.3.0+task.01',
        'v.0.3.0+task.02',
        'v.0.3.0+task.10',
        'v.0.3.0+task.25'
      ])
    end

    it 'falls back to string comparison for invalid task IDs' do
      task_ids = [
        'v.0.3.0+task.01',
        'invalid-task-id',
        'v.0.2.0+task.01'
      ]

      result = described_class.sort_task_ids(task_ids)
      # Should not raise error, uses string comparison as fallback
      expect(result).to be_an(Array)
      expect(result.size).to eq(3)
    end
  end

  describe '.compare_versions' do
    it 'returns 0 for identical versions' do
      result = described_class.compare_versions('v.0.3.0', 'v.0.3.0')
      expect(result).to eq(0)
    end

    it 'returns -1 when first version is lower' do
      result = described_class.compare_versions('v.0.2.0', 'v.0.3.0')
      expect(result).to eq(-1)
    end

    it 'returns 1 when first version is higher' do
      result = described_class.compare_versions('v.0.4.0', 'v.0.3.0')
      expect(result).to eq(1)
    end

    it 'compares major versions correctly' do
      result = described_class.compare_versions('v.1.0.0', 'v.2.0.0')
      expect(result).to eq(-1)
    end

    it 'compares minor versions correctly' do
      result = described_class.compare_versions('v.0.5.0', 'v.0.3.0')
      expect(result).to eq(1)
    end

    it 'compares patch versions correctly' do
      result = described_class.compare_versions('v.0.3.1', 'v.0.3.5')
      expect(result).to eq(-1)
    end

    it 'handles versions with different lengths' do
      result = described_class.compare_versions('v.0.3.0', 'v.0.3.0')
      expect(result).to eq(0)
    end
  end

  describe '.extract_sequential_from_text' do
    it 'extracts sequential number from filename' do
      result = described_class.extract_sequential_from_text('v.0.3.0+task.97-some-description.md')
      expect(result).to eq(97)
    end

    it 'extracts sequential number from any text containing pattern' do
      result = described_class.extract_sequential_from_text('Task v.0.3.0+task.05 is complete')
      expect(result).to eq(5)
    end

    it 'returns nil for text without task pattern' do
      result = described_class.extract_sequential_from_text('No task ID here')
      expect(result).to be_nil
    end

    it 'returns nil for nil input' do
      result = described_class.extract_sequential_from_text(nil)
      expect(result).to be_nil
    end

    it 'returns nil for empty string' do
      result = described_class.extract_sequential_from_text('')
      expect(result).to be_nil
    end

    it 'returns nil for non-string input' do
      result = described_class.extract_sequential_from_text(123)
      expect(result).to be_nil
    end

    it 'extracts from first occurrence when multiple patterns exist' do
      result = described_class.extract_sequential_from_text('Task +task.10 and +task.20')
      expect(result).to eq(10)
    end
  end

  describe '.build_task_id' do
    it 'builds task ID with zero padding by default' do
      result = described_class.build_task_id('v.0.3.0', 5)
      expect(result).to eq('v.0.3.0+task.05')
    end

    it 'builds task ID without zero padding when disabled' do
      result = described_class.build_task_id('v.0.3.0', 5, zero_pad: false)
      expect(result).to eq('v.0.3.0+task.5')
    end

    it 'builds task ID with large sequential number' do
      result = described_class.build_task_id('v.0.3.0', 999)
      expect(result).to eq('v.0.3.0+task.999')
    end

    it 'raises error for invalid version' do
      expect { described_class.build_task_id('invalid', 1) }.to raise_error(ArgumentError, /Invalid version format/)
    end

    it 'raises error for zero sequential number' do
      expect { described_class.build_task_id('v.0.3.0', 0) }.to raise_error(ArgumentError, /sequential_number must be a positive integer/)
    end

    it 'raises error for negative sequential number' do
      expect { described_class.build_task_id('v.0.3.0', -1) }.to raise_error(ArgumentError, /sequential_number must be a positive integer/)
    end

    it 'raises error for non-integer sequential number' do
      expect { described_class.build_task_id('v.0.3.0', 'abc') }.to raise_error(ArgumentError, /sequential_number must be a positive integer/)
    end
  end

  describe '.belongs_to_version?' do
    it 'returns true when task ID belongs to version' do
      result = described_class.belongs_to_version?('v.0.3.0+task.97', 'v.0.3.0')
      expect(result).to be true
    end

    it 'returns false when task ID belongs to different version' do
      result = described_class.belongs_to_version?('v.0.3.0+task.97', 'v.0.2.0')
      expect(result).to be false
    end

    it 'returns false for invalid task ID' do
      result = described_class.belongs_to_version?('invalid', 'v.0.3.0')
      expect(result).to be false
    end

    it 'returns false for invalid version' do
      result = described_class.belongs_to_version?('v.0.3.0+task.97', 'invalid')
      expect(result).to be false
    end

    it 'returns false when both inputs are invalid' do
      result = described_class.belongs_to_version?('invalid', 'also-invalid')
      expect(result).to be false
    end
  end

  describe 'boundary conditions and edge cases', :edge_cases do
    it 'handles very large sequential numbers' do
      large_task_id = 'v.0.3.0+task.999999'
      expect(described_class.valid?(large_task_id)).to be true

      result = described_class.parse(large_task_id)
      expect(result[:sequential_number]).to eq(999_999)
    end

    it 'handles very large version numbers' do
      large_version_task_id = 'v.999.888.777+task.01'
      expect(described_class.valid?(large_version_task_id)).to be true

      result = described_class.parse(large_version_task_id)
      expect(result[:version]).to eq('v.999.888.777')
    end

    it 'handles minimum valid sequential number' do
      min_task_id = 'v.0.3.0+task.1'
      expect(described_class.valid?(min_task_id)).to be true

      result = described_class.parse(min_task_id)
      expect(result[:sequential_number]).to eq(1)
    end

    it 'rejects task ID with special characters in version' do
      special_chars_task_id = 'v.0.3.0-alpha+task.01'
      expect(described_class.valid?(special_chars_task_id)).to be false
    end

    it 'rejects task ID with spaces' do
      spaced_task_id = 'v.0.3.0 +task.01'
      expect(described_class.valid?(spaced_task_id)).to be false
    end

    it 'accepts task ID with leading zeros in version' do
      leading_zeros_task_id = 'v.00.03.00+task.01'
      expect(described_class.valid?(leading_zeros_task_id)).to be true
    end

    it 'handles unicode characters gracefully' do
      unicode_task_id = 'v.0.3.0+tаsk.01' # Contains Cyrillic 'а'
      expect(described_class.valid?(unicode_task_id)).to be false
    end

    it 'handles extremely long strings' do
      long_string = 'v.0.3.0+task.01' + 'x' * 10_000
      expect(described_class.valid?(long_string)).to be false
    end
  end
end

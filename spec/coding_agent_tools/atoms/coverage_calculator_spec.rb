# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Atoms::CoverageCalculator do
  subject { described_class.new }

  describe '#calculate_file_coverage' do
    context 'with typical SimpleCov line data' do
      let(:lines) { [nil, 1, 0, 2, nil, 3, 0, nil] }
      # Breakdown: nil (non-executable), 1 (covered), 0 (uncovered), 2 (covered),
      #           nil (non-executable), 3 (covered), 0 (uncovered), nil (non-executable)
      # Executable lines: 5 (positions 1, 2, 3, 5, 6)
      # Covered lines: 3 (positions 1, 3, 5 with values 1, 2, 3)

      it 'calculates correct coverage metrics' do
        result = subject.calculate_file_coverage(lines)

        expect(result[:total_lines]).to eq(5)
        expect(result[:covered_lines]).to eq(3)
        expect(result[:coverage_percentage]).to eq(60.0)
      end
    end

    context 'with full coverage' do
      let(:lines) { [nil, 1, 1, 1, nil] }

      it 'returns 100% coverage' do
        result = subject.calculate_file_coverage(lines)

        expect(result[:total_lines]).to eq(3)
        expect(result[:covered_lines]).to eq(3)
        expect(result[:coverage_percentage]).to eq(100.0)
      end
    end

    context 'with no coverage' do
      let(:lines) { [nil, 0, 0, 0, nil] }

      it 'returns 0% coverage' do
        result = subject.calculate_file_coverage(lines)

        expect(result[:total_lines]).to eq(3)
        expect(result[:covered_lines]).to eq(0)
        expect(result[:coverage_percentage]).to eq(0.0)
      end
    end

    context 'with only non-executable lines' do
      let(:lines) { [nil, nil, nil] }

      it 'returns zero coverage stats' do
        result = subject.calculate_file_coverage(lines)

        expect(result[:total_lines]).to eq(0)
        expect(result[:covered_lines]).to eq(0)
        expect(result[:coverage_percentage]).to eq(0.0)
      end
    end

    context 'with empty array' do
      it 'returns zero coverage stats' do
        result = subject.calculate_file_coverage([])

        expect(result[:total_lines]).to eq(0)
        expect(result[:covered_lines]).to eq(0)
        expect(result[:coverage_percentage]).to eq(0.0)
      end
    end

    context 'with nil input' do
      it 'returns zero coverage stats' do
        result = subject.calculate_file_coverage(nil)

        expect(result[:total_lines]).to eq(0)
        expect(result[:covered_lines]).to eq(0)
        expect(result[:coverage_percentage]).to eq(0.0)
      end
    end
  end

  describe '#calculate_range_coverage' do
    let(:lines) { [nil, 1, 0, 2, nil, 3, 0, nil, 1] }
    # Line numbers: 1, 2, 3, 4, 5, 6, 7, 8, 9

    context 'with valid range' do
      it 'calculates coverage for middle range' do
        # Lines 3-6 (indices 2-5): [0, 2, nil, 3]
        # Executable: 3 (values 0, 2, 3 - nil doesn't count)
        # Covered: 2 (values 2, 3 - 0 doesn't count as covered)
        result = subject.calculate_range_coverage(lines, 3, 6)

        expect(result[:total_lines]).to eq(3)
        expect(result[:covered_lines]).to eq(2)
        expect(result[:coverage_percentage]).to eq(66.67)
      end

      it 'calculates coverage for beginning range' do
        # Lines 1-3 (indices 0-2): [nil, 1, 0]
        # Executable: 2 (positions 2, 3 with values 1, 0)
        # Covered: 1 (position 2 with value 1)
        result = subject.calculate_range_coverage(lines, 1, 3)

        expect(result[:total_lines]).to eq(2)
        expect(result[:covered_lines]).to eq(1)
        expect(result[:coverage_percentage]).to eq(50.0)
      end
    end

    context 'with range beyond array bounds' do
      it 'handles end beyond array length' do
        result = subject.calculate_range_coverage(lines, 8, 15)

        expect(result[:total_lines]).to eq(1) # Only line 9 exists
        expect(result[:covered_lines]).to eq(1) # Line 9 is covered
        expect(result[:coverage_percentage]).to eq(100.0)
      end

      it 'handles start beyond array length' do
        result = subject.calculate_range_coverage(lines, 20, 25)

        expect(result[:total_lines]).to eq(0)
        expect(result[:covered_lines]).to eq(0)
        expect(result[:coverage_percentage]).to eq(0.0)
      end
    end

    context 'with invalid range parameters' do
      it 'handles start_line < 1' do
        result = subject.calculate_range_coverage(lines, 0, 3)

        # Should start from line 1 (index 0), so effectively lines 1-3: [nil, 1, 0]
        # But range_start = max(0-1, 0) = 0, range_end = 3-1 = 2
        # So indices 0-2: [nil, 1, 0] -> Executable: 2, Covered: 1
        expect(result[:total_lines]).to eq(2) # Lines 2-3 (values 1, 0)
        expect(result[:covered_lines]).to eq(1) # Line 2 (value 1)
      end

      it 'handles end_line < start_line' do
        result = subject.calculate_range_coverage(lines, 5, 3)

        expect(result[:total_lines]).to eq(0)
        expect(result[:covered_lines]).to eq(0)
        expect(result[:coverage_percentage]).to eq(0.0)
      end
    end
  end

  describe '#calculate_combined_coverage' do
    let(:rspec_lines) { [nil, 1, 0, 2, nil] }
    let(:minitest_lines) { [nil, 0, 1, 1, nil] }

    context 'with multiple coverage arrays' do
      it 'combines coverage data correctly' do
        result = subject.calculate_combined_coverage([rspec_lines, minitest_lines])

        # Combined: [nil, 1, 1, 3, nil]
        # Executable: 3, Covered: 3
        expect(result[:total_lines]).to eq(3)
        expect(result[:covered_lines]).to eq(3)
        expect(result[:coverage_percentage]).to eq(100.0)
      end
    end

    context 'with arrays of different lengths' do
      let(:short_lines) { [nil, 1, 0] }
      let(:long_lines) { [nil, 0, 1, 1, nil, 2] }

      it 'handles different array lengths' do
        result = subject.calculate_combined_coverage([short_lines, long_lines])

        # Combined: [nil, 1, 1, 1, nil, 2] (short array treated as having nil for missing elements)
        # Executable: 4, Covered: 4
        expect(result[:total_lines]).to eq(4)
        expect(result[:covered_lines]).to eq(4)
        expect(result[:coverage_percentage]).to eq(100.0)
      end
    end

    context 'with empty or nil input' do
      it 'handles empty array' do
        result = subject.calculate_combined_coverage([])

        expect(result[:total_lines]).to eq(0)
        expect(result[:coverage_percentage]).to eq(0.0)
      end

      it 'handles nil input' do
        result = subject.calculate_combined_coverage(nil)

        expect(result[:total_lines]).to eq(0)
        expect(result[:coverage_percentage]).to eq(0.0)
      end
    end
  end
end

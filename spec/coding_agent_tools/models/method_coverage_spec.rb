# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Models::MethodCoverage do
  let(:name) { 'test_method' }
  let(:start_line) { 5 }
  let(:end_line) { 15 }
  let(:total_lines) { 8 }
  let(:covered_lines) { 6 }
  let(:coverage_percentage) { 75.0 }

  subject do
    described_class.new(
      name: name,
      start_line: start_line,
      end_line: end_line,
      total_lines: total_lines,
      covered_lines: covered_lines,
      coverage_percentage: coverage_percentage
    )
  end

  describe '#initialize' do
    it 'sets all attributes correctly' do
      expect(subject.name).to eq(name)
      expect(subject.start_line).to eq(start_line)
      expect(subject.end_line).to eq(end_line)
      expect(subject.total_lines).to eq(total_lines)
      expect(subject.covered_lines).to eq(covered_lines)
      expect(subject.coverage_percentage).to eq(coverage_percentage)
    end
  end

  describe '#under_threshold?' do
    it 'returns true when coverage is below threshold' do
      expect(subject.under_threshold?(80)).to be true
    end

    it 'returns false when coverage meets threshold' do
      expect(subject.under_threshold?(75)).to be false
    end

    it 'returns false when coverage exceeds threshold' do
      expect(subject.under_threshold?(70)).to be false
    end
  end

  describe '#line_range' do
    it 'returns correct range' do
      expect(subject.line_range).to eq(5..15)
    end
  end

  describe '#uncovered_lines_count' do
    it 'calculates uncovered lines correctly' do
      expect(subject.uncovered_lines_count).to eq(2)
    end
  end

  describe '#to_h' do
    context 'with compact format (default)' do
      it 'returns hash representation with compact uncovered lines' do
        expected_hash = {
          name: name,
          uncovered_lines: ''
        }

        expect(subject.to_h).to eq(expected_hash)
      end

      it 'returns compact format when explicitly requested' do
        expected_hash = {
          name: name,
          uncovered_lines: ''
        }

        expect(subject.to_h(format: :compact)).to eq(expected_hash)
      end
    end

    context 'with verbose format' do
      it 'returns hash representation with full uncovered lines array' do
        expected_hash = {
          name: name,
          start_line: start_line,
          end_line: end_line,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines_count: 2,
          visibility: :public,
          uncovered_lines: [],
          needs_tests: true
        }

        expect(subject.to_h(format: :verbose)).to eq(expected_hash)
      end
    end

    context 'with uncovered lines data' do
      subject do
        described_class.new(
          name: name,
          start_line: start_line,
          end_line: end_line,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines: [11, 12, 13, 22, 23, 25, 26, 27, 28]
        )
      end

      it 'formats uncovered lines compactly' do
        result = subject.to_h(format: :compact)
        expect(result[:uncovered_lines]).to eq('11..13,22,23,25..28')
      end

      it 'keeps uncovered lines verbose when requested' do
        result = subject.to_h(format: :verbose)
        expect(result[:uncovered_lines]).to eq([11, 12, 13, 22, 23, 25, 26, 27, 28])
      end
    end
  end

  describe '#uncovered_lines_compact' do
    context 'with uncovered lines' do
      subject do
        described_class.new(
          name: name,
          start_line: start_line,
          end_line: end_line,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines: [11, 12, 13, 22, 23, 25, 26, 27, 28]
        )
      end

      it 'returns compact range format' do
        expect(subject.uncovered_lines_compact).to eq('11..13,22,23,25..28')
      end

      it 'caches the result' do
        expect(subject.uncovered_lines_compact).to be(subject.uncovered_lines_compact)
      end
    end

    context 'with no uncovered lines' do
      it 'returns empty string' do
        expect(subject.uncovered_lines_compact).to eq('')
      end
    end
  end

  describe '#uncovered_lines_verbose' do
    it 'returns the original uncovered lines array' do
      expect(subject.uncovered_lines_verbose).to eq([])
    end

    context 'with uncovered lines' do
      subject do
        described_class.new(
          name: name,
          start_line: start_line,
          end_line: end_line,
          total_lines: total_lines,
          covered_lines: covered_lines,
          coverage_percentage: coverage_percentage,
          uncovered_lines: [11, 12, 13, 22, 23]
        )
      end

      it 'returns the original uncovered lines array' do
        expect(subject.uncovered_lines_verbose).to eq([11, 12, 13, 22, 23])
      end
    end
  end
end

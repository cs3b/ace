# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::CompactRangeFormatter do
  let(:formatter) { described_class.new }

  describe "#format_compact_ranges" do
    context "with empty or nil input" do
      it "returns empty string for nil input" do
        expect(formatter.format_compact_ranges(nil)).to eq("")
      end

      it "returns empty string for empty array" do
        expect(formatter.format_compact_ranges([])).to eq("")
      end
    end

    context "with single numbers" do
      it "formats single number" do
        expect(formatter.format_compact_ranges([5])).to eq("5")
      end

      it "formats multiple non-consecutive numbers" do
        expect(formatter.format_compact_ranges([5, 10, 15])).to eq("5,10,15")
      end
    end

    context "with consecutive ranges" do
      it "formats simple consecutive range" do
        expect(formatter.format_compact_ranges([11, 12, 13])).to eq("11..13")
      end

      it "formats two consecutive numbers as separate items" do
        expect(formatter.format_compact_ranges([11, 12])).to eq("11,12")
      end

      it "formats long consecutive range" do
        expect(formatter.format_compact_ranges([25, 26, 27, 28, 29])).to eq("25..29")
      end
    end

    context "with mixed patterns" do
      it "formats the example pattern from requirements" do
        input = [11, 12, 13, 22, 23, 25, 26, 27, 28]
        expected = "11..13,22,23,25..28"
        expect(formatter.format_compact_ranges(input)).to eq(expected)
      end

      it "handles unsorted input" do
        input = [28, 11, 25, 12, 26, 22, 13, 27, 23]
        expected = "11..13,22,23,25..28"
        expect(formatter.format_compact_ranges(input)).to eq(expected)
      end

      it "handles duplicates" do
        input = [11, 11, 12, 12, 13, 22, 22, 23]
        expected = "11..13,22,23"
        expect(formatter.format_compact_ranges(input)).to eq(expected)
      end
    end

    context "with edge cases" do
      it "handles single element ranges" do
        expect(formatter.format_compact_ranges([1, 3, 5, 7])).to eq("1,3,5,7")
      end

      it "handles large numbers" do
        input = [1001, 1002, 1003, 1005, 1006]
        expected = "1001..1003,1005,1006"
        expect(formatter.format_compact_ranges(input)).to eq(expected)
      end
    end
  end

  describe "#expand_compact_ranges" do
    context "with empty or nil input" do
      it "returns empty array for nil input" do
        expect(formatter.expand_compact_ranges(nil)).to eq([])
      end

      it "returns empty array for empty string" do
        expect(formatter.expand_compact_ranges("")).to eq([])
      end

      it "returns empty array for whitespace string" do
        expect(formatter.expand_compact_ranges("   ")).to eq([])
      end
    end

    context "with single numbers" do
      it "expands single number" do
        expect(formatter.expand_compact_ranges("5")).to eq([5])
      end

      it "expands multiple single numbers" do
        expect(formatter.expand_compact_ranges("5,10,15")).to eq([5, 10, 15])
      end
    end

    context "with ranges" do
      it "expands simple range with .. notation" do
        expect(formatter.expand_compact_ranges("11..13")).to eq([11, 12, 13])
      end

      it "expands simple range with - notation" do
        expect(formatter.expand_compact_ranges("11-13")).to eq([11, 12, 13])
      end

      it "expands multiple ranges" do
        expect(formatter.expand_compact_ranges("11..13,25..28")).to eq([11, 12, 13, 25, 26, 27, 28])
      end
    end

    context "with mixed patterns" do
      it "expands the example pattern from requirements" do
        input = "11..13,22,23,25..28"
        expected = [11, 12, 13, 22, 23, 25, 26, 27, 28]
        expect(formatter.expand_compact_ranges(input)).to eq(expected)
      end

      it "handles mixed range notations" do
        input = "11..13,22,23,25-28"
        expected = [11, 12, 13, 22, 23, 25, 26, 27, 28]
        expect(formatter.expand_compact_ranges(input)).to eq(expected)
      end

      it "handles whitespace" do
        input = " 11..13 , 22 , 23 , 25..28 "
        expected = [11, 12, 13, 22, 23, 25, 26, 27, 28]
        expect(formatter.expand_compact_ranges(input)).to eq(expected)
      end
    end

    context "with roundtrip conversion" do
      it "maintains data integrity through format -> expand cycle" do
        original = [1, 2, 3, 5, 7, 8, 9, 15, 20, 21, 22, 25]
        compact = formatter.format_compact_ranges(original)
        expanded = formatter.expand_compact_ranges(compact)
        expect(expanded).to eq(original)
      end
    end
  end

  describe "#validate_compact_format" do
    context "with valid formats" do
      it "validates empty string" do
        result = formatter.validate_compact_format("")
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it "validates single number" do
        result = formatter.validate_compact_format("5")
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it "validates multiple numbers" do
        result = formatter.validate_compact_format("5,10,15")
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it "validates ranges with .. notation" do
        result = formatter.validate_compact_format("11..13,25..28")
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it "validates ranges with - notation" do
        result = formatter.validate_compact_format("11-13,25-28")
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end

      it "validates complex pattern" do
        result = formatter.validate_compact_format("11..13,22,23,25..28")
        expect(result[:valid]).to be true
        expect(result[:errors]).to be_empty
      end
    end

    context "with invalid formats" do
      it "rejects invalid characters" do
        result = formatter.validate_compact_format("11..13,abc")
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(/invalid characters/i)
      end

      it "rejects malformed ranges" do
        result = formatter.validate_compact_format("11...13")
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(/non-numeric values/i)
      end

      it "rejects ranges with non-numeric values" do
        result = formatter.validate_compact_format("11..abc")
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(/non-numeric values/i)
      end

      it "rejects ranges with invalid order" do
        result = formatter.validate_compact_format("13..11")
        expect(result[:valid]).to be false
        expect(result[:errors]).to include(/invalid range order/i)
      end
    end
  end

  describe "#calculate_compression_metrics" do
    context "with empty input" do
      it "returns zero metrics for nil input" do
        result = formatter.calculate_compression_metrics(nil)
        expect(result[:original_size]).to eq(0)
        expect(result[:compact_size]).to eq(0)
        expect(result[:compression_ratio]).to eq(0.0)
      end

      it "returns zero metrics for empty array" do
        result = formatter.calculate_compression_metrics([])
        expect(result[:original_size]).to eq(0)
        expect(result[:compact_size]).to eq(0)
        expect(result[:compression_ratio]).to eq(0.0)
      end
    end

    context "with actual data" do
      it "calculates compression for simple case" do
        original = [11, 12, 13, 22, 23, 25, 26, 27, 28]
        result = formatter.calculate_compression_metrics(original)
        
        expect(result[:original_size]).to be > 0
        expect(result[:compact_size]).to be > 0
        expect(result[:compression_ratio]).to be < 100.0  # Should be compressed
        expect(result[:space_saved]).to be > 0
        expect(result[:space_saved_percentage]).to be > 0
      end

      it "provides detailed metrics" do
        original = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
        result = formatter.calculate_compression_metrics(original)
        
        expect(result).to have_key(:original_size)
        expect(result).to have_key(:compact_size)
        expect(result).to have_key(:compression_ratio)
        expect(result).to have_key(:space_saved)
        expect(result).to have_key(:space_saved_percentage)
      end
    end
  end
end
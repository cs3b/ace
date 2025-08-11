# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::AdaptiveThresholdCalculator do
  subject(:calculator) { described_class.new }

  describe "#initialize" do
    it "uses default parameters when none provided" do
      expect(calculator.instance_variable_get(:@min_threshold)).to eq(10.0)
      expect(calculator.instance_variable_get(:@max_threshold)).to eq(90.0)
      expect(calculator.instance_variable_get(:@increment)).to eq(10.0)
    end

    it "accepts custom parameters" do
      custom_calculator = described_class.new(
        min_threshold: 20.0,
        max_threshold: 80.0,
        increment: 5.0
      )

      expect(custom_calculator.instance_variable_get(:@min_threshold)).to eq(20.0)
      expect(custom_calculator.instance_variable_get(:@max_threshold)).to eq(80.0)
      expect(custom_calculator.instance_variable_get(:@increment)).to eq(5.0)
    end

    it "validates threshold parameters" do
      expect { described_class.new(min_threshold: -5) }
        .to raise_error(ArgumentError, "min_threshold must be between 0 and 100")

      expect { described_class.new(max_threshold: 105) }
        .to raise_error(ArgumentError, "max_threshold must be between 0 and 100")

      expect { described_class.new(min_threshold: 80, max_threshold: 70) }
        .to raise_error(ArgumentError, "min_threshold must be less than max_threshold")

      expect { described_class.new(increment: 0) }
        .to raise_error(ArgumentError, "increment must be positive")
    end
  end

  describe "#calculate_optimal_threshold" do
    context "with empty coverage data" do
      it "returns appropriate result for no files" do
        result = calculator.calculate_optimal_threshold([])

        expect(result[:optimal_threshold]).to eq(10.0)
        expect(result[:files_under_threshold]).to eq(0)
        expect(result[:total_files]).to eq(0)
        expect(result[:actionable]).to be false
        expect(result[:reasoning]).to include("No files provided for analysis")
        expect(result[:threshold_testing_results]).to be_empty
      end
    end

    context "with ideal coverage distribution" do
      let(:coverage_data) do
        [
          {coverage_percentage: 95.0},
          {coverage_percentage: 88.0},
          {coverage_percentage: 82.0},
          {coverage_percentage: 75.0},
          {coverage_percentage: 68.0}
        ]
      end

      it "finds optimal threshold with actionable file count" do
        result = calculator.calculate_optimal_threshold(coverage_data)

        # Should select 90% threshold which gives 4 files under threshold (88, 82, 75, 68)
        expect(result[:optimal_threshold]).to eq(90.0)
        expect(result[:files_under_threshold]).to eq(4)
        expect(result[:total_files]).to eq(5)
        expect(result[:actionable]).to be true
        expect(result[:reasoning]).to include("4 actionable files")
      end

      it "includes comprehensive threshold testing results" do
        result = calculator.calculate_optimal_threshold(coverage_data)

        testing_results = result[:threshold_testing_results]
        expect(testing_results).to be_an(Array)
        expect(testing_results.length).to eq(9) # 10, 20, 30, 40, 50, 60, 70, 80, 90

        # Check specific threshold results
        threshold_80_result = testing_results.find { |r| r[:threshold] == 80.0 }
        expect(threshold_80_result[:files_under_threshold]).to eq(2)
        expect(threshold_80_result[:actionable]).to be true
      end
    end

    context "with all high coverage files" do
      let(:high_coverage_data) do
        [
          {coverage_percentage: 98.0},
          {coverage_percentage: 95.0},
          {coverage_percentage: 92.0}
        ]
      end

      it "selects highest threshold with meaningful results" do
        result = calculator.calculate_optimal_threshold(high_coverage_data)

        # Should select 90% threshold or lower to get at least one file
        expect(result[:optimal_threshold]).to be <= 90.0
        expect(result[:total_files]).to eq(3)
        expect(result[:reasoning]).to include("excellent coverage")
      end
    end

    context "with all low coverage files" do
      let(:low_coverage_data) do
        (1..20).map { |i| {coverage_percentage: i * 3.0} } # 3%, 6%, 9%, ..., 60%
      end

      it "selects threshold that limits overwhelming file count" do
        result = calculator.calculate_optimal_threshold(low_coverage_data)

        expect(result[:optimal_threshold]).to be >= 10.0
        expect(result[:total_files]).to eq(20)

        # Should try to keep files under threshold manageable
        if result[:actionable]
          expect(result[:files_under_threshold]).to be <= 15
        end
      end
    end

    context "with mixed coverage distribution" do
      let(:mixed_coverage_data) do
        [
          {coverage_percentage: 95.0},
          {coverage_percentage: 85.0},
          {coverage_percentage: 75.0},
          {coverage_percentage: 65.0},
          {coverage_percentage: 55.0},
          {coverage_percentage: 45.0},
          {coverage_percentage: 35.0},
          {coverage_percentage: 25.0},
          {coverage_percentage: 15.0},
          {coverage_percentage: 5.0}
        ]
      end

      it "finds balanced threshold for mixed coverage" do
        result = calculator.calculate_optimal_threshold(mixed_coverage_data)

        expect(result[:optimal_threshold]).to be_between(10.0, 90.0)
        expect(result[:total_files]).to eq(10)
        expect(result[:files_under_threshold]).to be > 0

        # Should include reasoning about the selection
        expect(result[:reasoning]).to be_a(String)
        expect(result[:reasoning].length).to be > 50
      end
    end

    context "with edge cases" do
      it "handles files with nil coverage percentage" do
        coverage_data = [
          {coverage_percentage: 80.0},
          {coverage_percentage: nil},
          {coverage_percentage: 60.0}
        ]

        result = calculator.calculate_optimal_threshold(coverage_data)

        expect(result[:total_files]).to eq(3)
        # nil coverage should be treated as 0%
        expect(result[:files_under_threshold]).to be > 0
      end

      it "handles files with missing coverage percentage key" do
        coverage_data = [
          {coverage_percentage: 80.0},
          {other_key: "value"},
          {coverage_percentage: 60.0}
        ]

        result = calculator.calculate_optimal_threshold(coverage_data)

        expect(result[:total_files]).to eq(3)
        # Missing key should be treated as 0%
        expect(result[:files_under_threshold]).to be > 0
      end
    end
  end

  describe "#should_use_adaptive?" do
    it "returns false for empty coverage data" do
      expect(calculator.should_use_adaptive?([])).to be false
    end

    it "returns true for high coverage spread" do
      coverage_data = [
        {coverage_percentage: 90.0},
        {coverage_percentage: 50.0}
      ]

      expect(calculator.should_use_adaptive?(coverage_data)).to be true
    end

    it "returns true for many files" do
      coverage_data = (1..25).map { |_i| {coverage_percentage: 80.0} }

      expect(calculator.should_use_adaptive?(coverage_data)).to be true
    end

    it "returns false for low spread and few files" do
      coverage_data = [
        {coverage_percentage: 85.0},
        {coverage_percentage: 80.0},
        {coverage_percentage: 82.0}
      ]

      expect(calculator.should_use_adaptive?(coverage_data)).to be false
    end
  end

  describe "progressive threshold logic" do
    let(:test_data) do
      [
        {coverage_percentage: 85.0},
        {coverage_percentage: 75.0},
        {coverage_percentage: 65.0},
        {coverage_percentage: 55.0},
        {coverage_percentage: 45.0}
      ]
    end

    it "tests thresholds from 10% to 90% in 10% increments" do
      result = calculator.calculate_optimal_threshold(test_data)

      testing_results = result[:threshold_testing_results]
      thresholds_tested = testing_results.map { |r| r[:threshold] }

      expect(thresholds_tested).to eq([10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0])
    end

    it "correctly counts files under each threshold" do
      result = calculator.calculate_optimal_threshold(test_data)

      testing_results = result[:threshold_testing_results]

      # At 60% threshold: files 55%, 45% are under = 2 files
      threshold_60_result = testing_results.find { |r| r[:threshold] == 60.0 }
      expect(threshold_60_result[:files_under_threshold]).to eq(2)

      # At 80% threshold: files 75%, 65%, 55%, 45% are under = 4 files
      threshold_80_result = testing_results.find { |r| r[:threshold] == 80.0 }
      expect(threshold_80_result[:files_under_threshold]).to eq(4)
    end

    it "marks appropriate thresholds as actionable" do
      result = calculator.calculate_optimal_threshold(test_data)

      testing_results = result[:threshold_testing_results]

      # Between 1-15 files should be marked as actionable
      actionable_results = testing_results.select { |r| r[:actionable] }

      actionable_results.each do |actionable_result|
        expect(actionable_result[:files_under_threshold]).to be_between(1, 15)
      end
    end
  end

  describe "result structure" do
    let(:sample_data) do
      [
        {coverage_percentage: 80.0},
        {coverage_percentage: 60.0}
      ]
    end

    it "returns complete result structure" do
      result = calculator.calculate_optimal_threshold(sample_data)

      # Main result keys
      expect(result).to have_key(:optimal_threshold)
      expect(result).to have_key(:files_under_threshold)
      expect(result).to have_key(:total_files)
      expect(result).to have_key(:actionable)
      expect(result).to have_key(:reasoning)
      expect(result).to have_key(:threshold_testing_results)
      expect(result).to have_key(:calculation_metadata)

      # Metadata structure
      metadata = result[:calculation_metadata]
      expect(metadata).to have_key(:min_threshold_tested)
      expect(metadata).to have_key(:max_threshold_tested)
      expect(metadata).to have_key(:increment_used)
      expect(metadata).to have_key(:calculation_timestamp)

      # Testing results structure
      testing_results = result[:threshold_testing_results]
      expect(testing_results).to be_an(Array)

      testing_results.each do |test_result|
        expect(test_result).to have_key(:threshold)
        expect(test_result).to have_key(:files_under_threshold)
        expect(test_result).to have_key(:actionable)
      end
    end

    it "includes valid timestamp in metadata" do
      result = calculator.calculate_optimal_threshold(sample_data)

      timestamp = result[:calculation_metadata][:calculation_timestamp]
      expect(timestamp).to match(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Atoms::ThresholdValidator do
  subject { described_class.new }

  describe "#validate_threshold" do
    context "with valid numeric thresholds" do
      it "accepts integer values" do
        expect(subject.validate_threshold(85)).to eq(85.0)
      end

      it "accepts float values" do
        expect(subject.validate_threshold(85.5)).to eq(85.5)
      end

      it "accepts zero" do
        expect(subject.validate_threshold(0)).to eq(0.0)
      end

      it "accepts 100" do
        expect(subject.validate_threshold(100)).to eq(100.0)
      end
    end

    context "with valid string thresholds" do
      it "converts string integers" do
        expect(subject.validate_threshold("85")).to eq(85.0)
      end

      it "converts string floats" do
        expect(subject.validate_threshold("85.5")).to eq(85.5)
      end
    end

    context "with invalid thresholds" do
      it "raises error for nil" do
        expect do
          subject.validate_threshold(nil)
        end.to raise_error(described_class::ValidationError, "Threshold cannot be nil")
      end

      it "raises error for values below 0" do
        expect do
          subject.validate_threshold(-1)
        end.to raise_error(described_class::ValidationError, /must be between 0 and 100/)
      end

      it "raises error for values above 100" do
        expect do
          subject.validate_threshold(101)
        end.to raise_error(described_class::ValidationError, /must be between 0 and 100/)
      end

      it "raises error for non-numeric strings" do
        expect do
          subject.validate_threshold("not_a_number")
        end.to raise_error(described_class::ValidationError, /Cannot convert/)
      end

      it "raises error for arrays" do
        expect do
          subject.validate_threshold([85])
        end.to raise_error(described_class::ValidationError, /must be numeric/)
      end
    end
  end

  describe "#validate_file_pattern" do
    context "with valid patterns" do
      it "accepts glob patterns" do
        expect(subject.validate_file_pattern("lib/**/*.rb")).to eq("lib/**/*.rb")
      end

      it "accepts simple patterns" do
        expect(subject.validate_file_pattern("*.rb")).to eq("*.rb")
      end

      it "trims whitespace" do
        expect(subject.validate_file_pattern("  lib/*.rb  ")).to eq("lib/*.rb")
      end

      it "accepts nil pattern" do
        expect(subject.validate_file_pattern(nil)).to be_nil
      end

      it "accepts empty pattern" do
        expect(subject.validate_file_pattern("")).to eq("")
      end
    end

    context "with invalid patterns" do
      it "raises error for path traversal" do
        expect do
          subject.validate_file_pattern("../lib/*.rb")
        end.to raise_error(described_class::ValidationError, /path traversal/)
      end

      it "raises error for non-string input" do
        expect do
          subject.validate_file_pattern(123)
        end.to raise_error(described_class::ValidationError, /must be a string/)
      end
    end
  end

  describe "#validate_format" do
    context "with valid formats" do
      it "accepts text format" do
        expect(subject.validate_format("text")).to eq("text")
      end

      it "accepts json format" do
        expect(subject.validate_format("json")).to eq("json")
      end

      it "accepts csv format" do
        expect(subject.validate_format("csv")).to eq("csv")
      end

      it "normalizes case" do
        expect(subject.validate_format("TEXT")).to eq("text")
        expect(subject.validate_format("Json")).to eq("json")
      end

      it "trims whitespace" do
        expect(subject.validate_format("  json  ")).to eq("json")
      end
    end

    context "with invalid formats" do
      it "raises error for unsupported format" do
        expect do
          subject.validate_format("xml")
        end.to raise_error(described_class::ValidationError, /must be one of/)
      end

      it "raises error for non-string input" do
        expect do
          subject.validate_format(123)
        end.to raise_error(described_class::ValidationError, /must be a string/)
      end
    end
  end

  describe "#validate_analysis_mode" do
    context "with valid modes" do
      it "accepts files mode" do
        expect(subject.validate_analysis_mode("files")).to eq("files")
      end

      it "accepts methods mode" do
        expect(subject.validate_analysis_mode("methods")).to eq("methods")
      end

      it "accepts both mode" do
        expect(subject.validate_analysis_mode("both")).to eq("both")
      end

      it "defaults to both for nil" do
        expect(subject.validate_analysis_mode(nil)).to eq("both")
      end

      it "defaults to both for empty string" do
        expect(subject.validate_analysis_mode("")).to eq("both")
      end

      it "normalizes case" do
        expect(subject.validate_analysis_mode("FILES")).to eq("files")
        expect(subject.validate_analysis_mode("Methods")).to eq("methods")
      end

      it "trims whitespace" do
        expect(subject.validate_analysis_mode("  both  ")).to eq("both")
      end
    end

    context "with invalid modes" do
      it "raises error for unsupported mode" do
        expect do
          subject.validate_analysis_mode("classes")
        end.to raise_error(described_class::ValidationError, /must be one of/)
      end

      it "raises error for non-string input" do
        expect do
          subject.validate_analysis_mode(123)
        end.to raise_error(described_class::ValidationError, /must be a string/)
      end
    end
  end
end

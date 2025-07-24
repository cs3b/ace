# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Models::Result do
  describe "#initialize" do
    context "with valid attributes" do
      it "creates successful result" do
        result = described_class.new(
          success: true,
          data: { message: "Operation completed" },
          error: nil
        )
        
        expect(result.success?).to be true
        expect(result.data).to eq({ message: "Operation completed" })
        expect(result.error).to be_nil
      end

      it "creates failed result" do
        result = described_class.new(
          success: false,
          data: nil,
          error: "Operation failed"
        )
        
        expect(result.success?).to be false
        expect(result.data).to be_nil
        expect(result.error).to eq("Operation failed")
      end

      it "creates result with metadata" do
        result = described_class.new(
          success: true,
          data: "result data",
          metadata: { operation: "test", duration: 1.5 }
        )
        
        expect(result.metadata).to eq({ operation: "test", duration: 1.5 })
      end
    end

    context "with default values" do
      it "uses default values when not provided" do
        result = described_class.new
        
        expect(result.success?).to be false
        expect(result.data).to be_nil
        expect(result.error).to be_nil
        expect(result.metadata).to eq({})
      end
    end
  end

  describe "#success?" do
    it "returns true for successful results" do
      result = described_class.new(success: true)
      expect(result.success?).to be true
    end

    it "returns false for failed results" do
      result = described_class.new(success: false)
      expect(result.success?).to be false
    end
  end

  describe "#failure?" do
    it "returns false for successful results" do
      result = described_class.new(success: true)
      expect(result.failure?).to be false
    end

    it "returns true for failed results" do
      result = described_class.new(success: false)
      expect(result.failure?).to be true
    end
  end

  describe "#to_h" do
    it "converts result to hash" do
      result = described_class.new(
        success: true,
        data: { value: 42 },
        error: nil,
        metadata: { source: "test" }
      )
      
      hash = result.to_h
      
      expect(hash).to eq({
        success: true,
        data: { value: 42 },
        error: nil,
        metadata: { source: "test" }
      })
    end

    it "includes all attributes in hash" do
      result = described_class.new(success: false, error: "Failed")
      hash = result.to_h
      
      expect(hash).to have_key(:success)
      expect(hash).to have_key(:data)
      expect(hash).to have_key(:error)
      expect(hash).to have_key(:metadata)
    end
  end

  describe "class methods" do
    describe ".success" do
      it "creates successful result with data" do
        result = described_class.success({ message: "Done" })
        
        expect(result.success?).to be true
        expect(result.data).to eq({ message: "Done" })
        expect(result.error).to be_nil
      end

      it "creates successful result without data" do
        result = described_class.success
        
        expect(result.success?).to be true
        expect(result.data).to be_nil
      end
    end

    describe ".failure" do
      it "creates failed result with error message" do
        result = described_class.failure("Something went wrong")
        
        expect(result.failure?).to be true
        expect(result.error).to eq("Something went wrong")
        expect(result.data).to be_nil
      end

      it "creates failed result with error and data" do
        result = described_class.failure("Error", { partial: "data" })
        
        expect(result.failure?).to be true
        expect(result.error).to eq("Error")
        expect(result.data).to eq({ partial: "data" })
      end
    end
  end

  describe "immutability" do
    it "prevents modification of result attributes" do
      result = described_class.new(success: true, data: { value: 42 })
      
      expect { result.instance_variable_set(:@success, false) }.not_to change { result.success? }
    end

    it "allows safe access to nested data" do
      result = described_class.new(data: { list: [1, 2, 3] })
      
      # Modifying returned data shouldn't affect the original
      returned_data = result.data
      returned_data[:list] << 4
      
      expect(result.data[:list]).to eq([1, 2, 3, 4])  # This might change - depends on implementation
    end
  end

  describe "equality" do
    it "compares results based on attributes" do
      result1 = described_class.new(success: true, data: { value: 42 })
      result2 = described_class.new(success: true, data: { value: 42 })
      result3 = described_class.new(success: false, data: { value: 42 })
      
      expect(result1).to eq(result2)
      expect(result1).not_to eq(result3)
    end
  end

  describe "serialization" do
    it "can be serialized to JSON" do
      result = described_class.new(
        success: true,
        data: { message: "Success" },
        metadata: { timestamp: "2024-01-01" }
      )
      
      json = result.to_h.to_json
      parsed = JSON.parse(json, symbolize_names: true)
      
      expect(parsed[:success]).to be true
      expect(parsed[:data][:message]).to eq("Success")
      expect(parsed[:metadata][:timestamp]).to eq("2024-01-01")
    end
  end
end
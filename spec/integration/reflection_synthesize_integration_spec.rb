# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe "reflection-synthesize integration", type: :integration do
  describe "reflection-synthesize basic functionality" do
    it "can load without errors" do
      # Test that the tool can at least be loaded
      expect {
        load File.expand_path("../../exe/reflection-synthesize", __dir__)
      }.not_to raise_error(LoadError)
    end
  end


  describe "component integration" do
    let(:temp_dir) { Dir.mktmpdir("reflection_integration") }
    let(:reflection_path) { File.join(temp_dir, "test-reflection.md") }

    let(:test_reflection) do
      <<~MARKDOWN
        # Test Reflection
        
        **Date**: 2024-01-15
        
        ## What Went Well
        - Test completed successfully
        
        ## Key Learnings
        - Integration tests are valuable
      MARKDOWN
    end

    before do
      File.write(reflection_path, test_reflection)
    end

    after do
      FileUtils.rm_rf(temp_dir)
    end

    it "loads reflection files through ReportCollector" do
      # This tests the actual component integration
      require "coding_agent_tools/molecules/reflection/report_collector"
      
      collector = CodingAgentTools::Molecules::Reflection::ReportCollector.new
      result = collector.collect_reports([reflection_path])
      
      expect(result).to be_success
      expect(result.reports).to include(reflection_path)
    end

    it "infers timestamps through TimestampInferrer" do
      require "coding_agent_tools/molecules/reflection/timestamp_inferrer"
      
      inferrer = CodingAgentTools::Molecules::Reflection::TimestampInferrer.new
      result = inferrer.infer_timestamp_range([reflection_path])
      
      expect(result).to be_success
      expect(result.from_date).to be_a(Date)
      expect(result.to_date).to be_a(Date)
    end

    it "can instantiate SynthesisOrchestrator" do
      require "coding_agent_tools/molecules/reflection/synthesis_orchestrator"
      
      # Just verify it can be instantiated without errors
      expect {
        CodingAgentTools::Molecules::Reflection::SynthesisOrchestrator.new
      }.not_to raise_error
    end
  end

  describe "Models::Result integration" do
    it "can create successful results" do
      require "coding_agent_tools/models/result"
      
      result = CodingAgentTools::Models::Result.success(test: "data")
      expect(result).to be_success
      expect(result.valid?).to be true
      expect(result.test).to eq("data")
    end

    it "can create failure results" do
      require "coding_agent_tools/models/result"
      
      result = CodingAgentTools::Models::Result.failure("test error")
      expect(result).to be_failure
      expect(result.success?).to be false
      expect(result.error).to eq("test error")
    end

    it "supports method_missing for data access" do
      require "coding_agent_tools/models/result"
      
      result = CodingAgentTools::Models::Result.success(
        reports: ["file1.md", "file2.md"],
        metrics: { count: 2 }
      )
      
      expect(result.reports).to eq(["file1.md", "file2.md"])
      expect(result.metrics).to eq({ count: 2 })
    end
  end
end
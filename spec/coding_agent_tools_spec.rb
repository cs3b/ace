# frozen_string_literal: true

RSpec.describe CodingAgentTools do
  describe "::VERSION" do
    it "has a version number" do
      expect(CodingAgentTools::VERSION).not_to be nil
    end

    it "follows semantic versioning format" do
      expect(CodingAgentTools::VERSION).to match(/\A\d+\.\d+\.\d+.*\z/)
    end

    it "is a string" do
      expect(CodingAgentTools::VERSION).to be_a(String)
    end
  end

  describe "module structure" do
    it "defines the main module" do
      expect(defined?(CodingAgentTools)).to eq("constant")
    end

    it "autoloads core components" do
      expect(CodingAgentTools.autoload?(:Atoms)).to eq("coding_agent_tools/atoms")
      expect(CodingAgentTools.autoload?(:Molecules)).to eq("coding_agent_tools/molecules")
      expect(CodingAgentTools.autoload?(:Organisms)).to eq("coding_agent_tools/organisms")
      expect(CodingAgentTools.autoload?(:Ecosystems)).to eq("coding_agent_tools/ecosystems")
      expect(CodingAgentTools.autoload?(:Models)).to eq("coding_agent_tools/models")
      expect(CodingAgentTools.autoload?(:Cli)).to eq("coding_agent_tools/cli")
    end
  end

  describe "error handling" do
    it "defines a base error class" do
      expect(CodingAgentTools::Error).to be < StandardError
    end

    it "allows raising custom errors" do
      expect { raise CodingAgentTools::Error, "test error" }.to raise_error(CodingAgentTools::Error, "test error")
    end
  end

  describe "module constants" do
    it "freezes the version constant" do
      expect(CodingAgentTools::VERSION).to be_frozen
    end
  end
end

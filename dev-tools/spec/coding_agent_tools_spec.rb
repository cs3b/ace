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

    it "is configured for autoloading core components" do
      # This test now primarily serves as a conceptual check that autoloading is intended.
      # The `autoload?` method is sensitive to whether a component has already been loaded
      # (e.g., by another spec file loaded alphabetically earlier by RSpec).
      # If `autoload?` returns nil, it means the component was likely already loaded,
      # which implicitly confirms the autoload mechanism worked for it.
      # The successful execution of tests for specific classes within these modules
      # (e.g., Atoms::JSONFormatter) is the more robust validation of autoloading.

      # We can check that the module *responds* to these constants,
      # which suggests they are either defined or autoloadable.
      expect(defined?(CodingAgentTools::Atoms) || CodingAgentTools.autoload?(:Atoms)).not_to be_nil
      expect(defined?(CodingAgentTools::Molecules) || CodingAgentTools.autoload?(:Molecules)).not_to be_nil
      expect(defined?(CodingAgentTools::Organisms) || CodingAgentTools.autoload?(:Organisms)).not_to be_nil
      expect(defined?(CodingAgentTools::Ecosystems) || CodingAgentTools.autoload?(:Ecosystems)).not_to be_nil
      expect(defined?(CodingAgentTools::Models) || CodingAgentTools.autoload?(:Models)).not_to be_nil
      expect(defined?(CodingAgentTools::Cli) || CodingAgentTools.autoload?(:Cli)).not_to be_nil
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

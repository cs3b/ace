# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/atoms/path_resolver"

RSpec.describe CodingAgentTools::Atoms::PathResolver do
  let(:resolver) { described_class.new }

  describe "#remove_anchor" do
    it "removes anchor from link" do
      expect(resolver.remove_anchor("file.md#section")).to eq("file.md")
      expect(resolver.remove_anchor("file.md")).to eq("file.md")
    end
  end

  describe "#absolute_path?" do
    it "identifies absolute paths" do
      expect(resolver.absolute_path?("/docs/file.md")).to be true
      expect(resolver.absolute_path?("docs/file.md")).to be false
      expect(resolver.absolute_path?("../file.md")).to be false
    end
  end

  describe "#resolve_link" do
    it "resolves relative links" do
      from_file = "docs/architecture.md"
      link = "../README.md"

      resolved = resolver.resolve_link(from_file, link)
      expect(resolved).to eq("README.md")
    end

    it "handles absolute links" do
      from_file = "docs/architecture.md"
      link = "/docs/blueprint.md"

      resolved = resolver.resolve_link(from_file, link)
      expect(resolved).to eq("docs/blueprint.md")
    end

    it "removes anchors during resolution" do
      from_file = "docs/architecture.md"
      link = "../README.md#section"

      resolved = resolver.resolve_link(from_file, link)
      expect(resolved).to eq("README.md")
    end
  end

  describe "#normalize_path" do
    it "normalizes paths relative to current directory" do
      # This test may be environment-dependent
      normalized = resolver.normalize_path("./docs/../README.md")
      expect(normalized).to eq("README.md")
    end
  end

  describe "#file_exists?" do
    it "checks if file exists and is a file" do
      # Create a temporary file for testing
      require "tempfile"

      temp_file = Tempfile.new("test")
      expect(resolver.file_exists?(temp_file.path)).to be true

      temp_file.close!
      expect(resolver.file_exists?(temp_file.path)).to be false

      expect(resolver.file_exists?("nonexistent.md")).to be false
    end
  end
end

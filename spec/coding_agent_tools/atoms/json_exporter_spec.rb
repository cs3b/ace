# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "json"

RSpec.describe CodingAgentTools::Atoms::JsonExporter do
  let(:exporter) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe "#format_dependencies" do
    it "formats simple dependencies" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["file2.md", "file3.md"]),
          refs_from: Set.new(["file4.md"])
        }
      }

      result = exporter.format_dependencies(dependencies)

      expect(result["file1.md"]).to eq({
        references: ["file2.md", "file3.md"],
        referenced_by: ["file4.md"]
      })
    end

    it "handles empty dependencies" do
      result = exporter.format_dependencies({})
      expect(result).to eq({})
    end

    it "sorts references and referenced_by arrays" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["zebra.md", "alpha.md", "beta.md"]),
          refs_from: Set.new(["charlie.md", "alpha.md"])
        }
      }

      result = exporter.format_dependencies(dependencies)

      expect(result["file1.md"][:references]).to eq(["alpha.md", "beta.md", "zebra.md"])
      expect(result["file1.md"][:referenced_by]).to eq(["alpha.md", "charlie.md"])
    end
  end

  describe "#export_to_file" do
    it "exports dependencies to JSON file with default name" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["file2.md"]),
          refs_from: Set.new(["file3.md"])
        }
      }

      filename = exporter.export_to_file(dependencies)

      expect(filename).to eq("doc-dependencies.json")
      expect(File.exist?(filename)).to be true

      content = JSON.parse(File.read(filename))
      expect(content["file1.md"]["references"]).to eq(["file2.md"])

      # Clean up
      File.delete(filename) if File.exist?(filename)
    end

    it "exports dependencies to JSON file with custom name" do
      dependencies = {
        "test.md" => {
          refs_to: Set.new(["target.md"]),
          refs_from: Set.new([])
        }
      }
      custom_filename = File.join(temp_dir, "custom.json")

      result = exporter.export_to_file(dependencies, custom_filename)

      expect(result).to eq(custom_filename)
      expect(File.exist?(custom_filename)).to be true

      content = JSON.parse(File.read(custom_filename))
      expect(content["test.md"]["references"]).to eq(["target.md"])
      expect(content["test.md"]["referenced_by"]).to eq([])
    end

    it "creates pretty-formatted JSON" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["file2.md"]),
          refs_from: Set.new([])
        }
      }
      custom_filename = File.join(temp_dir, "pretty.json")

      exporter.export_to_file(dependencies, custom_filename)

      content = File.read(custom_filename)
      expect(content).to include("\n")
      expect(content).to include("  ")
    end
  end

  describe "#export_to_string" do
    it "exports dependencies to JSON string" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["file2.md"]),
          refs_from: Set.new(["file3.md"])
        }
      }

      result = exporter.export_to_string(dependencies)

      expect(result).to be_a(String)
      parsed = JSON.parse(result)
      expect(parsed["file1.md"]["references"]).to eq(["file2.md"])
      expect(parsed["file1.md"]["referenced_by"]).to eq(["file3.md"])
    end

    it "returns pretty-formatted JSON string" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["file2.md"]),
          refs_from: Set.new([])
        }
      }

      result = exporter.export_to_string(dependencies)

      expect(result).to include("\n")
      expect(result).to include("  ")
    end
  end

  describe "#export_compact" do
    it "exports dependencies to compact JSON string" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["file2.md"]),
          refs_from: Set.new(["file3.md"])
        }
      }

      result = exporter.export_compact(dependencies)

      expect(result).to be_a(String)
      expect(result).not_to include("\n")
      expect(result).not_to include("  ")

      parsed = JSON.parse(result)
      expect(parsed["file1.md"]["references"]).to eq(["file2.md"])
      expect(parsed["file1.md"]["referenced_by"]).to eq(["file3.md"])
    end
  end

  describe "integration" do
    it "handles complex dependencies structure" do
      dependencies = {
        "docs/architecture.md" => {
          refs_to: Set.new(["docs/blueprint.md", "../README.md"]),
          refs_from: Set.new(["docs/guide.md", "docs/overview.md"])
        },
        "README.md" => {
          refs_to: Set.new([]),
          refs_from: Set.new(["docs/architecture.md"])
        }
      }

      formatted = exporter.format_dependencies(dependencies)
      json_string = exporter.export_to_string(dependencies)
      compact_string = exporter.export_compact(dependencies)

      expect(formatted).to have_key("docs/architecture.md")
      expect(formatted).to have_key("README.md")
      expect(json_string).to include("architecture.md")
      expect(compact_string).to include("blueprint.md")

      # Verify that compact is actually more compact
      expect(compact_string.length).to be < json_string.length
    end
  end
end

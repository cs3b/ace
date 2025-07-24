# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Atoms::DotGraphWriter do
  let(:writer) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(temp_dir) }

  describe "#generate_dot_content" do
    it "generates DOT content for simple dependencies" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["file2.md"]),
          refs_from: Set.new([])
        },
        "file2.md" => {
          refs_to: Set.new([]),
          refs_from: Set.new(["file1.md"])
        }
      }

      content = writer.generate_dot_content(dependencies)

      expect(content).to include("digraph DocumentDependencies")
      expect(content).to include("rankdir=LR")
      expect(content).to include('"file1.md"')
      expect(content).to include('"file2.md"')
      expect(content).to include('"file1.md" -> "file2.md"')
    end

    it "includes colored nodes based on file type" do
      dependencies = {
        "test.wf.md" => {refs_to: Set.new([]), refs_from: Set.new([])},
        "guide.g.md" => {refs_to: Set.new([]), refs_from: Set.new([])},
        "tasks/task.md" => {refs_to: Set.new([]), refs_from: Set.new([])},
        "normal.md" => {refs_to: Set.new([]), refs_from: Set.new([])}
      }

      content = writer.generate_dot_content(dependencies)

      expect(content).to include("fillcolor=lightblue")   # .wf.md files
      expect(content).to include("fillcolor=lightgreen")  # .g.md files
      expect(content).to include("fillcolor=lightyellow") # tasks files
      expect(content).to include("fillcolor=lightgray")   # normal files
    end

    it "handles empty dependencies" do
      content = writer.generate_dot_content({})

      expect(content).to include("digraph DocumentDependencies")
      expect(content).to include("rankdir=LR")
      expect(content).to include("node [shape=box]")
    end

    it "handles complex dependency structures" do
      dependencies = {
        "docs/architecture.md" => {
          refs_to: Set.new(["docs/blueprint.md", "README.md"]),
          refs_from: Set.new(["docs/guide.md"])
        },
        "docs/blueprint.md" => {
          refs_to: Set.new([]),
          refs_from: Set.new(["docs/architecture.md"])
        },
        "README.md" => {
          refs_to: Set.new([]),
          refs_from: Set.new(["docs/architecture.md"])
        }
      }

      content = writer.generate_dot_content(dependencies)

      expect(content).to include('"docs/architecture.md" -> "docs/blueprint.md"')
      expect(content).to include('"docs/architecture.md" -> "README.md"')
      expect(content.scan("->").length).to eq(2)
    end
  end

  describe "#write_dot_file" do
    it "writes DOT content to default file" do
      dependencies = {
        "file1.md" => {
          refs_to: Set.new(["file2.md"]),
          refs_from: Set.new([])
        }
      }

      filename = writer.write_dot_file(dependencies)

      expect(filename).to eq("doc-dependencies.dot")
      expect(File.exist?(filename)).to be true

      content = File.read(filename)
      expect(content).to include("digraph DocumentDependencies")
      expect(content).to include('"file1.md" -> "file2.md"')

      # Clean up
      File.delete(filename) if File.exist?(filename)
    end

    it "writes DOT content to custom file" do
      dependencies = {
        "test.md" => {
          refs_to: Set.new(["target.md"]),
          refs_from: Set.new([])
        }
      }
      custom_filename = File.join(temp_dir, "custom.dot")

      result = writer.write_dot_file(dependencies, custom_filename)

      expect(result).to eq(custom_filename)
      expect(File.exist?(custom_filename)).to be true

      content = File.read(custom_filename)
      expect(content).to include('"test.md" -> "target.md"')
    end
  end

  describe "#node_color" do
    it "returns correct colors for different file types" do
      expect(writer.node_color("workflow.wf.md")).to eq("lightblue")
      expect(writer.node_color("guide.g.md")).to eq("lightgreen")
      expect(writer.node_color("tasks/task.md")).to eq("lightyellow")
      expect(writer.node_color("normal.md")).to eq("lightgray")
      expect(writer.node_color("README.md")).to eq("lightgray")
    end

    it "handles edge cases in file naming" do
      expect(writer.node_color("test.wf.md.backup")).to eq("lightgray")
      expect(writer.node_color("tasks")).to eq("lightgray")
      expect(writer.node_color("tasks/subtask/file.md")).to eq("lightyellow")
    end
  end

  describe "#png_generation_instructions" do
    it "generates correct Graphviz command" do
      instructions = writer.png_generation_instructions("graph.dot")
      expect(instructions).to eq("dot -Tpng graph.dot -o graph.png")
    end

    it "handles paths with directories" do
      instructions = writer.png_generation_instructions("output/dependencies.dot")
      expect(instructions).to eq("dot -Tpng output/dependencies.dot -o output/dependencies.png")
    end
  end

  describe "integration" do
    it "creates complete DOT file workflow" do
      dependencies = {
        "docs/architecture.md" => {
          refs_to: Set.new(["docs/blueprint.md"]),
          refs_from: Set.new([])
        },
        "workflow.wf.md" => {
          refs_to: Set.new(["guide.g.md"]),
          refs_from: Set.new([])
        }
      }

      filename = File.join(temp_dir, "complete.dot")
      writer.write_dot_file(dependencies, filename)

      content = File.read(filename)
      instructions = writer.png_generation_instructions(filename)

      expect(content).to include("digraph DocumentDependencies")
      expect(content).to include("fillcolor=lightblue")  # workflow file
      expect(content).to include("fillcolor=lightgray")  # docs file
      expect(instructions).to include("complete.png")
    end
  end
end

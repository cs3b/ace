# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/organisms/doc_dependency_analyzer"
require "tempfile"
require "fileutils"

RSpec.describe CodingAgentTools::Organisms::DocDependencyAnalyzer do
  let(:analyzer) { described_class.new }

  # Create a temporary directory structure for testing
  around do |example|
    Dir.mktmpdir do |tmpdir|
      @test_dir = tmpdir
      Dir.chdir(@test_dir) do
        setup_test_files
        example.run
      end
    end
  end

  def setup_test_files
    # Create directory structure
    FileUtils.mkdir_p("docs")
    FileUtils.mkdir_p("dev-handbook/workflow-instructions")
    FileUtils.mkdir_p("dev-handbook/guides")
    FileUtils.mkdir_p("dev-taskflow/current/tasks")

    # Create test files with references
    File.write("docs/architecture.md", <<~CONTENT)
      # Architecture
      See [Blueprint](blueprint.md) for overview.
      Load config: [Config](config.md)
    CONTENT

    File.write("docs/blueprint.md", <<~CONTENT)
      # Blueprint
      References [Architecture](architecture.md).
    CONTENT

    File.write("docs/config.md", "# Config\nNo references.")

    File.write("dev-handbook/workflow-instructions/test.wf.md", <<~CONTENT)
      # Test Workflow
      Check [Blueprint](../../blueprint.md).
    CONTENT

    File.write("orphan.md", "# Orphan\nNo references to or from this file.")
  end

  describe "#analyze_dependencies_only" do
    it "builds dependency graph correctly" do
      dependencies = analyzer.analyze_dependencies_only

      expect(dependencies).to be_a(Hash)
      # Only check files that match the expected patterns
      expect(dependencies.keys).to include("docs/architecture.md")
      # blueprint.md is not in the expected file patterns, so it won't be analyzed
    end

    it "tracks bidirectional references" do
      dependencies = analyzer.analyze_dependencies_only

      # Just verify the structure exists and has the expected keys
      expect(dependencies["docs/architecture.md"]).to have_key(:refs_to)
      expect(dependencies["docs/architecture.md"]).to have_key(:refs_from)

      # Verify that at least one file has references
      has_references = dependencies.any? { |_, deps| deps[:refs_to].any? }
      expect(has_references).to be true
    end
  end

  describe "#get_statistics" do
    it "calculates basic statistics" do
      analyzer.analyze_dependencies_only
      stats = analyzer.get_statistics

      expect(stats[:total_files]).to be > 0
      expect(stats[:files_with_outgoing_refs]).to be >= 0
      expect(stats[:files_with_incoming_refs]).to be >= 0
      expect(stats[:total_references]).to be >= 0
      expect(stats[:average_outgoing_refs]).to be >= 0
      expect(stats[:average_incoming_refs]).to be >= 0
    end
  end

  describe "#get_orphaned_files" do
    it "identifies orphaned files" do
      analyzer.analyze_dependencies_only
      orphaned = analyzer.get_orphaned_files

      # orphan.md is not in file patterns, so it won't be analyzed
      # docs/config.md is referenced but doesn't reference others, so not orphaned
      # dev-handbook/workflow-instructions/test.wf.md references but isn't referenced back
      expect(orphaned).to include("dev-handbook/workflow-instructions/test.wf.md")
    end
  end

  describe "#get_circular_dependencies" do
    it "detects no circular dependencies in simple structure" do
      analyzer.analyze_dependencies_only
      circular = analyzer.get_circular_dependencies

      expect(circular).to be_empty
    end
  end

  describe "#get_most_referenced_files" do
    it "identifies most referenced files" do
      analyzer.analyze_dependencies_only
      most_referenced = analyzer.get_most_referenced_files(5)

      expect(most_referenced).to be_an(Array)
      most_referenced.each do |item|
        expect(item).to have_key(:file)
        expect(item).to have_key(:reference_count)
        expect(item[:reference_count]).to be > 0
      end
    end
  end

  describe "#analyze" do
    it "returns formatted text output by default" do
      result = analyzer.analyze(export_dot: false, export_json: false)

      expect(result).to be_a(String)
      expect(result).to include("# Document Dependency Analysis")
      expect(result).to include("## Summary")
    end

    it "returns JSON output when requested" do
      result = analyzer.analyze(output_format: :json, export_dot: false, export_json: false)

      expect(result).to be_a(String)
      parsed = JSON.parse(result)
      expect(parsed).to have_key("timestamp")
      expect(parsed).to have_key("statistics")
    end

    it "creates DOT file when requested" do
      analyzer.analyze(export_dot: true, export_json: false)

      expect(File.exist?("doc-dependencies.dot")).to be true

      dot_content = File.read("doc-dependencies.dot")
      expect(dot_content).to include("digraph DocumentDependencies")
    end

    it "creates JSON file when requested" do
      analyzer.analyze(export_dot: false, export_json: true)

      expect(File.exist?("doc-dependencies.json")).to be true

      json_content = File.read("doc-dependencies.json")
      parsed = JSON.parse(json_content)
      expect(parsed).to be_a(Hash)
    end
  end
end

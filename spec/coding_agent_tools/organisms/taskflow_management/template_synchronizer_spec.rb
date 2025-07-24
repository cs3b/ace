# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer do
  let(:xml_parser) { instance_double(CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser) }
  let(:file_synchronizer) { instance_double(CodingAgentTools::Molecules::TaskflowManagement::FileSynchronizer) }
  let(:config) { described_class::SyncConfig.new(path: "spec/fixtures", dry_run: false, verbose: false) }
  let(:synchronizer) { described_class.new(xml_parser: xml_parser, file_synchronizer: file_synchronizer, config: config) }

  let(:mock_stats) do
    instance_double(
      CodingAgentTools::Molecules::TaskflowManagement::FileSynchronizer::SyncStats,
      files_processed: 1,
      documents_synchronized: 2,
      documents_up_to_date: 1,
      errors: 0
    )
  end

  let(:sample_document) do
    CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::ParsedDocument.new(
      "dev-handbook/templates/test.template.md",
      "Sample content",
      :template,
      :documents,
      1,
      5
    )
  end

  let(:parse_result) do
    CodingAgentTools::Molecules::TaskflowManagement::XmlTemplateParser::ParserResult.new(
      [sample_document],
      [],
      []
    )
  end

  let(:sync_result_updated) do
    CodingAgentTools::Molecules::TaskflowManagement::FileSynchronizer::SyncResult.new(
      :updated,
      "Updated content",
      nil,
      nil
    )
  end

  let(:sync_result_up_to_date) do
    CodingAgentTools::Molecules::TaskflowManagement::FileSynchronizer::SyncResult.new(
      :up_to_date,
      nil,
      nil,
      nil
    )
  end

  before do
    # Mock file system operations
    allow(Dir).to receive(:glob).and_return(["spec/fixtures/test.wf.md"])
    allow(File).to receive(:read).with("spec/fixtures/test.wf.md").and_return("# Test workflow\n\n<documents></documents>")
    allow(File).to receive(:write)

    # Mock parser
    allow(xml_parser).to receive(:parse).and_return(parse_result)

    # Mock file synchronizer
    allow(file_synchronizer).to receive(:synchronize_document).and_return(sync_result_updated)
    allow(file_synchronizer).to receive(:reset_stats)
    allow(file_synchronizer).to receive(:stats).and_return(mock_stats)

    # Mock git operations
    allow(synchronizer).to receive(:system).and_return(true)
  end

  describe "#synchronize", :initialize do
    it "organism initializes correctly and coordinates molecules" do
      result = nil
      expect { result = synchronizer.synchronize }.to output(/Summary:.*Documents synchronized: 2/m).to_stdout

      expect(xml_parser).to have_received(:parse)
      expect(file_synchronizer).to have_received(:synchronize_document)
      expect(result.success?).to be true
    end

    context "when files are found and processed successfully" do
      it "returns successful result with statistics" do
        result = nil
        expect { result = synchronizer.synchronize }.to output(/Summary:.*Documents synchronized: 2/m).to_stdout

        expect(result.success?).to be true
        expect(result.stats).to eq mock_stats
        expect(result.errors).to be_empty
        expect(result.changes_made?).to be true
      end

      it "writes updated content to files when not in dry-run mode" do
        expect { synchronizer.synchronize }.to output(/Summary:.*Documents synchronized: 2/m).to_stdout

        expect(File).to have_received(:write).with("spec/fixtures/test.wf.md", "Updated content")
      end
    end

    context "when no workflow files are found" do
      before do
        allow(Dir).to receive(:glob).and_return([])
      end

      it "returns result with warning" do
        result = nil
        expect { result = synchronizer.synchronize }.to output("\n").to_stdout

        expect(result.success?).to be true
        expect(result.has_warnings?).to be true
        expect(result.warnings.first).to include("No workflow files found")
      end
    end

    context "when documents are up-to-date" do
      before do
        allow(file_synchronizer).to receive(:synchronize_document).and_return(sync_result_up_to_date)
      end

      it "processes without making changes" do
        result = nil
        expect { result = synchronizer.synchronize }.to output(/Summary:.*Documents up-to-date: 1/m).to_stdout

        expect(result.success?).to be true
        expect(result.changes_made?).to be false
        expect(File).not_to have_received(:write)
      end
    end

    context "with synchronization errors" do
      let(:sync_result_error) do
        CodingAgentTools::Molecules::TaskflowManagement::FileSynchronizer::SyncResult.new(
          :error,
          nil,
          "Test error message",
          nil
        )
      end

      before do
        allow(file_synchronizer).to receive(:synchronize_document).and_return(sync_result_error)
      end

      it "collects and reports errors" do
        result = nil
        expect { result = synchronizer.synchronize }.to output(/❌.*Error.*Test error message/).to_stdout

        expect(result.failure?).to be true
        expect(result.has_errors?).to be true
        expect(result.errors.first).to include("Test error message")
      end
    end

    context "with file processing errors" do
      before do
        allow(File).to receive(:read).and_raise(StandardError.new("File read error"))
      end

      it "handles file processing errors gracefully" do
        result = nil
        expect { result = synchronizer.synchronize }.to output(/❌.*Error processing file.*File read error/).to_stdout

        expect(result.failure?).to be true
        expect(result.has_errors?).to be true
        expect(result.errors.first).to include("File read error")
      end
    end
  end

  describe "dry-run mode", :dry_run do
    let(:dry_run_config) { described_class::SyncConfig.new(path: "spec/fixtures", dry_run: true) }
    let(:dry_run_synchronizer) { described_class.new(xml_parser: xml_parser, file_synchronizer: file_synchronizer, config: dry_run_config) }

    let(:sync_result_with_diff) do
      CodingAgentTools::Molecules::TaskflowManagement::FileSynchronizer::SyncResult.new(
        :updated,
        nil,
        nil,
        "Diff preview content"
      )
    end

    before do
      allow(file_synchronizer).to receive(:synchronize_document).and_return(sync_result_with_diff)
    end

    it "dry-run shows changes without applying, respects security constraints" do
      result = nil
      expect { result = dry_run_synchronizer.synchronize }.to output(/Summary:.*Would synchronize: 2 documents/m).to_stdout

      expect(result.success?).to be true
      expect(result.changes_made?).to be true
      expect(File).not_to have_received(:write)
    end
  end

  describe "commit functionality" do
    let(:commit_config) { described_class::SyncConfig.new(path: "spec/fixtures", commit: true) }
    let(:commit_synchronizer) { described_class.new(xml_parser: xml_parser, file_synchronizer: file_synchronizer, config: commit_config) }

    before do
      # Mock git repository check
      allow(commit_synchronizer).to receive(:system).with("git rev-parse --git-dir > /dev/null 2>&1").and_return(true)
      allow(commit_synchronizer).to receive(:system).with("git add -A").and_return(true)
      allow(commit_synchronizer).to receive(:system).with("git", "commit", "-m", anything).and_return(true)
    end

    it "commits changes when commit option is enabled" do
      result = nil
      expect { result = commit_synchronizer.synchronize }.to output(/Summary:.*Documents synchronized: 2/m).to_stdout

      expect(result.success?).to be true
      expect(commit_synchronizer).to have_received(:system).with("git add -A")
      expect(commit_synchronizer).to have_received(:system).with("git", "commit", "-m", anything)
    end

    context "when not in a git repository" do
      before do
        allow(commit_synchronizer).to receive(:system).with("git rev-parse --git-dir > /dev/null 2>&1").and_return(false)
      end

      it "reports error when not in git repository" do
        result = nil
        expect { result = commit_synchronizer.synchronize }.to output(/❌ Error: Not in a git repository.*Summary:.*Documents synchronized: 2.*Errors: 1/m).to_stdout

        expect(result.failure?).to be true
        expect(result.errors).to include("Not in a git repository")
      end
    end
  end

  describe "configuration and initialization" do
    describe "SyncConfig" do
      it "provides default configuration" do
        default_config = described_class::SyncConfig.new

        expect(default_config.path).to eq "dev-handbook/workflow-instructions"
        expect(default_config.dry_run).to be false
        expect(default_config.verbose).to be false
        expect(default_config.commit).to be false
        expect(default_config.file_patterns).to eq ["**/*.wf.md"]
      end

      it "allows custom configuration" do
        custom_config = described_class::SyncConfig.new(
          path: "custom/path",
          dry_run: true,
          verbose: true,
          commit: true,
          file_patterns: ["*.md"]
        )

        expect(custom_config.path).to eq "custom/path"
        expect(custom_config.dry_run).to be true
        expect(custom_config.verbose).to be true
        expect(custom_config.commit).to be true
        expect(custom_config.file_patterns).to eq ["*.md"]
      end
    end

    describe "SyncOperationResult" do
      let(:result) { described_class::SyncOperationResult.new(true, mock_stats, [], ["warning"], ["file.md"]) }

      it "provides status checking methods" do
        expect(result.success?).to be true
        expect(result.failure?).to be false
        expect(result.has_errors?).to be false
        expect(result.has_warnings?).to be true
        expect(result.changes_made?).to be true
      end
    end
  end

  describe "state management" do
    it "resets state and statistics" do
      synchronizer.reset_state

      expect(file_synchronizer).to have_received(:reset_stats)
    end

    it "provides access to current statistics" do
      stats = synchronizer.stats

      expect(stats).to eq mock_stats
    end
  end
end

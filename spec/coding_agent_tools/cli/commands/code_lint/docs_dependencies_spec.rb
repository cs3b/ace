# frozen_string_literal: true

require "spec_helper"

RSpec.describe CodingAgentTools::Cli::Commands::CodeLint::DocsDependencies do
  let(:command) { described_class.new }
  let(:mock_analyzer) { instance_double("CodingAgentTools::Organisms::DocDependencyAnalyzer") }
  let(:analysis_result) { "Analysis complete: 5 files processed" }
  let(:mock_stats) do
    {
      total_files: 10,
      files_with_outgoing_refs: 5,
      files_with_incoming_refs: 7,
      total_references: 15,
      average_outgoing_refs: 1.5,
      average_incoming_refs: 2.1
    }
  end

  before do
    allow(CodingAgentTools::Organisms::DocDependencyAnalyzer).to receive(:new)
      .and_return(mock_analyzer)
    allow(mock_analyzer).to receive(:analyze).and_return(analysis_result)
    allow(mock_analyzer).to receive(:analyze_dependencies_only)
    allow(mock_analyzer).to receive(:get_statistics).and_return(mock_stats)
    allow(mock_analyzer).to receive(:get_orphaned_files).and_return([])
    allow(mock_analyzer).to receive(:get_circular_dependencies).and_return([])
    allow(File).to receive(:write)
  end

  describe "#call" do
    context "with default options" do
      it "creates analyzer with default config" do
        allow(command).to receive(:puts)
        
        command.call

        expect(CodingAgentTools::Organisms::DocDependencyAnalyzer)
          .to have_received(:new).with(".coding-agent/lint.yml")
      end

      it "runs full analysis with default format" do
        allow(command).to receive(:puts)
        
        command.call

        expect(mock_analyzer).to have_received(:analyze).with(
          output_format: :text,
          export_dot: true,
          export_json: true
        )
      end

      it "outputs analysis result to stdout" do
        allow(command).to receive(:puts)
        
        command.call

        expect(command).to have_received(:puts).with(analysis_result)
      end

      it "displays export file information" do
        allow(command).to receive(:puts)
        
        command.call

        expect(command).to have_received(:puts).with("\nVisualization files:")
        expect(command).to have_received(:puts).with("- DOT graph: doc-dependencies.dot")
        expect(command).to have_received(:puts).with("- To generate PNG: dot -Tpng doc-dependencies.dot -o doc-dependencies.png")
        expect(command).to have_received(:puts).with("- JSON data: doc-dependencies.json")
      end
    end

    context "with custom config" do
      let(:custom_config) { "custom-lint.yml" }

      it "creates analyzer with custom config path" do
        allow(command).to receive(:puts)
        
        command.call(config: custom_config)

        expect(CodingAgentTools::Organisms::DocDependencyAnalyzer)
          .to have_received(:new).with(custom_config)
      end
    end

    context "with JSON format" do
      it "requests JSON output format" do
        allow(command).to receive(:puts)
        
        command.call(format: "json")

        expect(mock_analyzer).to have_received(:analyze).with(
          output_format: :json,
          export_dot: true,
          export_json: true
        )
      end
    end

    context "with output file" do
      let(:output_file) { "analysis-output.txt" }

      it "writes result to specified file" do
        allow(command).to receive(:puts)
        
        command.call(output: output_file)

        expect(File).to have_received(:write).with(output_file, analysis_result)
        expect(command).to have_received(:puts).with("Analysis saved to: #{output_file}")
      end
    end

    context "with no_exports option" do
      it "disables file exports" do
        allow(command).to receive(:puts)
        
        command.call(no_exports: true)

        expect(mock_analyzer).to have_received(:analyze).with(
          output_format: :text,
          export_dot: false,
          export_json: false
        )
      end

      it "does not show export file information" do
        allow(command).to receive(:puts)
        
        command.call(no_exports: true)

        expect(command).not_to have_received(:puts).with("\nVisualization files:")
      end
    end

    context "with stats_only option" do
      let(:orphaned_files) { ["orphan1.md", "orphan2.md"] }
      let(:circular_deps) { [["file1.md", "file2.md"]] }

      before do
        allow(mock_analyzer).to receive(:get_orphaned_files).and_return(orphaned_files)
        allow(mock_analyzer).to receive(:get_circular_dependencies).and_return(circular_deps)
      end

      it "runs analysis without exports" do
        allow(command).to receive(:puts)
        
        command.call(stats_only: true)

        expect(mock_analyzer).to have_received(:analyze_dependencies_only)
        expect(mock_analyzer).not_to have_received(:analyze)
      end

      it "outputs comprehensive statistics" do
        allow(command).to receive(:puts)
        
        command.call(stats_only: true)

        expect(command).to have_received(:puts).with("## Documentation Dependency Statistics")
        expect(command).to have_received(:puts).with("- Total files analyzed: 10")
        expect(command).to have_received(:puts).with("- Files with outgoing references: 5")
        expect(command).to have_received(:puts).with("- Files with incoming references: 7")
        expect(command).to have_received(:puts).with("- Total references: 15")
        expect(command).to have_received(:puts).with("- Average outgoing references per file: 1.5")
        expect(command).to have_received(:puts).with("- Average incoming references per file: 2.1")
        expect(command).to have_received(:puts).with("- Orphaned files: 2")
        expect(command).to have_received(:puts).with("- Circular dependencies: 1")
      end
    end

    context "with custom export files" do
      it "uses custom DOT file name" do
        allow(command).to receive(:puts)
        
        command.call(dot_file: "custom.dot")

        expect(command).to have_received(:puts).with("- DOT graph: custom.dot")
        expect(command).to have_received(:puts).with("- To generate PNG: dot -Tpng custom.dot -o doc-dependencies.png")
      end

      it "uses custom JSON file name" do
        allow(command).to receive(:puts)
        
        command.call(json_file: "custom.json")

        expect(command).to have_received(:puts).with("- JSON data: custom.json")
      end
    end

    context "when an exception occurs" do
      let(:error_message) { "Analysis failed" }

      before do
        allow(mock_analyzer).to receive(:analyze).and_raise(StandardError, error_message)
      end

      it "handles the exception gracefully" do
        allow(command).to receive(:warn)
        allow(command).to receive(:exit)
        
        command.call

        expect(command).to have_received(:warn).with("Error during analysis: #{error_message}")
        expect(command).to have_received(:exit).with(1)
      end

      context "with DEBUG environment variable" do
        before do
          allow(ENV).to receive(:[]).with("DEBUG").and_return("true")
          allow(mock_analyzer).to receive(:analyze).and_raise(StandardError.new(error_message).tap do |e|
            e.set_backtrace(["line1", "line2", "line3"])
          end)
        end

        it "includes backtrace in error output" do
          allow(command).to receive(:warn)
          allow(command).to receive(:exit)
          
          command.call

          expect(command).to have_received(:warn).with("Error during analysis: #{error_message}")
          expect(command).to have_received(:warn).with("line1\nline2\nline3")
          expect(command).to have_received(:exit).with(1)
        end
      end
    end

    context "with stats_only and no_exports combined" do
      it "runs stats only mode without affecting exports logic" do
        allow(command).to receive(:puts)
        
        command.call(stats_only: true, no_exports: true)

        expect(mock_analyzer).to have_received(:analyze_dependencies_only)
        expect(mock_analyzer).not_to have_received(:analyze)
      end
    end

    context "with output file and stats_only" do
      it "does not write to output file in stats only mode" do
        allow(command).to receive(:puts)
        
        command.call(stats_only: true, output: "output.txt")

        expect(File).not_to have_received(:write)
      end
    end
  end
end
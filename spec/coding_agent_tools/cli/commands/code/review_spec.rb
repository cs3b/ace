# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Code::Review do
  let(:command) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  before do
    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#call" do
    context "with list presets option" do
      let(:mock_preset_manager) { instance_double("CodingAgentTools::Molecules::Code::ReviewPresetManager") }

      before do
        allow(CodingAgentTools::Molecules::Code::ReviewPresetManager).to receive(:new).and_return(mock_preset_manager)
      end

      it "lists available presets" do
        allow(mock_preset_manager).to receive(:available_presets).and_return(["pr", "code", "docs"])
        allow(mock_preset_manager).to receive(:load_preset).with("pr").and_return({"description" => "Pull request review"})
        allow(mock_preset_manager).to receive(:load_preset).with("code").and_return({"description" => "Code review"})
        allow(mock_preset_manager).to receive(:load_preset).with("docs").and_return({"description" => "Documentation review"})

        result = command.call(list_presets: true)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with("Available review presets:")
        expect($stdout).to have_received(:puts).with("  pr: Pull request review")
        expect($stdout).to have_received(:puts).with("  code: Code review")
        expect($stdout).to have_received(:puts).with("  docs: Documentation review")
      end

      it "shows message when no presets found" do
        allow(mock_preset_manager).to receive(:available_presets).and_return([])

        result = command.call(list_presets: true)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with("No presets found. Create .coding-agent/code-review.yml to define presets.")
      end
    end

    context "with minimal configuration" do
      before do
        # Mock the components used by the new architecture
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({})
        allow(command).to receive(:execute_review).and_return(0)
      end

      it "executes successfully with no options" do
        result = command.call

        expect(result).to eq(0)
      end

      it "handles preset option" do
        result = command.call(preset: "pr")

        expect(result).to eq(0)
      end

      it "handles context and subject options" do
        result = command.call(context: "project", subject: "HEAD~1..HEAD")

        expect(result).to eq(0)
      end
    end

    context "with dry run option" do
      before do
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({
          preset: "pr",
          context: "project",
          subject: "HEAD~1..HEAD"
        })
        allow(command).to receive(:show_dry_run).and_return(0)
      end

      it "executes dry run without creating session" do
        result = command.call(preset: "pr", dry_run: true)

        expect(result).to eq(0)
        expect(command).to have_received(:show_dry_run)
      end
    end

    context "with prompt composition options" do
      before do
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({})
        allow(command).to receive(:execute_review).and_return(0)
      end

      it "handles prompt composition options" do
        result = command.call(
          prompt_base: "system",
          prompt_format: "detailed", 
          prompt_focus: "architecture/atom,languages/ruby",
          prompt_guidelines: "tone,icons"
        )

        expect(result).to eq(0)
      end

      it "handles add_focus option with preset" do
        result = command.call(
          preset: "pr",
          add_focus: "quality/security"
        )

        expect(result).to eq(0)
      end
    end

    context "with auto execute option" do
      before do
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({})
        allow(command).to receive(:execute_review).and_return(0)
      end

      it "automatically executes review when auto_execute is true" do
        result = command.call(preset: "pr", auto_execute: true)

        expect(result).to eq(0)
        expect(command).to have_received(:execute_review)
      end

      it "works with output file specification" do
        result = command.call(preset: "pr", auto_execute: true, output: "review.md")

        expect(result).to eq(0)
      end
    end

    context "with config file option" do
      let(:config_file) { File.join(temp_dir, "config.md") }

      before do
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({})
        allow(command).to receive(:execute_review).and_return(0)
      end

      it "loads configuration from file" do
        File.write(config_file, "---\npreset: pr\nauto_execute: true\n---\n# Review")
        
        result = command.call(config_file: config_file)

        expect(result).to eq(0)
      end

      it "handles missing config file" do
        result = command.call(config_file: "/nonexistent.md")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Config file not found: /nonexistent.md\n")
      end
    end

    context "with error conditions" do
      it "handles validation errors gracefully" do
        allow(command).to receive(:validate_inputs).and_return(1)

        result = command.call(preset: "invalid")

        expect(result).to eq(1)
      end

      it "handles exceptions gracefully" do
        allow(command).to receive(:validate_inputs).and_raise(StandardError, "Unexpected error")

        result = command.call(preset: "pr")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Unexpected error\n")
      end

      it "shows backtrace in debug mode" do
        allow(command).to receive(:validate_inputs).and_raise(StandardError, "Debug error")

        result = command.call(preset: "pr", debug: true)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Debug error\n")
      end
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.description).to eq("Execute code review using presets or custom configuration")
    end

    it "allows calls without required arguments" do
      # The new command structure no longer requires specific arguments
      # It can run with just defaults or show help
      expect { command.call }.not_to raise_error
    end

    it "has usage examples defined" do
      # This tests that examples are provided for the command
      expect(described_class).to respond_to(:example)
    end
  end
end

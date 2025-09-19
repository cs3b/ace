# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"
require_relative "../../../../lib/coding_agent_tools/cli/commands/context"

RSpec.describe CodingAgentTools::Cli::Commands::Context do
  let(:command) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#call" do
    context "with --list-presets option" do
      it "lists available presets" do
        output = capture_stdout do
          expect(command.call(list_presets: true)).to eq(0)
        end

        expect(output).to include("Available presets:")
        expect(output).to include("project")
      end
    end

    context "with validation errors" do
      it "requires an input method" do
        expect(command.call).to eq(1)
      end

      it "prevents multiple input methods" do
        yaml_file = File.join(temp_dir, "test.yaml")
        File.write(yaml_file, "files: [README.md]")

        expect(command.call(yaml: yaml_file, preset: "project")).to eq(1)
      end
    end

    context "with missing preset" do
      it "shows error for non-existent preset" do
        output = capture_stderr do
          expect(command.call(preset: "nonexistent")).to eq(1)
        end

        expect(output).to include("Preset 'nonexistent' not found")
        expect(output).to include("Use --list-presets")
      end
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end

  def capture_stderr
    original_stderr = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original_stderr
  end
end

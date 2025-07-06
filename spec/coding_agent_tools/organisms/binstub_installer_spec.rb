# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "securerandom"

RSpec.describe CodingAgentTools::Organisms::BinstubInstaller do
  let(:config_content) do
    {
      "version" => "1.0",
      "aliases" => {
        "tn" => {
          "description" => "Get next task",
          "executable" => "task-manager",
          "command" => "next",
          "type" => "shell"
        },
        "llm" => {
          "description" => "Query LLM",
          "executable" => "llm-query",
          "type" => "shell"
        }
      }
    }
  end

  let(:config_file_path) { File.join(Dir.tmpdir, "config_#{SecureRandom.hex(8)}.yml") }
  let(:target_directory) { Dir.mktmpdir }
  let(:installer) { described_class.new(config_file_path, target_directory) }

  before do
    File.write(config_file_path, config_content.to_yaml)
  end

  after do
    File.unlink(config_file_path) if File.exist?(config_file_path)
    FileUtils.rm_rf(target_directory) if target_directory && Dir.exist?(target_directory)
  end

  describe "#initialize" do
    it "sets config_path and target_directory" do
      expect(installer.config_path).to eq(config_file_path)
      expect(installer.target_directory).to eq(target_directory)
    end
  end

  describe "#install_all" do
    context "when installing all binstubs" do
      it "installs all binstubs from config" do
        result = installer.install_all(verbose: false)

        expect(result[:installed]).to contain_exactly("tn", "llm")
        expect(result[:skipped]).to be_empty
        expect(result[:errors]).to be_empty

        tn_file = File.join(target_directory, "tn")
        llm_file = File.join(target_directory, "llm")

        expect(File.exist?(tn_file)).to be true
        expect(File.exist?(llm_file)).to be true
        expect(File.executable?(tn_file)).to be true
        expect(File.executable?(llm_file)).to be true

        tn_content = File.read(tn_file)
        expect(tn_content).to include("# Get next task")
        expect(tn_content).to include("./exe/task-manager next \"$@\"")
      end
    end

    context "when files already exist and force is false" do
      before do
        File.write(File.join(target_directory, "tn"), "existing content")
      end

      it "asks for confirmation and may skip files" do
        # Mock the confirmer to always return false (don't overwrite)
        allow(CodingAgentTools::Molecules::FileOperationConfirmer)
          .to receive(:confirm_overwrite).and_return(false)

        result = installer.install_all(force: false, verbose: false)

        expect(result[:installed]).to contain_exactly("llm")
        expect(result[:skipped]).to contain_exactly("tn")
        expect(result[:errors]).to be_empty
      end
    end

    context "when force option is true" do
      before do
        File.write(File.join(target_directory, "tn"), "existing content")
      end

      it "overwrites existing files without confirmation" do
        result = installer.install_all(force: true, verbose: false)

        expect(result[:installed]).to contain_exactly("tn", "llm")
        expect(result[:skipped]).to be_empty
        expect(result[:errors]).to be_empty

        tn_content = File.read(File.join(target_directory, "tn"))
        expect(tn_content).to include("# Get next task")
        expect(tn_content).not_to eq("existing content")
      end
    end

    context "when an error occurs during installation" do
      it "records errors and continues with other files" do
        # Make target directory read-only to cause write errors
        File.chmod(0o444, target_directory)

        result = installer.install_all(verbose: false)

        expect(result[:installed]).to be_empty
        expect(result[:errors].size).to eq(2)
        expect(result[:errors].map { |e| e[:alias] }).to contain_exactly("tn", "llm")
      ensure
        # Restore permissions for cleanup
        File.chmod(0o755, target_directory)
      end
    end
  end

  describe "#install_specific" do
    context "when installing existing alias" do
      it "installs the specific binstub" do
        result = installer.install_specific("tn", verbose: false)

        expect(result).to be true

        tn_file = File.join(target_directory, "tn")
        expect(File.exist?(tn_file)).to be true
        expect(File.executable?(tn_file)).to be true

        tn_content = File.read(tn_file)
        expect(tn_content).to include("# Get next task")
      end
    end

    context "when alias does not exist in config" do
      it "raises an error" do
        expect {
          installer.install_specific("nonexistent", verbose: false)
        }.to raise_error(CodingAgentTools::Error, /Alias 'nonexistent' not found/)
      end
    end

    context "when file exists and force is false" do
      before do
        File.write(File.join(target_directory, "tn"), "existing content")
      end

      it "asks for confirmation" do
        allow(CodingAgentTools::Molecules::FileOperationConfirmer)
          .to receive(:confirm_overwrite).and_return(false)

        result = installer.install_specific("tn", force: false, verbose: false)

        expect(result).to be false
        expect(File.read(File.join(target_directory, "tn"))).to eq("existing content")
      end
    end
  end

  describe "#list_available_aliases" do
    it "returns list of alias names from config" do
      aliases = installer.list_available_aliases

      expect(aliases).to contain_exactly("tn", "llm")
    end

    context "when config has no aliases" do
      let(:config_content) { {"version" => "1.0"} }

      it "returns empty array" do
        aliases = installer.list_available_aliases

        expect(aliases).to eq([])
      end
    end
  end

  describe "private methods" do
    describe "#write_binstub_file" do
      it "writes content and makes file executable" do
        content = "#!/bin/sh\necho 'test'"
        file_path = File.join(target_directory, "test")

        installer.send(:write_binstub_file, file_path, content, false)

        expect(File.exist?(file_path)).to be true
        expect(File.executable?(file_path)).to be true
        expect(File.read(file_path)).to eq(content)
      end
    end
  end
end

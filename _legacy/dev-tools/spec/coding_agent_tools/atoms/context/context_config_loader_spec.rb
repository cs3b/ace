# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"
require_relative "../../../../lib/coding_agent_tools/atoms/context/context_config_loader"

RSpec.describe CodingAgentTools::Atoms::Context::ContextConfigLoader do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_dir, ".coding-agent") }
  let(:config_path) { File.join(config_dir, "context.yml") }
  let(:loader) { described_class.new(temp_dir, config_path) }

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#initialize" do
    it "uses provided project root and config path" do
      expect(loader.project_root).to eq(temp_dir)
      expect(loader.default_config_path).to eq(config_path)
    end

    it "detects project root when not provided" do
      loader = described_class.new
      expect(loader.project_root).to be_a(String)
    end
  end

  describe "#load" do
    context "when config file does not exist" do
      it "returns default configuration" do
        config = loader.load
        expect(config).to be_a(Hash)
        expect(config["presets"]).to be_a(Hash)
        expect(config["settings"]).to be_a(Hash)
        expect(config["security"]).to be_a(Hash)
      end
    end

    context "when config file exists" do
      before do
        FileUtils.mkdir_p(config_dir)
      end

      it "loads valid YAML configuration" do
        File.write(config_path, <<~YAML)
          presets:
            custom:
              description: "Custom preset"
              template: "custom/template.md"
              output: "custom/output.md"
          settings:
            default_chunk_limit: 200000
        YAML

        config = loader.load
        expect(config["presets"]["custom"]["description"]).to eq("Custom preset")
        expect(config["settings"]["default_chunk_limit"]).to eq(200_000)
      end

      it "merges user config with defaults" do
        File.write(config_path, <<~YAML)
          presets:
            project:
              output: "custom/project.md"
            new_preset:
              description: "New preset"
              template: "new/template.md"
        YAML

        config = loader.load

        # Default preset should be updated
        expect(config["presets"]["project"]["output"]).to eq("custom/project.md")
        expect(config["presets"]["project"]["template"]).to eq("docs/context/project.md") # from default

        # New preset should be added
        expect(config["presets"]["new_preset"]["description"]).to eq("New preset")

        # Default settings should be preserved
        expect(config["settings"]["default_chunk_limit"]).to eq(150_000)
      end

      it "raises error for invalid YAML" do
        File.write(config_path, "invalid: yaml: [")

        expect { loader.load }.to raise_error(CodingAgentTools::Error, /Invalid YAML/)
      end

      it "raises error for non-hash root" do
        File.write(config_path, "- not a hash")

        expect { loader.load }.to raise_error(CodingAgentTools::Error, /Configuration must be a Hash/)
      end
    end
  end

  describe "#config_exists?" do
    it "returns false when config file does not exist" do
      expect(loader.config_exists?).to be false
    end

    it "returns true when config file exists" do
      FileUtils.mkdir_p(config_dir)
      File.write(config_path, "presets: {}")

      expect(loader.config_exists?).to be true
    end
  end

  describe "#default_config_path" do
    it "returns path in .coding-agent directory" do
      expected_path = File.join(temp_dir, ".coding-agent", "context.yml")
      expect(loader.default_config_path).to eq(expected_path)
    end
  end

  describe "configuration validation" do
    before do
      FileUtils.mkdir_p(config_dir)
    end

    it "validates preset structure" do
      File.write(config_path, <<~YAML)
        presets:
          invalid_preset: "not a hash"
      YAML

      expect { loader.load }.to raise_error(CodingAgentTools::Error, /must be a Hash/)
    end

    it "allows missing template key in user presets (merged with defaults)" do
      File.write(config_path, <<~YAML)
        presets:
          missing_template:
            description: "Missing template"
            output: "output.md"
      YAML

      config = loader.load
      # Should load successfully because template is not required for user config
      expect(config["presets"]["missing_template"]["description"]).to eq("Missing template")
      expect(config["presets"]["missing_template"]["output"]).to eq("output.md")
    end

    it "validates preset key types" do
      File.write(config_path, <<~YAML)
        presets:
          invalid_types:
            template: "valid.md"
            description: 123
            chunk_limit: "not_integer"
      YAML

      expect { loader.load }.to raise_error(CodingAgentTools::Error, /must be a String|must be a Integer/)
    end

    it "validates section types" do
      File.write(config_path, <<~YAML)
        presets: "not a hash"
      YAML

      expect { loader.load }.to raise_error(CodingAgentTools::Error, /presets must be a Hash/)
    end
  end

  describe "default configuration structure" do
    let(:default_config) { described_class::DEFAULT_CONFIG }

    it "has required top-level sections" do
      expect(default_config).to have_key("presets")
      expect(default_config).to have_key("settings")
      expect(default_config).to have_key("security")
    end

    it "has default project preset" do
      project_preset = default_config["presets"]["project"]
      expect(project_preset).to be_a(Hash)
      expect(project_preset).to have_key("description")
      expect(project_preset).to have_key("template")
      expect(project_preset).to have_key("output")
      expect(project_preset).to have_key("chunk_limit")
    end

    it "has security configuration" do
      security = default_config["security"]
      expect(security).to have_key("allowed_template_paths")
      expect(security).to have_key("allowed_output_paths")
      expect(security).to have_key("forbidden_patterns")
      expect(security["allowed_template_paths"]).to be_an(Array)
      expect(security["forbidden_patterns"]).to be_an(Array)
    end

    it "has settings configuration" do
      settings = default_config["settings"]
      expect(settings).to have_key("default_chunk_limit")
      expect(settings).to have_key("cache_directory")
      expect(settings).to have_key("auto_create_directories")
      expect(settings["default_chunk_limit"]).to be_an(Integer)
      expect([true, false]).to include(settings["auto_create_directories"])
    end
  end
end

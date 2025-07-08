# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::PathConfigLoader do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_dir, ".coding-agent") }
  let(:config_path) { File.join(config_dir, "path.yml") }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  after do
    FileUtils.remove_entry(temp_dir)
  end

  describe "#initialize" do
    it "uses provided project root" do
      loader = described_class.new(temp_dir)
      expect(loader.default_config_path).to eq(config_path)
    end

    it "detects project root when not provided" do
      # Create a .git directory to mark as project root
      FileUtils.mkdir_p(File.join(temp_dir, ".git"))

      Dir.chdir(temp_dir) do
        loader = described_class.new
        expect(File.realpath(File.dirname(loader.default_config_path))).to eq(File.realpath(config_dir))
      end
    end
  end

  describe "#load" do
    context "when config file doesn't exist" do
      it "returns default configuration" do
        loader = described_class.new(temp_dir)
        config = loader.load

        expect(config["project"]["root"]).to eq("..")
        expect(config["project"]["name"]).to eq("tools-meta")
        expect(config["repositories"]["scan_order"]).to be_an(Array)
        expect(config["path_patterns"]["task_new"]["template"]).to include("dev-taskflow")
        expect(config["security"]["enforce_sandbox"]).to be true
      end
    end

    context "when config file exists" do
      let(:config_content) do
        {
          "project" => {
            "root" => "/custom/root",
            "name" => "custom-project"
          },
          "repositories" => {
            "scan_order" => [
              {
                "name" => "custom-repo",
                "path" => "custom",
                "priority" => 1
              }
            ]
          },
          "security" => {
            "enforce_sandbox" => false
          }
        }
      end

      before do
        File.write(config_path, config_content.to_yaml)
      end

      it "loads and merges with defaults" do
        loader = described_class.new(temp_dir)
        config = loader.load

        expect(config["project"]["root"]).to eq("/custom/root")
        expect(config["project"]["name"]).to eq("custom-project")
        expect(config["repositories"]["scan_order"].first["name"]).to eq("custom-repo")
        expect(config["security"]["enforce_sandbox"]).to be false

        # Defaults should still be present for unspecified sections
        expect(config["path_patterns"]["task_new"]).to be_a(Hash)
        expect(config["resolution"]["fuzzy"]["enabled"]).to be true
      end
    end

    context "when config file has invalid YAML" do
      before do
        File.write(config_path, "invalid: yaml: content: [")
      end

      it "raises an error" do
        loader = described_class.new(temp_dir)
        expect { loader.load }.to raise_error(CodingAgentTools::Error, /Invalid YAML/)
      end
    end

    context "when config file has invalid structure" do
      before do
        File.write(config_path, "not_a_hash")
      end

      it "raises an error" do
        loader = described_class.new(temp_dir)
        expect { loader.load }.to raise_error(CodingAgentTools::Error, /Configuration must be a Hash/)
      end
    end

    context "when project section is not a Hash" do
      before do
        File.write(config_path, {"project" => "invalid"}.to_yaml)
      end

      it "raises an error" do
        loader = described_class.new(temp_dir)
        expect { loader.load }.to raise_error(CodingAgentTools::Error, /project must be a Hash/)
      end
    end

    context "when repositories section is not a Hash" do
      before do
        File.write(config_path, {"repositories" => "invalid"}.to_yaml)
      end

      it "raises an error" do
        loader = described_class.new(temp_dir)
        expect { loader.load }.to raise_error(CodingAgentTools::Error, /repositories must be a Hash/)
      end
    end
  end

  describe "#config_exists?" do
    it "returns false when config doesn't exist" do
      loader = described_class.new(temp_dir)
      expect(loader.config_exists?).to be false
    end

    it "returns true when config exists" do
      File.write(config_path, {}.to_yaml)
      loader = described_class.new(temp_dir)
      expect(loader.config_exists?).to be true
    end
  end

  describe "#default_config_path" do
    it "returns correct path" do
      loader = described_class.new(temp_dir)
      expect(loader.default_config_path).to eq(config_path)
    end
  end

  describe "deep merge functionality" do
    let(:config_content) do
      {
        "resolution" => {
          "fuzzy" => {
            "enabled" => false,
            "custom_option" => "value"
          }
        }
      }
    end

    before do
      File.write(config_path, config_content.to_yaml)
    end

    it "deep merges nested configuration" do
      loader = described_class.new(temp_dir)
      config = loader.load

      expect(config["resolution"]["fuzzy"]["enabled"]).to be false # overridden
      expect(config["resolution"]["fuzzy"]["custom_option"]).to eq("value") # added
      expect(config["resolution"]["fuzzy"]["min_similarity"]).to eq(0.5) # preserved from default
    end
  end

  describe "scan_order preservation" do
    let(:config_content) do
      {
        "repositories" => {
          "scan_order" => [
            {"name" => "first", "path" => ".", "priority" => 1},
            {"name" => "second", "path" => "sub", "priority" => 2}
          ]
        }
      }
    end

    before do
      File.write(config_path, config_content.to_yaml)
    end

    it "preserves scan_order exactly as specified" do
      loader = described_class.new(temp_dir)
      config = loader.load

      scan_order = config["repositories"]["scan_order"]
      expect(scan_order).to eq(config_content["repositories"]["scan_order"])
      expect(scan_order.length).to eq(2)
      expect(scan_order.first["name"]).to eq("first")
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"

RSpec.describe CodingAgentTools::Molecules::TreeConfigLoader do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_dir, ".coding-agent") }
  let(:config_path) { File.join(config_dir, "tree.yml") }

  before do
    FileUtils.mkdir_p(config_dir)
  end

  after do
    safe_directory_cleanup(temp_dir)
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

        expect(config["default_depth"]).to eq(3)
        expect(config["global_excludes"]).to include(".git", "node_modules")
        expect(config["contexts"]["default"]).to be_a(Hash)
      end
    end

    context "when config file exists" do
      let(:config_content) do
        {
          "default_depth" => 5,
          "global_excludes" => [".git", "custom_exclude"],
          "contexts" => {
            "custom" => {
              "excludes" => ["custom_dir"],
              "max_depth" => 4
            }
          }
        }
      end

      before do
        File.write(config_path, config_content.to_yaml)
      end

      it "loads and merges with defaults" do
        loader = described_class.new(temp_dir)
        config = loader.load

        expect(config["default_depth"]).to eq(5)
        expect(config["global_excludes"]).to eq([".git", "custom_exclude"])
        expect(config["contexts"]["default"]).to be_a(Hash) # default context preserved
        expect(config["contexts"]["custom"]["excludes"]).to eq(["custom_dir"])
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

    context "when contexts is not a Hash" do
      before do
        File.write(config_path, {"contexts" => "invalid"}.to_yaml)
      end

      it "raises an error" do
        loader = described_class.new(temp_dir)
        expect { loader.load }.to raise_error(CodingAgentTools::Error, /contexts must be a Hash/)
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

  describe "project root detection" do
    it "finds project root with .coding-agent marker" do
      nested_dir = File.join(temp_dir, "nested", "deep")
      FileUtils.mkdir_p(nested_dir)

      Dir.chdir(nested_dir) do
        loader = described_class.new
        expect(File.realpath(File.dirname(loader.default_config_path))).to eq(File.realpath(config_dir))
      end
    end

    it "finds project root with .git marker" do
      git_dir = File.join(temp_dir, ".git")
      nested_dir = File.join(temp_dir, "nested")
      FileUtils.mkdir_p([git_dir, nested_dir])

      Dir.chdir(nested_dir) do
        loader = described_class.new
        expect(File.realpath(File.dirname(loader.default_config_path))).to eq(File.realpath(config_dir))
      end
    end

    it "finds project root with CLAUDE.md marker" do
      claude_file = File.join(temp_dir, "CLAUDE.md")
      nested_dir = File.join(temp_dir, "nested")
      FileUtils.mkdir_p(nested_dir)
      FileUtils.touch(claude_file)

      Dir.chdir(nested_dir) do
        loader = described_class.new
        expect(File.realpath(File.dirname(loader.default_config_path))).to eq(File.realpath(config_dir))
      end
    end

    it "falls back to current directory when no markers found" do
      isolated_dir = Dir.mktmpdir

      begin
        Dir.chdir(isolated_dir) do
          loader = described_class.new
          expected_dir = File.join(isolated_dir, ".coding-agent")
          FileUtils.mkdir_p(expected_dir) # Create the directory for realpath to work
          expect(File.realpath(File.dirname(loader.default_config_path))).to eq(File.realpath(expected_dir))
        end
      ensure
        FileUtils.remove_entry(isolated_dir)
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/code/review_preset_manager"
require "tempfile"
require "yaml"

RSpec.describe CodingAgentTools::Molecules::Code::ReviewPresetManager do
  let(:config_content) do
    {
      "presets" => {
        "pr" => {
          "description" => "Pull request review",
          "system_prompt" => "templates/pr.md",
          "context" => "project",
          "subject" => {
            "commands" => ["git diff origin/main...HEAD"]
          }
        },
        "code" => {
          "description" => "Code quality review",
          "system_prompt" => "templates/code.md",
          "context" => {
            "files" => ["docs/architecture.md"]
          },
          "subject" => {
            "commands" => ["git diff --cached"]
          }
        }
      },
      "defaults" => {
        "model" => "google:gemini-2.0-flash-exp",
        "context" => "project",
        "output_format" => "markdown"
      }
    }
  end

  let(:temp_dir) { Dir.mktmpdir }
  let(:config_path) { File.join(temp_dir, ".coding-agent", "code-review.yml") }

  before do
    FileUtils.mkdir_p(File.dirname(config_path))
    File.write(config_path, config_content.to_yaml)
  end

  after do
    FileUtils.rm_rf(temp_dir)
  end

  describe "#initialize" do
    it "loads configuration from default path" do
      manager = described_class.new(project_root: temp_dir)
      expect(manager.config).to eq(config_content)
    end

    it "loads configuration from custom path" do
      custom_path = File.join(temp_dir, "custom-review.yml")
      File.write(custom_path, config_content.to_yaml)

      manager = described_class.new(config_path: custom_path)
      expect(manager.config).to eq(config_content)
    end

    it "handles missing configuration file gracefully" do
      manager = described_class.new(project_root: "/nonexistent")
      expect(manager.config).to be_nil
    end
  end

  describe "#load_preset" do
    let(:manager) { described_class.new(project_root: temp_dir) }

    it "loads an existing preset" do
      preset = manager.load_preset("pr")
      expect(preset["description"]).to eq("Pull request review")
      expect(preset["system_prompt"]).to eq("templates/pr.md")
    end

    it "merges defaults into preset" do
      preset = manager.load_preset("pr")
      expect(preset["model"]).to eq("google:gemini-2.0-flash-exp")
    end

    it "returns nil for non-existent preset" do
      preset = manager.load_preset("nonexistent")
      expect(preset).to be_nil
    end
  end

  describe "#available_presets" do
    let(:manager) { described_class.new(project_root: temp_dir) }

    it "returns sorted list of preset names" do
      expect(manager.available_presets).to eq(["code", "pr"])
    end

    it "returns empty array when no config" do
      manager = described_class.new(project_root: "/nonexistent")
      expect(manager.available_presets).to eq([])
    end
  end

  describe "#preset_exists?" do
    let(:manager) { described_class.new(project_root: temp_dir) }

    it "returns true for existing preset" do
      expect(manager.preset_exists?("pr")).to be true
    end

    it "returns false for non-existent preset" do
      expect(manager.preset_exists?("nonexistent")).to be false
    end
  end

  describe "#resolve_preset" do
    let(:manager) { described_class.new(project_root: temp_dir) }

    it "resolves preset with all components" do
      resolved = manager.resolve_preset("pr")

      expect(resolved[:description]).to eq("Pull request review")
      expect(resolved[:system_prompt]).to include("templates/pr.md")
      expect(resolved[:context]).to eq("project")
      expect(resolved[:subject]).to eq({"commands" => ["git diff origin/main...HEAD"]})
      expect(resolved[:model]).to eq("google:gemini-2.0-flash-exp")
    end

    it "applies overrides to preset" do
      overrides = {
        model: "openai:gpt-4",
        context: "custom",
        subject: "HEAD~1..HEAD"
      }

      resolved = manager.resolve_preset("pr", overrides)

      expect(resolved[:model]).to eq("openai:gpt-4")
      expect(resolved[:context]).to eq("custom")
      expect(resolved[:subject]).to eq({"commands" => ["git diff HEAD~1..HEAD"]})
    end

    it "handles git range shorthand in subject override" do
      resolved = manager.resolve_preset("pr", subject: "HEAD~3..HEAD")
      expect(resolved[:subject]).to eq({"commands" => ["git diff HEAD~3..HEAD"]})
    end

    it "returns nil for non-existent preset" do
      resolved = manager.resolve_preset("nonexistent")
      expect(resolved).to be_nil
    end
  end

  describe "#default_model" do
    let(:manager) { described_class.new(project_root: temp_dir) }

    it "returns the default model from config" do
      expect(manager.default_model).to eq("google:gemini-2.0-flash-exp")
    end
  end

  describe "#default_context" do
    let(:manager) { described_class.new(project_root: temp_dir) }

    it "returns the default context from config" do
      expect(manager.default_context).to eq("project")
    end
  end

  describe "#default_output_format" do
    let(:manager) { described_class.new(project_root: temp_dir) }

    it "returns the default output format from config" do
      expect(manager.default_output_format).to eq("markdown")
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/search/preset_manager"
require "tempfile"
require "yaml"

RSpec.describe CodingAgentTools::Molecules::Search::PresetManager do
  let(:temp_config) { Tempfile.new(['search-presets', '.yml']) }
  let(:manager) { described_class.new(config_paths: [temp_config.path]) }

  after do
    temp_config.close
    temp_config.unlink
  end

  describe "#initialize" do
    it "loads built-in presets" do
      expect(manager.list).to include("todo", "ruby", "tests", "recent", "git-changes")
    end

    it "loads presets from config file" do
      config = {
        "custom_preset" => {
          "pattern" => "custom_pattern",
          "type" => "content"
        }
      }
      File.write(temp_config.path, YAML.dump(config))
      
      manager = described_class.new(config_paths: [temp_config.path])
      
      expect(manager.exists?("custom_preset")).to be true
      expect(manager.get("custom_preset")).to eq(config["custom_preset"])
    end
  end

  describe "#get" do
    it "returns preset by name" do
      preset = manager.get("todo")
      
      expect(preset).to include("pattern", "type")
      expect(preset["pattern"]).to include("TODO")
    end

    it "returns nil for non-existent preset" do
      expect(manager.get("non_existent")).to be nil
    end

    it "accepts symbol names" do
      preset = manager.get(:ruby)
      
      expect(preset).to include("glob", "type")
    end
  end

  describe "#list" do
    it "returns sorted list of preset names" do
      presets = manager.list
      
      expect(presets).to be_an(Array)
      expect(presets).to eq(presets.sort)
      expect(presets).to include("todo", "ruby")
    end
  end

  describe "#exists?" do
    it "returns true for existing presets" do
      expect(manager.exists?("todo")).to be true
      expect(manager.exists?(:ruby)).to be true
    end

    it "returns false for non-existent presets" do
      expect(manager.exists?("non_existent")).to be false
    end
  end

  describe "#merge_with_options" do
    it "merges preset with options" do
      result = manager.merge_with_options("ruby", { max_results: 100 })
      
      expect(result).to include("glob" => "*.rb", "type" => "file", max_results: 100)
    end

    it "gives precedence to options over preset" do
      result = manager.merge_with_options("ruby", { type: "content" })
      
      expect(result[:type]).to eq("content")
    end

    it "returns options if preset doesn't exist" do
      options = { pattern: "test" }
      result = manager.merge_with_options("non_existent", options)
      
      expect(result).to eq(options)
    end
  end

  describe "#apply_variables" do
    it "substitutes variables in preset" do
      preset = {
        "pattern" => "${SEARCH_TERM}",
        "path" => "${PROJECT_ROOT}/src"
      }
      variables = {
        "SEARCH_TERM" => "TODO",
        "PROJECT_ROOT" => "/home/user/project"
      }
      
      result = manager.apply_variables(preset, variables)
      
      expect(result["pattern"]).to eq("TODO")
      expect(result["path"]).to eq("/home/user/project/src")
    end

    it "substitutes environment variables" do
      ENV["TEST_VAR"] = "test_value"
      preset = { "pattern" => "${ENV:TEST_VAR}" }
      
      result = manager.apply_variables(preset, {})
      
      expect(result["pattern"]).to eq("test_value")
    ensure
      ENV.delete("TEST_VAR")
    end
  end

  describe "#save" do
    it "saves new preset to file" do
      config = { "pattern" => "test", "type" => "content" }
      
      result = manager.save("new_preset", config, path: temp_config.path)
      
      expect(result).to be true
      expect(manager.exists?("new_preset")).to be true
      expect(manager.get("new_preset")).to eq(config)
    end

    it "updates existing preset" do
      manager.save("existing", { "pattern" => "old" }, path: temp_config.path)
      manager.save("existing", { "pattern" => "new" }, path: temp_config.path)
      
      expect(manager.get("existing")["pattern"]).to eq("new")
    end
  end

  describe "#delete" do
    it "deletes preset from file" do
      manager.save("to_delete", { "pattern" => "test" }, path: temp_config.path)
      
      result = manager.delete("to_delete", path: temp_config.path)
      
      expect(result).to be true
      expect(manager.exists?("to_delete")).to be false
    end

    it "returns false if preset doesn't exist" do
      result = manager.delete("non_existent", path: temp_config.path)
      
      expect(result).to be false
    end
  end
end
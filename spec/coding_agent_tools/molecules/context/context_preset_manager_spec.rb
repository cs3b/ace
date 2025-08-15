# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "fileutils"
require_relative "../../../../lib/coding_agent_tools/molecules/context/context_preset_manager"

RSpec.describe CodingAgentTools::Molecules::Context::ContextPresetManager do
  let(:temp_dir) { Dir.mktmpdir }
  let(:config_dir) { File.join(temp_dir, ".coding-agent") }
  let(:config_path) { File.join(config_dir, "context.yml") }
  let(:template_dir) { File.join(temp_dir, "docs", "context") }
  let(:template_file) { File.join(template_dir, "project.md") }
  let(:manager) { described_class.new(nil, temp_dir) }

  before do
    FileUtils.mkdir_p(config_dir)
    FileUtils.mkdir_p(template_dir)
    
    # Create a basic template file
    File.write(template_file, "# Project Context\n\nSample content")
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#list_presets" do
    context "with default configuration" do
      it "returns default presets" do
        presets = manager.list_presets
        
        expect(presets).to be_an(Array)
        expect(presets.length).to eq(1)
        
        project_preset = presets.find { |p| p[:name] == "project" }
        expect(project_preset).not_to be_nil
        expect(project_preset[:description]).to eq("Main project context")
        expect(project_preset[:template]).to include("docs/context/project.md")
        expect(project_preset[:chunk_limit]).to eq(150_000)
      end
    end

    context "with custom configuration" do
      before do
        File.write(config_path, <<~YAML)
          presets:
            custom:
              description: "Custom preset"
              template: "custom/template.md"
              output: "custom/output.md"
              chunk_limit: 200000
            project:
              output: "custom/project.md"
        YAML
      end

      it "returns both default and custom presets" do
        presets = manager.list_presets
        
        expect(presets.length).to eq(2)
        
        custom_preset = presets.find { |p| p[:name] == "custom" }
        expect(custom_preset[:description]).to eq("Custom preset")
        expect(custom_preset[:chunk_limit]).to eq(200_000)
        
        project_preset = presets.find { |p| p[:name] == "project" }
        expect(project_preset[:output]).to include("custom/project.md")
      end
    end
  end

  describe "#resolve_preset" do
    context "with existing preset" do
      it "resolves preset configuration successfully" do
        resolved = manager.resolve_preset("project")
        
        expect(resolved).to be_a(Hash)
        expect(resolved[:name]).to eq("project")
        expect(resolved[:description]).to eq("Main project context")
        expect(File.exist?(resolved[:template])).to be true
        expect(resolved[:chunk_limit]).to eq(150_000)
      end
    end

    context "with non-existent preset" do
      it "returns nil" do
        resolved = manager.resolve_preset("nonexistent")
        expect(resolved).to be_nil
      end
    end

    context "with missing template file" do
      before do
        File.write(config_path, <<~YAML)
          presets:
            missing_template:
              description: "Missing template"
              template: "missing/template.md"
        YAML
      end

      it "raises error for missing template" do
        expect { manager.resolve_preset("missing_template") }.to raise_error(
          CodingAgentTools::Error, /Template file not found/
        )
      end
    end

    context "with forbidden template path" do
      let(:forbidden_template) { File.join(temp_dir, ".git", "template.md") }
      
      before do
        FileUtils.mkdir_p(File.dirname(forbidden_template))
        File.write(forbidden_template, "content")
        
        File.write(config_path, <<~YAML)
          presets:
            forbidden:
              description: "Forbidden template"
              template: ".git/template.md"
        YAML
      end

      it "raises error for forbidden path" do
        expect { manager.resolve_preset("forbidden") }.to raise_error(
          CodingAgentTools::Error, /not allowed.*forbidden pattern/
        )
      end
    end
  end

  describe "#preset_exists?" do
    it "returns true for existing preset" do
      expect(manager.preset_exists?("project")).to be true
    end

    it "returns false for non-existent preset" do
      expect(manager.preset_exists?("nonexistent")).to be false
    end
  end

  describe "#default_output_path" do
    it "generates default output path in cache directory" do
      path = manager.default_output_path("project")
      expect(path).to include("docs/context/cached/project.md")
      expect(path).to start_with(temp_dir)
    end
  end

  describe "#validate_all_presets" do
    context "with valid presets" do
      it "returns validation results for all presets" do
        results = manager.validate_all_presets
        
        expect(results).to be_an(Array)
        expect(results.length).to eq(1)
        
        project_result = results.find { |r| r[:name] == "project" }
        expect(project_result[:valid]).to be true
        expect(project_result[:template_exists]).to be true
        expect(project_result[:message]).to eq("Valid")
      end
    end

    context "with invalid presets" do
      before do
        File.write(config_path, <<~YAML)
          presets:
            invalid:
              description: "Invalid preset"
              template: "missing/template.md"
        YAML
      end

      it "returns validation errors" do
        results = manager.validate_all_presets
        
        invalid_result = results.find { |r| r[:name] == "invalid" }
        expect(invalid_result[:valid]).to be false
        expect(invalid_result[:template_exists]).to be false
        expect(invalid_result[:message]).to include("Template file not found")
      end
    end
  end

  describe "path resolution" do
    context "with relative paths" do
      before do
        File.write(config_path, <<~YAML)
          presets:
            relative:
              template: "docs/context/project.md"
              output: "docs/context/cached/relative.md"
        YAML
      end

      it "resolves relative paths correctly" do
        resolved = manager.resolve_preset("relative")
        
        expect(resolved[:template]).to start_with(temp_dir)
        expect(resolved[:output]).to start_with(temp_dir)
        expect(resolved[:template]).to end_with("docs/context/project.md")
        expect(resolved[:output]).to end_with("docs/context/cached/relative.md")
      end
    end

    context "with absolute paths" do
      let(:absolute_template) { File.join(temp_dir, "docs", "absolute_template.md") }
      let(:absolute_output) { File.join(temp_dir, "docs", "absolute_output.md") }
      
      before do
        FileUtils.mkdir_p(File.dirname(absolute_template))
        File.write(absolute_template, "content")
        
        File.write(config_path, <<~YAML)
          presets:
            absolute:
              template: "#{absolute_template}"
              output: "#{absolute_output}"
        YAML
      end

      it "uses absolute paths as-is" do
        resolved = manager.resolve_preset("absolute")
        
        expect(resolved[:template]).to eq(absolute_template)
        expect(resolved[:output]).to eq(absolute_output)
      end
    end
  end

  describe "security validation" do
    let(:allowed_template) { File.join(temp_dir, "docs", "allowed.md") }
    let(:forbidden_template) { File.join(temp_dir, ".env") }
    
    before do
      File.write(allowed_template, "content")
      File.write(forbidden_template, "secret")
    end

    context "with allowed paths" do
      before do
        File.write(config_path, <<~YAML)
          presets:
            allowed:
              template: "docs/allowed.md"
              output: "docs/output.md"
        YAML
      end

      it "allows access to permitted paths" do
        expect { manager.resolve_preset("allowed") }.not_to raise_error
      end
    end

    context "with forbidden paths" do
      before do
        File.write(config_path, <<~YAML)
          presets:
            forbidden_template:
              template: ".env"
            forbidden_output:
              template: "docs/allowed.md"
              output: ".env.output"
        YAML
      end

      it "blocks access to forbidden template paths" do
        expect { manager.resolve_preset("forbidden_template") }.to raise_error(
          CodingAgentTools::Error, /not allowed.*forbidden pattern/
        )
      end

      it "blocks access to forbidden output paths" do
        expect { manager.resolve_preset("forbidden_output") }.to raise_error(
          CodingAgentTools::Error, /not allowed.*forbidden pattern/
        )
      end
    end
  end

  describe "#get_config" do
    it "returns loaded configuration" do
      config = manager.get_config
      
      expect(config).to be_a(Hash)
      expect(config).to have_key("presets")
      expect(config).to have_key("settings")
      expect(config).to have_key("security")
    end
  end
end
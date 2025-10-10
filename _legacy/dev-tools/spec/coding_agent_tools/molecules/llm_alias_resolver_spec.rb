# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/coding_agent_tools/molecules/llm_alias_resolver"

RSpec.describe CodingAgentTools::Molecules::LlmAliasResolver do
  let(:temp_config_dir) { Dir.mktmpdir }
  let(:temp_default_config_path) { File.join(temp_config_dir, "default-llm-aliases.yml") }
  let(:temp_user_config_path) { File.join(temp_config_dir, "llm-aliases.yml") }
  
  let(:default_aliases) do
    {
      "global" => {
        "opus" => "cc:claude-opus-4-1",
        "sonnet" => "cc:claude-sonnet-4-0",
        "gflash" => "google:gemini-2.5-flash"
      },
      "providers" => {
        "cc" => {
          "opus" => "claude-opus-4-1",
          "sonnet" => "claude-sonnet-4-0"
        },
        "google" => {
          "flash" => "gemini-2.5-flash"
        }
      }
    }
  end

  before do
    # Create default config file
    File.write(temp_default_config_path, default_aliases.to_yaml)
    
    # Stub the default config path
    stub_const("CodingAgentTools::Molecules::LlmAliasResolver::DEFAULT_CONFIG_PATH", temp_default_config_path)
    
    # Stub user config path by stubbing the method
    allow_any_instance_of(described_class).to receive(:user_aliases_config_path).and_return(temp_user_config_path)
  end

  after do
    FileUtils.remove_entry(temp_config_dir) if Dir.exist?(temp_config_dir)
  end

  describe "#initialize" do
    it "loads default config when no user config exists" do
      resolver = described_class.new
      expect(resolver.aliases_config).to eq(default_aliases)
    end

    it "loads user config when it exists" do
      user_aliases = {
        "global" => {
          "custom" => "openai:gpt-4o"
        },
        "providers" => {}
      }
      File.write(temp_user_config_path, user_aliases.to_yaml)
      
      resolver = described_class.new
      expect(resolver.aliases_config).to eq(user_aliases)
    end

    it "falls back to empty config when no files exist" do
      FileUtils.rm_f(temp_default_config_path)
      
      resolver = described_class.new
      expect(resolver.aliases_config).to eq({ "global" => {}, "providers" => {} })
    end
  end

  describe "#resolve" do
    let(:resolver) { described_class.new }

    context "with global aliases" do
      it "resolves global alias to provider:model format" do
        expect(resolver.resolve("opus")).to eq("cc:claude-opus-4-1")
        expect(resolver.resolve("sonnet")).to eq("cc:claude-sonnet-4-0")
        expect(resolver.resolve("gflash")).to eq("google:gemini-2.5-flash")
      end
    end

    context "with provider-specific aliases" do
      it "resolves provider-specific aliases" do
        expect(resolver.resolve("cc:opus")).to eq("cc:claude-opus-4-1")
        expect(resolver.resolve("cc:sonnet")).to eq("cc:claude-sonnet-4-0")
        expect(resolver.resolve("google:flash")).to eq("google:gemini-2.5-flash")
      end
    end

    context "with direct model names" do
      it "returns provider:model as-is when not an alias" do
        expect(resolver.resolve("google:gemini-1.5-pro")).to eq("google:gemini-1.5-pro")
        expect(resolver.resolve("openai:gpt-4o")).to eq("openai:gpt-4o")
      end

      it "returns model-only input as-is when not an alias" do
        expect(resolver.resolve("unknown-model")).to eq("unknown-model")
      end
    end

    context "with edge cases" do
      it "handles empty and nil input" do
        expect(resolver.resolve("")).to eq("")
        expect(resolver.resolve(nil)).to eq("")
      end

      it "handles whitespace" do
        expect(resolver.resolve("  opus  ")).to eq("cc:claude-opus-4-1")
        expect(resolver.resolve("  cc:opus  ")).to eq("cc:claude-opus-4-1")
      end
    end
  end

  describe "#alias?" do
    let(:resolver) { described_class.new }

    it "returns true for global aliases" do
      expect(resolver.alias?("opus")).to be true
      expect(resolver.alias?("gflash")).to be true
    end

    it "returns true for provider-specific aliases" do
      expect(resolver.alias?("cc:opus")).to be true
      expect(resolver.alias?("google:flash")).to be true
    end

    it "returns false for non-aliases" do
      expect(resolver.alias?("unknown")).to be false
      expect(resolver.alias?("google:gemini-1.5-pro")).to be false
    end
  end

  describe "#available_aliases" do
    let(:resolver) { described_class.new }

    it "returns all available aliases" do
      aliases = resolver.available_aliases
      
      expect(aliases[:global]).to include(
        "opus" => "cc:claude-opus-4-1",
        "sonnet" => "cc:claude-sonnet-4-0",
        "gflash" => "google:gemini-2.5-flash"
      )
      
      expect(aliases[:providers]).to include(
        "cc" => {
          "opus" => "claude-opus-4-1",
          "sonnet" => "claude-sonnet-4-0"
        },
        "google" => {
          "flash" => "gemini-2.5-flash"
        }
      )
    end
  end
end

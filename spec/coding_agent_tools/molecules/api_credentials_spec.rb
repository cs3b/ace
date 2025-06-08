# frozen_string_literal: true

require "spec_helper"
require "coding_agent_tools/molecules/api_credentials"
require "tempfile"
require "fileutils"

RSpec.describe CodingAgentTools::Molecules::APICredentials do
  # Store original ENV state
  let(:original_env) { ENV.to_h }

  # Clean up ENV and reset configuration after each test
  after do
    ENV.clear
    original_env.each { |k, v| ENV[k] = v }
    described_class.reset!
  end

  describe "configuration" do
    describe ".configure" do
      it "allows setting API keys via configuration block" do
        described_class.configure do |config|
          config["GEMINI_API_KEY"] = "test-api-key"
          config["CUSTOM_API_KEY"] = "custom-key"
        end

        expect(described_class.config["GEMINI_API_KEY"]).to eq("test-api-key")
        expect(described_class.config["CUSTOM_API_KEY"]).to eq("custom-key")
      end

      it "preserves existing configuration when called without block" do
        described_class.config["EXISTING_KEY"] = "existing-value"
        described_class.configure
        expect(described_class.config["EXISTING_KEY"]).to eq("existing-value")
      end
    end

    describe ".reset!" do
      it "clears all configuration" do
        described_class.config["KEY1"] = "value1"
        described_class.config["KEY2"] = "value2"

        described_class.reset!

        expect(described_class.config).to eq({})
      end
    end
  end

  describe "#initialize" do
    context "with default parameters" do
      let(:credentials) { described_class.new }

      it "uses nil environment key name when not provided" do
        expect(credentials.instance_variable_get(:@env_key_name)).to be_nil
      end

      it "attempts to find .env file automatically" do
        expect(credentials.instance_variable_get(:@env_file_path)).to eq(File.expand_path(".env", Dir.pwd))
      end
    end

    context "with custom parameters" do
      let(:credentials) { described_class.new(env_key_name: "CUSTOM_API_KEY", env_file_path: "/custom/path/.env") }

      it "uses custom environment key name" do
        expect(credentials.instance_variable_get(:@env_key_name)).to eq("CUSTOM_API_KEY")
      end

      it "uses custom env file path" do
        expect(credentials.instance_variable_get(:@env_file_path)).to eq("/custom/path/.env")
      end
    end

    context "with .env file" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:env_file_path) { File.join(temp_dir, ".env") }

      before do
        File.write(env_file_path, "GEMINI_API_KEY=env-file-key\nOTHER_KEY=other-value")
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "loads environment variables from specified .env file" do
        described_class.new(env_key_name: "GEMINI_API_KEY", env_file_path: env_file_path)
        expect(ENV["GEMINI_API_KEY"]).to eq("env-file-key")
        expect(ENV["OTHER_KEY"]).to eq("other-value")
      end
    end
  end

  describe "#api_key" do
    subject(:credentials) { described_class.new(env_key_name: "GEMINI_API_KEY") }

    context "when API key is in singleton configuration" do
      before do
        described_class.configure do |config|
          config["GEMINI_API_KEY"] = "config-api-key"
        end
      end

      it "returns the configured API key" do
        expect(credentials.api_key).to eq("config-api-key")
      end

      it "prefers configuration over environment variable" do
        ENV["GEMINI_API_KEY"] = "env-api-key"
        expect(credentials.api_key).to eq("config-api-key")
      end
    end

    context "when API key is in environment variable" do
      before do
        ENV["GEMINI_API_KEY"] = "env-api-key"
      end

      it "returns the environment variable value" do
        expect(credentials.api_key).to eq("env-api-key")
      end
    end

    context "when API key is not found" do
      before do
        ENV.delete("GEMINI_API_KEY")
        described_class.reset!
      end

      it "raises KeyError with helpful message" do
        # Create credentials object after clearing environment
        test_credentials = described_class.new(env_key_name: "GEMINI_API_KEY", env_file_path: "/nonexistent/path/.env")

        expect { test_credentials.api_key }.to raise_error(
          KeyError,
          "API key not found. Please set GEMINI_API_KEY environment variable or configure it via APICredentials.configure"
        )
      end
    end

    context "when API key is empty" do
      before do
        ENV["GEMINI_API_KEY"] = "   "
      end

      it "raises KeyError for whitespace-only value" do
        expect { credentials.api_key }.to raise_error(KeyError)
      end
    end

    context "with custom environment key" do
      subject(:credentials) { described_class.new(env_key_name: "CUSTOM_API_KEY") }

      before do
        ENV["CUSTOM_API_KEY"] = "custom-key-value"
      end

      it "uses the custom environment key" do
        expect(credentials.api_key).to eq("custom-key-value")
      end

      it "raises error with custom key name in message" do
        ENV.delete("CUSTOM_API_KEY")
        expect { credentials.api_key }.to raise_error(
          KeyError,
          /Please set CUSTOM_API_KEY environment variable/
        )
      end
    end

    context "when env_key_name is not provided" do
      subject(:credentials) { described_class.new }

      it "raises KeyError with appropriate message" do
        expect { credentials.api_key }.to raise_error(
          KeyError,
          "env_key_name not set. Please provide it during initialization."
        )
      end
    end
  end

  describe "#api_key_present?" do
    subject(:credentials) { described_class.new(env_key_name: "GEMINI_API_KEY") }

    context "when API key is in configuration" do
      before do
        described_class.configure do |config|
          config["GEMINI_API_KEY"] = "config-key"
        end
      end

      it "returns true" do
        expect(credentials.api_key_present?).to be true
      end
    end

    context "when API key is in environment" do
      before do
        ENV["GEMINI_API_KEY"] = "env-key"
      end

      it "returns true" do
        expect(credentials.api_key_present?).to be true
      end
    end

    context "when API key is empty in environment" do
      before do
        ENV["GEMINI_API_KEY"] = ""
      end

      it "returns false" do
        expect(credentials.api_key_present?).to be false
      end
    end

    context "when API key is not found" do
      before do
        ENV.delete("GEMINI_API_KEY")
        described_class.reset!
        # Ensure the subject is created and then remove any env vars that might have been loaded
        credentials
        ENV.delete("GEMINI_API_KEY")
      end

      it "returns false" do
        expect(credentials.api_key_present?).to be false
      end
    end

    context "when env_key_name is not provided" do
      subject(:credentials) { described_class.new }

      it "returns false" do
        expect(credentials.api_key_present?).to be false
      end
    end
  end

  describe "#api_key_with_prefix" do
    subject(:credentials) { described_class.new(env_key_name: "GEMINI_API_KEY") }

    before do
      ENV["GEMINI_API_KEY"] = "test-key-123"
    end

    it "returns API key with specified prefix" do
      expect(credentials.api_key_with_prefix("Bearer ")).to eq("Bearer test-key-123")
    end

    it "handles empty prefix" do
      expect(credentials.api_key_with_prefix("")).to eq("test-key-123")
    end

    it "handles complex prefixes" do
      expect(credentials.api_key_with_prefix("API-KEY: ")).to eq("API-KEY: test-key-123")
    end

    it "raises error if API key not found" do
      # Ensure credentials object is created first (which may load .env)
      credentials
      # Then delete the environment variable
      ENV.delete("GEMINI_API_KEY")
      expect { credentials.api_key_with_prefix("Bearer ") }.to raise_error(KeyError)
    end
  end

  describe "#load_for_environment" do
    subject(:credentials) { described_class.new(env_key_name: "GEMINI_API_KEY") }

    before do
      ENV["DEVELOPMENT_API_KEY"] = "dev-key"
      ENV["DEVELOPMENT_API_URL"] = "https://dev.api.com"
      ENV["DEVELOPMENT_TOKEN"] = "dev-token"
      ENV["DEVELOPMENT_DATABASE_URL"] = "postgres://dev"
      ENV["PRODUCTION_API_KEY"] = "prod-key"
      ENV["PRODUCTION_SECRET_TOKEN"] = "prod-secret"
      ENV["OTHER_VAR"] = "other"
    end

    it "returns API-related variables for development environment" do
      result = credentials.load_for_environment("development")

      expect(result).to include(
        "DEVELOPMENT_API_KEY" => "dev-key",
        "DEVELOPMENT_API_URL" => "https://dev.api.com",
        "DEVELOPMENT_TOKEN" => "dev-token"
      )
      expect(result).not_to include("DEVELOPMENT_DATABASE_URL")
      expect(result).not_to include("PRODUCTION_API_KEY")
      expect(result).not_to include("OTHER_VAR")
    end

    it "returns API-related variables for production environment" do
      result = credentials.load_for_environment("production")

      expect(result).to include(
        "PRODUCTION_API_KEY" => "prod-key",
        "PRODUCTION_SECRET_TOKEN" => "prod-secret"
      )
      expect(result).not_to include("DEVELOPMENT_API_KEY")
    end

    it "handles case-insensitive environment names" do
      result = credentials.load_for_environment("Production")
      expect(result).to include("PRODUCTION_API_KEY" => "prod-key")
    end

    it "returns empty hash for non-existent environment" do
      result = credentials.load_for_environment("staging")
      expect(result).to eq({})
    end
  end

  describe "private methods" do
    describe "#find_env_file" do
      let(:credentials) { described_class.new(env_key_name: "GEMINI_API_KEY") }
      let(:temp_dir) { Dir.mktmpdir }

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "finds .env file in current directory" do
        canonical_temp_dir = File.expand_path(temp_dir)
        env_file = File.join(canonical_temp_dir, ".env")
        FileUtils.touch(env_file)

        Dir.chdir(canonical_temp_dir) do
          found_path = credentials.send(:find_env_file)
          # Use File.realpath to resolve symlinks consistently on both paths
          expect(File.realpath(found_path)).to eq(File.realpath(env_file))
        end
      end

      it "finds .env file in parent directory" do
        canonical_temp_dir = File.expand_path(temp_dir)
        sub_dir = File.join(canonical_temp_dir, "subdir")
        FileUtils.mkdir_p(sub_dir)
        env_file = File.join(canonical_temp_dir, ".env") # .env in canonical_temp_dir (parent)
        FileUtils.touch(env_file)

        Dir.chdir(sub_dir) do # CWD is sub_dir, but parent is canonical_temp_dir
          found_path = credentials.send(:find_env_file)
          # Use File.realpath to resolve symlinks consistently on both paths
          expect(File.realpath(found_path)).to eq(File.realpath(env_file))
        end
      end

      it "returns nil when no .env file found" do
        canonical_temp_dir = File.expand_path(temp_dir)
        Dir.chdir(canonical_temp_dir) do
          found_path = credentials.send(:find_env_file)
          expect(found_path).to be_nil
        end
      end
    end
  end

  describe "integration scenarios" do
    context "with multiple API key sources" do
      let(:temp_dir) { Dir.mktmpdir }
      let(:env_file_path) { File.join(temp_dir, ".env") }

      before do
        # Set up .env file
        File.write(env_file_path, "GEMINI_API_KEY=file-key")

        # Set up environment variable
        ENV["GEMINI_API_KEY"] = "env-key"

        # Set up configuration
        described_class.configure do |config|
          config["GEMINI_API_KEY"] = "config-key"
        end
      end

      after do
        FileUtils.rm_rf(temp_dir)
      end

      it "follows correct precedence: config > env > file" do
        credentials = described_class.new(env_key_name: "GEMINI_API_KEY", env_file_path: env_file_path)
        expect(credentials.api_key).to eq("config-key")

        described_class.reset!
        expect(credentials.api_key).to eq("env-key")
      end
    end

    context "with custom environment key and configuration" do
      it "works with custom key names throughout" do
        described_class.configure do |config|
          config["MY_CUSTOM_KEY"] = "custom-value"
        end

        credentials = described_class.new(env_key_name: "MY_CUSTOM_KEY")
        expect(credentials.api_key).to eq("custom-value")
        expect(credentials.api_key_present?).to be true
        expect(credentials.api_key_with_prefix("Token: ")).to eq("Token: custom-value")
      end
    end
  end
end

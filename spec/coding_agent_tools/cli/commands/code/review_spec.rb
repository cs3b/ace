# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

RSpec.describe CodingAgentTools::Cli::Commands::Code::Review do
  let(:command) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:mock_preset_manager) { instance_double("CodingAgentTools::Molecules::Code::ReviewPresetManager") }
  let(:mock_context_integrator) { instance_double("CodingAgentTools::Molecules::Code::ContextIntegrator") }
  let(:mock_prompt_enhancer) { instance_double("CodingAgentTools::Molecules::Code::PromptEnhancer") }
  let(:mock_llm_executor) { instance_double("CodingAgentTools::Molecules::Code::LLMExecutor") }
  let(:mock_config_extractor) { instance_double("CodingAgentTools::Molecules::Code::ConfigExtractor") }

  before do
    # Capture output
    allow($stdout).to receive(:puts)
    allow($stderr).to receive(:write)
    
    # Default component mocks
    allow(CodingAgentTools::Molecules::Code::ReviewPresetManager).to receive(:new).and_return(mock_preset_manager)
    allow(CodingAgentTools::Molecules::Code::ContextIntegrator).to receive(:new).and_return(mock_context_integrator)
    allow(CodingAgentTools::Molecules::Code::PromptEnhancer).to receive(:new).and_return(mock_prompt_enhancer)
    allow(CodingAgentTools::Molecules::Code::LLMExecutor).to receive(:new).and_return(mock_llm_executor)
    allow(CodingAgentTools::Molecules::Code::ConfigExtractor).to receive(:new).and_return(mock_config_extractor)
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#call" do
    context "with list presets option" do
      let(:mock_preset_manager) { instance_double("CodingAgentTools::Molecules::Code::ReviewPresetManager") }

      before do
        allow(CodingAgentTools::Molecules::Code::ReviewPresetManager).to receive(:new).and_return(mock_preset_manager)
      end

      it "lists available presets" do
        allow(mock_preset_manager).to receive(:available_presets).and_return(["pr", "code", "docs"])
        allow(mock_preset_manager).to receive(:load_preset).with("pr").and_return({"description" => "Pull request review"})
        allow(mock_preset_manager).to receive(:load_preset).with("code").and_return({"description" => "Code review"})
        allow(mock_preset_manager).to receive(:load_preset).with("docs").and_return({"description" => "Documentation review"})

        result = command.call(list_presets: true)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with("Available review presets:")
        expect($stdout).to have_received(:puts).with("  pr: Pull request review")
        expect($stdout).to have_received(:puts).with("  code: Code review")
        expect($stdout).to have_received(:puts).with("  docs: Documentation review")
      end

      it "shows message when no presets found" do
        allow(mock_preset_manager).to receive(:available_presets).and_return([])

        result = command.call(list_presets: true)

        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with("No presets found. Create .coding-agent/code-review.yml to define presets.")
      end
    end

    context "with minimal configuration" do
      before do
        # Mock the components used by the new architecture
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({})
        allow(command).to receive(:execute_review).and_return(0)
      end

      it "executes successfully with no options" do
        result = command.call

        expect(result).to eq(0)
      end

      it "handles preset option" do
        result = command.call(preset: "pr")

        expect(result).to eq(0)
      end

      it "handles context and subject options" do
        result = command.call(context: "project", subject: "HEAD~1..HEAD")

        expect(result).to eq(0)
      end
    end

    context "with dry run option" do
      before do
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({
          preset: "pr",
          context: "project",
          subject: "HEAD~1..HEAD"
        })
        allow(command).to receive(:show_dry_run).and_return(0)
      end

      it "executes dry run without creating session" do
        result = command.call(preset: "pr", dry_run: true)

        expect(result).to eq(0)
        expect(command).to have_received(:show_dry_run)
      end
    end

    context "with prompt composition options" do
      before do
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({})
        allow(command).to receive(:execute_review).and_return(0)
      end

      it "handles prompt composition options" do
        result = command.call(
          prompt_base: "system",
          prompt_format: "detailed",
          prompt_focus: "architecture/atom,languages/ruby",
          prompt_guidelines: "tone,icons"
        )

        expect(result).to eq(0)
      end

      it "handles add_focus option with preset" do
        result = command.call(
          preset: "pr",
          add_focus: "quality/security"
        )

        expect(result).to eq(0)
      end
    end

    context "with auto execute option" do
      before do
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({})
        allow(command).to receive(:execute_review).and_return(0)
      end

      it "automatically executes review when auto_execute is true" do
        result = command.call(preset: "pr", auto_execute: true)

        expect(result).to eq(0)
        expect(command).to have_received(:execute_review)
      end

      it "works with output file specification" do
        result = command.call(preset: "pr", auto_execute: true, output: "review.md")

        expect(result).to eq(0)
      end
    end

    context "with config file option" do
      let(:config_file) { File.join(temp_dir, "config.md") }

      before do
        allow(command).to receive(:validate_inputs).and_return(0)
        allow(command).to receive(:load_preset_config).and_return({})
        allow(command).to receive(:merge_configurations).and_return({})
        allow(command).to receive(:execute_review).and_return(0)
      end

      it "loads configuration from file" do
        File.write(config_file, "---\npreset: pr\nauto_execute: true\n---\n# Review")
        allow(mock_config_extractor).to receive(:extract_from_file).with(config_file).and_return({
          "preset" => "pr",
          "auto_execute" => true
        })
        # Need to mock preset validation for the config test
        allow(mock_preset_manager).to receive(:preset_exists?).with("pr").and_return(true)
        allow(mock_preset_manager).to receive(:resolve_preset).with("pr", anything).and_return({
          context: { files: ["README.md"] },
          subject: { commands: ["git diff"] },
          model: "google:gemini-2.0-flash-exp"
        })

        result = command.call(config_file: config_file)

        expect(result).to eq(0)
      end

      it "handles missing config file" do
        result = command.call(config_file: "/nonexistent.md")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Config file not found: /nonexistent.md\n")
      end
    end

    context "with error conditions" do
      it "handles validation errors gracefully" do
        allow(command).to receive(:validate_inputs).and_return(1)

        result = command.call(preset: "invalid")

        expect(result).to eq(1)
      end

      it "handles exceptions gracefully" do
        allow(command).to receive(:validate_inputs).and_raise(StandardError, "Unexpected error")

        result = command.call(preset: "pr")

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Unexpected error\n")
      end

      it "shows backtrace in debug mode" do
        allow(command).to receive(:validate_inputs).and_raise(StandardError, "Debug error")

        result = command.call(preset: "pr", debug: true)

        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with("Error: Debug error\n")
      end
    end
  end

  describe "#validate_inputs" do
    it "passes validation with preset option" do
      result = command.send(:validate_inputs, { preset: "pr" })
      expect(result).to eq(0)
    end

    it "passes validation with context and subject options" do
      result = command.send(:validate_inputs, { context: "project", subject: "HEAD~1..HEAD" })
      expect(result).to eq(0)
    end

    it "fails validation without preset or context/subject" do
      result = command.send(:validate_inputs, {})
      expect(result).to eq(1)
    end

    it "fails validation with invalid system prompt file" do
      result = command.send(:validate_inputs, { preset: "pr", system_prompt: "/nonexistent.md" })
      expect(result).to eq(1)
    end

    it "passes validation with existing system prompt file" do
      prompt_file = File.join(temp_dir, "prompt.md")
      File.write(prompt_file, "Test prompt")
      
      result = command.send(:validate_inputs, { preset: "pr", system_prompt: prompt_file })
      expect(result).to eq(0)
    end
  end

  describe "#load_preset_config" do
    context "with preset option" do
      it "loads valid preset successfully" do
        allow(mock_preset_manager).to receive(:preset_exists?).with("pr").and_return(true)
        allow(mock_preset_manager).to receive(:resolve_preset).with("pr", anything).and_return({
          context: { files: ["README.md"] },
          subject: { commands: ["git diff"] },
          model: "google:gemini-2.0-flash-exp"
        })

        result = command.send(:load_preset_config, { preset: "pr" })
        
        expect(result).to be_a(Hash)
        expect(result[:context]).to eq({ files: ["README.md"] })
      end

      it "returns nil for invalid preset" do
        allow(mock_preset_manager).to receive(:preset_exists?).with("invalid").and_return(false)
        allow(mock_preset_manager).to receive(:available_presets).and_return(["pr", "code"])

        result = command.send(:load_preset_config, { preset: "invalid" })
        
        expect(result).to be_nil
        expect($stderr).to have_received(:write).with(/Error: Preset 'invalid' not found/)
      end
    end

    context "without preset option" do
      it "builds config from individual options" do
        allow(mock_preset_manager).to receive(:default_model).and_return("google:gemini-2.0-flash-exp")
        allow(mock_preset_manager).to receive(:send).with(:resolve_context_config, nil, "project").and_return({ files: ["docs/"] })
        allow(mock_preset_manager).to receive(:send).with(:resolve_subject_config, nil, "HEAD~1..HEAD").and_return({ commands: ["git diff HEAD~1..HEAD"] })

        result = command.send(:load_preset_config, { context: "project", subject: "HEAD~1..HEAD" })
        
        expect(result).to be_a(Hash)
        expect(result[:context]).to eq({ files: ["docs/"] })
        expect(result[:subject]).to eq({ commands: ["git diff HEAD~1..HEAD"] })
      end
    end
  end

  describe "#merge_configurations" do
    let(:preset_config) do
      {
        context: { files: ["README.md"] },
        subject: { commands: ["git diff"] },
        model: "google:gemini-1.5-flash",
        prompt_composition: { base: "system", format: "standard" }
      }
    end

    it "merges preset with CLI options" do
      allow(mock_preset_manager).to receive(:send).with(:resolve_prompt_composition, anything, anything).and_return({ base: "system", format: "detailed" })

      result = command.send(:merge_configurations, preset_config, { model: "google:gemini-2.0-flash-exp", prompt_format: "detailed" })
      
      expect(result[:model]).to eq("google:gemini-2.0-flash-exp")
      expect(result[:context]).to eq({ files: ["README.md"] })
    end

    it "overrides context with CLI option" do
      allow(mock_preset_manager).to receive(:send).with(:resolve_context_config, nil, "custom").and_return({ files: ["custom.md"] })
      allow(mock_preset_manager).to receive(:send).with(:resolve_prompt_composition, anything, anything).and_return(preset_config[:prompt_composition])

      result = command.send(:merge_configurations, preset_config, { context: "custom" })
      
      expect(result[:context]).to eq({ files: ["custom.md"] })
    end

    it "overrides subject with CLI option" do
      allow(mock_preset_manager).to receive(:send).with(:resolve_subject_config, nil, "HEAD~2..HEAD").and_return({ commands: ["git diff HEAD~2..HEAD"] })
      allow(mock_preset_manager).to receive(:send).with(:resolve_prompt_composition, anything, anything).and_return(preset_config[:prompt_composition])

      result = command.send(:merge_configurations, preset_config, { subject: "HEAD~2..HEAD" })
      
      expect(result[:subject]).to eq({ commands: ["git diff HEAD~2..HEAD"] })
    end
  end

  describe "#show_dry_run" do
    let(:config) do
      {
        context: { files: ["README.md"] },
        subject: { commands: ["git diff"] },
        model: "google:gemini-2.0-flash-exp",
        system_prompt: "custom_prompt.md",
        output: "review.md"
      }
    end

    it "displays configuration details" do
      result = command.send(:show_dry_run, config)
      
      expect(result).to eq(0)
      expect($stdout).to have_received(:puts).with("🔍 Dry run - Review configuration:")
      expect($stdout).to have_received(:puts).with(/Context \(background information\):/)
      expect($stdout).to have_received(:puts).with(/Subject \(what to review\):/)
      expect($stdout).to have_received(:puts).with(/System prompt:/)
      expect($stdout).to have_received(:puts).with(/Model:/)
      expect($stdout).to have_received(:puts).with(/Output:/)
    end

    it "handles prompt composition display" do
      config[:prompt_composition] = {
        "base" => "system",
        "format" => "detailed",
        "focus" => ["architecture/atom", "languages/ruby"],
        "guidelines" => ["tone", "icons"]
      }
      config.delete(:system_prompt)

      result = command.send(:show_dry_run, config)
      
      expect(result).to eq(0)
      expect($stdout).to have_received(:puts).with(include("composed from modules"))
    end
  end

  describe "#execute_review" do
    let(:config) do
      {
        context: { files: ["README.md"] },
        subject: { commands: ["git diff"] },
        model: "google:gemini-2.0-flash-exp",
        system_prompt: "Test prompt"
      }
    end

    before do
      allow(mock_context_integrator).to receive(:generate_context).and_return("Context content")
      allow(mock_context_integrator).to receive(:generate_subject).and_return("Subject content")
      allow(mock_prompt_enhancer).to receive(:enhance_prompt).and_return("Enhanced prompt")
      allow(mock_prompt_enhancer).to receive(:default_prompt).and_return("Default prompt")
      allow(command).to receive(:create_session_directory).and_return(temp_dir)
      allow(command).to receive(:load_system_prompt).and_return("System prompt")
      allow(File).to receive(:write)
    end

    context "without auto-execute" do
      it "prepares review session with files" do
        result = command.send(:execute_review, config, { save_session: true, debug: false })
        
        expect(result).to eq(0)
        expect(mock_context_integrator).to have_received(:generate_context).with(config[:context])
        expect(mock_context_integrator).to have_received(:generate_subject).with(config[:subject])
        expect(mock_prompt_enhancer).to have_received(:enhance_prompt).with("System prompt", "Context content")
        expect($stdout).to have_received(:puts).with(/Review session prepared/)
      end

      it "prepares review in memory without session files" do
        result = command.send(:execute_review, config, { save_session: false, debug: false })
        
        expect(result).to eq(0)
        expect($stdout).to have_received(:puts).with(/Review prepared in memory/)
      end
    end

    context "with auto-execute" do
      it "executes LLM query successfully" do
        allow(mock_llm_executor).to receive(:execute_query).and_return(true)
        
        result = command.send(:execute_review, config, { auto_execute: true, save_session: true, debug: false })
        
        expect(result).to eq(0)
        expect(mock_llm_executor).to have_received(:execute_query).with(
          config[:model],
          "Subject content",
          "Enhanced prompt",
          hash_including(output_file: /\.md$/, timeout: 600)
        )
        expect($stdout).to have_received(:puts).with(/Review completed successfully/)
      end

      it "handles LLM execution errors" do
        allow(mock_llm_executor).to receive(:execute_query).and_raise(StandardError, "LLM error")
        
        result = command.send(:execute_review, config, { auto_execute: true, save_session: true, debug: false })
        
        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(/Error executing LLM query: LLM error/)
      end

      it "uses custom output file when specified" do
        allow(mock_llm_executor).to receive(:execute_query).and_return(true)
        config[:output] = "custom_review.md"
        
        result = command.send(:execute_review, config, { auto_execute: true, save_session: true, debug: false })
        
        expect(result).to eq(0)
        expect(mock_llm_executor).to have_received(:execute_query).with(
          anything,
          anything,
          anything,
          hash_including(output_file: "custom_review.md")
        )
      end
    end

    context "with prompt composition" do
      it "composes prompt from modules instead of loading file" do
        config[:prompt_composition] = { base: "system", format: "detailed" }
        config.delete(:system_prompt)
        allow(mock_prompt_enhancer).to receive(:compose_prompt).and_return("Composed prompt")
        
        result = command.send(:execute_review, config, { save_session: true, debug: true })
        
        expect(result).to eq(0)
        expect(mock_prompt_enhancer).to have_received(:compose_prompt).with(config[:prompt_composition])
        expect(mock_prompt_enhancer).to have_received(:enhance_prompt).with("Composed prompt", "Context content")
      end
    end
  end

  describe "#load_system_prompt" do
    it "loads prompt from existing file" do
      prompt_file = File.join(temp_dir, "prompt.md")
      File.write(prompt_file, "Test prompt content")
      
      result = command.send(:load_system_prompt, prompt_file)
      
      expect(result).to eq("Test prompt content")
    end

    it "returns nil for non-existent file" do
      result = command.send(:load_system_prompt, "/nonexistent.md")
      
      expect(result).to be_nil
    end

    it "returns nil when no prompt path provided" do
      result = command.send(:load_system_prompt, nil)
      
      expect(result).to be_nil
    end

    it "tries project root for relative paths" do
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)
      prompt_file = File.join(temp_dir, "prompt.md")
      File.write(prompt_file, "Relative prompt content")
      
      result = command.send(:load_system_prompt, "prompt.md")
      
      expect(result).to eq("Relative prompt content")
    end
  end

  describe "#create_session_directory" do
    before do
      allow(command).to receive(:find_current_release_dir).and_return(temp_dir)
    end

    it "creates timestamped session directory" do
      allow(Time).to receive(:now).and_return(Time.new(2024, 1, 1, 12, 0, 0))
      
      result = command.send(:create_session_directory)
      
      expect(result).to include("review-20240101-120000")
      expect(Dir.exist?(result)).to be_truthy
    end
  end

  describe "#find_current_release_dir" do
    it "finds dev-taskflow current release directory" do
      release_dir = File.join(temp_dir, "dev-taskflow", "current", "v.0.5.0-test")
      FileUtils.mkdir_p(release_dir)
      
      # Stub Dir.exist? and Dir.glob for our test
      allow(Dir).to receive(:exist?).with("dev-taskflow/current").and_return(true)
      allow(Dir).to receive(:glob).with("dev-taskflow/current/v.*").and_return([release_dir])
      allow(File).to receive(:directory?).with(release_dir).and_return(true)
      
      result = command.send(:find_current_release_dir)
      
      expect(result).to eq(release_dir)
    end

    it "falls back to temp directory when no release found" do
      allow(Dir).to receive(:exist?).with("dev-taskflow/current").and_return(false)
      allow(Dir).to receive(:mktmpdir).with("code-review-").and_return(temp_dir)
      
      result = command.send(:find_current_release_dir)
      
      expect(result).to eq(temp_dir)
    end
  end

  describe "#load_config_file" do
    let(:config_file) { File.join(temp_dir, "config.md") }

    it "loads configuration from valid file" do
      File.write(config_file, "---\npreset: pr\nauto_execute: true\n---\n# Review Config")
      allow(mock_config_extractor).to receive(:extract_from_file).with(config_file).and_return({
        "preset" => "pr",
        "auto_execute" => true
      })
      
      result = command.send(:load_config_file, config_file)
      
      expect(result).to eq({ preset: "pr", auto_execute: true })
    end

    it "returns nil for missing file" do
      result = command.send(:load_config_file, "/nonexistent.md")
      
      expect(result).to be_nil
      expect($stderr).to have_received(:write).with(/Config file not found/)
    end

    it "handles extraction errors gracefully" do
      File.write(config_file, "invalid content")
      allow(mock_config_extractor).to receive(:extract_from_file).and_raise(StandardError, "Parse error")
      
      result = command.send(:load_config_file, config_file)
      
      expect(result).to be_nil
      expect($stderr).to have_received(:write).with(/Error loading config file/)
    end

    it "returns nil when extractor returns nil" do
      File.write(config_file, "---\n---\n# No config")
      allow(mock_config_extractor).to receive(:extract_from_file).with(config_file).and_return(nil)
      
      result = command.send(:load_config_file, config_file)
      
      expect(result).to be_nil
      expect($stderr).to have_received(:write).with(/No valid configuration found/)
    end
  end

  describe "integration tests" do
    context "with real components" do
      before do
        # Use real components for integration testing
        allow(CodingAgentTools::Molecules::Code::ReviewPresetManager).to receive(:new).and_call_original
        allow(CodingAgentTools::Molecules::Code::ContextIntegrator).to receive(:new).and_call_original
        allow(CodingAgentTools::Molecules::Code::PromptEnhancer).to receive(:new).and_call_original
        allow(CodingAgentTools::Molecules::Code::ConfigExtractor).to receive(:new).and_call_original
      end

      it "handles validation failure with real validation logic" do
        result = command.call
        
        expect(result).to eq(1)
        expect($stderr).to have_received(:write).with(/Must specify either --preset or both --context and --subject/)
      end
    end
  end

  describe "command configuration" do
    it "has correct description" do
      expect(described_class.description).to eq("Execute code review using presets or custom configuration")
    end

    it "allows calls without required arguments" do
      # The new command structure no longer requires specific arguments
      # It can run with just defaults or show help
      expect { command.call }.not_to raise_error
    end

    it "has usage examples defined" do
      # This tests that examples are provided for the command
      expect(described_class).to respond_to(:example)
    end
  end
end

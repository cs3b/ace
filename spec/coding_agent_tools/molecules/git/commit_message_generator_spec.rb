# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Molecules::Git::CommitMessageGenerator do
  let(:fake_project_root) { '/fake/project/root' }
  let(:template_path) { File.join(fake_project_root, 'dev-handbook', '.meta', 'tpl', 'git-commit.system.prompt.md') }
  let(:system_template_content) { 'You are an expert at creating commit messages.' }
  let(:sample_diff) do
    <<~DIFF
      diff --git a/lib/user.rb b/lib/user.rb
      index 1234567..abcdefg 100644
      --- a/lib/user.rb
      +++ b/lib/user.rb
      @@ -10,6 +10,12 @@ class User
         def initialize(name)
           @name = name
         end
      +
      +  def email
      +    @email
      +  end
      +
      +  def email=(value)
      +    @email = value
      +  end
       end
    DIFF
  end

  before do
    # Mock project root detection
    allow(CodingAgentTools::Atoms::ProjectRootDetector)
      .to receive(:find_project_root)
      .and_return(fake_project_root)

    # Mock system template file
    allow(File).to receive(:exist?).with(template_path).and_return(true)
    allow(File).to receive(:read).with(template_path).and_return(system_template_content)

    # Mock ClientFactory and LLM interactions by default
    allow(CodingAgentTools::Molecules::ClientFactory)
      .to receive(:register)
    allow(CodingAgentTools::Molecules::ClientFactory)
      .to receive(:build)
      .and_return(mock_client)
  end

  let(:mock_client) do
    double('MockClient').tap do |client|
      allow(client).to receive(:generate_text).and_return({
        text: 'feat: add email getter and setter methods to User class'
      })
    end
  end

  let(:mock_provider_parser) do
    double('MockProviderParser').tap do |parser|
      allow(parser).to receive(:parse).and_return(mock_parse_result)
    end
  end

  let(:mock_parse_result) do
    double('MockParseResult').tap do |result|
      allow(result).to receive(:valid?).and_return(true)
      allow(result).to receive(:provider).and_return('google')
      allow(result).to receive(:model).and_return('gemini-2.0-flash-lite')
    end
  end

  before do
    allow(CodingAgentTools::Molecules::ProviderModelParser)
      .to receive(:new)
      .and_return(mock_provider_parser)
  end

  describe '.generate_message' do
    it 'creates a new instance and calls generate_message' do
      expect_any_instance_of(described_class)
        .to receive(:generate_message)
        .with(sample_diff)
        .and_return('feat: add user email functionality')

      result = described_class.generate_message(sample_diff)
      expect(result).to eq('feat: add user email functionality')
    end

    it 'passes options to the new instance' do
      options = { intention: 'add user feature', debug: true, model: 'google:gemini-pro' }

      expect(described_class)
        .to receive(:new)
        .with(options)
        .and_call_original

      described_class.generate_message(sample_diff, options)
    end
  end

  describe '#initialize' do
    it 'sets default values when no options provided' do
      generator = described_class.new

      expect(generator.send(:intention)).to be_nil
      expect(generator.send(:debug)).to be false
      expect(generator.send(:model)).to eq('google:gemini-2.0-flash-lite')
    end

    it 'uses provided intention' do
      generator = described_class.new(intention: 'fix bug')

      expect(generator.send(:intention)).to eq('fix bug')
    end

    it 'uses provided debug flag' do
      generator = described_class.new(debug: true)

      expect(generator.send(:debug)).to be true
    end

    it 'uses provided model' do
      generator = described_class.new(model: 'anthropic:claude-3.5-sonnet')

      expect(generator.send(:model)).to eq('anthropic:claude-3.5-sonnet')
    end

    it 'uses default debug value when not specified' do
      generator = described_class.new({})

      expect(generator.send(:debug)).to be false
    end
  end

  describe '#generate_message' do
    let(:generator) { described_class.new }

    context 'with valid diff' do
      it 'generates a commit message successfully' do
        result = generator.generate_message(sample_diff)
        expect(result).to eq('feat: add email getter and setter methods to User class')
      end

      it 'validates the diff before processing' do
        expect(generator).to receive(:validate_diff).with(sample_diff)
        generator.generate_message(sample_diff)
      end

      it 'builds system message from template' do
        expect(generator).to receive(:build_system_message).and_call_original
        generator.generate_message(sample_diff)
      end

      it 'builds user prompt with diff' do
        expect(generator).to receive(:build_user_prompt).with(sample_diff).and_call_original
        generator.generate_message(sample_diff)
      end

      it 'calls LLM generation with correct parameters' do
        expect(generator).to receive(:generate_with_llm).with(
          system_template_content,
          "Generate a commit message\n\nFor the following diff:\n\n#{sample_diff}"
        )
        generator.generate_message(sample_diff)
      end
    end

    context 'with empty diff' do
      it 'raises error for nil diff' do
        expect do
          generator.generate_message(nil)
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          'Diff cannot be empty'
        )
      end

      it 'raises error for empty string diff' do
        expect do
          generator.generate_message('')
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          'Diff cannot be empty'
        )
      end

      it 'raises error for whitespace-only diff' do
        expect do
          generator.generate_message("   \n  \t  ")
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          'Diff cannot be empty'
        )
      end
    end
  end

  describe '#validate_diff' do
    let(:generator) { described_class.new }

    it 'accepts valid diff content' do
      expect { generator.send(:validate_diff, sample_diff) }.not_to raise_error
    end

    it 'raises error for nil diff' do
      expect do
        generator.send(:validate_diff, nil)
      end.to raise_error(
        CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
        'Diff cannot be empty'
      )
    end

    it 'raises error for empty string' do
      expect do
        generator.send(:validate_diff, '')
      end.to raise_error(
        CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
        'Diff cannot be empty'
      )
    end

    it 'raises error for whitespace-only content' do
      expect do
        generator.send(:validate_diff, "   \n\t   ")
      end.to raise_error(
        CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
        'Diff cannot be empty'
      )
    end
  end

  describe '#build_system_message' do
    let(:generator) { described_class.new }

    context 'when template exists' do
      it 'reads and returns template content' do
        result = generator.send(:build_system_message)
        expect(result).to eq(system_template_content)
      end

      it 'reads from correct template path' do
        expect(File).to receive(:read).with(template_path).and_return(system_template_content)
        generator.send(:build_system_message)
      end
    end

    context 'when template does not exist' do
      before do
        allow(File).to receive(:exist?).with(template_path).and_return(false)
      end

      it 'raises error with template path' do
        expect do
          generator.send(:build_system_message)
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          "System prompt template not found at: #{template_path}"
        )
      end
    end

    context 'when project root detection fails' do
      before do
        allow(CodingAgentTools::Atoms::ProjectRootDetector)
          .to receive(:find_project_root)
          .and_raise(CodingAgentTools::Error, 'Git repository not found')
      end

      it 'raises more specific error' do
        expect do
          generator.send(:build_system_message)
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          'Failed to find project root: Git repository not found'
        )
      end
    end
  end

  describe '#build_user_prompt' do
    let(:generator) { described_class.new }

    context 'without intention' do
      it 'builds basic prompt with diff' do
        result = generator.send(:build_user_prompt, sample_diff)
        expected = "Generate a commit message\n\nFor the following diff:\n\n#{sample_diff}"
        expect(result).to eq(expected)
      end
    end

    context 'with intention' do
      let(:generator) { described_class.new(intention: 'improve user management') }

      it 'includes intention in prompt' do
        result = generator.send(:build_user_prompt, sample_diff)
        expected = "Generate a commit message, taking into account the following intention: improve user management\n\nFor the following diff:\n\n#{sample_diff}"
        expect(result).to eq(expected)
      end
    end

    context 'with empty intention' do
      let(:generator) { described_class.new(intention: '   ') }

      it 'ignores whitespace-only intention' do
        result = generator.send(:build_user_prompt, sample_diff)
        expected = "Generate a commit message\n\nFor the following diff:\n\n#{sample_diff}"
        expect(result).to eq(expected)
      end
    end

    context 'with nil intention' do
      let(:generator) { described_class.new(intention: nil) }

      it 'builds basic prompt without intention' do
        result = generator.send(:build_user_prompt, sample_diff)
        expected = "Generate a commit message\n\nFor the following diff:\n\n#{sample_diff}"
        expect(result).to eq(expected)
      end
    end
  end

  describe '#generate_with_llm' do
    let(:generator) { described_class.new }
    let(:system_message) { 'System prompt content' }
    let(:user_prompt) { 'User prompt content' }

    context 'with successful LLM response' do
      it 'returns cleaned response text' do
        result = generator.send(:generate_with_llm, system_message, user_prompt)
        expect(result).to eq('feat: add email getter and setter methods to User class')
      end

      it 'passes correct parameters to client' do
        expect(mock_client).to receive(:generate_text).with(
          user_prompt,
          system_instruction: system_message
        ).and_return({ text: 'commit message' })

        generator.send(:generate_with_llm, system_message, user_prompt)
      end

      it 'parses model specification correctly' do
        expect(mock_provider_parser).to receive(:parse).with('google:gemini-2.0-flash-lite')
        generator.send(:generate_with_llm, system_message, user_prompt)
      end

      it 'builds client with correct provider and model' do
        expect(CodingAgentTools::Molecules::ClientFactory)
          .to receive(:build)
          .with('google', model: 'gemini-2.0-flash-lite')

        generator.send(:generate_with_llm, system_message, user_prompt)
      end
    end

    context 'with invalid model specification' do
      before do
        allow(mock_parse_result).to receive(:valid?).and_return(false)
        allow(mock_parse_result).to receive(:error).and_return('Invalid format')
      end

      it 'raises error with model validation message' do
        expect do
          generator.send(:generate_with_llm, system_message, user_prompt)
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          "Invalid model specification 'google:gemini-2.0-flash-lite': Invalid format"
        )
      end
    end

    context 'with client factory error' do
      before do
        allow(CodingAgentTools::Molecules::ClientFactory)
          .to receive(:build)
          .and_raise(CodingAgentTools::Molecules::ClientFactory::UnknownProviderError, 'Provider not found')
      end

      it 'raises error with client creation message' do
        expect do
          generator.send(:generate_with_llm, system_message, user_prompt)
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          'Failed to create client: Provider not found'
        )
      end
    end

    context 'with LLM generation error' do
      before do
        allow(mock_client)
          .to receive(:generate_text)
          .and_raise(StandardError, 'API error')
      end

      context 'without debug mode' do
        it 'raises error with basic message' do
          expect do
            generator.send(:generate_with_llm, system_message, user_prompt)
          end.to raise_error(
            CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
            "Failed to generate commit message using google:gemini-2.0-flash-lite.\nRun with --debug for more details."
          )
        end
      end

      context 'with debug mode' do
        let(:generator) { described_class.new(debug: true) }

        it 'raises error with detailed message' do
          expect do
            generator.send(:generate_with_llm, system_message, user_prompt)
          end.to raise_error(
            CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
            "Failed to generate commit message using google:gemini-2.0-flash-lite.\nError: StandardError: API error"
          )
        end

        it 'outputs debug information during generation' do
          expect do
            begin
              generator.send(:generate_with_llm, system_message, user_prompt)
            rescue CodingAgentTools::Molecules::Git::CommitMessageGenerationError
              # Expected error, we're testing the debug output
            end
          end.to output(/DEBUG: Using provider: google/).to_stdout
        end
      end
    end
  end

  describe '#ensure_providers_loaded' do
    let(:generator) { described_class.new }

    it 'attempts to load common provider files' do
      providers = [
        'google_client',
        'anthropic_client',
        'openai_client',
        'mistral_client',
        'togetherai_client',
        'lmstudio_client'
      ]

      providers.each do |provider|
        expect(generator).to receive(:require_relative).with("../../organisms/#{provider}")
      end

      generator.send(:ensure_providers_loaded)
    end

    it 'registers providers with ClientFactory' do
      # Mock the provider classes
      mock_google_client = double('MockGoogleClient')

      # Allow first provider to succeed
      allow(generator).to receive(:require_relative).with('../../organisms/google_client').and_return(true)
      allow(CodingAgentTools::Organisms).to receive(:const_get).with('GoogleClient').and_return(mock_google_client)
      allow(mock_google_client).to receive(:provider_name).and_return('google')

      expect(CodingAgentTools::Molecules::ClientFactory)
        .to receive(:register)
        .with('google', mock_google_client)

      # Allow other providers to fail silently
      allow(generator).to receive(:require_relative).and_raise(LoadError, 'Not found')
      allow(generator).to receive(:require_relative).with('../../organisms/google_client').and_return(true)

      generator.send(:ensure_providers_loaded)
    end

    context 'with debug mode' do
      let(:generator) { described_class.new(debug: true) }

      it 'outputs warnings for failed provider loads' do
        allow(generator).to receive(:require_relative).and_raise(LoadError, 'Provider not found')

        expect do
          generator.send(:ensure_providers_loaded)
        end.to output(/Warning: Could not load provider/).to_stdout
      end
    end

    context 'without debug mode' do
      it 'silently skips failed provider loads' do
        allow(generator).to receive(:require_relative).and_raise(LoadError, 'Provider not found')

        expect do
          generator.send(:ensure_providers_loaded)
        end.not_to output.to_stdout
      end
    end
  end

  describe '#find_project_root' do
    let(:generator) { described_class.new }

    it 'delegates to ProjectRootDetector' do
      expect(CodingAgentTools::Atoms::ProjectRootDetector)
        .to receive(:find_project_root)
        .and_return(fake_project_root)

      result = generator.send(:find_project_root)
      expect(result).to eq(fake_project_root)
    end

    context 'when ProjectRootDetector fails' do
      before do
        allow(CodingAgentTools::Atoms::ProjectRootDetector)
          .to receive(:find_project_root)
          .and_raise(CodingAgentTools::Error, 'Not a git repository')
      end

      it 'raises more specific error' do
        expect do
          generator.send(:find_project_root)
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          'Failed to find project root: Not a git repository'
        )
      end
    end
  end

  describe '#find_system_prompt_template_path' do
    let(:generator) { described_class.new }

    it 'constructs correct template path' do
      result = generator.send(:find_system_prompt_template_path)
      expected_path = File.join(fake_project_root, 'dev-handbook', '.meta', 'tpl', 'git-commit.system.prompt.md')
      expect(result).to eq(expected_path)
    end

    it 'uses project root from detector' do
      expect(generator).to receive(:find_project_root).and_return(fake_project_root)
      generator.send(:find_system_prompt_template_path)
    end
  end

  describe '#clean_response' do
    let(:generator) { described_class.new }

    context 'with clean response' do
      it 'returns response as-is' do
        response = 'feat: add user authentication'
        result = generator.send(:clean_response, response)
        expect(result).to eq('feat: add user authentication')
      end
    end

    context 'with markdown code blocks' do
      it 'removes markdown fences at start' do
        response = "```\nfeat: add feature\n"
        result = generator.send(:clean_response, response)
        expect(result).to eq('feat: add feature')
      end

      it 'removes markdown fences at end' do
        response = "feat: add feature\n```"
        result = generator.send(:clean_response, response)
        expect(result).to eq('feat: add feature')
      end

      it 'removes language-specific markdown fences' do
        response = "```bash\nfeat: add feature\n```"
        result = generator.send(:clean_response, response)
        expect(result).to eq('feat: add feature')
      end

      it 'removes fences with numbers and underscores' do
        response = "```git_diff\nfeat: add feature\n```"
        result = generator.send(:clean_response, response)
        expect(result).to eq('feat: add feature')
      end
    end

    context 'with whitespace' do
      it 'trims leading and trailing whitespace' do
        response = "  \n  feat: add feature  \n  "
        result = generator.send(:clean_response, response)
        expect(result).to eq('feat: add feature')
      end
    end

    context 'with nil response' do
      it 'returns empty string' do
        result = generator.send(:clean_response, nil)
        expect(result).to eq('')
      end
    end

    context 'with empty response after cleaning' do
      it 'raises error for whitespace-only response' do
        expect do
          generator.send(:clean_response, "```\n   \n```")
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          'LLM returned empty commit message after cleaning'
        )
      end

      it 'raises error for code block only response' do
        expect do
          generator.send(:clean_response, "```bash\n```")
        end.to raise_error(
          CodingAgentTools::Molecules::Git::CommitMessageGenerationError,
          'LLM returned empty commit message after cleaning'
        )
      end
    end
  end

  describe 'integration scenarios' do
    let(:generator) { described_class.new(intention: 'improve user features', debug: false) }

    context 'with complex diff' do
      let(:complex_diff) do
        <<~DIFF
          diff --git a/app/models/user.rb b/app/models/user.rb
          index 1234567..abcdefg 100644
          --- a/app/models/user.rb
          +++ b/app/models/user.rb
          @@ -1,5 +1,15 @@
           class User < ApplicationRecord
             validates :name, presence: true
          +  validates :email, presence: true, uniqueness: true
          +
          +  before_save :downcase_email
          +
          +  private
          +
          +  def downcase_email
          +    self.email = email.downcase if email.present?
          +  end
           end
        DIFF
      end

      it 'generates appropriate commit message' do
        result = generator.generate_message(complex_diff)
        expect(result).to eq('feat: add email getter and setter methods to User class')
      end
    end

    context 'with custom model' do
      let(:generator) { described_class.new(model: 'anthropic:claude-3.5-sonnet') }

      before do
        allow(mock_parse_result).to receive(:provider).and_return('anthropic')
        allow(mock_parse_result).to receive(:model).and_return('claude-3.5-sonnet')
      end

      it 'uses custom model for generation' do
        expect(CodingAgentTools::Molecules::ClientFactory)
          .to receive(:build)
          .with('anthropic', model: 'claude-3.5-sonnet')

        generator.generate_message(sample_diff)
      end
    end

    context 'end-to-end with real-like responses' do
      before do
        allow(mock_client).to receive(:generate_text).and_return({
          text: "```\nfeat: add email validation and normalization to User model\n\nAdd email presence and uniqueness validation\nImplement automatic email downcasing before save\n```"
        })
      end

      it 'cleans and returns properly formatted commit message' do
        result = generator.generate_message(sample_diff)
        expected = "feat: add email validation and normalization to User model\n\nAdd email presence and uniqueness validation\nImplement automatic email downcasing before save"
        expect(result).to eq(expected)
      end
    end
  end
end

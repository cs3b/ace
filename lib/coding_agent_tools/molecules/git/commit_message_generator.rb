# frozen_string_literal: true

require_relative '../../atoms/project_root_detector'
require_relative '../client_factory'
require_relative '../provider_model_parser'
require_relative '../../error'

module CodingAgentTools
  module Molecules
    module Git
      class CommitMessageGenerationError < StandardError; end

      class CommitMessageGenerator
        DEFAULT_MODEL = 'google:gemini-2.0-flash-lite'

        def self.generate_message(diff, options = {})
          new(options).generate_message(diff)
        end

        def initialize(options = {})
          @intention = options[:intention]
          @debug = options.fetch(:debug, false)
          @model = options[:model] || DEFAULT_MODEL
        end

        def generate_message(diff)
          validate_diff(diff)

          system_message = build_system_message
          user_prompt = build_user_prompt(diff)

          generate_with_llm(system_message, user_prompt)
        end

        private

        attr_reader :intention, :debug, :model

        def validate_diff(diff)
          return unless diff.nil? || diff.strip.empty?

          raise CommitMessageGenerationError, 'Diff cannot be empty'
        end

        def build_system_message
          template_path = find_system_prompt_template_path

          unless File.exist?(template_path)
            raise CommitMessageGenerationError, "System prompt template not found at: #{template_path}"
          end

          File.read(template_path)
        end

        def build_user_prompt(diff)
          prompt = 'Generate a commit message'

          if intention && !intention.strip.empty?
            prompt += ", taking into account the following intention: #{intention}"
          end

          prompt += "\n\nFor the following diff:\n\n#{diff}"
          prompt
        end

        def generate_with_llm(system_message, user_prompt)
          # Ensure provider clients are available
          ensure_providers_loaded

          # Parse the model string to get provider and model
          parser = Molecules::ProviderModelParser.new
          parse_result = parser.parse(model)

          unless parse_result.valid?
            raise CommitMessageGenerationError, "Invalid model specification '#{model}': #{parse_result.error}"
          end

          # Build the LLM client
          begin
            client = Molecules::ClientFactory.build(parse_result.provider, model: parse_result.model)
          rescue Molecules::ClientFactory::UnknownProviderError => e
            raise CommitMessageGenerationError, "Failed to create client: #{e.message}"
          end

          # Prepare generation options
          generation_options = {
            system_instruction: system_message
          }

          if debug
            puts "DEBUG: Using provider: #{parse_result.provider}"
            puts "DEBUG: Using model: #{parse_result.model}"
            puts "DEBUG: System message: #{system_message[0..100]}..."
            puts "DEBUG: User prompt: #{user_prompt[0..100]}..."
          end

          # Generate the response using direct Ruby call
          begin
            response = client.generate_text(user_prompt, **generation_options)
            clean_response(response[:text])
          rescue StandardError => e
            error_message = "Failed to generate commit message using #{parse_result.provider}:#{parse_result.model}."

            error_message += if debug
                               "\nError: #{e.class.name}: #{e.message}"
                             else
                               "\nRun with --debug for more details."
                             end

            raise CommitMessageGenerationError, error_message
          end
        end

        def ensure_providers_loaded
          # Manually load and register the most common providers
          # This ensures they're available even if the inherited hook doesn't work properly
          providers_to_load = %w[
            google_client
            anthropic_client
            openai_client
            mistral_client
            togetherai_client
            lmstudio_client
          ]

          providers_to_load.each do |provider_file|
            require_relative "../../organisms/#{provider_file}"

            # Convert filename to class name and manually register if needed
            class_name = provider_file.split('_').map(&:capitalize).join
            client_class = CodingAgentTools::Organisms.const_get(class_name)

            if client_class.respond_to?(:provider_name)
              provider_key = client_class.provider_name
              Molecules::ClientFactory.register(provider_key, client_class)
            end
          rescue LoadError, NameError => e
            # Silently skip providers that can't be loaded
            puts "Warning: Could not load provider #{provider_file}: #{e.message}" if debug
          end
        end

        def find_project_root
          CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
        rescue CodingAgentTools::Error => e
          # If project root detection fails, raise a more specific error
          raise CommitMessageGenerationError, "Failed to find project root: #{e.message}"
        end

        def find_system_prompt_template_path
          project_root = find_project_root
          File.join(project_root, 'dev-handbook', '.meta', 'tpl', 'git-commit.system.prompt.md')
        end

        def clean_response(response)
          return '' if response.nil?

          # Remove markdown code block markers
          cleaned = response.gsub(/^```[a-zA-Z0-9_-]*\s*/, '')
                            .gsub(/```\s*$/, '')

          # Trim whitespace and ensure single newline at end
          cleaned = cleaned.strip

          raise CommitMessageGenerationError, 'LLM returned empty commit message after cleaning' if cleaned.empty?

          cleaned
        end
      end
    end
  end
end

# frozen_string_literal: true

module Ace
  module LLM
    module Molecules
      class InteractiveCommandBuilder
        def initialize(registry: ClientRegistry.new)
          @registry = registry
          @parser = ProviderModelParser.new(registry: registry)
        end

        def build(provider_model:, prompt:, model: nil, preset: nil, system: nil, cli_args: nil,
          system_append: nil, sandbox: nil, working_dir: nil, subprocess_env: nil)
          parse_result = @parser.parse(provider_model)
          raise Error, parse_result.error unless parse_result.valid?

          resolved_preset = QueryInterface.send(:resolve_preset_name, parse_result.preset, preset)
          final_model = model || parse_result.model
          if final_model.nil? || final_model.empty?
            raise Error, "No model specified and no default available for #{parse_result.provider}"
          end

          final_prompt = prompt.to_s
          raise Error, "No prompt specified. Use positional prompt or --prompt." if final_prompt.empty?

        generation_opts = QueryInterface.send(
            :build_generation_opts,
            provider: parse_result.provider,
            preset: resolved_preset,
            thinking_level: parse_result.thinking_level,
            temperature: nil,
            max_tokens: nil,
            system_file: nil,
            prompt_file: nil,
            cli_args: cli_args,
            system_append: system_append,
            sandbox: sandbox,
            working_dir: working_dir,
            subprocess_env: subprocess_env,
            subprocess_command_prefix: nil,
            last_message_file: nil
          )

          client = @registry.get_client(parse_result.provider, model: final_model)
          unless client.respond_to?(:interactive_supported?) && client.interactive_supported?
            raise Error, "Provider '#{parse_result.provider}' does not support interactive mode"
          end

          messages = []
          messages << {role: "system", content: system} if system && !system.empty?
          messages << {role: "user", content: final_prompt}

          invocation = client.build_interactive_invocation(messages, **generation_opts)
          invocation.merge(
            provider: parse_result.provider,
            model: final_model,
            preset: resolved_preset,
            thinking_level: parse_result.thinking_level
          )
        end
      end
    end
  end
end

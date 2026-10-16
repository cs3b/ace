# frozen_string_literal: true
require "ace/llm"
module Ace
  module Design
    module Molecules
      class AgentExecutor
        def validate_model(model, execution_preset: nil)
          registry = Ace::LLM::Molecules::ClientRegistry.new
          parsed = Ace::LLM::Molecules::ProviderModelParser.new(registry: registry).parse(model)
          raise Error, parsed.error unless parsed.valid?
          provider = registry.get_provider(parsed.provider)
          unless provider && provider["gem"] == "ace-llm-providers-cli"
            raise Error, "Design workers require a coding CLI provider: #{model}"
          end
          if execution_preset && parsed.preset
            raise Error, "Use model@preset or execution_preset, not both"
          end
        end
        def call(model:, prompt:, system:, workspace:, timeout:, execution_preset: nil)
          result = Ace::LLM::QueryInterface.query(model, prompt, system: system, working_dir: workspace,
            timeout: timeout, preset: execution_preset, format: "text")
          # Preserve the actual provider identity, including configured fallback outcomes.
          JSON.parse(JSON.generate(result.slice(:execution, :model, :provider, :usage, :metadata, :text)))
        end
      end
    end
  end
end

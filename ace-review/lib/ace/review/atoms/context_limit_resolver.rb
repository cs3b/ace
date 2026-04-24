# frozen_string_literal: true

require "ace/llm"

module Ace
  module Review
    module Atoms
      # Review-local wrapper around ace-llm's resolved model limit lookup.
      module ContextLimitResolver
        DEFAULT_LIMIT = Ace::LLM::Molecules::ModelLimitResolver::DEFAULT_CONTEXT_LIMIT

        def self.resolve(model_name)
          resolve_details(model_name).context_limit
        end

        def self.resolve_details(model_name)
          Ace::LLM::Molecules::ModelLimitResolver.resolve(model_name)
        rescue
          Ace::LLM::Molecules::ModelLimitResolver::ResolveResult.new(
            provider: nil,
            model: nil,
            context_limit: DEFAULT_LIMIT,
            output_limit: nil,
            source: :fallback,
            original_target: model_name.to_s
          )
        end

        def self.default_limit
          DEFAULT_LIMIT
        end
      end
    end
  end
end

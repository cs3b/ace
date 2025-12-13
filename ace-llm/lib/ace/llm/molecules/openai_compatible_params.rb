# frozen_string_literal: true

module Ace
  module LLM
    module Molecules
      # Shared parameter extraction for OpenAI-compatible providers
      # Preserves zero values using nil? check (0 is a valid penalty value)
      module OpenAICompatibleParams
        # Extract OpenAI-compatible generation options
        # @param options [Hash] Raw options from caller
        # @param gen_opts [Hash] Generation options to augment
        # @return [Hash] Augmented generation options
        def extract_openai_compatible_options(options, gen_opts)
          gen_opts[:frequency_penalty] = options[:frequency_penalty] unless options[:frequency_penalty].nil?
          gen_opts[:presence_penalty] = options[:presence_penalty] unless options[:presence_penalty].nil?
          gen_opts
        end
      end
    end
  end
end

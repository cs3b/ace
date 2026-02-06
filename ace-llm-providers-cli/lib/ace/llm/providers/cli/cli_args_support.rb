# frozen_string_literal: true

require_relative "atoms/args_normalizer"

module Ace
  module LLM
    module Providers
      module CLI
        module CliArgsSupport
          private

          def normalized_cli_args(options)
            Atoms::ArgsNormalizer.new.normalize_cli_args(options[:cli_args])
          end
        end
      end
    end
  end
end

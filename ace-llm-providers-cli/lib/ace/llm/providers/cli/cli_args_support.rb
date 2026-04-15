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

          def normalized_cli_args_without_conflicts(options, forbidden_flags:, label:)
            args = normalized_cli_args(options)
            conflict = find_conflicting_cli_arg(args, forbidden_flags)
            return args unless conflict

            raise Ace::LLM::ProviderError, "#{label} interactive mode does not support cli arg #{conflict}"
          end

          def find_conflicting_cli_arg(args, forbidden_flags)
            normalized_forbidden = Array(forbidden_flags).map(&:to_s)
            args.find do |arg|
              normalized_forbidden.any? { |flag| arg == flag || arg.start_with?("#{flag}=") }
            end
          end
        end
      end
    end
  end
end

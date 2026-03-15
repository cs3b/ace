# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module ModelsSubcommands
            # Show pricing for a model
            class Cost < Ace::Support::Cli::Command
              include Ace::Core::CLI::Base

              desc "Show pricing for a model"

              argument :model_id, required: true, desc: "Model ID (provider:model)"
              option :input, type: :integer, aliases: ["-i"], default: 1000, desc: "Input tokens"
              option :output, type: :integer, aliases: ["-o"], default: 500, desc: "Output tokens"
              option :reasoning, type: :integer, aliases: ["-r"], default: 0, desc: "Reasoning tokens"
              option :json, type: :boolean, desc: "Output as JSON"

              example [
                "openai:gpt-4o                    # Default token counts",
                "openai:gpt-4o -i 5000 -o 2000    # Custom token counts",
                "anthropic:claude-3-opus --json   # JSON output"
              ]

              def call(model_id:, **options)
                calculator = Molecules::CostCalculator.new
                result = calculator.calculate(
                  model_id,
                  input_tokens: options[:input],
                  output_tokens: options[:output],
                  reasoning_tokens: options[:reasoning]
                )

                if options[:json]
                  puts JSON.pretty_generate(result)
                else
                  puts calculator.format(result)
                end
              rescue ProviderNotFoundError, ModelNotFoundError => e
                raise Ace::Core::CLI::Error.new(e.message)
              rescue CacheError => e
                raise Ace::Core::CLI::Error.new(e.message)
              end
            end
          end
        end
      end
    end
  end
end

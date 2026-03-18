# frozen_string_literal: true

require "json"

module Ace
  module Support
    module Models
      module CLI
        module Commands
          module ModelsSubcommands
            # Show model information
            class Info < Ace::Support::Cli::Command
              include Ace::Support::Cli::Base

              desc "Show model information (brief by default)"

              argument :model_id, required: true, desc: "Model ID (provider:model)"
              option :full, type: :boolean, desc: "Show complete details"
              option :json, type: :boolean, desc: "Output as JSON"

              example [
                "openai:gpt-4o            # Brief info (default)",
                "openai:gpt-4o --full     # Full details",
                "anthropic:claude-3-opus --json  # JSON output"
              ]

              def call(model_id:, **options)
                model = Molecules::ModelValidator.new.validate(model_id)

                if options[:json]
                  puts JSON.pretty_generate(model.to_h)
                elsif options[:full]
                  puts format_model_info_full(model)
                else
                  puts format_model_info_brief(model)
                end
              rescue ProviderNotFoundError => e
                raise Ace::Support::Cli::Error.new("Model '#{e.model_id || model_id}' not found in provider '#{e.provider_id}'")
              rescue ModelNotFoundError => e
                raise Ace::Support::Cli::Error.new(e.message)
              rescue CacheError => e
                raise Ace::Support::Cli::Error.new(e.message)
              end

              private

              def format_model_info_brief(model)
                lines = []
                lines << "#{model.name} (#{model.full_id})"
                lines << "  Provider: #{model.provider_id}"
                lines << "  Status: #{model.status || 'active'}"
                lines << "  Context: #{format_number(model.context_limit)} tokens"
                lines << "  Output: #{format_number(model.output_limit)} tokens"

                pricing = model.pricing
                if pricing&.available?
                  lines << "  Pricing: $#{sprintf('%.2f', pricing.input)}/M input, $#{sprintf('%.2f', pricing.output)}/M output"
                end

                caps = model.capabilities
                enabled = []
                enabled << "reasoning" if caps[:reasoning]
                enabled << "tools" if caps[:tool_call]
                enabled << "structured" if caps[:structured_output]
                lines << "  Capabilities: #{enabled.any? ? enabled.join(', ') : 'none'}"

                lines << ""
                lines << "Use --full for complete details"

                lines.join("\n")
              end

              def format_model_info_full(model)
                lines = []
                lines << "Model: #{model.name} (#{model.full_id})"
                lines << "Provider: #{model.provider_id}"
                lines << "Status: #{model.status || 'active'}"
                lines << ""

                lines << "Capabilities:"
                caps = model.capabilities
                lines << "  Reasoning: #{caps[:reasoning] ? 'Yes' : 'No'}"
                lines << "  Tool Call: #{caps[:tool_call] ? 'Yes' : 'No'}"
                lines << "  Structured Output: #{caps[:structured_output] ? 'Yes' : 'No'}"
                lines << "  Attachment: #{caps[:attachment] ? 'Yes' : 'No'}"
                lines << "  Temperature: #{caps[:temperature] ? 'Yes' : 'No'}"
                lines << ""

                lines << "Modalities:"
                lines << "  Input: #{model.modalities[:input]&.join(', ') || 'none'}"
                lines << "  Output: #{model.modalities[:output]&.join(', ') || 'none'}"
                lines << ""

                lines << "Limits:"
                lines << "  Context: #{format_number(model.context_limit)} tokens"
                lines << "  Output: #{format_number(model.output_limit)} tokens"
                lines << ""

                pricing = model.pricing
                if pricing&.available?
                  lines << "Pricing (per million tokens):"
                  lines << "  Input: #{format_price(pricing.input)}"
                  lines << "  Output: #{format_price(pricing.output)}"
                  lines << "  Cache Read: #{format_price(pricing.cache_read)}" if pricing.cache_read
                  lines << "  Cache Write: #{format_price(pricing.cache_write)}" if pricing.cache_write
                  lines << "  Reasoning: #{format_price(pricing.reasoning)}" if pricing.reasoning
                  lines << ""
                end

                lines << "Metadata:"
                lines << "  Knowledge: #{model.knowledge_date || 'unknown'}"
                lines << "  Released: #{model.release_date || 'unknown'}"
                lines << "  Updated: #{model.last_updated || 'unknown'}"
                lines << "  Open Weights: #{model.open_weights ? 'Yes' : 'No'}"

                lines.join("\n")
              end

              def format_number(num)
                return "unknown" unless num

                num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
              end

              def format_price(price)
                return "N/A" unless price

                "$#{sprintf('%.2f', price)}"
              end
            end
          end
        end
      end
    end
  end
end

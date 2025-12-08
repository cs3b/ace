# frozen_string_literal: true

require "thor"
require "json"

module Ace
  module LLM
    module ModelsDev
      module Commands
        # Model operations subcommands
        class ModelsCLI < Thor
          def self.exit_on_failure?
            false
          end

          desc "search [QUERY]", "Search for models (query optional with filters)"
          long_desc <<-LONGDESC
Search for models by name or filter by capabilities. Query is optional when using filters.

Available filters: provider, reasoning, tool_call, attachment, structured_output,
temperature, open_weights, modality, min_context, max_input_cost

Examples:
\x5  # Search by name
\x5  ace-llm-models models search gpt-4

\x5  # Search within a provider
\x5  ace-llm-models models search opus -p anthropic

\x5  # Filter by capability
\x5  ace-llm-models models search -f reasoning:true

\x5  # Multiple filters
\x5  ace-llm-models models search -f tool_call:true -f min_context:100000

\x5  # Limit results
\x5  ace-llm-models models search gpt -l 5

\x5  # Using top-level shortcut
\x5  ace-llm-models search claude
          LONGDESC
          option :provider, type: :string, aliases: "-p", desc: "Limit to provider"
          option :limit, type: :numeric, aliases: "-l", default: 20, desc: "Max results"
          option :filter, type: :array, aliases: "-f", desc: "Filter by key:value (repeatable)"
          option :json, type: :boolean, desc: "Output as JSON"
          def search(query = nil)
            # Validate filters before searching
            filter_errors = Atoms::ModelFilter.validate(options[:filter])
            unless filter_errors.empty?
              filter_errors.each { |e| warn "Error: #{e}" }
              return 1
            end

            searcher = Molecules::ModelSearcher.new
            filters = parse_filters(options[:filter])
            limit = options[:limit] || 20

            # Single search with total count for efficient pagination
            result = searcher.search(
              query,
              provider: options[:provider],
              limit: limit,
              filters: filters.empty? ? nil : filters,
              with_total: true
            )

            models = result[:models]
            total_models_count = result[:total]

            if models.empty?
              if options[:json]
                puts "[]"
              else
                message = query ? "No models found matching '#{query}'" : "No models found"
                message += " with filters: #{options[:filter].join(', ')}" if options[:filter]&.any?
                puts message
              end
              return 0
            end

            if options[:json]
              json_result = {
                models: models.map(&:to_h),
                showing: models.size,
                total: total_models_count
              }
              puts JSON.pretty_generate(json_result)
            else
              if models.size < total_models_count
                puts "Showing #{models.size} of #{total_models_count} results:"
              else
                puts "Found #{models.size} model(s):"
              end
              models.each do |model|
                status = model.deprecated? ? " (deprecated)" : ""
                puts "  #{model.full_id}#{status}"
                puts "    #{model.name}"
              end
            end
            0
          rescue CacheError => e
            warn "Error: #{e.message}"
            return 1
          end

          desc "info MODEL_ID", "Show model information (brief by default)"
          long_desc <<-LONGDESC
Display information about a specific model. Shows brief summary by default;
use --full for complete details including capabilities, modalities, and metadata.

MODEL_ID format: provider:model (e.g., openai:gpt-4o, anthropic:claude-3-opus)

Examples:
\x5  # Brief info (default)
\x5  ace-llm-models models info openai:gpt-4o

\x5  # Full details
\x5  ace-llm-models models info openai:gpt-4o --full

\x5  # JSON output
\x5  ace-llm-models models info anthropic:claude-3-opus --json

\x5  # Using top-level shortcut
\x5  ace-llm-models info openai:gpt-4o
          LONGDESC
          option :full, type: :boolean, desc: "Show complete details"
          option :json, type: :boolean, desc: "Output as JSON"
          def info(model_id)
            model = Molecules::ModelValidator.new.validate(model_id)

            if options[:json]
              puts JSON.pretty_generate(model.to_h)
            elsif options[:full]
              puts format_model_info_full(model)
            else
              puts format_model_info_brief(model)
            end
            0
          rescue ProviderNotFoundError => e
            warn "Error: Model '#{e.model_id || model_id}' not found in provider '#{e.provider_id}'"
            return 1
          rescue ModelNotFoundError => e
            warn "Error: #{e.message}"
            return 1
          rescue CacheError => e
            warn "Error: #{e.message}"
            return 1
          end

          desc "cost MODEL_ID", "Show pricing for a model"
          option :input, type: :numeric, aliases: "-i", default: 1000, desc: "Input tokens"
          option :output, type: :numeric, aliases: "-o", default: 500, desc: "Output tokens"
          option :reasoning, type: :numeric, aliases: "-r", default: 0, desc: "Reasoning tokens"
          option :json, type: :boolean, desc: "Output as JSON"
          def cost(model_id)
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
            0
          rescue ProviderNotFoundError, ModelNotFoundError => e
            warn "Error: #{e.message}"
            return 1
          rescue CacheError => e
            warn "Error: #{e.message}"
            return 1
          end

          # Default to help
          default_task :help

          private

          # Parse filter array from CLI into hash
          # @param filter_array [Array<String>, nil] Array of "key:value" strings
          # @return [Hash] Parsed filters
          def parse_filters(filter_array)
            Atoms::ModelFilter.parse_all(filter_array)
          end

          # Format brief model info (default output)
          # @param model [Models::ModelInfo] Model to format
          # @return [String] Formatted output
          def format_model_info_brief(model)
            lines = []
            lines << "#{model.name} (#{model.full_id})"
            lines << "  Provider: #{model.provider_id}"
            lines << "  Status: #{model.status || 'active'}"
            lines << "  Context: #{format_number(model.context_limit)} tokens"
            lines << "  Output: #{format_number(model.output_limit)} tokens"

            # Pricing summary
            pricing = model.pricing
            if pricing&.available?
              lines << "  Pricing: $#{sprintf('%.2f', pricing.input)}/M input, $#{sprintf('%.2f', pricing.output)}/M output"
            end

            # Key capabilities (compact)
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

          # Format complete model info (--full output)
          # @param model [Models::ModelInfo] Model to format
          # @return [String] Formatted output
          def format_model_info_full(model)
            lines = []
            lines << "Model: #{model.name} (#{model.full_id})"
            lines << "Provider: #{model.provider_id}"
            lines << "Status: #{model.status || 'active'}"
            lines << ""

            # Capabilities
            lines << "Capabilities:"
            caps = model.capabilities
            lines << "  Reasoning: #{caps[:reasoning] ? 'Yes' : 'No'}"
            lines << "  Tool Call: #{caps[:tool_call] ? 'Yes' : 'No'}"
            lines << "  Structured Output: #{caps[:structured_output] ? 'Yes' : 'No'}"
            lines << "  Attachment: #{caps[:attachment] ? 'Yes' : 'No'}"
            lines << "  Temperature: #{caps[:temperature] ? 'Yes' : 'No'}"
            lines << ""

            # Modalities
            lines << "Modalities:"
            lines << "  Input: #{model.modalities[:input]&.join(', ') || 'none'}"
            lines << "  Output: #{model.modalities[:output]&.join(', ') || 'none'}"
            lines << ""

            # Limits
            lines << "Limits:"
            lines << "  Context: #{format_number(model.context_limit)} tokens"
            lines << "  Output: #{format_number(model.output_limit)} tokens"
            lines << ""

            # Pricing
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

            # Metadata
            lines << "Metadata:"
            lines << "  Knowledge: #{model.knowledge_date || 'unknown'}"
            lines << "  Released: #{model.release_date || 'unknown'}"
            lines << "  Updated: #{model.last_updated || 'unknown'}"
            lines << "  Open Weights: #{model.open_weights ? 'Yes' : 'No'}"

            lines.join("\n")
          end

          # Format a number with commas
          # @param num [Integer, nil] Number to format
          # @return [String] Formatted number
          def format_number(num)
            return "unknown" unless num

            num.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
          end

          # Format a price value
          # @param price [Float, nil] Price to format
          # @return [String] Formatted price
          def format_price(price)
            return "N/A" unless price

            "$#{sprintf('%.2f', price)}"
          end
        end
      end
    end
  end
end

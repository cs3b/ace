# frozen_string_literal: true

module Ace
  module Support
    module Models
      module Models
        # Represents information about a single model
        class ModelInfo
          attr_reader :id, :name, :provider_id, :pricing, :context_limit, :output_limit,
            :modalities, :capabilities, :status, :knowledge_date, :release_date,
            :last_updated, :open_weights

          # Initialize model info
          def initialize(attrs = {})
            @id = attrs[:id]
            @name = attrs[:name]
            @provider_id = attrs[:provider_id]
            @pricing = attrs[:pricing] || PricingInfo.new
            @context_limit = attrs[:context_limit]
            @output_limit = attrs[:output_limit]
            @modalities = attrs[:modalities] || {input: [], output: []}
            @capabilities = attrs[:capabilities] || {}
            @status = attrs[:status]
            @knowledge_date = attrs[:knowledge_date]
            @release_date = attrs[:release_date]
            @last_updated = attrs[:last_updated]
            @open_weights = attrs[:open_weights]
          end

          # Create from API hash
          # @param hash [Hash] Model hash from API
          # @param provider_id [String] Provider ID
          # @return [ModelInfo] Parsed model info
          def self.from_hash(hash, provider_id:)
            new(
              id: hash["id"],
              name: hash["name"],
              provider_id: provider_id,
              pricing: PricingInfo.from_hash(hash["cost"]),
              context_limit: hash.dig("limit", "context"),
              output_limit: hash.dig("limit", "output"),
              modalities: parse_modalities(hash["modalities"]),
              capabilities: parse_capabilities(hash),
              status: hash["status"],
              knowledge_date: hash["knowledge"],
              release_date: hash["release_date"],
              last_updated: hash["last_updated"],
              open_weights: hash["open_weights"]
            )
          end

          # Full model identifier
          # @return [String] provider:model format
          def full_id
            "#{provider_id}:#{id}"
          end

          # Check if model is deprecated
          # @return [Boolean]
          def deprecated?
            status == "deprecated"
          end

          # Check if model is in preview/alpha/beta
          # @return [Boolean]
          def preview?
            %w[alpha beta preview].include?(status)
          end

          # Check if model supports a capability
          # @param capability [Symbol, String] Capability name
          # @return [Boolean]
          def supports?(capability)
            capabilities[capability.to_sym] == true
          end

          # Convert to hash
          # @return [Hash]
          def to_h
            {
              id: id,
              name: name,
              provider_id: provider_id,
              full_id: full_id,
              pricing: pricing.to_h,
              context_limit: context_limit,
              output_limit: output_limit,
              modalities: modalities,
              capabilities: capabilities,
              status: status,
              knowledge_date: knowledge_date,
              release_date: release_date,
              last_updated: last_updated,
              open_weights: open_weights
            }
          end

          private

          def self.parse_modalities(hash)
            return {input: [], output: []} if hash.nil?

            unless hash.is_a?(Hash)
              warn "[ModelInfo] Unexpected modalities type: #{hash.class}, expected Hash"
              return {input: [], output: []}
            end

            {
              input: Array(hash["input"]),
              output: Array(hash["output"])
            }
          end
          private_class_method :parse_modalities

          def self.parse_capabilities(hash)
            {
              attachment: hash["attachment"] == true,
              reasoning: hash["reasoning"] == true,
              tool_call: hash["tool_call"] == true,
              structured_output: hash["structured_output"] == true,
              temperature: hash["temperature"] == true
            }
          end
          private_class_method :parse_capabilities
        end
      end
    end
  end
end

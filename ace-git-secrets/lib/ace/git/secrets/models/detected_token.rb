# frozen_string_literal: true

module Ace
  module Git
    module Secrets
      module Models
        # Represents a detected token in Git history
        # Immutable value object containing token metadata
        class DetectedToken
          attr_reader :token_type, :pattern_name, :confidence, :commit_hash,
            :file_path, :line_number, :raw_value, :detected_by

          # Confidence levels for token detection
          CONFIDENCE_LEVELS = %w[high medium low].freeze

          # @param token_type [String] Type of token (github_pat, anthropic_api_key, etc.)
          # @param pattern_name [String] Name of pattern that matched
          # @param confidence [String] Confidence level (high, medium, low)
          # @param commit_hash [String] Git commit SHA where token was found
          # @param file_path [String] Path to file containing token
          # @param line_number [Integer, nil] Line number in file
          # @param raw_value [String] The actual token value (stored for revocation)
          # @param detected_by [String] Detection method (gitleaks, ruby_patterns)
          def initialize(token_type:, pattern_name:, confidence:, commit_hash:,
            file_path:, raw_value:, line_number: nil, detected_by: "ruby_patterns")
            @token_type = token_type
            @pattern_name = pattern_name
            @confidence = validate_confidence(confidence)
            @commit_hash = commit_hash
            @file_path = file_path
            @line_number = line_number
            @raw_value = raw_value
            @detected_by = detected_by

            freeze
          end

          # Returns masked version of token for display
          # Shows first 4 and last 4 characters with asterisks in between
          # @return [String] Masked token value
          def masked_value
            return "****" if raw_value.nil? || raw_value.length < 12

            prefix = raw_value[0, 4]
            suffix = raw_value[-4, 4]
            "#{prefix}#{"*" * [raw_value.length - 8, 4].max}#{suffix}"
          end

          # Returns short commit hash (7 characters)
          # @return [String] Short commit hash
          def short_commit
            commit_hash[0, 7]
          end

          # Check if this is a high confidence match
          # @return [Boolean]
          def high_confidence?
            confidence == "high"
          end

          # Returns service name for revocation
          # @return [String, nil] Service name or nil if not revocable
          def revocation_service
            case token_type
            when /^github_/
              "github"
            when "anthropic_api_key"
              "anthropic"
            when "openai_api_key"
              "openai"
            when /^aws_/
              "aws"
            end
          end

          # Check if token can be revoked via API
          # @return [Boolean]
          def revocable?
            !revocation_service.nil?
          end

          # Human-readable provider name for grouping in reports
          # @return [String] Provider display name
          def provider_name
            case revocation_service
            when "github"
              "GitHub"
            when "anthropic"
              "Anthropic"
            when "openai"
              "OpenAI"
            when "aws"
              "AWS"
            else
              "Manual Revocation Required"
            end
          end

          # Convert to hash for serialization
          # @param include_raw [Boolean] Whether to include raw token value
          # @return [Hash]
          def to_h(include_raw: false)
            h = {
              token_type: token_type,
              pattern_name: pattern_name,
              confidence: confidence,
              commit_hash: commit_hash,
              file_path: file_path,
              line_number: line_number,
              masked_value: masked_value,
              detected_by: detected_by,
              revocable: revocable?
            }
            h[:raw_value] = raw_value if include_raw
            h
          end

          private

          def validate_confidence(level)
            return level if CONFIDENCE_LEVELS.include?(level)

            raise ArgumentError, "Invalid confidence level: #{level}. Must be one of: #{CONFIDENCE_LEVELS.join(", ")}"
          end
        end
      end
    end
  end
end

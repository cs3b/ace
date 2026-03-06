# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Validates typed provider references used by reviewer catalogs and CLI overrides.
      class ProviderRefValidator
        MAX_LENGTH = 120
        SEGMENT_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/.freeze

        def self.validate(provider_ref)
          ref = provider_ref.to_s.strip
          return failure("Provider reference cannot be nil or empty") if ref.empty?
          return failure("Invalid provider reference '#{ref}': max length is #{MAX_LENGTH} characters") if ref.length > MAX_LENGTH
          return failure("Invalid provider reference '#{ref}': cannot contain path separators or '..' sequences") if invalid_path?(ref)

          parts = ref.split(":")
          unless parts.length == 2
            return failure("Invalid provider reference '#{ref}': use KIND:NAME, for example llm:review-fast")
          end

          kind, name = parts
          return failure("Invalid provider reference '#{ref}': kind is required") if kind.empty?
          return failure("Invalid provider reference '#{ref}': name is required") if name.empty?
          return failure("Invalid provider reference '#{ref}': kind '#{kind}' is not supported") unless kind.match?(SEGMENT_PATTERN)
          return failure("Invalid provider reference '#{ref}': name '#{name}' is not supported") unless name.match?(SEGMENT_PATTERN)

          {
            success: true,
            kind: kind,
            name: name,
            ref: "#{kind}:#{name}"
          }
        end

        def self.validate!(provider_ref)
          result = validate(provider_ref)
          raise ArgumentError, result[:error] unless result[:success]

          result
        end

        def self.failure(message)
          { success: false, error: message }
        end
        private_class_method :failure

        def self.invalid_path?(ref)
          ref.include?("/") || ref.include?("\\") || ref.include?("..")
        end
        private_class_method :invalid_path?
      end
    end
  end
end

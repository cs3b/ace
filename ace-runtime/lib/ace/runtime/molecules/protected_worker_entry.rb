# frozen_string_literal: true

module Ace
  module Runtime
    module Molecules
      # Structural admission of source-owned pins. Artifact authentication belongs
      # to the selected entry owner; these references are never an execution grant.
      module ProtectedWorkerEntry
        LIMITS = {"interpreter" => 33_554_432, "wrapper" => 1_048_576}.freeze

        def self.validate!(value)
          unless value.is_a?(Hash) && value.keys.sort == LIMITS.keys.sort
            raise ArgumentError, "worker entry fields differ"
          end
          LIMITS.each do |key, limit|
            reference = value[key]
            unless reference.is_a?(Hash) && reference.keys.sort == %w[bytes path sha256] &&
                reference["bytes"].is_a?(Integer) && reference["bytes"].between?(1, limit) &&
                reference["sha256"].is_a?(String) && reference["sha256"].match?(/\A[0-9a-f]{64}\z/) &&
                reference["path"].is_a?(String) && reference["path"].encoding == Encoding::UTF_8 &&
                reference["path"].valid_encoding? && reference["path"].bytesize.between?(2, 4096) &&
                !reference["path"].include?("\0") && reference["path"].start_with?("/") &&
                File.expand_path(reference["path"]) == reference["path"]
              raise ArgumentError, "worker entry reference differs"
            end
          end
          value
        end
      end
    end
  end
end

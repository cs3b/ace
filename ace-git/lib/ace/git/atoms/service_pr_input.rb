# frozen_string_literal: true
require_relative "delivery_parameters"
require_relative "pr_reference"

module Ace
  module Git
    module Atoms
      # Fixed receiver input vocabulary; draft is source policy, not a flag.
      module ServicePrInput
        OPERATIONS = %w[create update ready merge].freeze
        DRAFT_OPERATIONS = %w[create update].freeze

        def self.validate(input, operation:)
          fields = case operation
          when "create", "update" then %w[target delivery title body]
          when "ready" then %w[target delivery]
          when "merge" then %w[target delivery method]
          else raise ArgumentError, "unsupported protected PR operation"
          end
          unless input.is_a?(Hash) && input.keys.sort == fields.sort &&
              input["target"].is_a?(Hash) && input["target"].keys.sort == %w[artifact_digest resource]
            raise ArgumentError, "protected PR input fields differ"
          end
          parameters = DeliveryParameters.validate(input.fetch("delivery"))
          unless input["delivery"].keys.sort == %w[forge_default forge_server pr_provenance] && input["delivery"] == parameters
            raise ArgumentError, "protected PR selection must be normalized"
          end
          resource = input.fetch("target").fetch("resource")
          if operation == "create"
            DeliveryParameters.validate_url!(resource)
            unless ServerUrl.match?(resource, parameters.fetch("pr_provenance").fetch("base_repository_url"))
              raise ArgumentError, "draft create target differs from base repository"
            end
          else
            reference = resource.is_a?(String) && PrReference.parse(resource)
            raise ArgumentError, "protected PR target requires an exact URL" unless reference && reference.repository_url
          end
          digest = input.fetch("target").fetch("artifact_digest")
          unless digest.nil? || digest.is_a?(String) && /\A[0-9a-f]{64}\z/.match?(digest)
            raise ArgumentError, "protected PR target artifact digest differs"
          end
          if DRAFT_OPERATIONS.include?(operation)
            unless input["title"].is_a?(String) && input["title"].bytesize.between?(1, 1024) &&
                input["body"].is_a?(String) && input["body"].bytesize <= 32 * 1024 &&
                [input["title"], input["body"]].all? { |text| text.dup.force_encoding(Encoding::UTF_8).valid_encoding? && !text.include?("\0") }
              raise ArgumentError, "draft PR requires bounded UTF-8 title/body"
            end
          elsif operation == "merge" && !%w[squash merge rebase].include?(input["method"])
            raise ArgumentError, "protected merge requires an exact method"
          end
          input
        end
      end
    end
  end
end

# frozen_string_literal: true

require "json"
require_relative "hermes_contract"

module Ace
  module Hitl
    module Hermes
      module Molecules
        # Message format registry (spec 8wm.t.vs1 §9): the decode gate
        # every message file passes before any other validation. Supports
        # exactly ace.hitl.hermes.message/v1; unknown versions and every
        # encoding/size violation fail closed.
        module HermesFormats
          SUPPORTED = [HermesContract::MESSAGE_SCHEMA].freeze

          module_function

          def supported
            SUPPORTED.dup
          end

          # bytes -> parsed JSON object (Hash). Raises InvalidMessageError
          # for size/encoding/JSON violations, UnknownFormatError for an
          # unsupported or absent schema id.
          def decode!(bytes)
            unless bytes.bytesize <= HermesContract::MAX_BYTES
              raise InvalidMessageError,
                "message exceeds the #{HermesContract::MAX_BYTES}-byte size bound " \
                "(#{bytes.bytesize} bytes)"
            end

            content = bytes.dup.force_encoding(Encoding::UTF_8)
            unless content.valid_encoding?
              raise InvalidMessageError, "message is not valid UTF-8"
            end

            hash =
              begin
                JSON.parse(content)
              rescue JSON::ParserError => e
                raise InvalidMessageError, "message is not valid JSON: #{e.message}"
              end
            unless hash.is_a?(Hash)
              raise InvalidMessageError, "message must be a JSON object"
            end

            schema = hash["schema"]
            unless SUPPORTED.include?(schema)
              raise UnknownFormatError,
                "unsupported message schema #{schema.inspect} (supported: " \
                "#{SUPPORTED.join(", ")})"
            end

            hash
          end
        end
      end
    end
  end
end

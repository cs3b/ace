# frozen_string_literal: true

require "digest"
require "json"

module Ace
  module Assign
    module Atoms
      # Pure canonical digest helpers for attempt evidence.
      #
      # Every accepted evidence record (events, receipts, artifacts) carries a
      # SHA-256 digest over a canonical JSON serialization (sorted keys, no
      # insignificant whitespace) so records remain comparable across writers
      # and reloads. Digests are over non-secret metadata only.
      module EvidenceDigest
        # Canonical JSON serialization of an object.
        #
        # Sorts hash keys recursively and strips insignificant whitespace so
        # semantically equal payloads produce byte-identical output.
        #
        # @param object [Object] JSON-serializable object
        # @return [String] Canonical JSON string
        def self.canonical_json(object)
          JSON.generate(sort_keys(object))
        end

        # SHA-256 hex digest over the canonical JSON of an object.
        #
        # @param object [Object] JSON-serializable object
        # @return [String] 64-character hex digest
        def self.digest(object)
          digest_string(canonical_json(object))
        end

        # SHA-256 hex digest over raw bytes.
        #
        # @param bytes [String] Raw byte content
        # @return [String] 64-character hex digest
        def self.digest_string(bytes)
          Digest::SHA256.hexdigest(bytes)
        end

        # SHA-256 hex digest of a file's contents.
        #
        # @param path [String] File path
        # @return [String] 64-character hex digest
        # @raise [Errno::ENOENT] if the file does not exist
        def self.digest_file(path)
          digest_string(File.read(path))
        end

        # Short digest prefix for file naming (collision-resistant enough for
        # append-only event filenames; full digests remain in the payload).
        #
        # @param object [Object] JSON-serializable object
        # @return [String] 12-character hex prefix
        def self.short_digest(object)
          digest(object)[0, 12]
        end

        class << self
          private

          def sort_keys(value)
            case value
            when Hash
              value.sort.to_h.transform_values { |v| sort_keys(v) }
            when Array
              value.map { |item| sort_keys(item) }
            else
              value
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "digest"
require "json"
require "stringio"
require "zlib"
require "rubygems/package"
require_relative "../molecules/canonical_evidence"

module Ace
  module Assign
    module Authority
      # One retained gem and the source-owned publication input it binds.
      # Inspect bounded metadata only; never extract or evaluate build files.
      module ReleaseArtifactManifest
        FIELDS = %w[gem_name version platform registry sha256 bytes].freeze
        NAME = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        MAX_METADATA_BYTES = 1024 * 1024
        REGISTRY = "https://rubygems.org"

        def self.validate!(value)
          unless value.is_a?(Hash) && value.keys.sort == FIELDS.sort &&
              value["gem_name"].is_a?(String) && NAME.match?(value["gem_name"]) &&
              value["version"].is_a?(String) && value["version"].bytesize.between?(1, 128) && Gem::Version.correct?(value["version"]) &&
              value["platform"].is_a?(String) && NAME.match?(value["platform"]) &&
              value["registry"] == REGISTRY && value["sha256"].is_a?(String) && value["sha256"].match?(/\A[0-9a-f]{64}\z/) &&
              value["bytes"].is_a?(Integer) && value["bytes"].between?(1, Molecules::CanonicalEvidence::MAX_RELEASE_ARTIFACT_BYTES)
            raise ArgumentError, "invalid release artifact manifest"
          end
          value
        end

        def self.verify!(bytes, manifest)
          validate!(manifest)
          unless bytes.is_a?(String) && bytes.bytesize == manifest.fetch("bytes") &&
              Digest::SHA256.hexdigest(bytes.b) == manifest.fetch("sha256")
            raise AttemptErrors::ReceiptRejected, "release artifact bytes differ from the manifest"
          end
          metadata = metadata!(bytes)
          unless metadata == manifest.slice("gem_name", "version", "platform")
            raise AttemptErrors::ReceiptRejected, "release artifact gem metadata differs from the manifest"
          end
          true
        end

        # Shared immutable input for retention and the later fixed publisher.
        # Candidate/reference come from the installed canonical owner, not wire
        # claims. Its digest is the existing service authorization input_digest.
        def self.publication_input(manifest:, candidate:, reference:)
          validate!(manifest)
          {"target" => {"resource" => "rubygems:#{manifest.fetch('gem_name')}:#{manifest.fetch('version')}",
            "artifact_digest" => manifest.fetch("sha256")},
           "publication" => manifest.slice("gem_name", "version", "platform", "registry").merge(
             "head" => candidate.fetch("head"), "tree" => candidate.fetch("tree"), "candidate_reference" => reference,
             "artifact_bytes" => manifest.fetch("bytes"), "artifact_relative_path" => "artifacts/#{manifest.fetch('sha256')}.gem")}
        end

        def self.metadata!(bytes)
          metadata = nil
          Gem::Package::TarReader.new(StringIO.new(bytes)) do |archive|
            archive.each do |entry|
              next unless entry.full_name == "metadata.gz"
              unless metadata.nil? && entry.file? && entry.header.size.between?(1, MAX_METADATA_BYTES)
                raise AttemptErrors::ReceiptRejected, "release artifact metadata is missing, repeated or oversized"
              end
              compressed = entry.read
              Zlib::GzipReader.wrap(StringIO.new(compressed)) do |reader|
                metadata = reader.read(MAX_METADATA_BYTES + 1)
                if metadata.bytesize > MAX_METADATA_BYTES
                  raise AttemptErrors::ReceiptRejected, "release artifact metadata exceeds its bound"
                end
              end
            end
          end
          raise AttemptErrors::ReceiptRejected, "release artifact metadata is unavailable" unless metadata
          specification = Gem::Specification.from_yaml(metadata)
          unless specification.is_a?(Gem::Specification)
            raise AttemptErrors::ReceiptRejected, "release artifact metadata is invalid"
          end
          {"gem_name" => specification.name, "version" => specification.version.to_s,
            "platform" => specification.platform.to_s}
        rescue AttemptErrors::ReceiptRejected
          raise
        rescue StandardError
          raise AttemptErrors::ReceiptRejected, "release artifact metadata is invalid"
        end
        private_class_method :metadata!
      end
    end
  end
end

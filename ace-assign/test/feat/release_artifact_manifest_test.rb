# frozen_string_literal: true

require_relative "../test_helper"
require "ace/assign/authority/release_artifact_manifest"

module Ace
  module Assign
    class ReleaseArtifactManifestTest < AceAssignTestCase
      def with_gem
        Dir.mktmpdir("release-artifact-") do |root|
          path = File.join(root, "retained.gem")
          specification = Gem::Specification.new do |gem|
            gem.name = "retained-fixture"
            gem.version = "1.2.3"
            gem.summary = "Retained fixture"
            gem.authors = ["ACE"]
            gem.files = []
          end
          capture_io { Gem::Package.build(specification, true, false, path) }
          bytes = File.binread(path)
          manifest = {"gem_name" => specification.name, "version" => specification.version.to_s,
            "platform" => specification.platform.to_s, "registry" => "https://rubygems.org",
            "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
          yield bytes, manifest
        end
      end

      def test_actual_built_gem_matches_exact_manifest_and_immutable_source_input
        with_gem do |bytes, manifest|
          assert Authority::ReleaseArtifactManifest.verify!(bytes, manifest)
          candidate = {"head" => "a" * 40, "tree" => "b" * 40}
          reference = {"assignment_id" => "release", "attempt_id" => "release-run",
            "candidate_generation" => 1, "acceptance_event_digest" => "c" * 64}
          input = Authority::ReleaseArtifactManifest.publication_input(manifest: manifest,
            candidate: candidate, reference: reference)
          assert_equal "rubygems:retained-fixture:1.2.3", input.dig("target", "resource")
          assert_equal manifest.fetch("sha256"), input.dig("target", "artifact_digest")
          assert_equal candidate.fetch("head"), input.dig("publication", "head")
          assert_equal candidate.fetch("tree"), input.dig("publication", "tree")
          assert_equal reference, input.dig("publication", "candidate_reference")
          assert_equal manifest.fetch("bytes"), input.dig("publication", "artifact_bytes")
          assert_equal "artifacts/#{manifest.fetch('sha256')}.gem", input.dig("publication", "artifact_relative_path")
        end
      end

      def test_changed_artifact_metadata_digest_or_length_cannot_match_the_manifest
        with_gem do |bytes, manifest|
          [{"gem_name" => "different"}, {"version" => "9.9.9"}, {"platform" => "x86_64-linux"},
            {"sha256" => "f" * 64}, {"bytes" => bytes.bytesize + 1}].each do |change|
            assert_raises(AttemptErrors::ReceiptRejected) do
              Authority::ReleaseArtifactManifest.verify!(bytes, manifest.merge(change))
            end
          end
          assert_raises(AttemptErrors::ReceiptRejected) do
            Authority::ReleaseArtifactManifest.verify!(bytes + "extra", manifest)
          end
        end
      end

      def test_manifest_has_closed_fields_registry_names_and_bounds
        with_gem do |_bytes, manifest|
          [{"extra" => true}, {"registry" => "https://other.invalid"}, {"bytes" => 0},
            {"bytes" => 64 * 1024 * 1024 + 1}, {"bytes" => "10"}, {"gem_name" => "../other"},
            {"platform" => "../other"}, {"version" => "~> 1.0"}, {"sha256" => "not-a-digest"}].each do |change|
            assert_raises(ArgumentError) { Authority::ReleaseArtifactManifest.validate!(manifest.merge(change)) }
          end
        end
      end

      def archive_with_metadata(parts)
        output = StringIO.new("".b)
        Gem::Package::TarWriter.new(output) do |archive|
          parts.each do |metadata|
            compressed = Zlib.gzip(metadata)
            archive.add_file_simple("metadata.gz", 0o644, compressed.bytesize) { |entry| entry.write(compressed) }
          end
        end
        output.string
      end

      def test_missing_repeated_or_compressed_oversized_metadata_refuses_without_payload_extraction
        valid_metadata = Gem::Specification.new { |gem| gem.name = "retained-fixture"; gem.version = "1.2.3" }.to_yaml
        [archive_with_metadata([]), archive_with_metadata([valid_metadata, valid_metadata]),
          archive_with_metadata(["a" * (Authority::ReleaseArtifactManifest::MAX_METADATA_BYTES + 1)]), "invalid archive"].each do |bytes|
          manifest = {"gem_name" => "retained-fixture", "version" => "1.2.3", "platform" => "ruby",
            "registry" => "https://rubygems.org", "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
          assert_raises(AttemptErrors::ReceiptRejected) { Authority::ReleaseArtifactManifest.verify!(bytes, manifest) }
        end
      end
    end
  end
end

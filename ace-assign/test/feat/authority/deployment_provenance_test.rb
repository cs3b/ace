# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/assign/authority/deployment"

module Ace
  module Assign
    class DeploymentProvenanceTest < AceAssignTestCase
      # Controlled protection boundary only. Real descriptors, ancestry, length,
      # digest and replacement revalidation remain the production reader's job.
      class FixtureProtection
        def root_path!(_path); true; end
        def verify!(_path, handle, directory:)
          raise "unexpected fixture kind" unless directory ? handle.stat.directory? : handle.stat.file?
        end
      end

      def with_artifact(bytes)
        Dir.mktmpdir do |root|
          path = File.join(File.realpath(root), "descriptor.json")
          File.binwrite(path, bytes)
          reference = {"path" => path, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}
          factory = -> { Ace::Runtime::Molecules::ProtectedArtifactSet.allocate.tap { |reader| reader.send(:initialize, protection: FixtureProtection.new) } }
          Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, factory) { yield path, reference }
        end
      end

      def descriptor_bytes
        JSON.generate("schema" => "ace.assign.authorities/v2", "authorities" => {}, "projects" => {}, "launch_mappings" => {})
      end

      def test_selected_artifact_preserves_exact_immutable_held_byte_provenance
        with_artifact(descriptor_bytes) do |_path, reference|
          loaded = Authority::Deployment.load_artifact(reference)
          assert_equal reference, loaded.artifact_reference
          assert loaded.frozen?
          assert loaded.data.frozen?
          assert_raises(FrozenError) { loaded.artifact_reference.fetch("path").replace("/changed") }
          assert_raises(FrozenError) { loaded.data.fetch("projects")["other"] = {} }
        end
      end

      def test_fixed_reader_derives_digest_from_same_held_bytes_and_reuses_held_identity
        with_artifact(descriptor_bytes) do |path, reference|
          Ace::Runtime::Molecules::ProtectedArtifactSet.new.with do |reader|
            bytes, actual = reader.read_path!(path, limit: 65_536)
            assert_equal descriptor_bytes, bytes
            assert_equal reference, actual
            assert actual.frozen?
            assert actual.fetch("path").frozen?
            assert_equal [bytes, actual], reader.read_path!(path, limit: 65_536)
            assert reader.verify_unchanged!
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.read_path!(path, limit: 1) }
          end
        end
      end

      def test_held_fixed_artifact_replacement_is_detected_even_for_identical_bytes
        with_artifact(descriptor_bytes) do |path, _reference|
          Ace::Runtime::Molecules::ProtectedArtifactSet.new.with do |reader|
            reader.read_path!(path, limit: 65_536)
            replacement = "#{path}.replacement"
            File.binwrite(replacement, descriptor_bytes)
            File.rename(replacement, path)
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.verify_unchanged! }
          end
        end
      end

      def test_fixed_deployment_loader_uses_shared_strict_reader_and_immutable_provenance
        bytes = descriptor_bytes
        selected = {"path" => Authority::Deployment::PATH, "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}.freeze
        boundary = Object.new
        checked = false
        boundary.define_singleton_method(:with) { |&block| block.call(boundary) }
        boundary.define_singleton_method(:read_path!) do |path, limit:|
          raise "wrong fixed selection" unless path == Authority::Deployment::PATH && limit == 65_536
          [bytes, selected]
        end
        boundary.define_singleton_method(:verify_unchanged!) { checked = true }
        Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, boundary) do
          loaded = Authority::Deployment.load
          assert loaded.frozen?
          assert_equal selected, loaded.artifact_reference
          assert checked
        end
      end

      def test_artifact_bounds_duplicate_json_and_invalid_utf8_refuse
        ['{"schema":"first","schema":"second"}', "\xff".b].each do |bytes|
          with_artifact(bytes) do |_path, reference|
            assert_raises(JSON::ParserError, ArgumentError) { Authority::Deployment.load_artifact(reference) }
          end
        end
        with_artifact("x" * 65_537) do |path, reference|
          assert_raises(ArgumentError) { Authority::Deployment.load_artifact(reference) }
          Ace::Runtime::Molecules::ProtectedArtifactSet.new.with do |reader|
            assert_raises(Ace::Runtime::RuntimeUnavailableError) { reader.read_path!(path, limit: 65_536) }
          end
        end
      end
    end
  end
end

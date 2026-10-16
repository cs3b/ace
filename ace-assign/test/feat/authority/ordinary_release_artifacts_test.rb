# frozen_string_literal: true

require_relative "ordinary_reviews_test"
require "rubygems/package"

module Ace
  module Assign
    # Reuse the genuine ordinary registration/native-start/candidate/review
    # fixture. Native observation and the external release-decision policy are
    # controlled boundaries; retention, transfer and canonical imports are real.
    class OrdinaryReviewsTest
      def prepare_reviewed_release
        register_and_start
        submit_candidate
        @admission.selected = "supervisor"
        assigned = assign_review
        @admission.selected = "reviewer"
        accept_review(assigned)
        @admission.selected = "producer"
      end

      def built_release_artifact
        path = File.join(@inputs, "built-release.gem")
        specification = Gem::Specification.new do |gem|
          gem.name = "ordinary-release-fixture"
          gem.version = "1.2.3"
          gem.summary = "Ordinary release fixture"
          gem.authors = ["ACE"]
          gem.files = []
        end
        capture_io { Gem::Package.build(specification, true, false, path) }
        bytes = File.binread(path)
        [bytes, {"gem_name" => specification.name, "version" => specification.version.to_s,
          "platform" => specification.platform.to_s, "registry" => "https://rubygems.org",
          "sha256" => Digest::SHA256.hexdigest(bytes), "bytes" => bytes.bytesize}]
      end

      def retain_release(bytes, manifest, changes: {}, mutation: "retained-gem")
        @client.call("retain_release_artifact", selection.merge("pane" => "w1:p1", "expected_generation" => 4,
          "authorization" => "release-grant", "manifest" => manifest).merge(changes), mutation_id: mutation,
          upload_parts: [bytes], purpose: :release_artifact)
      end

      def producer_events(prefix = @journal.ref_value)
        @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
      end

      def test_release_artifact_retention_imports_real_built_bytes_and_replays_without_second_import
        bindings = []
        authorizer = lambda do |binding|
          bindings << Marshal.load(Marshal.dump(binding))
          true
        end
        fixture(release_authorizer: authorizer) do
          prepare_reviewed_release
          bytes, manifest = built_release_artifact
          accepted = retain_release(bytes, manifest)
          refute accepted.replayed
          assert_equal 5, accepted.data.fetch("generation")
          prefix = @journal.ref_value
          replay = retain_release(bytes, manifest)
          assert replay.replayed
          assert_equal accepted.data, replay.data
          assert_equal prefix, @journal.ref_value
          events = producer_events(prefix)
          imports = events.select { |event| event["type"] == "evidence_import" && event.dig("payload", "kind") == "release-artifact" }
          assert_equal 1, imports.size
          assert_equal "worker", imports.first.dig("payload", "role")
          retained = @owner.release_artifact_at!(events: events, commit: prefix, artifact_id: "retained-gem")
          assert_equal bytes, retained.fetch("bytes")
          assert_equal @head, retained.dig("input", "publication", "head")
          assert_equal 1, retained.dig("input", "publication", "candidate_reference", "candidate_generation")
          assert_operator bindings.size, :>=, 4
          bindings.each do |binding|
            assert_equal "publish", binding.fetch("operation")
            assert_equal "atlas", binding.fetch("project_id")
            assert_equal Process.uid, binding.fetch("caller_uid")
            assert_equal retained.fetch("input_digest"), binding.fetch("input_digest")
            assert_equal manifest.fetch("sha256"), binding.dig("target", "artifact_digest")
          end
          forged = Marshal.load(Marshal.dump(events))
          forged.last["payload"]["data"]["input_digest"] = "f" * 64
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @owner.release_artifact_at!(events: forged, commit: prefix, artifact_id: "retained-gem")
          end
        end
      end

      def test_release_artifact_retention_refuses_changed_bytes_metadata_candidate_or_native_origin_before_write
        fixture(release_authorizer: ->(_binding) { true }) do
          prepare_reviewed_release
          bytes, manifest = built_release_artifact
          before = @journal.ref_value
          [manifest.merge("gem_name" => "other"), manifest.merge("version" => "9.9.9"),
            manifest.merge("sha256" => "f" * 64)].each do |changed|
            assert_raises(AttemptErrors::EvidenceUnavailable) { retain_release(bytes, changed) }
            assert_equal before, @journal.ref_value
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { retain_release(bytes + "extra", manifest) }
          assert_equal before, @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { retain_release(bytes, manifest, changes: {"candidate_generation" => 2}) }
          assert_equal before, @journal.ref_value
          @admission.head = @base_head
          assert_raises(AttemptErrors::EvidenceUnavailable) { retain_release(bytes, manifest) }
          assert_equal before, @journal.ref_value
          @admission.head = @head
          original = @admission.bindings.fetch("producer")
          @admission.bindings["producer"] = original.merge("agent_session" => {"agent" => "pi", "kind" => "id", "value" => SecureRandom.uuid})
          assert_raises(AttemptErrors::EvidenceUnavailable) { retain_release(bytes, manifest) }
          assert_equal before, @journal.ref_value
          assert_empty producer_events.select { |event| event.dig("payload", "kind") == "release-artifact" }
        end
      end

      def test_release_artifact_replay_rechecks_revoked_release_grant
        enabled = true
        authorizer = ->(_binding) { raise SecurityError, "controlled release grant revoked" unless enabled; true }
        fixture(release_authorizer: authorizer) do
          prepare_reviewed_release
          bytes, manifest = built_release_artifact
          retained = retain_release(bytes, manifest)
          before = @journal.ref_value
          enabled = false
          assert_raises(AttemptErrors::EvidenceUnavailable) { retain_release(bytes, manifest) }
          assert_equal before, @journal.ref_value
          assert_equal bytes, @owner.release_artifact_at!(events: producer_events, commit: before,
            artifact_id: retained.data.fetch("artifact_id")).fetch("bytes"), "retained readback is not a fresh effect permit"
        end
      end

      def test_release_artifact_requires_installed_authorizer_and_current_independent_review
        fixture do
          prepare_reviewed_release
          bytes, manifest = built_release_artifact
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { retain_release(bytes, manifest) }
          assert_equal before, @journal.ref_value
        end
        fixture(release_authorizer: ->(_binding) { true }) do
          prepare_reviewed_release
          bytes, manifest = built_release_artifact
          @admission.selected = "supervisor"
          review = @client.call("review_status", selection).data
          @client.call("cancel_review", selection.merge("pane" => "w1:pS", "expected_generation" => 4,
            "review_id" => review.fetch("review_id")), mutation_id: "cancel-before-retain")
          @admission.selected = "producer"
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { retain_release(bytes, manifest, changes: {"expected_generation" => 5}) }
          assert_equal before, @journal.ref_value
        end
      end
    end
  end
end

# frozen_string_literal: true

require "digest"
require "json"
require "net/http"
require "uri"

module Ace
  module Lab
    module Organisms
      # Staging consumer for ordinary releases: reads the retained release
      # artifacts through the sole Assign owner, verifies every canonical
      # byte digest, reconciles each artifact against the authoritative
      # registry readback, and produces the publisher's staged queue —
      # dependency-ordered, with per-artifact published/uncertain/pending
      # states. It never pushes and never holds credentials; execution stays
      # with the existing project publisher in its authorized executor.
      class OrdinaryReleaseStaging
        State = Struct.new(:artifacts, :order, :blocked) do
          def pending
            order.filter_map { |reference| artifacts.dig(reference, "state") == "pending" ? reference : nil }
          end
        end

        # registry responds to published_digest(name, version) -> String digest,
        # nil when the version is absent, or :unreachable.
        def initialize(owner:, registry: RubyGemsRegistry.new)
          @owner = owner
          @registry = registry
        end

        def stage(references:, order:)
          unless references.is_a?(Array) && !references.empty? && references.all? do |reference|
              reference.is_a?(Hash) && reference.keys.sort == %w[artifact_id assignment_id attempt_id]
            end
            raise ArgumentError, "release staging requires exact retained artifact references"
          end
          unless order.is_a?(Array) && order.map { |entry| entry.slice("assignment_id", "attempt_id", "artifact_id") } ==
              references.map { |entry| entry.slice("assignment_id", "attempt_id", "artifact_id") } &&
              order.size == references.uniq { |entry| entry["artifact_id"] }.size
            raise ArgumentError, "release staging order must cover the exact artifact set once"
          end
          staged = {}
          order.each do |reference|
            staged[reference["artifact_id"]] = stage_one(reference)
          end
          blocked = staged.select { |_id, entry| entry["state"] != "pending" && entry["state"] != "published" }
          State.new(staged, order.map { |entry| entry["artifact_id"] }, blocked.keys)
        end

        # Reads the authoritative RubyGems versions API; the CDN-cached
        # latest.json is deliberately not used (stale after publish).
        class RubyGemsRegistry
          def published_digest(name, version)
            uri = URI("https://rubygems.org/api/v1/versions/#{name}.json")
            response = Net::HTTP.get_response(uri)
            return :unreachable unless response.is_a?(Net::HTTPSuccess)
            JSON.parse(response.body).find { |entry| entry["number"] == version && entry["platform"] == "ruby" }
              &.fetch("sha", nil)
          rescue JSON::ParserError, SystemCallError
            :unreachable
          end
        end

        private

        def stage_one(reference)
          events = @owner.result_events({"assignment_id" => reference.fetch("assignment_id"),
            "attempt_id" => reference.fetch("attempt_id")}, @owner.journal.ref_value)
          retained = @owner.release_artifact_at!(events: events, commit: @owner.journal.ref_value,
            artifact_id: reference.fetch("artifact_id"))
          input = retained.fetch("input")
          name = input.dig("target", "name")
          version = input.dig("target", "version")
          digest = input.dig("target", "artifact_digest")
          unless name.is_a?(String) && version.is_a?(String) && digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/)
            raise ArgumentError, "retained release target is incomplete"
          end
          observed = @registry.published_digest(name, version)
          state = case observed
          when :unreachable then "uncertain"
          when nil then "pending"
          when digest then "published"
          else "conflict"
          end
          {"name" => name, "version" => version, "artifact_digest" => digest,
            "bytes" => retained.fetch("bytes").bytesize, "state" => state,
            "registry_digest" => observed.is_a?(String) ? observed : nil}
        end
      end
    end
  end
end

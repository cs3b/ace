# frozen_string_literal: true

require "time"

module Ace
  module Overseer
    module Molecules
      # Evaluate the current Pi session branch; this owns no additional
      # persisted state and must be paired with a live Herdr/process binding.
      class EyesEvidence
        ENTRY = "ace-wake-eyes"
        BINDING = "ace-wake-eyes-binding"

        def self.ready?(branch:, root:, process:, prompt:, required_sources:, now_ms:)
          return false unless branch.is_a?(Array) && root.is_a?(String) && process.is_a?(Hash) &&
            prompt.is_a?(String) && !prompt.empty? && required_sources.is_a?(Array) &&
            !required_sources.empty? && required_sources.all? { |name| name.is_a?(String) && !name.empty? } &&
            process["pid"].is_a?(Integer) && process["pid"].positive? && process["started_at"].is_a?(String) &&
            process["started_at"].match?(/\Alinux:[0-9a-f-]{36}:[1-9][0-9]*\z/) && now_ms.is_a?(Integer)
          eye_index = branch.rindex { |entry| entry.is_a?(Hash) && entry["type"] == "custom" && entry["customType"] == ENTRY }
          return false unless eye_index

          identity = {"pid" => process["pid"], "startedAt" => process["started_at"]}

          # A user prompt in the current branch followed by an assistant
          # completed assistant turn before the eyes entry proves more than
          # an unrelated Herdr activity transition. Reject an intervening
          # user turn or an assistant error during initialization.
          prefix = branch[0...eye_index]
          prompt_index = prefix.rindex do |entry|
            message = entry.is_a?(Hash) && entry["type"] == "message" ? entry["message"] : nil
            next false unless message.is_a?(Hash) && message["role"] == "user"
            content = message["content"]
            content == prompt || content.is_a?(Array) && content.any? { |part| part.is_a?(Hash) && part["type"] == "text" && part["text"] == prompt }
          end
          return false unless prompt_index
          binding_index = prefix.rindex do |entry|
            entry.is_a?(Hash) && entry["type"] == "custom" && entry["customType"] == BINDING &&
              entry["data"].is_a?(Hash) && entry["data"]["ownerCwd"] == root && entry["data"]["process"] == identity
          end
          return false unless binding_index
          prompt_at = (Time.iso8601(prefix[prompt_index].fetch("timestamp")).to_r * 1000).to_i
          return false unless snapshot_healthy?(branch[eye_index], root: root, identity: identity,
            required_sources: required_sources, now_ms: now_ms, prompt_at: prompt_at, fresh: true)

          complete = false
          known_bindings = {}
          branch[0..prompt_index].each do |entry|
            data = entry.is_a?(Hash) && entry["type"] == "custom" && entry["customType"] == BINDING && entry["data"]
            known_bindings[data["process"]] = true if data.is_a?(Hash) && data["ownerCwd"] == root && data["process"].is_a?(Hash)
          end
          branch[(prompt_index + 1)..eye_index].each do |entry|
            data = entry.is_a?(Hash) && entry["type"] == "custom" && entry["customType"] == BINDING && entry["data"]
            known_bindings[data["process"]] = true if data.is_a?(Hash) && data["ownerCwd"] == root && data["process"].is_a?(Hash)
            prior_identity = entry.is_a?(Hash) && entry.dig("data", "observerEvidence", "process")
            prior_binding = prior_identity.is_a?(Hash) && prior_identity["pid"].is_a?(Integer) &&
              prior_identity["pid"].positive? && prior_identity["startedAt"].is_a?(String) &&
              prior_identity["startedAt"].match?(/\Alinux:[0-9a-f-]{36}:[1-9][0-9]*\z/) && known_bindings[prior_identity]
            if complete && prior_binding && snapshot_healthy?(entry, root: root, identity: prior_identity,
                required_sources: required_sources, now_ms: now_ms, prompt_at: prompt_at, fresh: false)
              # The current binding was found in the prefix before the last
              # snapshot; initial proof may precede a process restart.
              return true
            end
            message = entry.is_a?(Hash) && entry["type"] == "message" ? entry["message"] : nil
            next unless message.is_a?(Hash)
            return false if message["role"] == "user"
            next unless message["role"] == "assistant"
            if message["stopReason"] == "stop"
              complete = true
              next
            end
            return false unless message["stopReason"] == "toolUse"
          end
          false
        rescue ArgumentError, KeyError, TypeError
          false
        end

        def self.snapshot_healthy?(entry, root:, identity:, required_sources:, now_ms:, prompt_at:, fresh:)
          return false unless entry.is_a?(Hash) && entry["type"] == "custom" && entry["customType"] == ENTRY
          eye = entry["data"]
          return false unless eye.is_a?(Hash) && eye["ownerCwd"] == root && eye["enabled"] == true &&
            eye["retired"] == false && eye["breaker"].nil? && eye["errors"] == 0
          evidence = eye["observerEvidence"]
          return false unless evidence.is_a?(Hash) && evidence["process"] == identity
          observed, sources, config = evidence.values_at("observedAt", "sources") + [eye["config"]]
          return false unless observed.is_a?(Integer) && observed >= prompt_at && observed <= now_ms && config.is_a?(Hash) &&
            config["intervalSeconds"].is_a?(Integer) && config["intervalSeconds"].between?(1, 3600) &&
            config["maxObservationsPerHour"].is_a?(Integer) && config["maxObservationsPerHour"].between?(1, 3600) &&
            config["timeoutMs"].is_a?(Integer) && config["timeoutMs"].between?(100, 120_000)
          interval = config["intervalSeconds"] * 1000
          cadence = (3_600_000.0 / (config["maxObservationsPerHour"] * interval)).ceil * interval
          return false if fresh && now_ms - observed > cadence + config["timeoutMs"]
          sources.is_a?(Hash) && sources.size.between?(1, 64) &&
            sources.keys.all? { |name| name.is_a?(String) && name.match?(/\A[a-zA-Z0-9_.:-]{1,128}\z/) } &&
            required_sources.all? { |name| sources[name] == "ok" } && sources.values.all? { |status| status == "ok" }
        end
      end
    end
  end
end

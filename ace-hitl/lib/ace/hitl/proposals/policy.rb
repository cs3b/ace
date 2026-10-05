# frozen_string_literal: true

require "json"
require "digest"
require "time"
require "ace/hitl/contract/secret_gate"

module Ace
  module Hitl
    module Proposals
      # HITL owns decisions. This policy never claims or executes an effect.
      module Policy
        WINDOW = 16 * 60 * 60
        APPROVED = %w[approved-explicitly approved-by-silence].freeze
        REQUIRED = %w[operation target candidate_head input_digest context options recommendation prerequisites].freeze

        module_function

        def document(value)
          data = JSON.parse(JSON.generate(value))
          unless data.is_a?(Hash) && (REQUIRED - data.keys).empty? &&
              (data.keys - REQUIRED - ["rationale"]).empty?
            raise Lifecycle::StateError, "proposal fields differ from proposal/v1"
          end
          unless data["operation"].is_a?(String) && data["operation"].match?(/\A[a-z][a-z0-9-]{0,63}\z/) &&
              data["candidate_head"].is_a?(String) && data["candidate_head"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/) &&
              data["input_digest"].is_a?(String) && data["input_digest"].match?(/\A[0-9a-f]{64}\z/)
            raise Lifecycle::StateError, "proposal must bind exact operation, candidate head and input digest"
          end
          target = data["target"]
          unless target.is_a?(Hash) && (target.keys - %w[resource artifact_digest]).empty? &&
              target["resource"].is_a?(String) && target["resource"].match?(/\A[a-zA-Z0-9_.:\/-]{1,256}\z/) &&
              (!target["artifact_digest"] || (target["artifact_digest"].is_a?(String) &&
                target["artifact_digest"].match?(/\A[0-9a-f]{64}\z/)))
            raise Lifecycle::StateError, "proposal target must name exact resource and optional artifact digest"
          end
          target["artifact_digest"] ||= nil
          %w[context recommendation].each { |key| text!(data[key], key) }
          text!(data["rationale"], "rationale") if data.key?("rationale")
          %w[options prerequisites].each do |key|
            unless data[key].is_a?(Array) && data[key].length <= 8 && (key != "options" || !data[key].empty?)
              raise Lifecycle::StateError, "proposal #{key} must be a bounded list"
            end
            data[key].each { |item| text!(item, key) }
          end
          if JSON.generate(data).bytesize > 3500 || Contract::SecretGate::PATTERN.match?(JSON.generate(data))
            raise Lifecycle::StateError, "proposal must be bounded and non-secret"
          end
          data
        end

        def text!(value, field)
          unless value.is_a?(String) && value.valid_encoding? && !value.strip.empty? &&
              value.bytesize <= 1024 && !value.include?("\0")
            raise Lifecycle::StateError, "invalid proposal #{field}"
          end
        end

        def timestamp(value)
          time = Time.iso8601(value.to_s)
          raise Lifecycle::StateError, "proposal time must be canonical UTC" unless time.utc.iso8601 == value
          time
        rescue ArgumentError
          raise Lifecycle::StateError, "invalid proposal timestamp"
        end

        def acknowledge(record, delivered_at)
          timestamp(delivered_at)
          return record if record["delivered_at"] == delivered_at
          unless record["state"] == "awaiting-delivery" && !record["delivered_at"]
            raise Lifecycle::StateError, "proposal delivery acknowledgement changed"
          end
          record.merge("state" => "awaiting-decision", "delivered_at" => delivered_at,
            "deadline" => (timestamp(delivered_at) + WINDOW).iso8601)
        end

        def reply(record, answer:, received_at:, sequence:, claimed:, applied: nil)
          timestamp(received_at)
          raise Lifecycle::StateError, "proposal reply has no admitted ingress" unless sequence.is_a?(Integer) && sequence.positive?
          digest = Digest::SHA256.hexdigest(JSON.generate([sequence, received_at, answer]))
          applied ||= record if record["reply_sequence"] == sequence
          if applied
            raise Lifecycle::StateError, "duplicate ingress sequence changed content" unless applied["reply_digest"] == digest
            return record
          end
          return record if %w[superseded denied].include?(record["state"])
          raise Lifecycle::StateError, "proposal has no acknowledged delivery" unless record["delivered_at"]
          text!(answer, "answer")
          Lifecycle::Kinds.check_answer!("proposal", answer)
          verb, rationale = answer.strip.split(/\s+/, 2)
          decision = {"approve" => "approved-explicitly", "veto" => "denied", "clarify" => "superseded"}[verb.downcase]
          # Scope changes and all unrecognized replies stop automatic approval.
          decision ||= "superseded"
          if claimed
            decision = record["state"]
          elsif APPROVED.include?(record["state"]) && verb.downcase == "approve"
            decision = record["state"]
          end
          result = record.merge("state" => decision, "last_sequence" => [record.fetch("last_sequence", 0), sequence].max,
            "reply_sequence" => sequence, "reply_digest" => digest,
            "captain_answer" => answer, "received_at" => received_at)
          result.delete("captain_rationale")
          result["captain_rationale"] = rationale if rationale && !rationale.strip.empty?
          result["stop_requested"] = true if claimed && verb.downcase != "approve"
          result["resolution"] = claimed ? "effect-already-claimed; stop remaining safely stoppable work" : decision
          result
        end

        def resolve(record, checkpoint:, now:)
          return record unless record["state"] == "awaiting-decision"
          return record if timestamp(now) < timestamp(record.fetch("deadline"))
          valid = checkpoint["schema"] == "ace.hitl.hermes.ingress-checkpoint/v1" &&
            checkpoint["request"] == record["request_id"] && checkpoint["revision"] == record["revision_id"] &&
            checkpoint["healthy"] == true && checkpoint["drained"] == true &&
            checkpoint.dig("checkpoint", "through") == record["deadline"] &&
            checkpoint.dig("checkpoint", "sequence").is_a?(Integer) &&
            checkpoint.dig("checkpoint", "sequence") >= record.fetch("last_sequence", 0)
          return record unless valid
          record.merge("state" => "approved-by-silence", "resolution" => "approved-by-silence",
            "resolved_at" => now, "ingress_checkpoint" => checkpoint["checkpoint"])
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "ordinary_release_staging"

module Ace
  module Lab
    module Organisms
      # Execution side of the ordinary release: publishes the staged queue
      # through the authorized project publisher — one artifact at a time in
      # dependency order, never parallel — and reconciles every attempted
      # effect against the authoritative registry readback. Partial success
      # retains the per-artifact published/uncertain sets; a failed or
      # uncertain artifact stops its dependents. Credentials and the actual
      # push stay with the executor; this organism only sequences, reads
      # back, and records outcomes.
      class OrdinaryReleasePublication
        # executor responds to publish(name:, version:) -> {exit_status:,
        # signal:, output:} — the iy6 project-command channel running the
        # existing publisher script under its authorized identity.
        def initialize(registry:, executor:)
          @registry = registry
          @executor = executor
        end

        def run(staged)
          results = {}
          halted = nil
          staged.order.each do |artifact_id|
            entry = staged.artifacts.fetch(artifact_id)
            if halted
              results[artifact_id] = entry.merge("state" => "dependent_blocked", "halted_by" => halted)
              next
            end
            case entry.fetch("state")
            when "published"
              results[artifact_id] = entry
            when "pending"
              results[artifact_id] = publish_and_reconcile(artifact_id, entry)
              unless results[artifact_id].fetch("state") == "published"
                halted = artifact_id
              end
            else
              results[artifact_id] = entry
              halted = artifact_id
            end
          end
          {"results" => results, "published" => results.count { |_id, entry| entry.fetch("state") == "published" },
            "uncertain" => results.select { |_id, entry| entry.fetch("state") == "uncertain" }.keys,
            "halted_by" => halted}
        end

        private

        def publish_and_reconcile(artifact_id, entry)
          outcome = @executor.publish(name: entry.fetch("name"), version: entry.fetch("version"))
          if outcome.fetch(:exit_status) != 0 || outcome.fetch(:signal)
            observed = @registry.published_digest(entry.fetch("name"), entry.fetch("version"))
            # The push refused but the registry may still show it (a retry
            # that actually landed earlier): reconcile before judging.
            return entry.merge("state" => "published") if observed == entry.fetch("artifact_digest")
            return entry.merge("state" => "uncertain", "executor" => outcome.slice(:exit_status, :signal))
          end
          observed = @registry.published_digest(entry.fetch("name"), entry.fetch("version"))
          case observed
          when entry.fetch("artifact_digest") then entry.merge("state" => "published")
          when nil, :unreachable then entry.merge("state" => "uncertain", "registry_readback" => observed.nil? ? "absent" : "unreachable")
          else entry.merge("state" => "conflict", "registry_digest" => observed)
          end
        rescue SystemCallError
          entry.merge("state" => "uncertain", "artifact_id" => artifact_id)
        end
      end
    end
  end
end

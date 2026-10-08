# frozen_string_literal: true
require "json"
require "open3"
require "rbconfig"

module Ace
  module Review
    module Molecules
      # Optional qjl read boundary. No ace-assign Ruby dependency/cycle and no
      # local execution journal: only its coordinator may attest accepted execution.
      class CampaignExecutionEvidence
        def initialize(repo_root:)
          @repo_root = repo_root
        end

        def check(reference, head:, name:, historical: false)
          data = read(reference, head: head, kind: "check", check_name: name, historical: historical)
          unless Array(data["checks"]).any? { |check| check["name"] == name && check["verdict"] == "passed" }
            raise Atoms::CampaignContract::Invalid, "check receipt does not prove #{name} at the reviewed head"
          end
          data
        end

        def review(reference, head:, artifacts:, historical: false)
          data = read(reference, head: head, kind: "review-collection", historical: historical)
          unless (artifacts - Array(data["artifacts"])).empty?
            raise Atoms::CampaignContract::Invalid, "review receipt does not bind every session artifact"
          end
          data
        end

        def approval(reference, head:, artifacts:, producer:, reviewer:, historical: false)
          data = read(reference, head: head, kind: "review-approval", historical: historical)
          unless data.dig("producer", "actor") == producer && data.dig("review", "reviewer", "actor") == reviewer &&
              data.dig("review", "verdict") == "approved" && data.dig("review", "head") == head &&
              (artifacts - Array(data["artifacts"])).empty?
            raise Atoms::CampaignContract::Invalid, "accepted review approval does not bind verdict, actors and reports"
          end
          data
        end

        private

        def read(reference, head:, kind:, check_name: "tests", historical: false)
          Atoms::CampaignContract.object!(reference, "accepted execution receipt")
          attempt = Atoms::CampaignContract.id!(reference["attempt_id"], "execution attempt ID")
          digest = reference["digest"]
          unless digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/)
            raise Atoms::CampaignContract::Invalid, "accepted execution receipt requires a SHA256 digest"
          end
          spec = Gem.loaded_specs["ace-assign"] || Gem::Specification.find_by_name("ace-assign")
          workspace = File.dirname(spec.full_gem_path)
          source_binstub = File.join(workspace, "bin", "ace-assign")
          env = {"PROJECT_ROOT_PATH" => @repo_root}
          if File.file?(source_binstub) && File.file?(File.join(workspace, "Gemfile"))
            executable = source_binstub
            env["BUNDLE_GEMFILE"] = File.join(workspace, "Gemfile")
          else
            executable = File.join(spec.full_gem_path, "exe", "ace-assign")
          end
          args = ["attempt", "evidence", "--attempt", attempt, "--receipt-digest", digest, "--format", "json",
            "--kind", kind, "--check-name", check_name]
          args.concat(["--historical-head", head]) if historical
          out, err, status = Open3.capture3(env, RbConfig.ruby, executable, *args, chdir: @repo_root)
          raise Atoms::CampaignContract::Invalid, "accepted execution evidence unavailable: #{err.strip}" unless status.success?
          data = JSON.parse(out)
          unless data.is_a?(Hash) && data["attempt_id"] == attempt && data["receipt_digest"] == digest &&
              data["head"] == head && data["kind"] == kind && data["historical"] == historical
            raise Atoms::CampaignContract::Invalid, "accepted execution receipt identity/head/kind mismatch"
          end
          data
        rescue Gem::LoadError, JSON::ParserError, SystemCallError => e
          raise Atoms::CampaignContract::Invalid, "ace-assign execution authority unavailable: #{e.message}"
        end
      end
    end
  end
end

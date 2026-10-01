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

        def check(reference, head:, name:)
          data = read(reference, head: head, kind: "check", check_name: name)
          unless Array(data["checks"]).any? { |check| check["name"] == name && check["verdict"] == "passed" }
            raise Atoms::CampaignContract::Invalid, "check receipt does not prove #{name} at the reviewed head"
          end
          data
        end

        def review(reference, head:, artifacts:)
          data = read(reference, head: head, kind: "review-collection")
          unless (artifacts - Array(data["artifacts"])).empty?
            raise Atoms::CampaignContract::Invalid, "review receipt does not bind every session artifact"
          end
          data
        end

        private

        def read(reference, head:, kind:, check_name: "tests")
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
          out, err, status = Open3.capture3(env, RbConfig.ruby, executable,
            "attempt", "evidence", "--attempt", attempt, "--receipt-digest", digest, "--format", "json",
            "--kind", kind, "--check-name", check_name,
            chdir: @repo_root)
          raise Atoms::CampaignContract::Invalid, "accepted execution evidence unavailable: #{err.strip}" unless status.success?
          data = JSON.parse(out)
          unless data.is_a?(Hash) && data["attempt_id"] == attempt && data["receipt_digest"] == digest &&
              data["head"] == head && data["kind"] == kind
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

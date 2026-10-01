# frozen_string_literal: true
require "json"
require "open3"
require "rbconfig"

module Ace
  module Review
    module Molecules
      # Optional qjl read boundary. No ace-assign Ruby dependency/cycle and no
      # local check journal: only its coordinator may attest accepted execution.
      class CampaignCheckEvidence
        def initialize(repo_root:)
          @repo_root = repo_root
        end

        def call(reference, head:, name:)
          Atoms::CampaignContract.object!(reference, "accepted check receipt")
          attempt = Atoms::CampaignContract.id!(reference["attempt_id"], "check attempt ID")
          digest = reference["digest"]
          unless digest.is_a?(String) && digest.match?(/\A[0-9a-f]{64}\z/)
            raise Atoms::CampaignContract::Invalid, "accepted check receipt requires a SHA256 digest"
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
            chdir: @repo_root)
          raise Atoms::CampaignContract::Invalid, "accepted check evidence unavailable: #{err.strip}" unless status.success?
          data = JSON.parse(out)
          unless data.is_a?(Hash) && data["attempt_id"] == attempt && data["receipt_digest"] == digest &&
              data["head"] == head && Array(data["checks"]).any? { |c| c["name"] == name && c["verdict"] == "passed" }
            raise Atoms::CampaignContract::Invalid, "check receipt does not prove #{name} at the reviewed head"
          end
          data
        rescue Gem::LoadError, JSON::ParserError, SystemCallError => e
          raise Atoms::CampaignContract::Invalid, "ace-assign check authority unavailable: #{e.message}"
        end
      end
    end
  end
end

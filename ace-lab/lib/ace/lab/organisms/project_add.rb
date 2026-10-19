# frozen_string_literal: true

require_relative "../errors"
require_relative "../molecules/repository_provisioner"
require_relative "../molecules/overseer_provisioner"
require_relative "../molecules/project_registry"

module Ace
  module Lab
    module Organisms
      # Orchestrates `ace-lab project add` (L8.2, task 8xg.t.sbz.7.1):
      # making a project ready for team work means (1) the repository
      # exists at the declared path with the declared origin remote — the
      # planner provisions task worktrees from it, (2) the private
      # untracked `.ace-tasks/_overseer/` folder is prepared, and (3) the
      # project is registered in the project's own `.ace/lab/config.yml`
      # so `ace-lab status`, `ace-lab projects` and `ace-overseer
      # projects` see it through the ordinary config cascade. Accounts,
      # directories, keys and roles are machine-level facts already
      # converged by `ace-lab prepare` (L8.1); this organism adds no
      # other state owner. Steps run in a fixed order; a failed
      # repository step fails dependents instead of attempting them.
      # Re-adding an already-registered project re-validates and reports
      # without rewriting; contradictory or foreign registrations are
      # refused before anything is overwritten.
      class ProjectAdd
        attr_reader :dry_run

        def initialize(runner: nil, dry_run: false)
          @runner = runner
          @dry_run = dry_run
        end

        # @param id [String] project id (topology id)
        # @param path [String] absolute project path
        # @param remote [String, nil] origin remote URL
        # @param label [String, nil] display label
        # @param dry_run [Boolean, nil] per-call override
        # @return [Hash] report: ok / dry_run / project / repository /
        #   overseer / registry
        def call(id:, path:, remote: nil, label: nil, dry_run: nil)
          effective_dry_run = dry_run.nil? ? self.dry_run : dry_run
          repository = Molecules::RepositoryProvisioner.new(runner: @runner, dry_run: effective_dry_run)
            .call(path: path, remote: remote)
          ready = repository["status"] != "failed"

          overseer = if ready
            Molecules::OverseerProvisioner.new(dry_run: effective_dry_run).call(root: path)
          else
            skipped("_overseer", "repository not ready; fix the repository step first")
          end

          registry = if ready
            Molecules::ProjectRegistry.new.register(
              root: path,
              project: {"id" => id, "label" => label, "path" => path, "remote" => remote},
              dry_run: effective_dry_run
            )
          else
            skipped(".ace/lab/config.yml", "repository not ready; fix the repository step first")
          end

          {
            "ok" => [repository, overseer, registry].none? { |item| item["status"] == "failed" },
            "dry_run" => effective_dry_run,
            "project" => id,
            "path" => path,
            "remote" => remote,
            "repository" => repository,
            "overseer" => overseer,
            "registry" => registry
          }
        end

        private

        def skipped(location, message)
          {"location" => location, "status" => "failed", "message" => message}
        end
      end
    end
  end
end

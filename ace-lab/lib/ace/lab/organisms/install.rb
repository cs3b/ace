# frozen_string_literal: true

require_relative "../errors"
require_relative "../molecules/install_manifest_loader"
require_relative "../molecules/grant_provisioner"
require_relative "prepare"
require_relative "project_add"

module Ace
  module Lab
    module Organisms
      # Orchestrates the full new-lab installation (L8.3, task
      # 8xg.t.sbz.7.2) from the trusted install manifest by composing
      # the existing molecules in a fixed order — nothing here
      # duplicates them:
      #
      #   1. foreign-lab guard (BEFORE any mutation): the trusted
      #      authorization document must not grant projects this
      #      manifest does not declare — a ready/foreign lab is refused
      #      with a classified error and zero writes;
      #   2. `Prepare` (L8.1): accounts → directories → keys → roles;
      #   3. `ProjectAdd` (L8.2) per declared project: repository,
      #      private `_overseer`, project registry — each project is
      #      isolated; one failing project does not block the others;
      #   4. `GrantProvisioner`: trusted-tier principal grants that
      #      make the installed projects visible to `ace-lab projects`
      #      and `ace-overseer projects`.
      #
      # Every step is idempotent, so an interrupted re-run converges
      # where steps already completed (the resume contract .7.3 builds
      # on: no journal — the report is a per-step record in prepare's
      # established shape). The organism owns no new state: it writes
      # only through the provisioners above.
      class Install
        attr_reader :manifest_path, :dry_run, :platform

        def initialize(manifest_path: nil, runner: nil, account_lookup: nil, privileged: nil,
          platform: nil, dry_run: false, prepare: nil, project_add: nil, grants: nil)
          @manifest_path = manifest_path || Ace::Lab.install_manifest_path
          @runner = runner
          @account_lookup = account_lookup
          @privileged = privileged
          @platform = platform
          @dry_run = dry_run
          @prepare = prepare
          @project_add = project_add
          @grants = grants
        end

        # @param dry_run [Boolean, nil] per-call override of the
        #   constructor default (the CLI passes its --dry-run here)
        # @return [Hash] aggregated report (ok / dry_run / machine /
        #   manifest / prepare / projects / grants)
        # @raise [Ace::Lab::InvalidConfigurationError] missing, untrusted
        #   or invalid manifest, or a foreign lab refusing overwrite
        #   before any mutation
        def call(dry_run: nil)
          effective_dry_run = dry_run.nil? ? self.dry_run : dry_run
          manifest = Molecules::InstallManifestLoader.load(path: manifest_path, platform: platform)
          declared_projects = manifest["projects"].map { |project| project["id"] }

          conflict = grants_molecule.foreign_grants?(declared_projects)
          if conflict
            raise Ace::Lab::InvalidConfigurationError,
              "refusing to install over a foreign lab: #{conflict}"
          end

          prepare_report = prepare_organism.call(dry_run: effective_dry_run)
          prepare_ok = prepare_report["ok"]

          projects = manifest["projects"].map do |project|
            if prepare_ok
              project_add_organism.call(
                id: project["id"], path: project["path"],
                remote: project["remote"], label: project["label"],
                dry_run: effective_dry_run
              )
            else
              dependency_failed_project(project,
                "prepare did not converge; fix the prepare phase first")
            end
          end
          projects_ok = projects.all? { |report| report["ok"] }

          grants = if prepare_ok && projects_ok
            grants_molecule.call(
              desired: manifest["grants"], declared_projects: declared_projects,
              dry_run: effective_dry_run
            )
          else
            {"path" => Ace::Lab.authorization_path, "status" => "failed", "principals" => {},
              "message" => "install steps did not converge; fix the failing steps first " \
                "(trusted grants are configured only for a converged install)"}
          end

          {
            "ok" => prepare_ok && projects_ok && grants["status"] != "failed",
            "dry_run" => effective_dry_run,
            "machine" => manifest["machine"],
            "manifest" => manifest_path,
            "prepare" => prepare_report,
            "projects" => projects,
            "grants" => grants
          }
        end

        private

        def prepare_organism
          @prepare || Prepare.new(
            manifest_path: manifest_path, runner: @runner, account_lookup: @account_lookup,
            privileged: @privileged, platform: platform
          )
        end

        def project_add_organism
          @project_add || ProjectAdd.new(runner: @runner)
        end

        def grants_molecule
          @grants || Molecules::GrantProvisioner.new
        end

        # Same shape as a ProjectAdd report, with every step failed as a
        # dependency failure — mirroring prepare's dependency pattern.
        def dependency_failed_project(project, message)
          failed = ->(location) { {"location" => location, "status" => "failed", "message" => message} }
          {
            "ok" => false,
            "dry_run" => dry_run,
            "project" => project["id"],
            "path" => project["path"],
            "remote" => project["remote"],
            "repository" => failed.call(project["path"]),
            "overseer" => failed.call(File.join(project["path"], ".ace-tasks", "_overseer")),
            "registry" => failed.call(File.join(project["path"], ".ace", "lab", "config.yml"))
          }
        end
      end
    end
  end
end

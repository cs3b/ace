# frozen_string_literal: true

require_relative "../errors"
require_relative "../molecules/install_manifest_loader"
require_relative "../molecules/grant_provisioner"
require_relative "prepare"
require_relative "project_add"
require_relative "verify"

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
      #      private `_overseer`, project registry, executor ownership
      #      propagation — each project is isolated; one failing
      #      project does not block the others;
      #   4. `GrantProvisioner`: trusted-tier principal grants that
      #      make the installed projects visible to `ace-lab projects`
      #      and `ace-overseer projects`;
      #   5. `Verify` (final stage, task 8xg.t.sbz.7.4): the declared
      #      adapters and required tools are part of the SAME trusted
      #      manifest (validated at load, reported under `adapters` /
      #      `tools`), and the converged lab must prove ready UNDER THE
      #      TARGET ACCOUNTS — tool availability, adapter commands and
      #      every other readiness check — or install reports not ok.
      #      Dry runs skip this stage (nothing has converged to verify).
      #
      # Every step is idempotent, so an interrupted re-run converges
      # where steps already completed (the resume contract .7.3 builds
      # on: no journal — the report is a per-step record in prepare's
      # established shape). The organism owns no new state: it writes
      # only through the provisioners above; the trusted manifest
      # remains the single owner of the adapter/tool declarations.
      class Install
        attr_reader :manifest_path, :dry_run, :platform

        def initialize(manifest_path: nil, runner: nil, account_lookup: nil, privileged: nil,
          platform: nil, dry_run: false, prepare: nil, project_add: nil, grants: nil, verify: nil)
          @manifest_path = manifest_path || Ace::Lab.install_manifest_path
          @runner = runner
          @account_lookup = account_lookup
          @privileged = privileged
          @platform = platform
          @dry_run = dry_run
          @prepare = prepare
          @project_add = project_add
          @grants = grants
          @verify = verify
        end

        # @param dry_run [Boolean, nil] per-call override of the
        #   constructor default (the CLI passes its --dry-run here)
        # @return [Hash] aggregated report (ok / dry_run / machine /
        #   manifest / prepare / projects / grants / adapters / tools /
        #   verify)
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
                owner: project_owner(manifest, project["path"]),
                dry_run: effective_dry_run
              )
            else
              dependency_failed_project(project,
                "prepare did not converge; fix the prepare phase first", effective_dry_run)
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
              "kept" => [], "dry_run" => effective_dry_run,
              "message" => "install steps did not converge; fix the failing steps first " \
                "(trusted grants are configured only for a converged install)"}
          end

          verify_report = verify_stage(manifest, effective_dry_run)

          {
            "ok" => prepare_ok && projects_ok && grants["status"] != "failed" &&
              verify_stage_ok?(verify_report),
            "dry_run" => effective_dry_run,
            "machine" => manifest["machine"],
            "manifest" => manifest_path,
            "prepare" => prepare_report,
            "projects" => projects,
            "grants" => grants,
            "adapters" => manifest["adapters"],
            "tools" => manifest["tools"],
            "verify" => verify_report
          }
        end

        private

        # Final install verification (LAB-3): read-only, over the
        # converged artifacts. A wet run's readiness gates `ok`; a dry
        # run has nothing converged to verify and reports the stage
        # skipped instead of a guaranteed failure.
        def verify_stage(manifest, dry_run)
          return {"ready" => nil, "status" => "skipped",
                  "message" => "verification runs on the converged lab; dry-run predicts the " \
                    "steps above only"} if dry_run

          verify_organism.call
        rescue Ace::Lab::InvalidConfigurationError => e
          {"ready" => false, "status" => "failed",
           "message" => "final verification could not run: #{e.message}"}
        rescue StandardError => e
          {"ready" => false, "status" => "failed",
           "message" => "final verification crashed: #{e.class}: #{e.message}"}
        end

        def verify_stage_ok?(report)
          report["ready"] != false
        end

        def verify_organism
          @verify || Verify.new(
            manifest_path: manifest_path, runner: @runner, account_lookup: @account_lookup,
            authorization_path: grants_molecule.authorization_path, platform: platform
          )
        end

        # The project's target executor account: the owner of the
        # declared directory the project lives in (longest prefix
        # match); projects outside any declared directory are left
        # ownership-neutral.
        def project_owner(manifest, path)
          candidates = manifest["directories"].filter_map do |directory|
            owner = directory["owner"]
            prefix = directory["path"].to_s
            owner && path.start_with?("#{prefix}/") ? [prefix.length, owner] : nil
          end
          candidates.max_by(&:first)&.last
        end

        def prepare_organism
          @prepare || Prepare.new(
            manifest_path: manifest_path, runner: @runner, account_lookup: @account_lookup,
            privileged: @privileged, platform: platform
          )
        end

        def project_add_organism
          @project_add || ProjectAdd.new(runner: @runner, account_lookup: @account_lookup)
        end

        def grants_molecule
          @grants || Molecules::GrantProvisioner.new
        end

        # Same shape as a ProjectAdd report, with every step failed as a
        # dependency failure — mirroring prepare's dependency pattern.
        # `dry_run` is the effective per-call value, not the constructor
        # default (review r1).
        def dependency_failed_project(project, message, dry_run)
          failed = ->(location) { {"location" => location, "status" => "failed", "message" => message} }
          {
            "ok" => false,
            "dry_run" => dry_run,
            "project" => project["id"],
            "path" => project["path"],
            "remote" => project["remote"],
            "repository" => failed.call(project["path"]),
            "overseer" => failed.call(File.join(project["path"], ".ace-tasks", "_overseer")),
            "registry" => failed.call(File.join(project["path"], ".ace", "lab", "config.yml")),
            "owner" => failed.call(project["path"])
          }
        end
      end
    end
  end
end

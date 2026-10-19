# frozen_string_literal: true

require_relative "../errors"
require_relative "../molecules/repository_provisioner"
require_relative "../molecules/overseer_provisioner"
require_relative "../molecules/project_registry"
require_relative "../molecules/hitl_routes"
require "etc"

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

        def initialize(runner: nil, account_lookup: nil, chown: nil, dry_run: false)
          @runner = runner
          # Production resolves declared owners through the REAL system
          # passwd (same seam as RoleVerifier/Verify); only tests inject
          # a lookup (PR #393 final audit, FINAL-LAB1: a nil default
          # classified every declared owner as nonexistent).
          @account_lookup = account_lookup || method(:lookup_passwd)
          @chown = chown
          @dry_run = dry_run
        end

        # @param id [String] project id (topology id)
        # @param path [String] absolute project path
        # @param remote [String, nil] origin remote URL
        # @param label [String, nil] display label
        # @param owner [String, nil] target executor account the
        #   project tree must belong to when install runs privileged
        #   (root); nil leaves ownership untouched
        # @param hitl_adapters [Array<Hash>] normalized manifest
        #   adapters; the `kind: hitl` declarations are projected into
        #   the project's runtime HITL route configuration (FINAL-LAB2)
        # @param dry_run [Boolean, nil] per-call override
        # @return [Hash] report: ok / dry_run / project / repository /
        #   overseer / registry / hitl / owner
        def call(id:, path:, remote: nil, label: nil, owner: nil, hitl_adapters: [], dry_run: nil)
          effective_dry_run = dry_run.nil? ? self.dry_run : dry_run
          repository = Molecules::RepositoryProvisioner.new(runner: @runner, dry_run: effective_dry_run)
            .call(path: path, remote: remote)
          ready = repository["status"] != "failed"

          overseer = if ready
            Molecules::OverseerProvisioner.new(runner: @runner, dry_run: effective_dry_run).call(root: path)
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

          converged = [repository, overseer, registry].none? { |item| item["status"] == "failed" }
          hitl = if converged
            Molecules::HitlRoutes.new.install(
              root: path, adapters: hitl_adapters, dry_run: effective_dry_run
            )
          else
            skipped(".ace/hitl/config.yml", "repository not ready; fix the repository step first")
          end

          steps = {"repository" => repository, "overseer" => overseer,
                   "registry" => registry, "hitl" => hitl}
          ownership = if steps.any? { |_step, item| item["status"] == "failed" }
            failed_step, = steps.find { |_step, item| item["status"] == "failed" }
            skipped_owner(owner, "step '#{failed_step}' is not ready; fix that step first")
          else
            propagate_owner(path, owner, effective_dry_run)
          end

          {
            "ok" => [repository, overseer, registry, hitl, ownership].none? { |item| item["status"] == "failed" },
            "dry_run" => effective_dry_run,
            "project" => id,
            "path" => path,
            "remote" => remote,
            "repository" => repository,
            "overseer" => overseer,
            "registry" => registry,
            "hitl" => hitl,
            "owner" => ownership
          }
        end

        private

        # Root-installed projects must end up owned by the declared
        # target executor, or the executor cannot work in them (LAB-2).
        # Chown is a privileged operation: a non-root installer reports
        # skipped (verify then judges executor access on the real bits).
        def propagate_owner(path, owner, dry_run)
          base = {"account" => owner, "path" => path}
          return base.merge("status" => "skipped", "message" => nil) if owner.nil?

          entry = @account_lookup ? @account_lookup.call(owner) : nil
          if entry.nil?
            return base.merge("status" => "failed",
              "message" => "owner account '#{owner}' does not exist; fix the account phase first")
          end
          return base.merge("status" => "would_propagate", "message" => nil) if dry_run
          unless Process.uid.zero?
            return base.merge("status" => "skipped",
              "message" => "installer is not root; ownership left untouched (verify reports " \
                "the executor's actual access)")
          end

          # A root uid match on the project root proves nothing about
          # generated children (root may have just created
          # `.ace/lab/config.yml` / `.ace/hitl/config.yml` mode 0600
          # with its own uid inside), so a root installer ALWAYS
          # converges the whole tree instead of skipping.
          begin
            chown.call(entry.uid, entry.gid, path)
          rescue SystemCallError, ArgumentError, TypeError => e
            return base.merge("status" => "failed",
              "message" => "propagating ownership of '#{path}' to '#{owner}' failed: #{e.message}")
          end
          base.merge("status" => "propagated", "message" => nil)
        end

        # Privileged recursive chown; injectable so tests can exercise
        # the root branch without uid 0.
        def chown
          @chown || ->(uid, gid, path) {
            require "fileutils"
            FileUtils.chown_R(uid, gid, path)
          }
        end

        def skipped_owner(owner, message)
          {"account" => owner, "path" => nil, "status" => "failed", "message" => message}
        end

        def skipped(location, message)
          {"location" => location, "status" => "failed", "message" => message}
        end

        def lookup_passwd(username)
          Etc.getpwnam(username)
        rescue ArgumentError
          nil
        end
      end
    end
  end
end

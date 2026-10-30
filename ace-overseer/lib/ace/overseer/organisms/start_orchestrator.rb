# frozen_string_literal: true

require_relative "../atoms/start_contract"
require_relative "../molecules/project_root_resolver"
require "ace/herdr"
require "json"

module Ace
  module Overseer
    module Organisms
      # `ace-overseer start` (task 8xs.t.pu0.1): boots or reuses the
      # PROJECT overseer session from the directory's own configuration
      # — an explicit `start` section (scope/profile/instructions) in
      # the `.ace/overseer/config.yml` cascade, a profile from the same
      # document's `profiles` map, and the guide resolved through the
      # normal handbook override chain. No interim defaults: a missing
      # or ambiguous configuration is a blocked start, never a guess.
      #
      # Session identity is Herdr's: the tab/pane label
      # `overseer-<project>` derives from the canonical repository root
      # (subdirectory, symlink and worktree of one repository are the
      # SAME owner, so a worktree never spawns a second whole-project
      # overseer). A live owner pane is REUSED; a live pane with a
      # conflicting cwd is a conflict (never taken over); a dead pane is
      # replaced with a new identity reported in the result. The agent
      # boots with the packaged guide as standing instructions — the
      # overseer coordinates and delegates, it never substitutes for a
      # missing coworker.
      class StartOrchestrator
        AGENT_NAME = "ace-overseer"
        START_TIMEOUT_MS = 60_000

        attr_reader :cwd

        # @param config [Hash, nil] resolved overseer config (defaults
        #   to Ace::Overseer.config)
        # @param executor [HerdrExecutor, nil] herdr seam
        # @param root_resolver [ProjectRootResolver, nil]
        # @param nav_runner [Proc, nil] (argv, cwd) runner seam for
        #   resolving wfi:// instructions through ace-nav
        # @param cwd [String] invocation directory
        def initialize(config: nil, executor: nil, root_resolver: nil, nav_runner: nil,
          cwd: Dir.pwd)
          @config = config || Ace::Overseer.config
          @executor = executor || Ace::Herdr::Molecules::HerdrExecutor.new
          @root_resolver = root_resolver || Molecules::ProjectRootResolver.new
          @nav_runner = nav_runner || method(:run_nav)
          @cwd = cwd
        end

        # @param dry_run [Boolean] report the plan without creating a
        #   session, syncing, or invoking any model
        # @return [Hash] {status: started|reused|blocked|dry_run, scope,
        #   root, label, workspace, pane, agent, profile, instructions,
        #   replaced_pane, message}; scope lab additionally carries
        #   {projects: [{id, path, status, ...}], project_count, ready}
        def call(dry_run: false)
          plan = Atoms::StartContract.normalize(@config)
          return lab_start(plan, dry_run) if plan["scope"] == "lab"

          root = @root_resolver.resolve(cwd: @cwd)
          label = Atoms::StartContract.session_label(root)
          instructions_path = resolve_instructions(plan["instructions"], root)

          report = base_report(plan, root, label, instructions_path)
          return report.merge("status" => "dry_run",
            "message" => "dry-run: session would start with this plan; nothing was created") if dry_run

          workspace = resolve_workspace
          report["workspace"] = workspace

          owner = owner_pane(label)
          if owner
            conflict = owner_conflict(owner, root)
            if conflict
              return report.merge("status" => "blocked", "pane" => owner["id"], "message" => conflict)
            end

            if agent_alive?(owner["id"])
              return report.merge("status" => "reused", "pane" => owner["id"],
                "message" => "existing project overseer session reused; no second session created")
            end
            # a dead owner is replaced after observing the real state —
            # the new identity is reported, the old pane is left to the
            # operator's pane hygiene
            report["replaced_pane"] = owner["id"]
          end

          pane = boot_session(workspace, label, root, plan, instructions_path)
          report.merge("status" => "started", "pane" => pane,
            "message" => "project overseer session started; the agent reads its " \
              "private tasks and project state and stays idle when there is no work")
        rescue Ace::Overseer::Error, Ace::Herdr::ExecutorUnavailableError => e
          blocked(e.message)
        end

        private

        # --- lab scope (task 8xs.t.pu0.a) -----------------------------------
        # The lab root is its own coordination directory with its own
        # _overseer. The project list and canonical locations come from
        # the existing ace-lab topology configuration (topology.projects
        # id/path) — never from the sanitized public projection and
        # never derived from an id/label/repo name. Each project starts
        # through the SAME operation as a standalone start (its own
        # cascade, its own session identity); an unhealthy project is
        # reported per-project while healthy projects continue; a
        # repeated start repairs only what is missing and never
        # restarts healthy sessions or closes manual panes.
        def lab_start(plan, dry_run)
          lab_root = File.realpath(@cwd)
          instructions_path = resolve_instructions(plan["instructions"], lab_root)
          base = {"status" => nil, "scope" => "lab", "root" => lab_root,
            "label" => Atoms::StartContract.session_label(lab_root),
            "workspace" => nil, "pane" => nil, "agent" => AGENT_NAME,
            "profile" => plan["profile_name"],
            "instructions" => {"source" => plan["instructions"], "path" => instructions_path},
            "replaced_pane" => nil, "projects" => [], "project_count" => 0,
            "ready" => nil, "message" => nil}

          projects = begin
            Ace::Lab::Molecules::ProjectLocations.read(lab_root)
          rescue StandardError => e
            return base.merge("status" => "blocked",
              "message" => "lab topology could not be read: #{e.class}: #{e.message}")
          end

          if projects.any? { |project| project["path"].to_s.empty? == false &&
            File.directory?(project["path"]) && File.realpath(project["path"]) == lab_root }
            return base.merge("status" => "blocked",
              "message" => "the lab root '#{lab_root}' is itself declared as a project; " \
                "conflicting lab/project roles are refused")
          end

          return base.merge("status" => "dry_run", "project_count" => projects.size,
            "projects" => projects.map { |project| {"id" => project["id"], "path" => project["path"],
              "status" => "would_start"}},
            "message" => "dry-run: the lab space and #{projects.size} project overseer(s) " \
              "would start; nothing was created") if dry_run

          # An empty configured list is a valid idle lab.
          if projects.empty?
            return base.merge("status" => "ready", "ready" => true, "project_count" => 0,
              "message" => "no projects configured; the lab overseer is idle")
          end

          workspace = lab_workspace
          base["workspace"] = workspace

          results = projects.map { |project| start_project(project, lab_root) }
          ready = results.all? { |result| %w[started reused].include?(result["status"]) }
          base.merge("status" => ready ? "ready" : "partial", "ready" => ready,
            "projects" => results, "project_count" => results.size,
            "message" => "#{results.count { |r| %w[started reused].include?(r["status"]) }}/" \
              "#{results.size} project overseers ready")
        end

        # The lab's own herdr space, created once and reused by title.
        def lab_workspace
          existing = @executor.workspace_list.parsed_json
          list = existing.is_a?(Hash) ? Array(existing["result"] || existing["workspaces"]) : Array(existing)
          found = list.find { |entry| entry["title"] == "overseer-lab" || entry["label"] == "overseer-lab" }
          return found["id"] if found && (found["id"] || found["workspace_id"])

          created = @executor.workspace_create(label: "overseer-lab").parsed_json
          result = created.is_a?(Hash) ? created["result"] : nil
          dig_workspace(result.is_a?(Hash) ? result : created)
        rescue Ace::Herdr::ExecutorUnavailableError => e
          raise Ace::Overseer::Error, "herdr is unavailable: #{e.message}"
        end

        def dig_workspace(payload)
          return nil unless payload.is_a?(Hash)

          payload["workspace_id"] || payload["id"] || payload.dig("workspace", "id")
        end

        # One project through the SAME operation as a standalone start:
        # its own cascade (config_at), its own canonical root and session
        # identity. A missing path or unreadable directory is THAT
        # project's failure — the others continue.
        def start_project(project, lab_root)
          id = project["id"]
          path = project["path"]
          if path.nil? || path.to_s.strip.empty?
            return {"id" => id, "path" => nil, "status" => "blocked",
              "message" => "project '#{id}' declares no path in the lab topology"}
          end
          unless File.directory?(path)
            return {"id" => id, "path" => path, "status" => "blocked",
              "message" => "project '#{id}' directory '#{path}' does not exist"}
          end

          project_config = Ace::Overseer.config_at(path)
          orchestrator = self.class.new(config: project_config, executor: @executor,
            root_resolver: @root_resolver, nav_runner: @nav_runner, cwd: path)
          report = orchestrator.call
          report.merge("id" => id, "path" => path)
        rescue Ace::Overseer::Error, Ace::Herdr::ExecutorError => e
          {"id" => id, "path" => path, "status" => "blocked", "message" => e.message}
        end

        def base_report(plan, root, label, instructions_path)
          {"status" => nil, "scope" => plan["scope"], "root" => root, "label" => label,
           "workspace" => nil, "pane" => nil, "agent" => AGENT_NAME,
           "profile" => plan["profile_name"], "instructions" =>
             {"source" => plan["instructions"], "path" => instructions_path},
           "replaced_pane" => nil, "message" => nil}
        end

        def blocked(message)
          {"status" => "blocked", "scope" => nil, "root" => nil, "label" => nil,
           "workspace" => nil, "pane" => nil, "agent" => AGENT_NAME, "profile" => nil,
           "instructions" => nil, "replaced_pane" => nil, "message" => message}
        end

        # wfi:// (and sibling protocol) sources resolve through the
        # project's own ace-nav (binstub when present, PATH otherwise —
        # the same binary choice the executor's resolver makes); an
        # absolute path is used verbatim. The resolved file is the
        # harness's standing-instruction source.
        def resolve_instructions(source, root)
          return source unless source.include?("://")

          binstub = File.join(root, "bin", "ace-nav")
          binary = !Process.uid.zero? && File.executable?(binstub) ? binstub : "ace-nav"
          result = @nav_runner.call([binary, "resolve", source], root)
          path = result["status"] == "ok" ? result["out"].to_s.lines.first.to_s.strip : nil
          if path.nil? || path.empty?
            raise Ace::Overseer::Error,
              "start instructions '#{source}' do not resolve through ace-nav " \
                "for project '#{File.basename(root)}'"
          end

          path
        end

        # Same workspace policy as ControlSurface: the caller's herdr
        # workspace when invoked from a pane, otherwise the current
        # pane projection; an environment without herdr is a blocked
        # start, never a guessed session.
        def resolve_workspace
          env = ENV["HERDR_WORKSPACE_ID"].to_s
          return env unless env.empty?

          json = @executor.pane_current.parsed_json
          workspace = dig_workspace(json)
          unless workspace
            raise Ace::Overseer::Error,
              "cannot resolve the herdr workspace; run ace-overseer start " \
                "inside a herdr pane or start herdr first"
          end

          workspace
        rescue Ace::Herdr::ExecutorUnavailableError => e
          raise Ace::Overseer::Error, "herdr is unavailable: #{e.message}"
        end

        # The live pane owning this project's overseer label.
        def owner_pane(label)
          panes = extract_panes(@executor.pane_list.parsed_json)
          panes.find { |pane| pane["title"] == label || pane["label"] == label }
        rescue Ace::Herdr::ExecutorUnavailableError => e
          raise Ace::Overseer::Error, "herdr is unavailable: #{e.message}"
        end

        # A live owner whose cwd belongs to a DIFFERENT canonical root
        # is a conflict — it is never silently taken over. Returns the
        # conflict message or nil when the owner matches the root.
        def owner_conflict(owner, root)
          owner_cwd = owner["cwd"].to_s
          if owner_cwd.empty?
            return "owner pane '#{owner["id"]}' reports no working directory; " \
              "verify the session manually before starting"
          end

          owner_root = @root_resolver.resolve(cwd: owner_cwd)
          if owner_root != root
            return "owner pane '#{owner["id"]}' works in '#{owner_cwd}', which " \
              "resolves to '#{owner_root}', not the project root '#{root}'; " \
                "refusing to take over a foreign session"
          end

          nil
        rescue Ace::Overseer::Error
          "owner pane '#{owner["id"]}' works in '#{owner_cwd}', which does not " \
            "resolve to the project root '#{root}'; refusing to take over a " \
              "foreign session"
        end

        def agent_alive?(pane)
          @executor.agent_get(pane)
          true
        rescue Ace::Herdr::AgentNotFoundError
          false
        end

        # Boots the session: one herdr tab labeled with the owner
        # identity, cwd at the project root, then the harness agent with
        # the configured profile and the packaged guide as standing
        # instructions (passthrough args).
        def boot_session(workspace, label, root, plan, instructions_path)
          tab = @executor.tab_create(workspace_id: workspace, label: label, cwd: root)
            .parsed_json
          pane = dig_pane(tab)
          unless pane
            raise Ace::Overseer::Error,
              "herdr created tab '#{label}' but reported no root pane"
          end

          args = ["--model", plan["profile"]["model"]]
          if plan["profile"]["thinking"]
            args += ["--thinking", plan["profile"]["thinking"]]
          end
          args += ["--append-system-prompt", instructions_path]

          @executor.agent_start(name: AGENT_NAME, kind: plan["profile"]["harness"],
            pane: pane, timeout_ms: START_TIMEOUT_MS, args: args)
          pane
        rescue Ace::Herdr::CommandError => e
          raise Ace::Overseer::Error, "herdr failed to start the overseer session: #{e.message}"
        end

        def extract_panes(json)
          case json
          when Array then json
          when Hash then Array(json["result"] || json["panes"] || [])
          else []
          end
        end

        def dig_pane(json)
          return nil unless json.is_a?(Hash)

          result = json["result"]
          if result.is_a?(Hash)
            root = result["root_pane"]
            return root["pane_id"] || root["id"] if root.is_a?(Hash)
          end
          json["pane_id"] || json["pane"] || json["id"]
        end

        def dig_workspace(json)
          result = json.is_a?(Hash) ? json["result"] : nil
          source = result.is_a?(Hash) ? result : json
          return nil unless source.is_a?(Hash)

          source["workspace_id"] || source["workspaceId"] || source["workspace"]
        end

        def run_nav(argv, cwd)
          out, err, status = Open3.capture3(*argv, chdir: cwd)
          {"status" => status.success? ? "ok" : (status.exitstatus || "signal"),
           "out" => out, "err" => err}
        rescue Errno::ENOENT
          {"status" => "enoent", "out" => "", "err" => ""}
        rescue SystemCallError, IOError => e
          {"status" => "exec_failed", "out" => "", "err" => e.class.name}
        end
      end
    end
  end
end

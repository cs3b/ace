# frozen_string_literal: true

require_relative "../atoms/start_contract"
require_relative "../molecules/project_root_resolver"
require "ace/herdr"
require "ace/support/cli/toolchain"
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
        # The lab's own herdr space title. Namespaced ("lab-overseer",
        # never "overseer-…") so it can never collide with a session or
        # per-project space title derived from a directory name — e.g. a
        # project rooted at a directory literally named "lab" owns the
        # session/space title "overseer-lab".
        LAB_SPACE_TITLE = "lab-overseer"
        # `herdr agent start` success only means the interactive agent is
        # READY for input — the session begins its first turn when this
        # prompt arrives, exactly as the standing instructions' "First
        # turn after start" section describes (state read, /eyes arming).
        FIRST_TURN_PROMPT = <<~PROMPT.chomp
          Begin your first turn now. Follow the "First turn after start"
          section of your standing instructions: read your private
          _overseer tasks and the project state from its owners, continue
          existing commissioned work before choosing anything new, arm
          /eyes for standing observation, and remain idle when there is
          nothing to do.
        PROMPT

        attr_reader :cwd

        # @param config [Hash, nil] resolved overseer config (defaults
        #   to Ace::Overseer.config)
        # @param executor [HerdrExecutor, nil] herdr seam
        # @param root_resolver [ProjectRootResolver, nil]
        # @param nav_runner [Proc, nil] (argv, cwd) runner seam for
        #   resolving wfi:// instructions through ace-nav
        # @param workspace [String, nil] explicit herdr workspace id for
        #   the session; used verbatim by boot_session
        # @param workspace_factory [Proc, nil] label -> workspace id
        #   seam; the lab scope passes one so each project boots in its
        #   OWN space instead of the caller's ambient workspace. Called
        #   lazily, only when a session actually boots.
        # @param cwd [String] invocation directory
        def initialize(config: nil, executor: nil, root_resolver: nil, nav_runner: nil,
          workspace: nil, workspace_factory: nil, cwd: Dir.pwd)
          @config = config || Ace::Overseer.config
          @executor = executor || Ace::Herdr::Molecules::HerdrExecutor.new
          @root_resolver = root_resolver || Molecules::ProjectRootResolver.new
          @nav_runner = nav_runner || method(:run_nav)
          @workspace = workspace
          @workspace_factory = workspace_factory
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

          owner = owner_pane(label)
          if owner
            conflict = owner_conflict(owner, root)
            if conflict
              return report.merge("status" => "blocked", "pane" => owner["id"], "message" => conflict)
            end

            if agent_alive?(owner["id"])
              return report.merge("status" => "reused", "pane" => owner["id"],
                "workspace" => owner["workspace_id"] || owner["workspace"],
                "message" => "existing project overseer session reused; no second session created")
            end
            # a dead owner is replaced after observing the real state —
            # the new identity is reported, the old pane is left to the
            # operator's pane hygiene
            report["replaced_pane"] = owner["id"]
          end

          # resolved only once a session actually boots, so a merely
          # reused lab project never creates an empty space
          workspace = boot_workspace(label)
          report["workspace"] = workspace

          pane = boot_session(workspace, label, root, plan, instructions_path)
          prompt_warning = first_prompt(pane)
          report.merge("status" => "started", "pane" => pane,
            "prompt_failed" => !prompt_warning.nil?,
            "message" => prompt_warning ||
              "project overseer session started; the agent reads its " \
              "private tasks and project state and stays idle when there is no work")
        rescue Ace::Overseer::Error => e
          blocked(e.message)
        rescue Ace::Herdr::ExecutorError => e
          # herdr failures (pane list, agent probe, session boot) surface
          # as a blocked start report naming herdr — never an unhandled
          # exception out of `ace-overseer start`
          blocked("herdr failed while preparing the overseer session: #{e.message}")
        end

        private

        # --- lab scope (task 8xs.t.pu0.a) -----------------------------------
        # The lab root is its own coordination directory with its own
        # _overseer. The project list and canonical locations come from
        # the existing ace-lab topology configuration (topology.projects
        # id/path) — never from the sanitized public projection and
        # never derived from an id/label/repo name. The lab space hosts
        # ONLY the lab overseer session; EACH project boots in its OWN
        # herdr space (created/reused by the project's session label),
        # so project sessions are isolated from each other and from the
        # lab overseer. Each project starts through the SAME operation
        # as a standalone start (its own cascade, its own session
        # identity); an unhealthy project is reported per-project while
        # healthy projects continue; a repeated start repairs only what
        # is missing and never restarts healthy sessions or closes
        # manual panes.
        def lab_start(plan, dry_run)
          lab_root = File.realpath(@cwd)
          base = {"status" => nil, "scope" => "lab", "root" => lab_root,
            "label" => Atoms::StartContract.session_label(lab_root),
            "workspace" => nil, "pane" => nil, "agent" => AGENT_NAME,
            "profile" => plan["profile_name"],
            "instructions" => {"source" => plan["instructions"], "path" => nil},
            "replaced_pane" => nil, "projects" => [], "project_count" => 0,
            "ready" => nil, "message" => nil}
          base["instructions"]["path"] = resolve_instructions(plan["instructions"], lab_root)

          projects = begin
            Ace::Lab::Molecules::ProjectLocations.read(lab_root)
          rescue Ace::Lab::InvalidConfigurationError => e
            return base.merge("status" => "blocked",
              "message" => "lab topology could not be read: #{e.message}")
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
            "message" => "dry-run: the lab space with the lab overseer session and " \
              "#{projects.size} project space(s)/overseer(s) would start; nothing was created") if dry_run

          workspace = lab_workspace
          base["workspace"] = workspace

          # The lab's OWN overseer session (the wfi://overseer/lab-start
          # guide assumes it): booted or reused in the lab space before
          # any project, so the lab-start instructions reach an agent.
          session = boot_lab_session(workspace, plan, base["instructions"]["path"], lab_root)
          return base.merge("status" => "blocked", "pane" => session["pane"],
            "message" => session["message"]) if session["status"] == "blocked"

          base["pane"] = session["pane"]
          base["replaced_pane"] = session["replaced_pane"]
          base["prompt_failed"] = session["prompt_failed"] if session["prompt_failed"]

          # An empty configured list is a valid idle lab: the lab
          # overseer itself still runs.
          if projects.empty?
            message = "no projects configured; the lab overseer is idle"
            message += "; #{session["message"]}" if session["message"]
            return base.merge("status" => "ready", "ready" => true, "project_count" => 0,
              "message" => message)
          end

          results = projects.map { |project| start_project(project, lab_root) }
          ready = results.all? { |result| %w[started reused].include?(result["status"]) }
          summary = "#{results.count { |r| %w[started reused].include?(r["status"]) }}/" \
            "#{results.size} project overseers ready"
          summary += "; #{session["message"]}" if session["message"]
          base.merge("status" => ready ? "ready" : "partial", "ready" => ready,
            "projects" => results, "project_count" => results.size,
            "message" => summary)
        rescue Ace::Overseer::Error, Ace::Herdr::ExecutorError => e
          # A lab-level failure keeps the lab context (scope/root/label)
          # so callers can tell it from a per-project blocked result.
          base.merge("status" => "blocked", "message" => "lab start failed: #{e.message}")
        end

        # The lab's own herdr space, created once and reused by title.
        # The title is namespaced (see LAB_SPACE_TITLE) so it can never
        # collide with a session/space title derived from a project
        # directory name (e.g. a project rooted at a directory literally
        # named "lab" owns "overseer-lab").
        def lab_workspace
          find_or_create_workspace(LAB_SPACE_TITLE)
        end

        # A herdr space by title, created when absent: the lab space
        # ("overseer-lab") and each project's OWN space (titled by the
        # project's session label, so a repeated lab start converges on
        # the same space). herdr spaces are flat (tmux-session
        # analogue, no parent/child nesting) — the lab context owns
        # them by creating/reusing them from this one start flow.
        def find_or_create_workspace(title)
          found = find_workspace(title)
          return found if found

          created = @executor.workspace_create(label: title).parsed_json
          dig_workspace(created)
        rescue Ace::Herdr::ExecutorUnavailableError => e
          raise Ace::Overseer::Error, "herdr is unavailable: #{e.message}"
        end

        # An existing herdr space by title, or nil — never creates. A
        # titled entry without an id is REUSED (its title is the
        # workspace reference), never treated as absent: creating a
        # second space with the same title would duplicate the space.
        def find_workspace(title)
          existing = @executor.workspace_list.parsed_json
          list = existing.is_a?(Hash) ? Array(existing["result"] || existing["workspaces"]) : Array(existing)
          found = list.find { |entry| entry["title"] == title || entry["label"] == title }
          return nil unless found

          found["id"] || found["workspace_id"] || found["title"] || found["label"]
        rescue Ace::Herdr::ExecutorUnavailableError => e
          raise Ace::Overseer::Error, "herdr is unavailable: #{e.message}"
        end

        # The lab's own session through the SAME identity rules as a
        # project session (label from the lab root, cwd at the lab
        # root, live owner reused, dead owner replaced). The lab root
        # is a coordination directory, not a repository, so a live
        # owner is matched by its cwd directly — never through
        # project-root resolution.
        def boot_lab_session(workspace, plan, instructions_path, lab_root)
          label = Atoms::StartContract.session_label(lab_root)
          owner = owner_pane(label)
          replaced = nil
          if owner
            owner_cwd = owner["cwd"].to_s
            matching = !owner_cwd.empty? &&
              (File.realpath(owner_cwd) == lab_root rescue false)
            unless matching
              return {"status" => "blocked", "pane" => nil, "replaced_pane" => nil,
                "message" => "owner pane '#{owner["id"]}' works in '#{owner_cwd}', which is " \
                  "not the lab root '#{lab_root}'; refusing to take over a foreign session"}
            end
            return {"status" => "reused", "pane" => owner["id"], "replaced_pane" => nil,
              "prompt_failed" => false} if agent_alive?(owner["id"])

            replaced = owner["id"]
          end

          pane = boot_session(workspace, label, lab_root, plan, instructions_path)
          prompt_warning = first_prompt(pane)
          {"status" => "started", "pane" => pane, "replaced_pane" => replaced,
            "prompt_failed" => !prompt_warning.nil?, "message" => prompt_warning}
        rescue Ace::Overseer::Error => e
          {"status" => "blocked", "pane" => nil, "replaced_pane" => nil, "message" => e.message}
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
          # a project cascade that itself declares scope lab would
          # recurse (a nested lab start) — refused, never executed
          if project_config.is_a?(Hash) && project_config.dig("start", "scope") == "lab"
            return {"id" => id, "path" => path, "status" => "blocked",
              "message" => "project '#{id}' declares scope lab in its own " \
                ".ace/overseer/config.yml; nested lab scopes are refused"}
          end

          orchestrator = self.class.new(config: project_config, executor: @executor,
            root_resolver: @root_resolver, nav_runner: @nav_runner,
            workspace_factory: ->(label) { find_or_create_workspace(label) }, cwd: path)
          report = orchestrator.call
          # a reused session keeps its reported space: the lab-managed
          # space titled by the project's session label, when it exists
          report["workspace"] ||= find_workspace(report["label"])
          report.merge("id" => id, "path" => path)
        rescue Ace::Overseer::Error, Ace::Herdr::ExecutorError => e
          {"id" => id, "path" => path, "status" => "blocked", "message" => e.message}
        end

        def base_report(plan, root, label, instructions_path)
          {"status" => nil, "scope" => plan["scope"], "root" => root, "label" => label,
           "workspace" => nil, "pane" => nil, "agent" => AGENT_NAME,
           "profile" => plan["profile_name"], "instructions" =>
             {"source" => plan["instructions"], "path" => instructions_path},
           "replaced_pane" => nil, "prompt_failed" => false, "message" => nil}
        end

        def blocked(message)
          {"status" => "blocked", "scope" => nil, "root" => nil, "label" => nil,
           "workspace" => nil, "pane" => nil, "agent" => AGENT_NAME, "profile" => nil,
           "instructions" => nil, "replaced_pane" => nil, "prompt_failed" => false,
           "message" => message}
        end

        # wfi:// (and sibling protocol) sources resolve through the
        # project's own ace-nav; an absolute path is used verbatim. The
        # resolved file is the harness's standing-instruction source.
        # The executable comes from the repo toolchain policy
        # (Ace::Support::Cli::Toolchain): auto mode prefers the
        # project's bin/ binstub and falls back to PATH; installed mode
        # (ACE_TOOLCHAIN=installed) ALWAYS uses the installed gem
        # launcher — a checkout inside the project is data, never the
        # runtime source.
        def resolve_instructions(source, root)
          return source unless source.include?("://")

          binary = begin
            Ace::Support::Cli::Toolchain.executable("ace-nav", project_root: root,
              prefer_project: !Process.uid.zero?)
          rescue Ace::Support::Cli::Toolchain::Error => e
            raise Ace::Overseer::Error,
              "cannot resolve the ace-nav executable for the start instructions: #{e.message}"
          end
          result = @nav_runner.call([binary, "resolve", source], root)
          path = result["status"] == "ok" ? result["out"].to_s.lines.first.to_s.strip : nil
          if path.nil? || path.empty?
            raise Ace::Overseer::Error,
              "start instructions '#{source}' do not resolve through ace-nav " \
                "for project '#{File.basename(root)}'"
          end

          path
        end

        # The herdr space a NEW session boots in: the explicit id seam,
        # the lab-managed factory (each project's OWN space, titled by
        # its session label), or the caller's ambient resolution.
        def boot_workspace(label)
          return @workspace if @workspace
          return @workspace_factory.call(label) if @workspace_factory

          resolve_workspace
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
        # instructions (passthrough args). Ends at the started agent —
        # the first prompt is a SEPARATE step (first_prompt) so a
        # delivery failure never reports a live agent as not started.
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

        # `agent start` success only means the interactive agent is
        # ready for input; the first prompt begins the session's first
        # turn (state read, /eyes arming). A prompt failure AFTER a
        # started agent is a repairable warning (the agent is live and
        # idle), returned as a message — never raised as a failed start.
        def first_prompt(pane)
          @executor.agent_prompt(pane: pane, text: FIRST_TURN_PROMPT)
          nil
        rescue Ace::Herdr::ExecutorError => e
          "the agent is started and idle, but the first prompt failed " \
            "(#{e.message}); re-send it to begin the first turn"
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

        # Exactly the canonical workspace keys ace-herdr itself digs
        # (workspace_id/workspaceId, as in HerdrExecutor consumers like
        # Dispatcher/ControlSurface) — no broader key guessing.
        def dig_workspace(json)
          result = json.is_a?(Hash) ? json["result"] : nil
          source = result.is_a?(Hash) ? result : json
          return nil unless source.is_a?(Hash)

          source["workspace_id"] || source["workspaceId"]
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

# frozen_string_literal: true

require_relative "../atoms/start_contract"
require_relative "../molecules/project_root_resolver"
require_relative "../molecules/project_bundle"
require "ace/herdr"
require "ace/support/cli/toolchain"
require "json"

module Ace
  module Overseer
    module Organisms
      # `ace-overseer start` boots the Lab in the calling Herdr terminal,
      # or starts/reuses configured project sessions. Missing start config
      # uses the packaged bootstrap profile so the coordinator can configure
      # itself. Explicit malformed configuration remains a blocked start.
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
        # Bounds the --wait activity gate on the first-turn prompt: the
        # turn must BEGIN within this window (herdr enforces its own
        # 5s activity observation inside the wait).
        FIRST_TURN_TIMEOUT_MS = 120_000
        # Workspace display names are separate from session identities.
        # `overseer` belongs to the Lab; project spaces use topology ids.
        LAB_SPACE_TITLE = "overseer"
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
          workspace: nil, workspace_factory: nil, cwd: Dir.pwd, env: ENV, scope: nil, project_runner: nil)
          @config = config || Ace::Overseer.config
          @executor = executor || Ace::Herdr::Molecules::HerdrExecutor.new
          @control_surface = Ace::Herdr::Organisms::ControlSurface.new(executor: @executor)
          @root_resolver = root_resolver || Molecules::ProjectRootResolver.new
          @nav_runner = nav_runner || method(:run_nav)
          @workspace = workspace
          @workspace_factory = workspace_factory
          @cwd = cwd
          @env = env
          @scope = scope
          @project_runner = project_runner || Molecules::ProjectBundle.new
        end

        # @param dry_run [Boolean] report the plan without creating a
        #   session, syncing, or invoking any model
        # @return [Hash] {status: started|reused|blocked|dry_run, scope,
        #   root, label, workspace, pane, agent, profile, instructions,
        #   replaced_pane, message}; scope lab additionally carries
        #   {projects: [{id, path, status, ...}], project_count, ready}
        def call(dry_run: false)
          plan = Atoms::StartContract.normalize(Atoms::StartContract.bootstrap(@config, scope: @scope || "lab"))
          if @scope && plan["scope"] != @scope
            raise Ace::Overseer::Error, "configured start scope '#{plan["scope"]}' conflicts with requested '#{@scope}'; nested lab scopes are refused"
          end
          if plan["scope"] == "lab"
            foreground = foreground_start(plan, dry_run)
            return foreground if foreground
            return lab_start(plan, dry_run)
          end

          root = @root_resolver.resolve(cwd: @cwd)
          label = Atoms::StartContract.session_label(root)
          instructions_path = resolve_instructions(plan["instructions"], root)

          report = base_report(plan, root, label, instructions_path)
          if dry_run
            return report.merge("status" => "dry_run",
              "message" => "dry-run: session would start with this plan; nothing was created")
          end

          owner = owner_pane(label)
          if owner
            conflict = owner_conflict(owner, root)
            if conflict
              return report.merge("status" => "blocked", "pane" => owner["id"], "message" => conflict)
            end

            state = agent_state(owner["id"])
            if state
              # a live agent is a PROCESS, not necessarily a completed
              # start — the missing first-turn initialization is
              # repaired through the existing session (see
              # repair_reused_initialization)
              warning = repair_reused_initialization(owner["id"], state)
              return report.merge("status" => "reused", "pane" => owner["id"],
                "workspace" => owner["workspace_id"] || owner["workspace"],
                "prompt_failed" => !warning.nil?,
                "message" => warning ||
                  "existing project overseer session reused; no second session created")
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

        # The command entered in an existing Herdr terminal becomes the
        # coordinator in that terminal. Sending `agent start` to our own
        # busy terminal would wait on the CLI itself; the CLI execs this
        # argv instead. Calls made by an existing agent only reconcile.
        def foreground_start(plan, dry_run)
          pane_id = @env["HERDR_PANE"].to_s
          return nil if pane_id.empty? || agent_state(pane_id)

          pane = @control_surface.list_panes.find { |entry| entry[:id] == pane_id }
          unless pane && !pane[:cwd].to_s.empty? &&
              File.realpath(pane[:cwd]) == File.realpath(@cwd)
            raise Ace::Overseer::Error, "the calling Herdr pane does not belong to the lab directory"
          end
          unless plan["profile"]["harness"] == "pi"
            raise Ace::Overseer::Error, "foreground lab start requires the configured pi harness"
          end

          root = File.realpath(@cwd)
          label = Atoms::StartContract.session_label(root)
          owner = owner_pane(label)
          return nil if owner && owner["id"] != pane_id

          guide = resolve_instructions(plan["instructions"], root)
          command = ["pi", "--model", plan["profile"]["model"]]
          thinking = plan["profile"]["thinking"]
          command += ["--thinking", thinking] if thinking
          command += ["--append-system-prompt", guide, FIRST_TURN_PROMPT]
          @executor.pane_rename(pane_id, label) unless dry_run
          {"status" => dry_run ? "dry_run" : "foreground", "scope" => "lab",
           "root" => root, "label" => label, "workspace" => pane[:workspace],
           "pane" => pane_id, "agent" => AGENT_NAME, "profile" => plan["profile_name"],
           "instructions" => {"source" => plan["instructions"], "path" => guide},
           "command" => command, "message" => "start the lab coordinator in the calling terminal"}
        end

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

          if projects.any? { |project|
            project["path"].to_s.empty? == false &&
                File.directory?(project["path"]) && File.realpath(project["path"]) == lab_root
          }
            return base.merge("status" => "blocked",
              "message" => "the lab root '#{lab_root}' is itself declared as a project; " \
                "conflicting lab/project roles are refused")
          end

          if dry_run
            return base.merge("status" => "dry_run", "project_count" => projects.size,
              "projects" => projects.map { |project|
                {"id" => project["id"], "path" => project["path"],
                 "status" => "would_start"}
              },
              "message" => "dry-run: the lab space with the lab overseer session and " \
                "#{projects.size} project space(s)/overseer(s) would start; nothing was created")
          end

          workspace = lab_workspace
          base["workspace"] = workspace

          # The lab's OWN overseer session (the wfi://overseer/lab-start
          # guide assumes it): booted or reused in the lab space before
          # any project, so the lab-start instructions reach an agent.
          session = boot_lab_session(workspace, plan, base["instructions"]["path"], lab_root)
          if session["status"] == "blocked"
            return base.merge("status" => "blocked", "pane" => session["pane"],
              "message" => session["message"])
          end

          base["pane"] = session["pane"]
          base["replaced_pane"] = session["replaced_pane"]
          base["prompt_failed"] = !session["prompt_failed"].nil? && session["prompt_failed"]

          # Readiness REQUIRES a confirmed first turn (review R7): a
          # started/reused session whose first-turn delivery failed or
          # stays unconfirmed is NOT ready, whatever its process state.
          lab_ready = !session["prompt_failed"]

          # An empty configured list is a valid idle lab: the lab
          # overseer itself still runs (and must be initialized).
          if projects.empty?
            message = "no projects configured; the lab overseer is idle"
            message += "; #{session["message"]}" if session["message"]
            return base.merge("status" => lab_ready ? "ready" : "partial",
              "ready" => lab_ready, "project_count" => 0, "message" => message)
          end

          results = projects.map { |project| start_project(project, lab_root) }
          healthy = ->(result) { %w[started reused].include?(result["status"]) && !result["prompt_failed"] }
          ready = lab_ready && results.all?(&healthy)
          summary = "#{results.count(&healthy)}/#{results.size} project overseers ready"
          summary += "; lab overseer: #{session["message"]}" if session["message"]
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
          found = @control_surface.list_workspaces.find { |entry| entry[:title] == title }
          return nil unless found

          found[:id] || found[:title]
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
              begin
                File.realpath(owner_cwd) == lab_root
              rescue
                false
              end
            unless matching
              return {"status" => "blocked", "pane" => nil, "replaced_pane" => nil,
                      "message" => "owner pane '#{owner["id"]}' works in '#{owner_cwd}', which is " \
                  "not the lab root '#{lab_root}'; refusing to take over a foreign session"}
            end
            state = agent_state(owner["id"])
            if state
              warning = repair_reused_initialization(owner["id"], state)
              return {"status" => "reused", "pane" => owner["id"], "replaced_pane" => nil,
                      "prompt_failed" => !warning.nil?, "message" => warning}
            end

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

          if id == LAB_SPACE_TITLE
            return {"id" => id, "path" => path, "status" => "blocked",
                    "message" => "project id '#{id}' is reserved for the lab workspace"}
          end
          root = @root_resolver.resolve(cwd: path)
          label = Atoms::StartContract.session_label(root)
          owner = owner_pane(label)
          workspace = if owner && agent_state(owner["id"])
            owner["workspace"] || owner["workspace_id"]
          else
            find_or_create_workspace(id)
          end
          report = @project_runner.call(root: root, workspace: workspace, env: @env)

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
          path = (result["status"] == "ok") ? result["out"].to_s.lines.first.to_s.strip : nil
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
          pane = @control_surface.list_panes.find { |entry| entry[:title] == label }
          pane&.transform_keys(&:to_s)
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

        # Live agent classification from the existing herdr session
        # state: returns the agent_status string ("idle", "working",
        # "blocked", "done", "unknown", or "" when the payload carries
        # no recognizable status), or nil when NO agent lives in the
        # pane (AgentNotFoundError). This is the "live process" half of
        # the live-vs-completed-start distinction; delivery
        # confirmation comes from first_prompt's activity gate.
        def agent_state(pane)
          json = @executor.agent_get(pane).parsed_json
          return nil unless json.is_a?(Hash)

          agent = json["agent"]
          agent = json["result"]["agent"] if agent.nil? && json["result"].is_a?(Hash)
          agent = json["result"] if agent.nil? && json["result"].is_a?(Hash)
          return "" unless agent.is_a?(Hash)

          agent["agent_status"].to_s
        rescue Ace::Herdr::AgentNotFoundError
          nil
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

          @executor.pane_run(pane, Molecules::ProjectBundle.shell_setup(root, env: @env))
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
        # turn (state read, /eyes arming). Delivery is CONFIRMED through
        # herdr's activity gate (`agent prompt --wait`): success means
        # herdr observed working/blocked activity, so the turn actually
        # began — a stall, timeout or pre-send failure is an uncertain
        # outcome, returned as a visible warning instead of a readiness
        # claim. Never raised: the agent itself is live and idle.
        def first_prompt(pane)
          @executor.agent_prompt(pane: pane, text: FIRST_TURN_PROMPT,
            wait: true, timeout_ms: FIRST_TURN_TIMEOUT_MS)
          nil
        rescue Ace::Herdr::ExecutorError => e
          "the agent is started and idle, but its first turn could not be " \
            "confirmed delivered (#{e.message}); re-run start to repair the " \
              "missing initialization"
        end

        # A REUSED live agent proves a process, not a completed start.
        # Classification through the existing herdr session state (no
        # parallel store): working/blocked = mid-conversation, the first
        # turn is already underway — never interrupted; idle/done =
        # ready for input — the first-turn prompt is (re-)delivered
        # through the existing session with the activity gate, which
        # repairs a missing initialization without restarting anything
        # (a healthy agent simply reconciles once and settles); any
        # other state is visibly unconfirmed, never a readiness claim.
        def repair_reused_initialization(pane, state)
          case state
          when "working", "blocked"
            nil
          when "idle", "done"
            first_prompt(pane)
          else
            "the reused agent state is '#{state}'; its first turn could not " \
              "be verified — inspect the session before relying on it"
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

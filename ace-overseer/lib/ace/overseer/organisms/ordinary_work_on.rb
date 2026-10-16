# frozen_string_literal: true

require "shellwords"
require "ace/lab/organisms/ordinary_assignment_client"
require "ace/lab/molecules/ordinary_worktree_read"
require "ace/assign/organisms/ordinary_driver"
require "ace/assign/molecules/runtime_control_surface_runner"
require "ace/llm"

module Ace
  module Overseer
    module Organisms
      # Ordinary entry: existing worktree/native launch mechanisms, immutable
      # request inputs, and canonical Assign observations. No local execution.
      class OrdinaryWorkOn
        Files = Ace::Assign::Authority::RetainedInput

        def initialize(config: nil, runtime: nil, provisioner: nil, windows: nil, builder: nil, client: nil, prepare: nil, observer: nil)
          @config, @runtime = config, runtime
          @provisioner = provisioner
          @windows = windows
          @builder = builder
          @client = client
          @prepare = prepare || Ace::Lab::Organisms::OrdinaryAssignmentClient.method(:prepare)
          @observer = observer
        end

        def prepare(project:, task:, checkout:, output:, provider:)
          config = selected(project)
          caller = supervisor!(config)
          checkout = File.realpath(checkout)
          # The native coordinator can live in a different project. Explicit
          # preparation cwd must resolve to this installed common directory.
          source_reader = @observer || Ace::Lab::Molecules::OrdinaryWorktreeRead.new(root: checkout,
            common_dir: config.worktrees.fetch("common_dir"), deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
          source_reader.observe(checkout)
          directory = Files.create_output(output)
          worktree = in_worktree(checkout) do
            provisioner = @provisioner || Molecules::WorktreeProvisioner.new(
              manager: Ace::Git::Worktree::Organisms::WorktreeManager.new(project_root: checkout))
            provisioner.provision(task).fetch(:worktree_path)
          end
          cwd = validate_worktree!(config, worktree)
          # Resolve actual provider arguments before creating any pane/agent.
          prepared = in_worktree(cwd) do
            (@builder || Ace::LLM::Molecules::InteractiveCommandBuilder.new).build(
              provider_model: provider, prompt: "ordinary preparation", working_dir: cwd)
            @prepare.call(project: project, task: task, pane: caller.fetch(:pane), output: File.join(directory, "prepared"))
          end
          window = (@windows || Molecules::WindowOpener.new(runtime: runtime)).open(worktree_path: cwd)
          pane = runtime.prepare_pane(window: window)
          context = {"version" => 1, "project_id" => project, "assignment_id" => prepared.fetch("assignment_id"),
            "attempt_id" => SecureRandom.hex(16), "scope" => prepared.fetch("scope"), "pane" => pane,
            "supervisor_pane" => caller.fetch(:pane), "cwd" => cwd,
            "head" => observe(config, cwd).fetch("head"), "provider" => provider}
          Files.write_file(directory, "context.json", JSON.generate(context) + "\n")
          Files.write_file(directory, "result-hint.json", JSON.generate({"hint_only" => true}))
          registration = client(project).request(input: prepared.fetch("request"))
          unless registration.dig("data", "assignment_id") == prepared.fetch("assignment_id") &&
              registration.dig("data", "project_id") == project
            raise Error, "ordinary registration returned a different project or assignment; recover #{directory}/context.json"
          end
          describe(File.join(directory, "context.json"), context).merge("state" => "ready_not_dispatched", "window" => window)
        end

        def launch(project:, context:)
          driver = driver(project, context)
          selected_context = driver.context
          config = selected(project)
          caller = supervisor!(config)
          supervisor = driver.supervisor
          unless runtime.process_binding(pane: caller.fetch(:pane), caller_pid: Process.pid) == supervisor.fetch("binding")
            raise Error, "ordinary launch belongs to the canonical native supervisor; adopt explicitly after its previous generation ends"
          end
          cwd = validate_worktree!(config, selected_context.fetch("cwd"))
          directory = File.dirname(driver.path)
          # Canonical supervisor lookup also proves registration. Recovery does
          # not register again or reconstruct work from a local assignment cache.
          observed = driver.status
          return describe(driver.path, selected_context).merge("canonical" => observed) unless observed.fetch("state") == "not_started"
          unless observe(config, cwd).fetch("head") == selected_context.fetch("head")
            raise Error, "ordinary launch checkout moved; preserve original context and reconcile before dispatch"
          end
          invocation = in_worktree(cwd) do
            (@builder || Ace::LLM::Molecules::InteractiveCommandBuilder.new).build(provider_model: selected_context.fetch("provider"),
              prompt: "/as-assign-drive --ordinary #{driver.path.shellescape}", working_dir: cwd,
              subprocess_env: {"ACE_ASSIGN_ORDINARY_CONTEXT" => driver.path,
                "ACE_ASSIGN_ORDINARY_PROJECT" => project, "ACE_RUNTIME" => "herdr"})
          end
          # Create before native send. A lost send/reply cannot cause another
          # invocation. Resume only observes; it never deletes this intent.
          intent = {"pane" => selected_context.fetch("pane"), "assignment_id" => selected_context.fetch("assignment_id"),
            "attempt_id" => selected_context.fetch("attempt_id"), "provider" => invocation.fetch(:provider),
            "model" => invocation.fetch(:model), "thinking_level" => invocation[:thinking_level],
            "command_sha256" => Digest::SHA256.hexdigest(invocation.fetch(:command).to_json)}
          begin
            Files.write_file(directory, "dispatch.json", JSON.generate(intent) + "\n")
          rescue Errno::EEXIST
            return describe(driver.path, selected_context).merge("state" => "dispatch_uncertain", "canonical" => observed,
              "remediation" => "Inspect the original pane and canonical status; never launch a replacement from this context")
          end
          runner = Ace::Assign::Molecules::RuntimeControlSurfaceRunner.new(runtime: "herdr", adapter: runtime)
          runner.run_invocation_in_pane(pane_target: selected_context.fetch("pane"), command: invocation.fetch(:command),
            env: invocation[:env], working_dir: invocation.fetch(:working_dir), visible_handoff: invocation[:prompt])
          describe(driver.path, selected_context).merge("state" => "accepted_not_started", "canonical" => driver.status)
        end

        # Restart/recovery is an observation of original IDs, never redispatch.
        def resume(project:, context:)
          driver = driver(project, context)
          describe(driver.path, driver.context).merge("canonical" => driver.status,
            "supervisor" => driver.supervisor,
            "dispatch_intent" => File.file?(File.join(File.dirname(driver.path), "dispatch.json")))
        end

        private

        def selected(project)
          config = @config || Ace::Lab::Molecules::OrdinaryOwnerConfig.load(project: project)
          raise Error, "ordinary project selection differs" unless config.project == project
          config.verify_owner!
          config
        end

        def client(project)
          @client || Ace::Lab::Organisms::OrdinaryAssignmentClient.new(project: project)
        end

        def driver(project, context)
          Ace::Assign::Organisms::OrdinaryDriver.new(path: context, project: project, transport: client(project))
        end

        def runtime
          @runtime ||= Ace::Herdr::Organisms::RuntimeAdapter.new
        end

        def supervisor!(config)
          participant = config.selected_principal!(Process.uid)
          caller = runtime.context
          unless caller[:in_runtime] && caller[:session] == participant.fetch("workspace") &&
              participant.fetch("supervisor_panes").include?(caller[:pane])
            raise Error, "ordinary preparation and launch require the selected native supervisor"
          end
          caller
        end

        def validate_worktree!(config, path)
          actual = File.realpath(path)
          root = File.realpath(config.worktrees.fetch("root"))
          raise Error, "ordinary worktree is outside installed project selection" unless actual.start_with?(root + "/")
          actual
        end

        def observe(config, cwd)
          reader = @observer || Ace::Lab::Molecules::OrdinaryWorktreeRead.new(root: config.worktrees.fetch("root"),
            common_dir: config.worktrees.fetch("common_dir"), deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
          reader.observe(cwd)
        end

        def in_worktree(path)
          previous = ENV["PROJECT_ROOT_PATH"]
          Dir.chdir(path) do
            ENV["PROJECT_ROOT_PATH"] = path
            Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
            Ace::Assign.reset_config!
            Ace::LLM.reset_configuration!
            yield
          end
        ensure
          ENV["PROJECT_ROOT_PATH"] = previous
          Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!
          Ace::Assign.reset_config!
          Ace::LLM.reset_configuration!
        end

        def describe(path, context)
          read = "ace-lab assignment drive --project #{context.fetch('project_id').shellescape} --context #{path.shellescape} --operation status"
          {"context" => path, **context.slice("project_id", "assignment_id", "attempt_id", "scope", "pane", "supervisor_pane", "cwd", "provider"),
            "watch_command" => "/watch add ordinary-#{context.fetch('attempt_id')} --path #{File.join(File.dirname(path), 'result-hint.json').to_json} " \
              "--message #{("Ordinary result hint only. Run #{read}; adopt only its exact canonical submitted result. Preserve original IDs on uncertainty.").to_json}",
            "status_command" => read}
        end
      end
    end
  end
end

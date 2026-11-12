# frozen_string_literal: true

require "shellwords"
require "ace/coworker/molecules/execution_binding"
require "ace/herdr"
require "ace/herdr/atoms/native_agent_session"
require_relative "session_environment"
require_relative "eyes_readiness"

module Ace::Overseer::Molecules
  # Start and retire a real executor using the existing commission document.
  # A recorded uncertain start is a blocker, never permission to duplicate it.
  class CoworkerLauncher
    def initialize(executor: Ace::Herdr::Molecules::HerdrExecutor.new, env: ENV,
      environment: nil, bindings: Ace::Coworker::Molecules::ExecutionBinding.new,
      brief_factory: nil, readiness: nil, eyes: nil, root_resolver: nil,
      identity_timeout: 10, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) }, sleeper: ->(seconds) { sleep(seconds) })
      @identity_timeout, @clock, @sleeper = identity_timeout, clock, sleeper
      @executor, @env, @bindings = executor, env, bindings
      @environment = environment || SessionEnvironment.new(env: env)
      @brief_factory = brief_factory || ->(root, path) { Ace::Coworker::Organisms::StartOrchestrator.new(project_root: root).call(config_path: path) }
      @readiness = readiness || method(:check_eyes!)
      @eyes = eyes || EyesReadiness.new
      @root_resolver = root_resolver || ProjectRootResolver.new
    end

    def ready!
      @readiness.call
    end

    def recipient
      context = coordinator_context
      path = File.join(context.fetch(:root), ".ace-local/overseer/eyes.json")
      data = JSON.parse(File.read(path))
      value = data.is_a?(Hash) && data["recipient"]
      unless value.is_a?(String) && !value.strip.empty? && !value.match?(/[[:space:][:cntrl:]]/)
        raise Ace::Overseer::Error, "coordinator eyes recipient is unavailable"
      end
      value
    rescue JSON::ParserError, SystemCallError
      raise Ace::Overseer::Error, "coordinator eyes recipient is unavailable"
    end

    def call(worktree_path:, config_path:)
      ready!
      path = File.expand_path(config_path, worktree_path)
      brief = @brief_factory.call(worktree_path, path)
      @bindings.with_lock(path) do |document, save|
        unless document["assignment"] == brief.config.assignment && document["role"] == brief.config.role &&
            document["task"] == brief.config.task
          raise Ace::Overseer::Error, "executor commission changed during validation"
        end
        if document["execution"]
          execution = document.fetch("execution")
          if %w[resuming resumed].include?(execution["state"])
            next finish_resume(execution, brief, worktree_path, save)
          end
          if %w[launching started].include?(execution["state"])
            unless %w[paused empty].include?(brief.assignment_snapshot&.state.to_s)
              raise Ace::Overseer::Error, "unconfirmed executor already has assignment activity"
            end
            recover_unprompted(execution, worktree_path, save)
            next submit_prompt(execution, brief, save)
          end
          next reuse(execution, brief, worktree_path, save)
        end
        unless %w[paused empty].include?(brief.assignment_snapshot&.state.to_s)
          raise Ace::Overseer::Error, "unbound assignment is not ready for a new executor"
        end
        Dir.glob(File.join(File.dirname(path), "*.yml")).each do |other_path|
          next if other_path == path
          other = YAML.safe_load_file(other_path, permitted_classes: [Date, Time], aliases: false)
          if other.is_a?(Hash) && other.key?("execution") &&
              (!other["execution"].is_a?(Hash) || other.dig("execution", "state") != "retired")
            raise Ace::Overseer::Error, "another executor has not been retired from this worktree"
          end
        end
        name = "coworker-#{brief.config.assignment}"
        execution = {"agent" => name, "assignment" => brief.config.assignment,
          "role" => brief.config.role, "state" => "launching"}
        @environment.with_environment(root: worktree_path, role: brief.config.role) do |file, directory, profile_args|
          document["execution"] = execution
          execution["credentials_directory"] = directory if directory
          save.call
          dispatcher = Ace::Herdr::Organisms::Dispatcher.from_config(executor: @executor)
          result = dispatcher.dispatch(label: name, prompt: "", kind: "pi", cwd: worktree_path,
            env_file: file, args: Array(profile_args) + ["--append-system-prompt", brief.instructions_source])
          execution.merge!(result.to_h).merge!("state" => "started")
          save.call # Preserve the native receipt before asynchronous session publication.
          pane = pane_identity(execution.fetch("pane"))
          execution["terminal_id"] = pane.fetch("terminal_id")
          save.call
          execution["agent_session"] = await_session(execution)
          save.call
        end
        submit_prompt(execution, brief, save)
      end
    rescue Ace::Coworker::Error, Ace::Herdr::ExecutorError => e
      raise Ace::Overseer::Error, "executor launch blocked: #{e.message}"
    end

    def retire(worktree_path:, assignment:)
      paths = Dir.glob(File.join(worktree_path, Ace::Coworker::Organisms::StartConfigWriter::PREPARE_DIR, "*.yml"))
      paths.each do |path|
        @bindings.with_lock(path) do |document, save|
          next unless document["assignment"] == assignment
          execution = document["execution"]
          next unless execution
          next if execution["state"] == "retired"
          begin
            pane = pane_identity(execution.fetch("pane"))
            unless same_executor?(pane, execution)
              raise Ace::Overseer::Error, "executor terminal changed; retirement refused"
            end
            execution["state"] = "retiring"
            save.call
            @executor.pane_close(execution.fetch("pane"))
          rescue Ace::Herdr::PaneNotFoundError
            # The native owner positively confirms that this panel is gone.
          end
          SessionEnvironment.cleanup(execution["credentials_directory"])
          execution.delete("credentials_directory")
          execution["state"] = "retired"
          save.call
        end
      end
    end

    private

    def submit_prompt(execution, brief, save)
      # A crash after input reaches Pi must never repeat the commission.
      execution["state"] = "prompting"
      save.call
      prompt = "#{brief.config.start_prompt}\n\n#{Ace::Coworker::Atoms::BriefFormatter.format_table(brief)}"
      @executor.agent_prompt(pane: execution.fetch("pane"), text: prompt)
      execution["state"] = "running"
      save.call
      execution.reject { |key, _| key == "credentials_directory" }.merge("reused" => false)
    end

    def await_session(execution)
      deadline = @clock.call + @identity_timeout
      loop do
        pane = pane_identity(execution.fetch("pane"))
        unless pane["terminal_id"] == execution.fetch("terminal_id")
          raise Ace::Overseer::Error, "executor terminal changed before session publication"
        end
        identity = Ace::Herdr::Atoms::NativeAgentSession.normalize(pane["agent_session"], agent: "pi")
        if identity
          raw = pane["agent_session"]
          execution["session_path"] = raw["value"] if raw.is_a?(Hash) && raw["kind"] == "path"
          return identity
        end
        raise Ace::Overseer::Error, "native executor session identity is unavailable; retry the same handoff" if @clock.call >= deadline
        @sleeper.call(0.2)
      end
    end

    def recover_unprompted(execution, worktree_path, save)
      row = @executor.agent_get(execution["pane"] || execution.fetch("agent")).parsed_json&.dig("result", "agent")
      unless row.is_a?(Hash) && row["name"] == execution["agent"] &&
          row["cwd"] == worktree_path && row["agent_status"] == "idle" &&
          row["interactive_ready"] == true && row["pane_id"] && row["terminal_id"]
        raise Ace::Overseer::Error, "unconfirmed launch is not the expected idle executor"
      end
      if execution["terminal_id"] && execution["terminal_id"] != row["terminal_id"]
        raise Ace::Overseer::Error, "executor terminal changed before recovery"
      end
      identity = session_identity(row)
      if execution["agent_session"] && execution["agent_session"] != identity
        raise Ace::Overseer::Error, "executor session changed before recovery"
      end
      # Without a saved Pi identity, bind only the unique private session
      # directory allocated for this dispatch, never an arbitrary same-name pane.
      unless execution["agent_session"]
        directory = execution["credentials_directory"]
        native_session = row.fetch("agent_session")
        unless directory && native_session["kind"] == "path" && native_session["value"].start_with?("#{directory}/sessions/")
          raise Ace::Overseer::Error, "unconfirmed launch has no matching session provenance"
        end
      end
      execution.merge!("pane" => row["pane_id"], "terminal_id" => row["terminal_id"],
        "agent_session" => identity, "state" => "started")
      raw = row["agent_session"]
      execution["session_path"] = raw["value"] if raw.is_a?(Hash) && raw["kind"] == "path"
      save.call
    end

    def reuse(execution, brief, worktree_path, save)
      if execution["state"] == "retired"
        raise Ace::Overseer::Error, "recorded executor is retired; reconcile the assignment before starting another"
      end
      unless execution["state"] == "running"
        raise Ace::Overseer::Error, "executor start is unconfirmed; inspect the recorded assignment before retrying"
      end
      pane = pane_identity(execution.fetch("pane"))
      unless pane["terminal_id"] == execution["terminal_id"]
        raise Ace::Overseer::Error, "recorded executor terminal no longer matches"
      end
      begin
        agent = @executor.agent_get(execution.fetch("pane")).parsed_json&.dig("result", "agent")
      rescue Ace::Herdr::AgentNotFoundError
        return resume_dead(execution, brief, worktree_path, pane, save)
      end
      unless agent.is_a?(Hash) && agent["interactive_ready"] == true && same_executor?(agent, execution)
        raise Ace::Overseer::Error, "recorded executor is not a live interactive agent"
      end
      execution.reject { |key, _| key == "credentials_directory" }.merge("reused" => true)
    end

    def resume_dead(execution, brief, worktree_path, pane, save)
      unless brief.assignment_snapshot&.state.to_s == "running" && pane["cwd"] == worktree_path
        raise Ace::Overseer::Error, "dead executor recovery requires its running assignment and original directory"
      end
      transcript = resume_transcript(execution, worktree_path)
      SessionEnvironment.cleanup(execution["credentials_directory"])
      @environment.with_environment(root: worktree_path, role: brief.config.role) do |file, directory, args|
        execution.merge!("state" => "resuming", "resume_transcript" => transcript,
          "credentials_directory" => directory)
        save.call # An uncertain native start must be inspected, never repeated.
        @executor.agent_start(name: execution.fetch("agent"), kind: "pi", pane: execution.fetch("pane"),
          timeout_ms: 60_000, env_file: file,
          args: Array(args) + ["--session", transcript, "--append-system-prompt", brief.instructions_source])
        identity = await_session(execution)
        raise Ace::Overseer::Error, "resumed executor session changed" unless identity == execution["agent_session"]
        execution["state"] = "resumed"
        save.call
      end
      finish_resume(execution, brief, worktree_path, save)
    end

    def finish_resume(execution, brief, worktree_path, save)
      raise Ace::Overseer::Error, "resumed assignment is no longer running" unless brief.assignment_snapshot&.state.to_s == "running"
      if execution["replacement_pending"]
        recover_replacement(execution, worktree_path, save)
      end
      begin
        agent = @executor.agent_get(execution.fetch("pane")).parsed_json&.dig("result", "agent")
      rescue Ace::Herdr::AgentNotFoundError
        raise unless execution["state"] == "resuming"
        pane = pane_identity(execution.fetch("pane"))
        if pane["terminal_id"] != execution["terminal_id"]
          return replace_resume_terminal(execution, brief, worktree_path, pane, save)
        end
        pane = confirmed_resume_shell(execution, worktree_path)
        return resume_dead(execution, brief, worktree_path, pane, save)
      end
      unless agent.is_a?(Hash) && same_executor?(agent, execution) && agent["cwd"] == worktree_path &&
          agent["name"] == execution["agent"] && agent["interactive_ready"] == true && agent["agent_status"] == "idle"
        raise Ace::Overseer::Error, "resumed executor is not the expected idle session; inspect before retrying"
      end
      execution["state"] = "resume_prompting"
      save.call
      @executor.agent_prompt(pane: execution.fetch("pane"), text:
        "Continue the existing assignment #{brief.config.assignment} after process interruption. " \
        "Read its current owner state and preserved reports; resume unfinished work only. " \
        "Do not repeat completed effects or create a replacement assignment. " \
        "Use ace-coworker resume --config #{Shellwords.escape(brief.config.source_path)} to assess continuation.")
      execution["state"] = "running"
      save.call
      execution.reject { |key, _| key == "credentials_directory" }.merge("reused" => true, "resumed" => true)
    end

    def resume_inventory
      rows = @executor.agent_list.parsed_json&.dig("result", "agents")
      unless rows.is_a?(Array) && rows.all? { |row| row.is_a?(Hash) && row["name"].is_a?(String) && row["pane_id"].is_a?(String) &&
          Ace::Herdr::Atoms::NativeAgentSession.normalize(row["agent_session"], agent: row["agent"]) }
        raise Ace::Overseer::Error, "native executor inventory is incomplete"
      end
      rows
    end

    def replacement_matches(execution)
      resume_inventory.select do |row|
        row["name"] == execution["agent"] ||
          Ace::Herdr::Atoms::NativeAgentSession.normalize(row["agent_session"], agent: "pi") == execution["agent_session"]
      end
    end

    def recover_replacement(execution, worktree_path, save)
      rows = replacement_matches(execution)
      row = rows.one? && rows.first
      unless row && row["name"] == execution["agent"] && row["cwd"] == worktree_path && row["terminal_id"] &&
          row["interactive_ready"] == true && row["agent_status"] == "idle" && session_identity(row) == execution["agent_session"]
        raise Ace::Overseer::Error, "replacement resume is unconfirmed; inspect before retrying"
      end
      execution.merge!("pane" => row["pane_id"], "terminal_id" => row["terminal_id"])
      execution.delete("replacement_pending")
      save.call
    end

    def replace_resume_terminal(execution, brief, worktree_path, pane, save)
      transcript = resume_transcript(execution, worktree_path)
      info = @executor.pane_process_info(execution.fetch("pane")).parsed_json&.dig("result", "process_info")
      unless pane["cwd"] == worktree_path && shell_only?(info, execution["pane"]) && replacement_matches(execution).empty?
        raise Ace::Overseer::Error, "old executor absence is unconfirmed; replacement refused"
      end
      # A native live handoff may replace terminal identity. Never send input
      # to or close that old pane; resume the same Pi transcript in a new pane.
      SessionEnvironment.cleanup(execution["credentials_directory"])
      @environment.with_environment(root: worktree_path, role: brief.config.role) do |file, directory, args|
        execution["previous_terminal"] = execution.slice("pane", "terminal_id")
        execution.merge!("replacement_pending" => true, "credentials_directory" => directory, "resume_transcript" => transcript)
        save.call
        dispatcher = Ace::Herdr::Organisms::Dispatcher.from_config(executor: @executor)
        result = dispatcher.dispatch(label: execution.fetch("agent"), prompt: "", kind: "pi", cwd: worktree_path,
          workspace_id: execution["workspace"], env_file: file,
          args: Array(args) + ["--session", transcript, "--append-system-prompt", brief.instructions_source])
        execution.merge!(result.to_h)
        execution["terminal_id"] = pane_identity(execution.fetch("pane")).fetch("terminal_id")
        save.call
        identity = await_session(execution)
        raise Ace::Overseer::Error, "replacement executor session changed" unless identity == execution["agent_session"]
        execution.delete("replacement_pending")
        save.call
      end
      finish_resume(execution, brief, worktree_path, save)
    end

    def shell_only?(info, pane)
      info.is_a?(Hash) && info["pane_id"] == pane && info["shell_pid"].is_a?(Integer) && info["shell_pid"].positive? &&
        info["foreground_process_group_id"] == info["shell_pid"] && info["foreground_processes"].is_a?(Array) &&
        info["foreground_processes"].length == 1 && info["foreground_processes"].first.is_a?(Hash) &&
        info["foreground_processes"].first["pid"] == info["shell_pid"]
    end

    def confirmed_resume_shell(execution, worktree_path)
      pane = pane_identity(execution.fetch("pane"))
      info = @executor.pane_process_info(execution.fetch("pane")).parsed_json&.dig("result", "process_info")
      unless info.is_a?(Hash) && pane["terminal_id"] == execution["terminal_id"] && pane["cwd"] == worktree_path &&
          info["pane_id"] == execution["pane"] && info.dig("guarded_prompt_origin", "terminal_id") == execution["terminal_id"] &&
          info["guarded_prompt"] == true && info["guarded_input_drain"] == true &&
          shell_only?(info, execution["pane"])
        raise Ace::Overseer::Error, "failed resume has no confirmed original shell; inspect before retrying"
      end
      pane
    end

    def resume_transcript(execution, worktree_path)
      candidates = if execution["resume_transcript"]
        [execution.fetch("resume_transcript")]
      else
        directory = execution["credentials_directory"]
        raise Ace::Overseer::Error, "executor has no private session directory" unless directory
        Dir.glob(File.join(directory, "sessions", "**", "*.jsonl")).select do |path|
          Ace::Herdr::Atoms::NativeAgentSession.normalize({"agent" => "pi", "kind" => "path", "value" => path}, agent: "pi") == execution["agent_session"]
        end
      end
      raise Ace::Overseer::Error, "executor transcript is missing or ambiguous" unless candidates.length == 1
      path = candidates.first
      raise Ace::Overseer::Error, "executor transcript is not a regular file" unless File.file?(path) && !File.symlink?(path)
      header = File.open(path) { |file| JSON.parse(file.readline) }
      unless header["type"] == "session" && header["id"] == execution.dig("agent_session", "value") && header["cwd"] == worktree_path
        raise Ace::Overseer::Error, "executor transcript identity does not match"
      end
      path
    rescue JSON::ParserError, EOFError, SystemCallError
      raise Ace::Overseer::Error, "executor transcript is unavailable or invalid"
    end

    def pane_identity(pane)
      reply = @executor.pane_get(pane).parsed_json
      row = reply&.dig("result", "pane")
      unless row.is_a?(Hash) && row["pane_id"] == pane && row["terminal_id"]
        raise Ace::Overseer::Error, "native executor identity is unavailable"
      end
      row
    end

    def session_identity(pane)
      identity = Ace::Herdr::Atoms::NativeAgentSession.normalize(pane["agent_session"], agent: "pi")
      raise Ace::Overseer::Error, "native executor session identity is unavailable" unless identity
      identity
    end

    def same_executor?(pane, execution)
      pane["terminal_id"] == execution["terminal_id"] && session_identity(pane) == execution["agent_session"]
    end

    def check_eyes!
      context = coordinator_context
      sources = Ace::Overseer::Atoms::ObservationSources::REQUIRED.dup
      sources << Ace::Overseer::Atoms::ObservationSources::PROJECT_SESSIONS if context[:scope] == "lab"
      unless @eyes.ready?(pane: context[:pane], root: context[:root],
          prompt: Ace::Overseer::Atoms::StartContract::FIRST_TURN_PROMPT, required_sources: sources)
        raise Ace::Overseer::Error, "delegation requires the coordinator's active eyes"
      end
      true
    end

    def coordinator_context
      pane = @env["HERDR_PANE_ID"] || @env["HERDR_PANE"]
      raise Ace::Overseer::Error, "coordinator native pane is unavailable" if pane.to_s.empty?
      row = pane_identity(pane)
      cwd = row["cwd"]
      unless cwd.is_a?(String) && cwd.start_with?("/")
        raise Ace::Overseer::Error, "coordinator working directory is unavailable"
      end
      root = @root_resolver.resolve(cwd: cwd)
      config_path = File.join(root, ".ace/overseer/config.yml")
      config = File.file?(config_path) ? YAML.safe_load_file(config_path, permitted_classes: [Date], aliases: true) : {}
      scope = config.is_a?(Hash) ? config.dig("start", "scope") || "lab" : nil
      raise Ace::Overseer::Error, "coordinator scope is invalid" unless %w[lab project].include?(scope)
      {root: root, pane: pane, scope: scope}
    rescue Psych::Exception, SystemCallError, TypeError
      raise Ace::Overseer::Error, "coordinator configuration is unavailable"
    end
  end
end

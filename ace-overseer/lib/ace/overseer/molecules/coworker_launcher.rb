# frozen_string_literal: true

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
      brief_factory: nil, readiness: nil, eyes: nil, root_resolver: nil)
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
          next reuse(document.fetch("execution"))
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
          pane = pane_identity(execution.fetch("pane"))
          execution["terminal_id"] = pane.fetch("terminal_id")
          execution["agent_session"] = session_identity(pane)
          save.call
        end
        # Record uncertainty BEFORE submission. A crash after input reaches Pi
        # cannot cause the same task to be submitted again automatically.
        execution["state"] = "prompting"
        save.call
        prompt = "#{brief.config.start_prompt}\n\n#{Ace::Coworker::Atoms::BriefFormatter.format_table(brief)}"
        @executor.agent_prompt(pane: execution.fetch("pane"), text: prompt)
        execution["state"] = "running"
        save.call
        execution.reject { |key, _| key == "credentials_directory" }.merge("reused" => false)
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

    def reuse(execution)
      if execution["state"] == "retired"
        raise Ace::Overseer::Error, "recorded executor is retired; reconcile the assignment before starting another"
      end
      unless execution["state"] == "running"
        raise Ace::Overseer::Error, "executor start is unconfirmed; inspect the recorded assignment before retrying"
      end
      pane = pane_identity(execution.fetch("pane"))
      unless same_executor?(pane, execution)
        raise Ace::Overseer::Error, "recorded executor terminal no longer matches"
      end
      agent = @executor.agent_get(execution.fetch("pane")).parsed_json&.dig("result", "agent")
      unless agent.is_a?(Hash) && agent["interactive_ready"] == true && same_executor?(agent, execution)
        raise Ace::Overseer::Error, "recorded executor is not a live interactive agent"
      end
      execution.reject { |key, _| key == "credentials_directory" }.merge("reused" => true)
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

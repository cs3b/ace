# frozen_string_literal: true

require "digest"

module Ace::Herdr::Organisms
  # The configured host owns executable selection and isolation. This adapter
  # supplies only the granted project, role, worktree and commissioning prompt.
  class IsolatedDispatcher
    def initialize(executor:, env: ENV, loader: nil)
      @executor, @env = executor, env
      @loader = loader || lambda do
        require "ace/lab/molecules/install_manifest_loader"
        Ace::Lab::Molecules::InstallManifestLoader.load
      end
    end

    def dispatch(label:, prompt:, kind:, workspace_id:, pane:, cwd:, role:)
      unless @env["ACE_TOOLCHAIN"] == "installed" && kind == "pi" && pane.nil? &&
          %w[worker verifier integrator].include?(role)
        raise Ace::Herdr::ValidationError, "isolated dispatch requires installed Pi and a new configured worker role"
      end
      root = File.realpath(cwd || Dir.pwd)
      projects = @loader.call.fetch("projects").select do |entry|
        root == entry["path"] || root.start_with?(entry.fetch("path") + "/.ace-wt/")
      end
      raise Ace::Herdr::ValidationError, "dispatch directory is not a unique configured project" unless projects.length == 1
      project = projects.first.fetch("id")
      name = label.match?(/\A[a-z][a-z0-9_-]{0,31}\z/) ? label :
        "worker-#{label.gsub(/[^a-z0-9_-]/, '-')[0, 15]}-#{Digest::SHA256.hexdigest(label)[0, 8]}"
      existing = result(@executor.agent_list).fetch("agents").select { |agent| agent["name"] == name }
      unless existing.empty?
        raise Ace::Herdr::ValidationError, "dispatch name already exists; reconcile its assignment before sending another prompt"
      end
      agent = result(@executor.agent_start_isolated(name: name, workspace_id: workspace_id,
        project: project, role: role, cwd: root)).fetch("agent")
      terminal = agent.fetch("terminal_id")
      verify!(agent, terminal, project, role, root)
      ready = result(@executor.agent_wait(pane: terminal, until_states: ["idle"], timeout_ms: 60_000)).fetch("agent")
      verify!(ready, terminal, project, role, root)
      unless ready["interactive_ready"] == true && !ready["launch_pending"]
        raise Ace::Herdr::AgentNotReadyError, "isolated worker is not ready for its commissioning prompt"
      end
      unless prompt.empty?
        answer = result(@executor.agent_prompt(pane: terminal, text: prompt))
        unless answer["type"] == "agent_prompted" && answer.dig("agent", "terminal_id") == terminal
          raise Ace::Herdr::ExecutorError, "commission acknowledgement is unconfirmed; preserve the existing session"
        end
      end
      Ace::Herdr::Models::DispatchOutcome.new(workspace_id: workspace_id, pane: terminal,
        agent_name: name, kind: "pi", tab_created: true, prompted: !prompt.empty?)
    rescue KeyError, TypeError, SystemCallError => error
      raise Ace::Herdr::ExecutorError, "isolated dispatch is unconfirmed (#{error.class}); preserve existing sessions"
    end

    private

    def result(execution)
      reply = execution.parsed_json
      unless reply.is_a?(Hash) && !reply.key?("error") && reply["result"].is_a?(Hash)
        raise Ace::Herdr::ExecutorError, "isolated dispatch response is incomplete"
      end
      reply.fetch("result")
    end

    def verify!(agent, terminal, project, role, root)
      unless terminal.is_a?(String) && terminal.match?(/\Aterm_[0-9a-f]+\z/) &&
          agent["terminal_id"] == terminal && agent["cwd"] == root &&
          agent["isolated_session"] == {"project" => project, "role" => role}
        raise Ace::Herdr::ExecutorError, "isolated worker identity differs from the commission"
      end
    end
  end
end

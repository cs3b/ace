# frozen_string_literal: true
require "digest"
require "ace/lab/molecules/install_manifest_loader"
require "ace/lab/auth/issuer_client"
require_relative "../atoms/start_contract"
require_relative "../molecules/project_root_resolver"

module Ace::Overseer::Organisms
  # Runtime comes exclusively from the protected deployment. Herdr owns live
  # names and terminals; no local launch record or second session registry.
  class IsolatedStart
    def initialize(executor:, cwd:, env:, scope: nil, loader: -> { Ace::Lab::Molecules::InstallManifestLoader.load },
      client: Ace::Lab::Auth::IssuerClient.new, root_resolver: Ace::Overseer::Molecules::ProjectRootResolver.new)
      @executor, @cwd, @env, @scope = executor, cwd, env, scope
      @loader, @client, @root_resolver = loader, client, root_resolver
    end

    def call(dry_run: false)
      raise Ace::Overseer::Error, "isolated start requires installed runtime" unless @env["ACE_TOOLCHAIN"] == "installed"
      document = @loader.call
      root = File.realpath(@cwd)
      coordinator = document["coordinator"]
      lab = @scope == "lab" || (@scope.nil? && coordinator && coordinator["path"] == root)
      root = @root_resolver.resolve(cwd: root) unless lab
      entry = lab ? coordinator : document.fetch("projects").find { |project| project["path"] == root }
      unless entry && entry["path"] == root
        raise Ace::Overseer::Error, "directory is not a configured isolated #{lab ? 'lab' : 'project'} scope"
      end
      role = lab ? "lab-overseer" : "project-overseer"
      role_config = document.fetch("roles").find { |item| item["id"] == role }
      raise Ace::Overseer::Error, "isolated overseer role is not configured" unless role_config
      project = entry.fetch("id")
      name = lab ? "lab-overseer" : "overseer-#{project}"
      name = "#{name[0, 23]}-#{Digest::SHA256.hexdigest(name)[0, 8]}" if name.length > 32
      report = {"scope" => lab ? "lab" : "project", "root" => root, "label" => name, "agent" => name,
        "profile" => document.fetch("session_runtime").fetch("model"),
        "instructions" => {"source" => role_config.fetch("instructions")}, "ready" => false}
      return report.merge("status" => "dry_run", "message" => "protected host runtime would launch this scope") if dry_run

      agents = result(@executor.agent_list).fetch("agents")
      owners = agents.select { |agent| agent["name"] == name || agent["isolated_session"] == {"project" => project, "role" => role} }
      raise Ace::Overseer::Error, "multiple live overseer owners; preserve sessions for diagnosis" if owners.length > 1
      if (agent = owners.first)
        verify_agent!(agent, project, role)
        ready = readiness(agent, project, role, root)
        return report.merge("status" => "reused", "pane" => agent.fetch("terminal_id"),
          "workspace" => agent["workspace_id"], "ready" => ready,
          "message" => ready ? "existing isolated overseer and eyes verified" : "existing session preserved; first turn and eyes are not yet verified")
      end
      title = lab ? "overseer" : project
      spaces = result(@executor.workspace_list).fetch("workspaces").select { |space| space["label"] == title }
      raise Ace::Overseer::Error, "multiple project workspaces; refusing ambiguous start" if spaces.length > 1
      workspace = spaces.first || result(@executor.workspace_create(label: title, cwd: root, focus: false)).fetch("workspace")
      workspace_id = workspace.fetch("workspace_id")
      agent = result(@executor.agent_start_isolated(name: name, workspace_id: workspace_id, project: project, role: role)).fetch("agent")
      verify_agent!(agent, project, role)
      terminal = agent.fetch("terminal_id")
      report.merge!("status" => "started", "pane" => terminal, "workspace" => workspace_id)
      # Admission is not readiness. Wait only for input acceptance, then submit
      # exactly once and return; eyes/first-turn evidence arrives asynchronously.
      input_ready = result(@executor.agent_wait(pane: terminal, until_states: ["idle"], timeout_ms: 60_000)).fetch("agent")
      verify_agent!(input_ready, project, role)
      unless input_ready["terminal_id"] == terminal && input_ready["interactive_ready"] == true && !input_ready["launch_pending"]
        raise Ace::Overseer::Error, "isolated terminal is not ready for its first prompt"
      end
      reply = result(@executor.agent_prompt(pane: terminal, text: Ace::Overseer::Atoms::StartContract::FIRST_TURN_PROMPT))
      unless reply["type"] == "agent_prompted" && reply.dig("agent", "terminal_id") == terminal
        raise Ace::Overseer::Error, "first prompt acknowledgement differs; inspect existing session before retrying"
      end
      report.merge("message" => "first prompt submitted; awaiting first turn and active eyes", "ready" => false)
    rescue Ace::Herdr::ExecutorError, Ace::Lab::Error, KeyError, TypeError, SystemCallError => e
      raise Ace::Overseer::Error, "isolated start could not be confirmed (#{e.class}); preserve existing sessions"
    end

    def reconcile(dry_run: false)
      document = @loader.call
      root = File.realpath(@cwd)
      unless document.dig("coordinator", "path") == root
        raise Ace::Overseer::Error, "project reconciliation requires the configured lab root"
      end
      projects = document.fetch("projects").map do |project|
        begin
          self.class.new(executor: @executor, cwd: project.fetch("path"), env: @env, scope: "project",
            loader: -> { document }, client: @client, root_resolver: @root_resolver).call(dry_run: dry_run)
            .merge("id" => project.fetch("id"), "path" => project.fetch("path"))
        rescue Ace::Overseer::Error => e
          {"id" => project["id"], "path" => project["path"], "status" => "blocked", "ready" => false, "message" => e.message}
        end
      end
      ready = !projects.empty? && projects.all? { |project| project["ready"] }
      {"status" => dry_run ? "dry_run" : (ready ? "ready" : "partial"), "scope" => "lab", "root" => root,
        "projects" => projects, "project_count" => projects.length, "ready" => ready,
        "message" => ready ? "all configured project overseers verified" : "project readiness is not yet complete"}
    end

    private

    def result(execution)
      value = execution.parsed_json
      unless value.is_a?(Hash) && !value.key?("error") && value["result"].is_a?(Hash)
        raise Ace::Overseer::Error, "native isolated start response is incomplete"
      end
      value.fetch("result")
    end

    def verify_agent!(agent, project, role)
      unless agent.is_a?(Hash) && agent["terminal_id"].is_a?(String) && agent["terminal_id"].match?(/\Aterm_[0-9a-f]+\z/) &&
          agent["isolated_session"] == {"project" => project, "role" => role}
        raise Ace::Overseer::Error, "overseer owner differs from protected launch scope"
      end
    end

    def readiness(agent, project, role, root)
      answer = if @env["ACE_LAB_SESSION"] == "1"
        @client.readiness(target: agent.fetch("terminal_id"))
      else
        @client.host_readiness(terminal_id: agent.fetch("terminal_id"), project: project, role: role)
      end
      answer["ready"] == true && answer["terminal_id"] == agent["terminal_id"] && answer["root"] == root && answer["role"] == role
    end
  end
end

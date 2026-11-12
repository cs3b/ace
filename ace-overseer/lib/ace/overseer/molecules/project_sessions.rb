# frozen_string_literal: true

require "ace/lab"
require "ace/herdr"
require "digest"
require "json"
require_relative "project_root_resolver"
require_relative "eyes_readiness"

module Ace
  module Overseer
    module Molecules
      # Project locations and terminal sessions remain owned by ace-lab and
      # herdr. This projection has no persisted copy of either.
      class ProjectSessions
        def initialize(root: Dir.pwd, control: nil, locations: Ace::Lab::Molecules::ProjectLocations,
          root_resolver: ProjectRootResolver.new, executor: Ace::Herdr::Molecules::HerdrExecutor.new,
          eyes_evidence: EyesReadiness.new, env: ENV)
          @root = File.realpath(root)
          @control = control || Ace::Herdr::Organisms::ControlSurface.new
          @locations = locations
          @root_resolver = root_resolver
          @executor, @env = executor, env
          @eyes_evidence = eyes_evidence
        end

        def configured?
          File.file?(File.join(@root, ".ace/lab/config.yml"))
        end

        def call
          return [] unless configured?

          projects = @locations.read(@root)
          return [] if projects.empty?

          seen = {}
          failures = []
          resolved = projects.filter_map do |project|
            begin
              path = project.fetch("path")
              raise Error, "project has no configured path" if path.to_s.empty?
              canonical = File.realpath(path, @root)
              next if canonical == @root
              canonical = @root_resolver.resolve(cwd: canonical)
              next if canonical == @root
              raise Error, "multiple projects use the same root" if seen[canonical]

              seen[canonical] = true
              [project.fetch("id"), canonical, project]
            rescue StandardError => e
              failures << unavailable_row(project, e)
              nil
            end
          end
          return failures if resolved.empty?

          tabs = @control.list_tabs
          panes = @control.list_panes
          failures + resolved.flat_map do |id, root, project|
            begin
              project_row(id, root, tabs, panes)
            rescue StandardError => e
              unavailable_row(project, e)
            end
          end
        end

        private

        def unavailable_row(project, error)
          identity = Digest::SHA256.hexdigest(JSON.generate([project["id"], project["path"]]))
          payload = {"project" => project["id"], "state" => "unavailable", "error" => "#{error.class}: #{error.message}"}
          {"key" => "project-session-error:#{identity}",
           "revision" => Digest::SHA256.hexdigest(JSON.generate(payload)),
           "type" => "project-session"}.merge(payload)
        end


        def live_agent(pane)
          json = @executor.agent_get(pane).parsed_json
          raise Error, "herdr returned malformed agent state" unless json.is_a?(Hash)
          agent = json["agent"]
          agent ||= json.dig("result", "agent") if json["result"].is_a?(Hash)
          agent ||= json["result"] if json["result"].is_a?(Hash)
          raise Error, "herdr returned no agent identity" unless agent.is_a?(Hash)
          agent
        rescue Ace::Herdr::AgentNotFoundError
          nil
        end

        def project_row(id, root, tabs, panes)
          label = Atoms::StartContract.session_label(root)
          owners = tabs.select { |tab| tab[:title] == label }.flat_map do |tab|
            matches = panes.select { |pane| pane[:tab] == tab[:id] }
            raise Error, "project overseer tab has no unique pane: #{label}" unless matches.length == 1
            matches
          end
          # Reconciliation preserves dead panels for diagnostics. Native agent
          # presence, not retained tabs, identifies the live owner.
          live = owners.filter_map do |owner|
            agent = live_agent(owner.fetch(:id))
            [owner, agent] if agent
          end
          raise Error, "project overseer has ambiguous sessions: #{label}" if live.length > 1
          pane, agent = live.first
          raise Error, "project overseer session did not report a working directory: #{label}" if pane && pane[:cwd].to_s.empty?
          if pane && @root_resolver.resolve(cwd: pane[:cwd]) != root
            raise Error, "project overseer session has a different root: #{label}"
          end
          state = pane ? (pane[:agent_status] || "unknown").to_s : "absent"
          payload = {"project" => id, "root" => root, "pane" => pane && pane[:id], "state" => state}
          row = {"key" => "project-session:#{Digest::SHA256.hexdigest(root)}",
           "revision" => Digest::SHA256.hexdigest(JSON.generate(payload.merge(
             "state" => (%w[working idle done].include?(state) ? "available" : state)))),
           "type" => "project-session"}.merge(payload)
          [row, readiness_event(id, root, pane, agent)].compact
        end

        # A successful first-turn proof is a stable confirmation, not a sampled
        # boolean lifecycle. A concurrent transcript append can make a proof
        # inconclusive; omitting this marker then does not undo eyes' existing ack.
        # The recipient still rechecks start readiness before recording success.
        def readiness_event(id, root, pane, agent)
          return unless pane
          required = Atoms::ObservationSources::REQUIRED.dup
          required << Atoms::ObservationSources::PROJECT_SESSIONS if File.file?(File.join(root, ".ace/lab/config.yml"))
          return unless @eyes_evidence.ready?(pane: pane.fetch(:id), root: root,
            prompt: Atoms::StartContract::FIRST_TURN_PROMPT, required_sources: required)
          identity = readiness_identity(agent)
          current = live_agent(pane.fetch(:id))
          return unless current && readiness_identity(current) == identity

          payload = {"project" => id, "root" => root, "pane" => pane.fetch(:id),
            "terminal" => identity[0], "session" => identity[1], "ready" => true}
          key = Digest::SHA256.hexdigest(JSON.generate([root, *identity]))
          {"key" => "project-ready:#{key}", "revision" => Digest::SHA256.hexdigest("ready:#{key}"),
           "type" => "project-ready"}.merge(payload)
        end

        def readiness_identity(agent)
          terminal = agent["terminal_id"]
          session = agent.dig("agent_session", "value")
          unless terminal.is_a?(String) && !terminal.empty? && session.is_a?(String) && !session.empty?
            raise Error, "ready project agent has no terminal/session identity"
          end
          [terminal, session]
        end
      end
    end
  end
end

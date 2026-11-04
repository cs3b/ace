# frozen_string_literal: true

require "ace/lab"
require "ace/herdr"
require "digest"
require "json"
require_relative "project_root_resolver"
require_relative "isolated_runtime"

module Ace
  module Overseer
    module Molecules
      # Project locations and terminal sessions remain owned by ace-lab and
      # herdr. This projection has no persisted copy of either.
      class ProjectSessions
        def initialize(root: Dir.pwd, control: nil, locations: Ace::Lab::Molecules::ProjectLocations,
          root_resolver: ProjectRootResolver.new, executor: Ace::Herdr::Molecules::HerdrExecutor.new, env: ENV)
          @root = File.realpath(root)
          @control = control || Ace::Herdr::Organisms::ControlSurface.new
          @locations = locations
          @root_resolver = root_resolver
          @executor, @env = executor, env
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

          if IsolatedRuntime.enabled?(env: @env)
            response = @executor.agent_list.parsed_json
            unless response.is_a?(Hash) && !response.key?("error") && response.dig("result", "agents").is_a?(Array)
              raise Error, "isolated native session inventory is unavailable"
            end
            agents = response.dig("result", "agents")
            return failures + resolved.map do |id, root, project|
              begin
                isolated_row(id, root, agents)
              rescue StandardError => e
                unavailable_row(project, e)
              end
            end
          end

          tabs = @control.list_tabs
          panes = @control.list_panes
          failures + resolved.map do |id, root, project|
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

        def isolated_row(id, root, agents)
          owners = agents.select { |agent| agent["isolated_session"] == {"project" => id, "role" => "project-overseer"} }
          raise Error, "project overseer has ambiguous isolated sessions" if owners.length > 1
          agent = owners.first
          if agent
            unless agent["terminal_id"].is_a?(String) && agent["terminal_id"].match?(/\Aterm_[0-9a-f]+\z/) &&
                !agent["cwd"].to_s.empty? && @root_resolver.resolve(cwd: agent["cwd"]) == root
              raise Error, "isolated project session identity or root differs"
            end
          end
          payload = {"project" => id, "root" => root, "pane" => agent && agent["terminal_id"],
            "state" => agent ? agent.fetch("agent_status", "unknown") : "absent"}
          {"key" => "project-session:#{Digest::SHA256.hexdigest(root)}",
            "revision" => Digest::SHA256.hexdigest(JSON.generate(payload)), "type" => "project-session"}.merge(payload)
        end

        def project_row(id, root, tabs, panes)
          label = Atoms::StartContract.session_label(root)
          owners = tabs.select { |tab| tab[:title] == label }.flat_map do |tab|
            matches = panes.select { |pane| pane[:tab] == tab[:id] }
            raise Error, "project overseer tab has no unique pane: #{label}" unless matches.length == 1
            matches
          end
          raise Error, "project overseer has ambiguous sessions: #{label}" if owners.length > 1
          pane = owners.first
          raise Error, "project overseer session did not report a working directory: #{label}" if pane && pane[:cwd].to_s.empty?
          if pane && @root_resolver.resolve(cwd: pane[:cwd]) != root
            raise Error, "project overseer session has a different root: #{label}"
          end
          state = pane ? (pane[:agent_status] || "unknown").to_s : "absent"
          payload = {"project" => id, "root" => root, "pane" => pane && pane[:id], "state" => state}
          {"key" => "project-session:#{Digest::SHA256.hexdigest(root)}",
           "revision" => Digest::SHA256.hexdigest(JSON.generate(payload)),
           "type" => "project-session"}.merge(payload)
        end
      end
    end
  end
end

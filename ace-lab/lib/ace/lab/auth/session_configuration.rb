# frozen_string_literal: true

require_relative "session_unit"
require_relative "../molecules/install_manifest_loader"

module Ace
  module Lab
    module Auth
      # Select launch data from the existing deployment manifest, never from
      # a project checkout or agent-supplied executable/environment fields.
      class SessionConfiguration
        Selection = Data.define(:project, :path, :role, :instructions, :gem_home, :runtime)

        def initialize(loader: -> { Molecules::InstallManifestLoader.load })
          @loader = loader
        end

        # principal is supplied by the host's authenticated peer, not JSON.
        def resolve(project:, role:, principal: nil, session: nil)
          document = @loader.call
          unless SessionUnit::ROLES.include?(role)
            raise Error, "session role is not supported"
          end
          selected_project = document.fetch("projects").find { |entry| entry["id"] == project }
          selected_role = document.fetch("roles").find { |entry| entry["id"] == role }
          authorized = if session
            raise Error, "session delegation cannot supply a host principal" unless principal.nil?
            unless session.is_a?(SessionPeer::Identity)
              raise Error, "session delegation requires authenticated identity"
            end
            allowed_roles = case session.role
            when "lab-overseer" then %w[project-overseer worker verifier integrator]
            when "project-overseer" then %w[worker verifier integrator]
            else []
            end
            allowed_roles.include?(role) && selected_project &&
              (session.role == "lab-overseer" || selected_project["path"] == session.project_root) &&
              Array(document.fetch("grants")["session:#{session.role}"]).include?(project)
          else
            principal.is_a?(String) && selected_role && selected_role["account"] == principal &&
              Array(document.fetch("grants")[principal]).include?(project)
          end
          unless selected_project && selected_role && authorized
            raise Error, "session project or role is not granted to this principal"
          end
          gem_home = document.fetch("gemset").fetch("gem_home")
          unless gem_home.is_a?(String) && gem_home.start_with?("/") && File.expand_path(gem_home) == gem_home
            raise Error, "session installed runtime is not configured"
          end
          runtime = document.fetch("session_runtime")
          raise Error, "session Pi runtime is not configured" unless runtime.is_a?(Hash)
          Selection.new(project: project, path: selected_project.fetch("path"), role: role,
            instructions: selected_role.fetch("instructions"), gem_home: gem_home, runtime: runtime)
        rescue KeyError, NoMethodError
          raise Error, "session deployment configuration is incomplete"
        end
      end
    end
  end
end

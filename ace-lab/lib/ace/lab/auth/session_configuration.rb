# frozen_string_literal: true

require_relative "session_unit"
require_relative "../molecules/install_manifest_loader"

module Ace
  module Lab
    module Auth
      # Select launch data from the existing deployment manifest, never from
      # a project checkout or agent-supplied executable/environment fields.
      class SessionConfiguration
        Selection = Data.define(:project, :path, :role, :instructions, :gem_home)

        def initialize(loader: -> { Molecules::InstallManifestLoader.load })
          @loader = loader
        end

        # principal is supplied by the host's authenticated peer, not JSON.
        def resolve(project:, role:, principal:)
          document = @loader.call
          unless SessionUnit::ROLES.include?(role)
            raise Error, "session role is not supported"
          end
          selected_project = document.fetch("projects").find { |entry| entry["id"] == project }
          selected_role = document.fetch("roles").find { |entry| entry["id"] == role }
          unless selected_project && selected_role && selected_role["account"] == principal &&
              Array(document.fetch("grants")[principal]).include?(project)
            raise Error, "session project or role is not granted to this principal"
          end
          gem_home = document.fetch("gemset").fetch("gem_home")
          unless gem_home.is_a?(String) && gem_home.start_with?("/") && File.expand_path(gem_home) == gem_home
            raise Error, "session installed runtime is not configured"
          end
          Selection.new(project: project, path: selected_project.fetch("path"), role: role,
            instructions: selected_role.fetch("instructions"), gem_home: gem_home)
        rescue KeyError, NoMethodError
          raise Error, "session deployment configuration is incomplete"
        end
      end
    end
  end
end

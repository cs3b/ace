# frozen_string_literal: true

require_relative "error"
require_relative "../molecules/install_manifest_loader"

module Ace
  module Lab
    module Auth
      # Passive launch data from the installed manifest. Roles select a brief
      # and a project-specific environment, not an operating-system identity.
      class SessionConfiguration
        ROLES = %w[lab-overseer project-overseer worker verifier integrator].freeze
        Selection = Data.define(:project, :path, :role, :instructions, :gem_home, :runtime, :environment_file)

        def initialize(loader: -> { Molecules::InstallManifestLoader.load })
          @loader = loader
        end

        def resolve(project:, role:)
          document = @loader.call
          raise Error, "session role is not supported" unless ROLES.include?(role)

          scope = if role == "lab-overseer"
            document["coordinator"] if document.dig("coordinator", "id") == project
          else
            document.fetch("projects").find { |entry| entry["id"] == project }
          end
          selected_role = document.fetch("roles").find { |entry| entry["id"] == role }
          raise Error, "session project or role is not configured" unless scope && selected_role

          runtime = document.fetch("session_runtime")
          raise Error, "session Pi runtime is not configured" unless runtime.is_a?(Hash)

          Selection.new(project: project, path: scope.fetch("path"), role: role,
            instructions: selected_role.fetch("instructions"),
            gem_home: document.fetch("gemset").fetch("gem_home"), runtime: runtime,
            environment_file: scope.fetch("environment_files", {})[role])
        rescue KeyError, NoMethodError
          raise Error, "session deployment configuration is incomplete"
        end
      end
    end
  end
end

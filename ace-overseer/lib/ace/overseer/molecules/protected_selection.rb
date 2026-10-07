# frozen_string_literal: true

require "ace/lab"
require "ace/assign/authority/deployment"

module Ace
  module Overseer
    module Molecules
      # Visibility narrows the installed project pool; it never grants authority.
      class ProtectedSelection
        def initialize(topology: nil, deployment_loader: nil)
          @topology = topology || Ace::Lab::Organisms::TopologyService.from_config
          @deployment_loader = deployment_loader || -> { Ace::Assign::Authority::Deployment.load }
        end

        def call(project:, agent: nil)
          token!(project)
          token!(agent) if agent
          topology = @topology.agents(project: project)
          raise Error, "Protected topology unavailable (#{topology.error_code})" unless topology.ok?
          deployment = @deployment_loader.call
          pool = deployment.data.fetch("launch_mappings").select { |_id, map| map.fetch("project_id") == project }.keys.sort
          raise Error, "Protected project has no provisioned mappings" if pool.empty?
          visible = topology.data.fetch("agents")
          unless visible.is_a?(Array) && visible.all? { |entry| entry.is_a?(Hash) && entry["project"] == project && pool.include?(entry["id"]) } &&
              visible.map { |entry| entry.fetch("id") }.uniq.size == visible.size
            raise Error, "Public agent visibility differs from protected project mappings"
          end
          ids = visible.map { |entry| entry.fetch("id") }.sort
          if agent && !ids.include?(agent)
            raise Error, "Requested protected agent is not visible in this project"
          end
          [deployment, pool.freeze, ids.freeze].freeze
        rescue KeyError, TypeError, NoMethodError
          raise Error, "Protected selection metadata is malformed"
        end

        private

        def token!(value)
          raise Error, "Protected identity is invalid" unless value.is_a?(String) && value.match?(Ace::Assign::Authority::Deployment::TOKEN)
        end
      end
    end
  end
end

# frozen_string_literal: true
require "json"
require "ace/lab"
module Ace
  module Overseer
    module CLI
      module Commands
        class Agents < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          desc "List agents visible through maintained public topology"
          option :project, required: true, desc: "Visible installed project ID"
          def initialize(topology: nil)
            super()
            @topology = topology || Ace::Lab::Organisms::TopologyService.from_config
          end
          def call(project:, **extra)
            raise Error, "Unsupported topology options" unless extra.empty?
            result = @topology.agents(project: project)
            puts JSON.generate(result.envelope)
            raise Error, "#{result.error_code}: #{result.message}" unless result.ok?
          rescue StandardError => error
            raise Ace::Support::Cli::Error, error.message
          end
        end
      end
    end
  end
end

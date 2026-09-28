# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Lab
    module CLI
      module Commands
        class Route < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Select a configured capable service in a project

            Routing never invokes a service or grants credentials; zero
            candidates are missing, several without a configured default are
            ambiguous.
          DESC

          example ["--project atlas --capability search --format json"]

          option :project, type: :string, required: true, desc: "Project stable ID"
          option :capability, type: :string, required: true, desc: "Capability to route"
          option :format, type: :string, desc: "Output format (json only)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(topology_service: nil)
            @topology_service = topology_service
          end

          def call(project:, capability:, **options)
            ensure_json_format!(options)
            reject_identity_flags!(options)

            emit_result(
              topology_service.route(project: project, capability: capability),
              quiet: options[:quiet]
            )
          end
        end
      end
    end
  end
end

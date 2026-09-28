# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Lab
    module CLI
      module Commands
        class Services < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            List lab services in a project by stable ID

            Endpoints are sanitized to scheme/host identity; tokens, auth
            files, userinfo, query parameters, and fragments never appear.
          DESC

          example ["--project atlas --format json"]

          option :project, type: :string, required: true, desc: "Project stable ID"
          option :format, type: :string, desc: "Output format (json only)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(topology_service: nil)
            @topology_service = topology_service
          end

          def call(project:, **options)
            ensure_json_format!(options)
            reject_identity_flags!(options)

            emit_result(topology_service.services(project: project), quiet: options[:quiet])
          end
        end
      end
    end
  end
end

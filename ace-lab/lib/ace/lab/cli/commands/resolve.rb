# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Lab
    module CLI
      module Commands
        class Resolve < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Resolve one lab entry by exact stable ID

            Labels are display values and never resolve; an unknown ID is a
            classified missing error, a replaced process a classified stale
            error.
          DESC

          example ["--id atlas-planner --format json"]

          option :id, type: :string, required: true, desc: "Stable entry ID"
          option :format, type: :string, desc: "Output format (json only)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(topology_service: nil)
            @topology_service = topology_service
          end

          def call(id:, **options)
            ensure_json_format!(options)
            reject_identity_flags!(options)

            emit_result(topology_service.resolve(id: id), quiet: options[:quiet])
          end
        end
      end
    end
  end
end

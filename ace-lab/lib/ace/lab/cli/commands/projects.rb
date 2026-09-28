# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Lab
    module CLI
      module Commands
        class Projects < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            List lab projects visible to the verified caller

            Only projects covered by a configured authorization principal are
            returned; a caller with no principal receives a classified
            unauthorized error.
          DESC

          example ["--format json"]

          option :format, type: :string, desc: "Output format (json only)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(topology_service: nil)
            @topology_service = topology_service
          end

          def call(**options)
            ensure_json_format!(options)
            reject_identity_flags!(options)

            emit_result(topology_service.projects, quiet: options[:quiet])
          end
        end
      end
    end
  end
end

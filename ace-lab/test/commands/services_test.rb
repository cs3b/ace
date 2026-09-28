# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class ServicesTest < Minitest::Test
          def service
            @service ||= Ace::Lab::Organisms::TopologyService.from_config(
              authorized_for_local(topology_config)
            )
          end

          def test_lists_project_services_as_json
            cmd = Services.new(topology_service: service)

            out, = capture_io do
              cmd.call(project: "atlas", format: "json", quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal "ok", parsed["status"]
            assert_equal %w[atlas-search atlas-index], parsed["data"]["services"].map { |s| s["id"] }
          end

          def test_service_endpoints_are_sanitized_in_cli_output
            cmd = Services.new(topology_service: service)

            out, = capture_io do
              cmd.call(project: "atlas", format: "json", quiet: nil)
            end

            refute_includes out, "secret"
            refute_includes out, "token"
            refute_includes out, "query"
            assert_includes out, "https://search.example.internal:8443"
          end

          def test_unauthorized_project_classifies_error
            cmd = Services.new(topology_service: service)

            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                cmd.call(project: "ghost", format: "json", quiet: nil)
              end
            end.first

            parsed = JSON.parse(out)
            assert_equal "unauthorized", parsed["error"]["code"]
          end
        end
      end
    end
  end
end

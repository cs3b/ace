# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class RouteTest < Minitest::Test
          def service
            @service ||= Ace::Lab::Organisms::TopologyService.from_config(
              authorized_for_local(topology_config)
            )
          end

          def test_routes_to_configured_default_as_json
            cmd = Route.new(topology_service: service)

            out, = capture_io do
              cmd.call(project: "atlas", capability: "search", format: "json", quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal "ok", parsed["status"]
            assert_equal "atlas-search", parsed["data"]["entry"]["id"]
            assert_equal "https://search.example.internal:8443", parsed["data"]["entry"]["binding"]["endpoint"]["url"]
          end

          def test_zero_candidates_print_missing_document_and_fail
            cmd = Route.new(topology_service: service)

            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                cmd.call(project: "atlas", capability: "gpu", format: "json", quiet: nil)
              end
            end.first

            parsed = JSON.parse(out)
            assert_equal "missing", parsed["error"]["code"]
            assert_equal "atlas", parsed["error"]["project"]
            assert_equal "gpu", parsed["error"]["capability"]
          end

          def test_ambiguity_prints_classified_document_and_fails
            config = authorized_for_local(topology_config)
            config["topology"]["services"].first["default_for"] = []
            cmd = Route.new(topology_service: Ace::Lab::Organisms::TopologyService.from_config(config))

            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                cmd.call(project: "atlas", capability: "search", format: "json", quiet: nil)
              end
            end.first

            parsed = JSON.parse(out)
            assert_equal "ambiguous", parsed["error"]["code"]
          end

          def test_rejects_unsupported_format
            cmd = Route.new(topology_service: service)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(project: "atlas", capability: "search", format: "text", quiet: nil)
            end
            assert_match(/only --format json/, error.message)
          end

          def test_rejects_role_flag
            cmd = Route.new(topology_service: service)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(project: "atlas", capability: "search", format: "json", quiet: nil, role: "planner")
            end
            assert_match(/--role is not supported/, error.message)
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class ResolveTest < Minitest::Test
          def service
            @service ||= Ace::Lab::Organisms::TopologyService.from_config(
              authorized_for_local(topology_config)
            )
          end

          def test_resolves_exact_stable_id_as_json
            cmd = Resolve.new(topology_service: service)

            out, = capture_io do
              cmd.call(id: "atlas-planner", format: "json", quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal "ok", parsed["status"]
            assert_equal "atlas-planner", parsed["data"]["entry"]["id"]
          end

          def test_unknown_id_prints_missing_document_and_fails
            cmd = Resolve.new(topology_service: service)

            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                cmd.call(id: "ghost-agent", format: "json", quiet: nil)
              end
            end.first

            parsed = JSON.parse(out)
            assert_equal "error", parsed["status"]
            assert_equal "missing", parsed["error"]["code"]
            assert_equal "ghost-agent", parsed["error"]["id"]
          end

          def test_label_lookup_is_missing_not_fuzzy
            cmd = Resolve.new(topology_service: service)

            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                cmd.call(id: "Atlas platform", format: "json", quiet: nil)
              end
            end.first

            assert_equal "missing", JSON.parse(out)["error"]["code"]
          end

          def test_stale_binding_prints_stale_document_and_fails
            cmd = Resolve.new(topology_service: service)

            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                cmd.call(id: "atlas-coder", format: "json", quiet: nil)
              end
            end.first

            parsed = JSON.parse(out)
            assert_equal "stale", parsed["error"]["code"]
            assert_equal "atlas-coder", parsed["error"]["id"]
          end

          def test_rejects_caller_flag
            cmd = Resolve.new(topology_service: service)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(id: "atlas-planner", format: "json", quiet: nil, caller: "operator")
            end
            assert_match(/--caller is not supported/, error.message)
          end
        end
      end
    end
  end
end

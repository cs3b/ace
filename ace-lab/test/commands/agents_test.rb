# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class AgentsTest < Minitest::Test
          def service
            @service ||= Ace::Lab::Organisms::TopologyService.from_config(
              authorized_for_local(topology_config)
            )
          end

          def test_lists_project_agents_as_json
            cmd = Agents.new(topology_service: service)

            out, = capture_io do
              cmd.call(project: "atlas", format: "json", quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal "ok", parsed["status"]
            assert_equal %w[atlas-planner atlas-coder], parsed["data"]["agents"].map { |a| a["id"] }
            assert_equal "planner", parsed["data"]["agents"].first["role"]
          end

          def test_agent_entries_never_contain_binding_identities
            cmd = Agents.new(topology_service: service)

            out, = capture_io do
              cmd.call(project: "atlas", format: "json", quiet: nil)
            end

            refute_includes out, "inst-planner-1"
            refute_includes out, "pane"
            refute_includes out, "session"
          end

          def test_unauthorized_project_classifies_error
            cmd = Agents.new(topology_service: service)

            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                cmd.call(project: "ghost", format: "json", quiet: nil)
              end
            end.first

            parsed = JSON.parse(out)
            assert_equal "unauthorized", parsed["error"]["code"]
            assert_equal "ghost", parsed["error"]["project"]
          end

          def test_rejects_principal_flag
            cmd = Agents.new(topology_service: service)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(project: "atlas", format: "json", quiet: nil, principal: "operator")
            end
            assert_match(/--principal is not supported/, error.message)
          end
        end
      end
    end
  end
end

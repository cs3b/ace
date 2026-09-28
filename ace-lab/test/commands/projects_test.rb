# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class ProjectsTest < Minitest::Test
          def service
            @service ||= Ace::Lab::Organisms::TopologyService.from_config(
              authorized_for_local(topology_config)
            )
          end

          def test_lists_authorized_projects_as_json
            cmd = Projects.new(topology_service: service)

            out, = capture_io do
              cmd.call(format: "json", quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal "ok", parsed["status"]
            assert_equal %w[atlas borealis], parsed["data"]["projects"].map { |p| p["id"] }
          end

          def test_unauthorized_caller_receives_one_error_document_and_nonzero_exit
            config = topology_config
            config["authorization"]["principals"] = {}
            cmd = Projects.new(topology_service: Ace::Lab::Organisms::TopologyService.from_config(config))

            out = capture_io do
              error = assert_raises(Ace::Support::Cli::Error) do
                cmd.call(format: "json", quiet: nil)
              end
              assert_match(/unauthorized/, error.message)
            end.first

            parsed = JSON.parse(out)
            assert_equal "error", parsed["status"]
            assert_equal "unauthorized", parsed["error"]["code"]
          end

          def test_rejects_unsupported_format
            cmd = Projects.new(topology_service: service)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(format: "yaml", quiet: nil)
            end
            assert_match(/only --format json/, error.message)
          end

          def test_rejects_role_flag_as_identity_boundary_violation
            cmd = Projects.new(topology_service: service)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(format: "json", quiet: nil, role: "admin")
            end
            assert_match(/--role is not supported/, error.message)
          end

          def test_quiet_suppresses_stdout_but_keeps_exit_semantics
            cmd = Projects.new(topology_service: service)

            out, = capture_io do
              cmd.call(format: "json", quiet: true)
            end

            assert_empty out
          end
        end
      end
    end
  end
end

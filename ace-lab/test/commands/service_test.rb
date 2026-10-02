# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class ServiceTest < Minitest::Test
          def test_request_emits_json_and_passes_dry_run
            observed = nil
            fake = Object.new
            fake.define_singleton_method(:request) do |**arguments|
              observed = arguments
              {"status" => "ok", "data" => {"outcome" => "accepted", "dry_run" => true}}
            end
            command = Service::Request.new
            command.instance_variable_set(:@service, fake)
            out, = capture_io do
              command.call(project: "ace", assignment: "assignment", attempt: "attempt", operation: "publish",
                input: "input.json", authorization: "decision", request_id: "request", dry_run: true)
            end
            assert_equal true, JSON.parse(out).dig("data", "dry_run")
            assert_equal true, observed[:dry_run]
            assert_equal "request", observed[:request_id]
          end

          def test_status_prints_classified_error_and_exits_nonzero
            fake = Object.new
            fake.define_singleton_method(:status) do |request_id:|
              {"status" => "error", "error" => {"code" => "missing", "message" => "#{request_id} missing"}}
            end
            command = Service::Status.new
            command.instance_variable_set(:@service, fake)
            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) { command.call(request: "unknown", format: "json") }
            end.first
            assert_equal "missing", JSON.parse(out).dig("error", "code")
          end
        end
      end
    end
  end
end

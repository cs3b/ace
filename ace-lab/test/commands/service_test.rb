# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class ServiceTest < Minitest::Test
          def test_ordinary_mode_routes_request_and_status_to_the_ordinary_producer
            requests = []
            producer = Object.new
            producer.define_singleton_method(:request) do |**arguments|
              requests << arguments
              {"status" => "ok", "data" => {"schema" => "ace.lab.service.ordinary-merge-ack/v1"}}
            end
            statuses = []
            producer.define_singleton_method(:status) do |**arguments|
              statuses << arguments
              {"status" => "ok", "data" => {"schema" => "ace.lab.service.ordinary-merge-status/v1"}}
            end
            command = Service::Request.new
            command.instance_variable_set(:@ordinary_producer, producer)
            out = capture_io do
              command.call(project: "atlas", assignment: "a", attempt: "t", operation: "merge",
                input: "input.json", authorization: "decision", request_id: "request",
                mode: "ordinary-merge", queue_entry: "010")
            end.first
            assert_equal "ace.lab.service.ordinary-merge-ack/v1", JSON.parse(out).dig("data", "schema")
            assert_equal "010", requests.last.fetch(:queue_entry)

            status_command = Service::Status.new
            status_command.instance_variable_set(:@ordinary_producer, producer)
            out = capture_io do
              status_command.call(request: "request", mode: "ordinary-merge", format: "json",
                reference: "fmr1-#{"A" * 40}", project: "atlas", assignment: "a", attempt: "t",
                queue_entry: "010", input_digest: "e" * 64)
            end.first
            assert_equal "ace.lab.service.ordinary-merge-status/v1", JSON.parse(out).dig("data", "schema")
            assert_equal "fmr1-#{"A" * 40}", statuses.last.fetch(:reference)
          end

          def test_unknown_request_mode_refuses_with_the_ordinary_invalid_request_envelope
            command = Service::Request.new
            command.instance_variable_set(:@ordinary_producer, Object.new)
            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                command.call(project: "atlas", assignment: "a", attempt: "t", operation: "merge",
                  input: "input.json", authorization: "decision", request_id: "request", mode: "rebase")
              end
            end.first
            refusal = JSON.parse(out)
            assert_equal "error", refusal.fetch("status")
            assert_equal "ordinary_merge_invalid_request", refusal.dig("error", "code")
            assert_equal "ace.lab.service.ordinary-merge-refusal/v1", refusal.dig("error", "schema")
            assert_equal "request", refusal.dig("error", "request_id")
          end

          def test_unknown_status_mode_refuses_with_the_ordinary_status_error_envelope
            command = Service::Status.new
            command.instance_variable_set(:@ordinary_producer, Object.new)
            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                command.call(request: "request", mode: "rebase", format: "json",
                  reference: "fmr1-#{"A" * 40}", project: "atlas", assignment: "a", attempt: "t",
                  queue_entry: "010", input_digest: "e" * 64)
              end
            end.first
            refusal = JSON.parse(out)
            assert_equal "ordinary_merge_invalid_request", refusal.dig("error", "code")
            assert_equal "ace.lab.service.ordinary-merge-status-error/v1", refusal.dig("error", "schema")
          end

          def test_ordinary_mode_with_unknown_selector_stays_an_ordinary_refusal
            producer = Object.new
            producer.define_singleton_method(:request) do |**arguments|
              {"status" => "error", "error" => {
                "schema" => "ace.lab.service.ordinary-merge-refusal/v1",
                "code" => "ordinary_merge_invalid_request",
                "message" => "unknown request selector: mapping",
                "request_id" => "request", "input_digest" => nil
              }}
            end
            command = Service::Request.new
            command.instance_variable_set(:@ordinary_producer, producer)
            out = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                command.call(project: "atlas", assignment: "a", attempt: "t", operation: "merge",
                  input: "input.json", authorization: "decision", request_id: "request",
                  mode: "ordinary-merge", queue_entry: "010", mapping: "mapping")
              end
            end.first
            assert_equal "ordinary_merge_invalid_request", JSON.parse(out).dig("error", "code")
          end

          def test_identity_flags_are_rejected_before_any_producer_use
            command = Service::Request.new
            error = assert_raises(Ace::Support::Cli::Error) do
              capture_io do
                command.call(project: "atlas", assignment: "a", attempt: "t", operation: "merge",
                  input: "input.json", authorization: "decision", request_id: "request",
                  mode: "ordinary-merge", queue_entry: "010", role: "overseer")
              end
            end
            assert_includes error.message, "--role is not supported"
          end
        end
      end
    end
  end
end

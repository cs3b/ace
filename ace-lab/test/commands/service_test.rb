# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module CLI
      module Commands
        class ServiceTest < Minitest::Test
          def setup
            @ordinary = Object.new
            @ordinary.define_singleton_method(:selected?) { |_| false }
          end

          def test_request_emits_json_and_passes_dry_run
            observed = nil
            fake = Object.new
            fake.define_singleton_method(:request) do |**arguments|
              observed = arguments
              {"status" => "ok", "data" => {"outcome" => "accepted", "dry_run" => true}}
            end
            command = Service::Request.new
            command.instance_variable_set(:@service, fake)
            command.instance_variable_set(:@protected_service, @ordinary)
            out, = capture_io do
              command.call(project: "ace", assignment: "assignment", attempt: "attempt", operation: "publish",
                input: "input.json", authorization: "decision", request_id: "request", dry_run: true)
            end
            assert_equal true, JSON.parse(out).dig("data", "dry_run")
            assert_equal true, observed[:dry_run]
            assert_equal "request", observed[:request_id]
          end

          def test_protected_selection_and_submission_share_one_loaded_context
            constructions = 0
            selections = []
            adapter = Object.new
            adapter.define_singleton_method(:selected?) { |options| selections << options; true }
            adapter.define_singleton_method(:request) { |**arguments| selections << arguments; {"status" => "ok", "data" => {}} }
            factory = -> { constructions += 1; adapter }
            command = Service::Request.new
            command.instance_variable_set(:@service, Object.new) # local execution has no request method
            Organisms::ProtectedServiceRequest.stub(:new, factory) do
              capture_io do
                command.call(project: "project", assignment: "assignment", attempt: "attempt", operation: "merge",
                  input: "input.json", authorization: "approval", request_id: "request", mapping: "mapping")
              end
            end
            assert_equal 1, constructions
            assert_equal 2, selections.size
            assert_equal "mapping", selections.last.fetch(:mapping)
          end

          def test_status_prints_classified_error_and_exits_nonzero
            fake = Object.new
            fake.define_singleton_method(:status) do |request_id:|
              {"status" => "error", "error" => {"code" => "missing", "message" => "#{request_id} missing"}}
            end
            command = Service::Status.new
            command.instance_variable_set(:@service, fake)
            command.instance_variable_set(:@protected_service, @ordinary)
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

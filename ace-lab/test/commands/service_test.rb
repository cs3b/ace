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

          def registered_call(name, command, arguments)
            original, = Ace::Lab::CLI.resolve(name.split)
            Ace::Lab::CLI.register(name, command)
            Ace::Lab::CLI.start(name.split + arguments)
          ensure
            Ace::Lab::CLI.register(name, original) if original
          end

          def test_registered_protected_request_and_status_emit_one_json_refusal_not_raw_errors
            [["service request", Service::Request.new, "request", ArgumentError.new("invalid scoped selectors"),
              %w[--project project --assignment assignment --attempt attempt --operation merge --input unused.json --authorization approval --request-id request --mapping mapping]],
              ["service status", Service::Status.new, "status", Ace::Assign::AttemptErrors::EvidenceUnavailable.new("original mapping unavailable"), %w[--request request --mapping mapping]],
              ["service status", Service::Status.new, "status", Ace::Runtime::RuntimeUnavailableError.new("protected status deadline expired"), %w[--request request --mapping mapping]]].each do |name, command, method, error, arguments|
              adapter = Object.new
              adapter.define_singleton_method(:selected?) { |_| true }
              adapter.define_singleton_method(method) { |**_| raise error }
              command.instance_variable_set(:@protected_service, adapter)
              command.instance_variable_set(:@service, Object.new)
              output, stderr = capture_io do
                classified = assert_raises(Ace::Support::Cli::Error) { registered_call(name, command, arguments) }
                assert_includes classified.message, error.message
              end
              assert_empty stderr
              assert_equal 1, output.lines.size
              refusal = JSON.parse(output)
              assert_equal "error", refusal.fetch("status")
              assert_includes %w[protected_service_refused protected_service_unavailable], refusal.dig("error", "code")
              assert_equal error.message, refusal.dig("error", "message")
            end
          end

          def test_registered_empty_artifact_digest_is_refused_before_original_fetch
            context = Object.new
            context.define_singleton_method(:protected_participant?) { false }
            context.define_singleton_method(:mapping_hint?) { false }
            context.define_singleton_method(:resolve) { |**_| flunk "invalid digest cannot fetch prepared input" }
            command = Service::Status.new
            command.instance_variable_set(:@protected_service, Organisms::ProtectedServiceRequest.new(context: context))
            output, stderr = capture_io do
              assert_raises(Ace::Support::Cli::Error) do
                registered_call("service status", command, ["--request", "request", "--project", "project", "--assignment", "assignment",
                  "--attempt", "attempt", "--mapping", "mapping", "--scope", "1", "--candidate-head", "a" * 40,
                  "--candidate-generation", "1", "--input-digest", "b" * 64, "--target", "resource", "--artifact-digest", ""])
              end
            end
            assert_empty stderr
            assert_empty output
          end

          def test_installed_context_load_failure_is_classified_without_local_fallback
            command = Service::Status.new
            command.instance_variable_set(:@service, Object.new)
            output, stderr = capture_io do
              Ace::Assign::Authority::ProtectedAssignmentContext.stub(:load, -> { raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "installed descriptor unreadable" }) do
                assert_raises(Ace::Support::Cli::Error) { registered_call("service status", command, %w[--request request]) }
              end
            end
            assert_empty stderr
            assert_equal "protected_service_unavailable", JSON.parse(output).dig("error", "code")
          end

          def test_registered_removed_or_corrupt_installed_descriptor_never_uses_local_status
            deployment = Ace::Assign::Authority::Deployment
            history = Ace::Assign::Authority::DeploymentHistory
            original_lstat = File.method(:lstat)
            %i[removed corrupt].each do |mode|
              owner = Object.new
              owner.define_singleton_method(:read_path!) do |path, limit:|
                raise "wrong installed descriptor" unless path == deployment::PATH && limit == 65_536
                raise Errno::ENOENT, path if mode == :removed
                raw = "PRIVATE_DESCRIPTOR_MARKER_invalid_json"
                [raw, {"path" => path, "bytes" => raw.bytesize, "sha256" => Digest::SHA256.hexdigest(raw)}]
              end
              owner.define_singleton_method(:with) { |&block| block.call(owner) }
              presence = lambda do |path|
                if path == deployment::PATH
                  raise Errno::ENOENT, path if mode == :removed
                  next Object.new
                end
                next Object.new if path == history::PATH
                original_lstat.call(path)
              end
              command = Service::Status.new
              command.instance_variable_set(:@service, Object.new) # no local status method
              output, stderr = capture_io do
                File.stub(:lstat, presence) do
                  Ace::Runtime::Molecules::ProtectedArtifactSet.stub(:new, owner) do
                    assert_raises(Ace::Support::Cli::Error) { registered_call("service status", command, %w[--request request]) }
                  end
                end
              end
              assert_empty stderr
              assert_equal "protected_service_unavailable", JSON.parse(output).dig("error", "code")
              refute_includes output + stderr, "PRIVATE_DESCRIPTOR_MARKER"
              assert_equal "protected installed selection unavailable", JSON.parse(output).dig("error", "message") if mode == :corrupt
            end
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

# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "openssl"

module Ace
  module Herdr
    module CLI
      module Commands
        class InboxTest < Minitest::Test
          THREAD = "0123abcd-0000-4000-8000-000000000001"

          def test_cli_shared_pair_contract_accepts_native_and_refuses_mixed_targets
            consumer = Object.new.extend(Ace::Herdr::CLI::Commands::Runtime)
            ref = consumer.send(:resolve_ref, " $0 ", " %0 ")
            assert_equal ["$0", "%0"], [ref.session, ref.pane]
            assert_raises(Ace::Hitl::Providers::InvalidRefError) do
              consumer.send(:resolve_ref, "$0", "p1")
            end
          end

          class Executor
            def pane_get_bounded(_pane)
              Molecules::ExecutionResult.new(
                stdout: JSON.generate("result" => {"pane" => {
                  "pane_id" => "p1", "workspace_id" => "ws1", "terminal_id" => "term-1",
                  "agent" => "codex", "agent_status" => "busy",
                  "agent_session" => {"agent" => "codex", "kind" => "id", "value" => THREAD}
                }}), stderr: "", success: true, exit_code: 0
              )
            end
          end

          class Native
            attr_reader :calls
            attr_accessor :result

            def initialize
              @calls = []
              @result = {"accepted" => true, "stdout" => "queued"}
            end

            # This state-machine fixture injects the native boundary; real correlation is tested in the service composition.
            def prepare_submission(**_arguments) = nil

            def submit(**options)
              @calls << options
              result
            end
          end

          def setup
            @dir = Dir.mktmpdir("ace-herdr-inbox-cli")
            @receipt_key = OpenSSL::PKey::RSA.generate(2048)
            key_path = File.join(@dir, "receipt-public.pem")
            File.write(key_path, @receipt_key.public_key.to_pem)
            @native = Native.new
            entry = Ace::Runtime::Molecules::ProtectedTaskContextEntry.new(stat: ->(path) {
              allowed = [Ace::Runtime::Molecules::ProtectedTaskContextEntry::PATH,
                *Ace::Runtime::Molecules::ProtectedTaskContextEntry::PRESENCE_PATHS]
              raise "unexpected installation probe" unless allowed.include?(path)
              raise Errno::ENOENT, path
            })
            @selection = Molecules::ProtectedInboxSelection.new(entry_owner: entry, env: {})
            @command = Inbox.new(executor: Executor.new, native: @native, selection: @selection)
            delivery_path = File.join(@dir, "deliveries")
            @command.define_singleton_method(:config) do
              {"inbox_receipt_public_key" => key_path, "deliveries_dir" => delivery_path}
            end
            File.write(File.join(@dir, "ref.json"), JSON.generate("session" => "ws1", "pane" => "p1"))
            File.write(File.join(@dir, "payload.txt"), "hello")
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def call(operation, **options)
            out, = capture_io { @command.call(operation: operation, event: "inb-12345678", **options) }
            JSON.parse(out)
          end

          def test_even_empty_protected_only_options_refuse_before_local_configuration
            @command.define_singleton_method(:config) { raise "local configuration must not be read" }
            %i[project mapping inbox_context claim_generation assignment mutation expected_generation receipt_key_sha256].each do |key|
              assert_raises(Ace::Support::Cli::Error) { call("status", **{key => ""}) }
            end
          end

          def test_observe_requires_explicit_protected_selection_before_configuration
            @command.define_singleton_method(:config) { raise "local configuration must not be read" }
            assert_raises(Ace::Support::Cli::Error) { call("observe") }
            opts = {project: "project", mapping: "mapping", inbox_context: "ctx", assignment: "assignment", attempt: "attempt1", claim_generation: 1}
            assert_raises(Ace::Support::Cli::Error) { call("observe", **opts) }
            [0, -1, "1", nil].each do |generation|
              assert_raises(Ace::Support::Cli::Error) { call("observe", **opts.merge(claim_generation: generation)) }
            end
            assert_empty @native.calls
          end

          def test_enqueue_status_deliver_across_separate_command_calls
            queued = call("enqueue", attempt: "att-1", ref: File.join(@dir, "ref.json"),
              file: File.join(@dir, "payload.txt"))
            assert_equal "queued", queued["state"]
            assert_equal "att-1", queued["attempt_id"]
            assert_equal "queued", call("status", format: "json")["state"]

            delivered = call("deliver")

            assert_equal "delivered", delivered["state"]
            assert_equal 1, @native.calls.length
            assert_equal delivered["payload_sha256"], delivered.dig("receipt", "payload_sha256")
            assert_equal "delivered", call("status")["state"]
          end

          def test_missing_payload_is_cli_error_before_record_creation
            error = assert_raises(Ace::Support::Cli::Error) do
              call("enqueue", attempt: "att-1", ref: File.join(@dir, "ref.json"), file: "missing.txt")
            end

            assert_match(/missing.txt/, error.message)
            assert_raises(Ace::Support::Cli::Error) { call("status") }
          end

          def test_unreadable_receipt_file_reports_machine_readable_refusal
            call("enqueue", attempt: "att-1", ref: File.join(@dir, "ref.json"),
              file: File.join(@dir, "payload.txt"))
            @native.result = {"accepted" => false, "error" => "stalled"}
            uncertain = call("deliver")
            assert_equal "uncertain", uncertain["state"]
            receipt_path = File.join(@dir, "secret-receipt.json")
            File.write(receipt_path, "{}")
            File.chmod(0o000, receipt_path)

            result = call("reconcile", receipt: receipt_path)

            assert_equal "uncertain", result["state"]
            assert_match(/invalid receipt/, result["reconciliation_refusal"])
          ensure
            File.chmod(0o644, receipt_path)
          end

          def test_reconcile_reports_refusal_then_accepts_matching_observation_after_restart
            call("enqueue", attempt: "att-1", ref: File.join(@dir, "ref.json"),
              file: File.join(@dir, "payload.txt"))
            @native.result = {"accepted" => false, "error" => "stalled"}
            uncertain = call("deliver")
            assert_equal "uncertain", uncertain["state"]
            assert_equal "uncertain", call("reconcile")["state"]
            assert_match(/does not match/, call("reconcile")["reconciliation_refusal"])

            receipt = {"event_id" => uncertain["event_id"], "attempt_id" => "att-1",
              "claim_generation" => uncertain["claim_generation"],
              "payload_sha256" => uncertain["payload_sha256"], "binding" => uncertain["binding"],
              "outcome" => "consumed", "observer" => {"role" => "operator", "id" => "ops-1"},
              "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "session-log:42",
                             "observation" => "acknowledged"}}
            receipt_path = File.join(@dir, "receipt.json")
            File.write(receipt_path, JSON.generate(receipt.merge("attempt_id" => "wrong")))
            unsigned = call("reconcile", receipt: receipt_path)
            assert_equal "uncertain", unsigned["state"]
            assert_match(/invalid receipt/, unsigned["reconciliation_refusal"])
            File.binwrite("#{receipt_path}.sig", @receipt_key.sign(
              OpenSSL::Digest::SHA256.new, File.binread(receipt_path)))
            refused = call("reconcile", receipt: receipt_path)
            assert_equal "uncertain", refused["state"]
            assert_match(/does not match/, refused["reconciliation_refusal"])
            assert_equal "uncertain", call("status")["state"]

            restarted = Inbox.new(executor: Executor.new, native: @native, selection: @selection)
            delivery_path = File.join(@dir, "deliveries")
            trusted_path = File.join(@dir, "receipt-public.pem")
            restarted.define_singleton_method(:config) do
              {"inbox_receipt_public_key" => trusted_path, "deliveries_dir" => delivery_path}
            end
            File.write(receipt_path, JSON.generate(receipt))
            File.binwrite("#{receipt_path}.sig", @receipt_key.sign(
              OpenSSL::Digest::SHA256.new, File.binread(receipt_path)))
            out, = capture_io do
              restarted.call(operation: "reconcile", event: "inb-12345678", receipt: receipt_path)
            end
            assert_equal "completed", JSON.parse(out)["state"]
            assert_equal "completed", call("status")["state"]
            assert_equal 1, @native.calls.length
          end

          def test_reconcile_refuses_a_key_changed_after_enqueue
            call("enqueue", attempt: "att-1", ref: File.join(@dir, "ref.json"),
              file: File.join(@dir, "payload.txt"))
            @native.result = {"accepted" => false, "error" => "stalled"}
            uncertain = call("deliver")
            rogue_key = OpenSSL::PKey::RSA.generate(2048)
            rogue_path = File.join(@dir, "rogue-public.pem")
            File.write(rogue_path, rogue_key.public_key.to_pem)
            delivery_path = File.join(@dir, "deliveries")
            @command.define_singleton_method(:config) do
              {"inbox_receipt_public_key" => rogue_path, "deliveries_dir" => delivery_path}
            end

            receipt = {"event_id" => uncertain["event_id"], "attempt_id" => "att-1",
              "claim_generation" => uncertain["claim_generation"],
              "payload_sha256" => uncertain["payload_sha256"], "binding" => uncertain["binding"],
              "outcome" => "superseded", "observer" => {"role" => "operator", "id" => "rogue"},
              "evidence" => {"kind" => "queue_evicted", "native_reference" => "forged:1",
                             "observation" => "forged eviction"}}
            path = File.join(@dir, "rogue.json")
            File.write(path, JSON.generate(receipt))
            File.binwrite("#{path}.sig", rogue_key.sign(OpenSSL::Digest::SHA256.new, File.binread(path)))

            refused = call("reconcile", receipt: path)
            assert_equal "uncertain", refused["state"]
            assert_match(/differs from the enqueued event/, refused["reconciliation_refusal"])
            assert_equal "uncertain", call("status")["state"]
          end

          def test_reconcile_reports_missing_trusted_key_without_changing_uncertain_state
            call("enqueue", attempt: "att-1", ref: File.join(@dir, "ref.json"),
              file: File.join(@dir, "payload.txt"))
            @native.result = {"accepted" => false, "error" => "stalled"}
            uncertain = call("deliver")
            receipt = {"event_id" => uncertain["event_id"], "attempt_id" => "att-1",
              "claim_generation" => uncertain["claim_generation"],
              "payload_sha256" => uncertain["payload_sha256"], "binding" => uncertain["binding"],
              "outcome" => "consumed", "observer" => {"role" => "operator", "id" => "ops-1"},
              "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "log:1",
                             "observation" => "acknowledged"}}
            path = File.join(@dir, "receipt.json")
            File.write(path, JSON.generate(receipt))
            File.binwrite("#{path}.sig", @receipt_key.sign(
              OpenSSL::Digest::SHA256.new, File.binread(path)))
            File.delete(File.join(@dir, "receipt-public.pem"))

            result = call("reconcile", receipt: path)

            assert_equal "uncertain", result["state"]
            assert_match(/trusted receipt public key is unavailable/, result["reconciliation_refusal"])
            assert_equal uncertain["claim_generation"], call("status")["claim_generation"]
            assert_equal 1, @native.calls.length
          end
        end
      end
    end
  end
end

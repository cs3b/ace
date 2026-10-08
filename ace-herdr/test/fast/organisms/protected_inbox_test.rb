# frozen_string_literal: true
require "test_helper"
require "ace/herdr/organisms/protected_inbox"

module Ace
  module Herdr
    module Organisms
      class ProtectedInboxTest < Minitest::Test
        def test_retained_consumed_signature_after_stop_does_not_open_any_native_endpoint
          Dir.mktmpdir do |root|
            key = OpenSSL::PKey::RSA.new(1024)
            path = File.join(root, "public.pem")
            File.write(path, key.public_to_pem)
            pane = {"pane_id" => "p1", "workspace_id" => "w1", "terminal_id" => "original",
              "agent" => "codex", "agent_status" => "busy", "agent_session" => {"agent" => "codex",
                "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"}}
            executor = Object.new
            executor.define_singleton_method(:pane_get_bounded) do |_pane|
              Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => pane}),
                stderr: "", success: true, exit_code: 0)
            end
            native = Object.new
            # Only the initial delivery boundary is injected. Retained signed
            # reconciliation below must never prepare or contact a native client.
            native.define_singleton_method(:prepare_submission) { |**_args| nil }
            native.define_singleton_method(:submit) { |**args| {"accepted" => true} }
            original = Inbox.new(executor: executor, native: native, deliveries_dir: root, receipt_public_key: key.public_key)
            original.enqueue(event: "event", attempt: "attempt", ref: {"session" => "w1", "pane" => "p1"}, payload: "message")
            record = original.deliver(event: "event")
            receipt = record.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
              "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "observer"},
              "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "native-log:1", "observation" => "observed acknowledgement"})
            bytes = JSON.generate(receipt)
            kernel = Object.new
            kernel.define_singleton_method(:supported!) { raise "native endpoint must not be opened" }
            context = {"receipt_public_key" => path, "deliveries_dir" => root, "pi_queue_client" => "/absent/identity-client"}
            stage = {"server_identity" => {"pid" => 1}, "socket_identity" => [1, 2, 3], "workspace_id" => "w1"}
            factory = ProtectedInbox.build(context: context, mapping: {"native" => {}}, native: stage, kernel: kernel)
            registration = record.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256")
            signature = key.sign(OpenSSL::Digest::SHA256.new, bytes)
            assert_raises(ValidationError) do
              factory.verify_reconciliation(event: "event", receipt: receipt, signed_bytes: bytes,
                signature: signature, expected_registration: registration)
            end
            2.times do
              result = factory.reconcile(event: "event", receipt: receipt, signed_bytes: bytes,
                signature: signature, expected_registration: registration)
              assert_equal "completed", result.fetch("state")
              refute result.key?("reconciliation_refusal")
            end
            [nil, {}, registration.merge("extra" => true), registration.merge("payload_sha256" => "bad")].each do |invalid|
              assert_raises(ValidationError) do
                factory.verify_reconciliation(event: "event", receipt: receipt, signed_bytes: bytes,
                  signature: signature, expected_registration: invalid)
              end
            end
            before = Dir.glob(File.join(root, "**", "*"), File::FNM_DOTMATCH)
              .select { |entry| File.file?(entry) }.to_h { |entry| [entry, File.binread(entry)] }
            verified = factory.verify_reconciliation(event: "event", receipt: receipt,
              signed_bytes: bytes, signature: signature, expected_registration: registration)
            assert_equal "completed", verified.fetch("state")
            refute verified.key?("reconciliation_refusal")
            assert_equal before, before.keys.to_h { |entry| [entry, File.binread(entry)] }
            wrong = factory.verify_reconciliation(event: "event", receipt: receipt,
              signed_bytes: bytes, signature: "forged", expected_registration: registration)
            assert wrong.fetch("reconciliation_refusal")
            assert_raises(ValidationError) do
              factory.verify_reconciliation(event: "event", receipt: receipt, signed_bytes: bytes,
                signature: signature, expected_registration: registration.merge("payload_sha256" => "a" * 64))
            end
            lock = Molecules::DeliveryRecordStore.lock_path(root, "event")
            File.unlink(lock)
            assert_raises(ValidationError) { factory.retained_status(event: "event") }
            assert_raises(ValidationError) do
              factory.verify_reconciliation(event: "event", receipt: receipt, signed_bytes: bytes,
                signature: signature, expected_registration: registration)
            end
            refute File.exist?(lock)
          end
        end

        def test_pane_reader_uses_only_fixed_control_and_original_requested_pane
          control = Object.new
          calls = []
          control.define_singleton_method(:request) { |method, params| calls << [method, params]; {"pane" => {"pane_id" => params.fetch("pane_id")}} }
          reader = ProtectedInbox::PaneReader.new(control)
          assert_equal "p1", reader.pane_get_bounded("p1").parsed_json.dig("result", "pane", "pane_id")
          assert_equal [["pane.get", {"pane_id" => "p1"}]], calls
          refute reader.respond_to?(:agent_prompt_bounded)
        end

        def test_pi_identity_uses_explicit_installed_client_and_empty_environment
          Dir.mktmpdir do |root|
            client = File.join(root, "identity")
            File.write(client, "#!/bin/sh\n[ \"$1\" = --identity ] || exit 3\n[ -z \"$ACE_HERDR_PI_QUEUE_CLIENT\" ] || exit 4\nprintf '%s' '{\"session_id\":\"original\"}'\n")
            File.chmod(0700, client)
            previous = ENV["ACE_HERDR_PI_QUEUE_CLIENT"]
            ENV["ACE_HERDR_PI_QUEUE_CLIENT"] = "/foreign/client"
            identity = ProtectedInbox::PiIdentity.new(client)
            assert_equal "original", identity.pi_identity
            refute identity.respond_to?(:submit)
          ensure
            ENV["ACE_HERDR_PI_QUEUE_CLIENT"] = previous
          end
        end
      end
    end
  end
end

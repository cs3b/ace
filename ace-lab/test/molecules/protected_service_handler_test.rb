# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "etc"
require "ace/lab/molecules/protected_service_handler"

module Ace
  module Lab
    class ProtectedServiceHandlerTest < Minitest::Test
      def with_handler
        Dir.mktmpdir("ace-handler-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0o700, root)
          request = {"request_id" => "request-1", "input_digest" => "d" * 64}
          envelope = {"version" => 1, "request" => request, "input" => {"target" => "fixture"}}
          yield Molecules::ProtectedServiceHandler.new, root, envelope
        end
      end

      def operation(script)
        {"executor_uid" => Process.uid, "argv" => ["/bin/sh", "-c", script]}
      end

      def test_real_handler_exact_receipt_and_closed_environment
        with_handler do |handler, root, envelope|
          reply = JSON.generate(envelope.fetch("request").merge("outcome" => "succeeded", "evidence" => []))
          script = "test -z \"${ACE_HANDLER_UNTRUSTED_ENV+x}\" || exit 9; printf '%s' '#{reply}'"
          previous = ENV["ACE_HANDLER_UNTRUSTED_ENV"]
          ENV["ACE_HANDLER_UNTRUSTED_ENV"] = "fixture-only"
          result = handler.execute(operation: operation(script), envelope: envelope, candidate_root: root)
          assert_equal "succeeded", result.fetch("outcome")
          assert_equal "request-1", result.fetch("request_id")
        ensure
          previous ? ENV["ACE_HANDLER_UNTRUSTED_ENV"] = previous : ENV.delete("ACE_HANDLER_UNTRUSTED_ENV")
        end
      end

      def test_receiver_owned_process_group_cleanup_stops_background_writer
        with_handler do |handler, root, envelope|
          reply = JSON.generate(envelope.fetch("request").merge("outcome" => "succeeded", "evidence" => []))
          script = "(sleep 0.2; printf late > late-marker) </dev/null >/dev/null 2>/dev/null & printf '%s' '#{reply}'"
          assert_equal "succeeded", handler.execute(operation: operation(script), envelope: envelope, candidate_root: root).fetch("outcome")
          sleep 0.3
          refute File.exist?(File.join(root, "late-marker"))
        end
      end

      def test_noisy_or_mismatched_receipt_never_reports_success
        with_handler do |handler, root, envelope|
          assert_nil handler.execute(operation: operation("head -c 17000 /dev/zero"), envelope: envelope, candidate_root: root)
          assert_nil handler.execute(operation: operation("printf '{}'"), envelope: envelope, candidate_root: root)
          wrong = operation("printf '{}'").merge("executor_uid" => Process.uid + 1)
          assert_raises(SecurityError) { handler.execute(operation: wrong, envelope: envelope, candidate_root: root) }
        end
      end
    end
  end
end

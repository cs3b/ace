# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"
require "etc"
require "ace/lab/molecules/protected_service_handler"

module Ace
  module Lab
    class ProtectedServiceHandlerCleanupTest < Minitest::Test
      def with_handler
        Dir.mktmpdir("ace-handler-cleanup-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0o700, root)
          request = {"request_id" => "request-1", "input_digest" => "d" * 64}
          envelope = {"version" => 1, "request" => request, "input" => {"target" => "fixture"}}
          operation = {"executor_uid" => Process.uid, "argv" => ["fixed-selected-handler"]}
          yield Molecules::ProtectedServiceHandler.new, root, envelope, operation
        end
      end

      def test_actual_handler_delegates_separate_caps_closed_environment_and_original_group_cleanup
        with_handler do |handler, root, envelope, operation|
          response = envelope.fetch("request").merge("outcome" => "succeeded", "evidence" => [])
          status = Object.new
          status.define_singleton_method(:success?) { true }
          runner = lambda do |argv, **options|
            assert_equal operation.fetch("argv"), argv
            assert_equal JSON.generate(envelope), options.fetch(:stdin_data)
            assert_equal 30, options.fetch(:timeout_s)
            assert_equal 16 * 1024, options.fetch(:output_limit)
            assert_equal 8 * 1024, options.fetch(:stderr_limit)
            assert_equal true, options.fetch(:cleanup_group)
            assert_equal root, options.fetch(:chdir)
            assert_equal({"PATH" => "/usr/bin:/bin", "LANG" => "C.UTF-8", "HOME" => root}, options.fetch(:environment))
            Ace::Herdr::Molecules::BoundedProcess::Result.new(JSON.generate(response), "", status, false)
          end
          Ace::Herdr::Molecules::BoundedProcess.stub(:call, runner) do
            assert_equal response, handler.execute(operation: operation, envelope: envelope, candidate_root: root)
          end
        end
      end

      def test_unconfirmed_cleanup_and_timeout_never_return_a_handler_receipt
        with_handler do |handler, root, envelope, operation|
          [Timeout::Error.new("controlled timeout"),
            Ace::Herdr::Molecules::BoundedProcess::PostLaunchError.new("unconfirmed cleanup")].each do |error|
            Ace::Herdr::Molecules::BoundedProcess.stub(:call, ->(*) { raise error }) do
              assert_nil handler.execute(operation: operation, envelope: envelope, candidate_root: root)
            end
          end
        end
      end
    end
  end
end

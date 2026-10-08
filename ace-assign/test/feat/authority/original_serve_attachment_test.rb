# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/cli/commands/authority/serve"

module Ace
  module Assign
    class OriginalServeAttachmentTest < AceAssignTestCase
      Serve = CLI::Commands::Authority::Serve
      def launch
        owner = Authority::LaunchLifecycle.allocate
        owner.define_singleton_method(:close) { @closed = true }
        owner.define_singleton_method(:closed?) { @closed }
        owner
      end

      def test_original_scope_is_thread_local_and_expires_on_exception
        owner = launch
        assert_raises(IOError) do
          Serve.with_original_launch(owner) do
            assert_same owner, Thread.current[:ace_assign_original_launch_owner]
            assert_nil Thread.new { Thread.current[:ace_assign_original_launch_owner] }.value
            raise IOError, "selected executable failed"
          end
        end
        assert owner.closed?
        assert_nil Thread.current[:ace_assign_original_launch_owner]
      end

      def test_conflicting_nested_owner_cannot_replace_original
        original, replacement = launch, launch
        Serve.with_original_launch(original) do
          assert_raises(ArgumentError) { Serve.with_original_launch(replacement) { flunk } }
          assert_same original, Thread.current[:ace_assign_original_launch_owner]
          refute replacement.closed?
        end
        assert original.closed?
      end

      def test_attached_descriptor_cannot_be_substituted_by_loaded_history
        owner = launch
        installed = Object.new
        original = Object.new
        original.define_singleton_method(:artifact_reference) { {"sha256" => "a" * 64} }
        installed.define_singleton_method(:artifact_reference) { {"sha256" => "b" * 64} }
        owner.instance_variable_set(:@deployment, original)
        owner.instance_variable_set(:@deployment_history, original)
        Serve.with_original_launch(owner) do
          Authority::Deployment.stub(:load, installed) do
            Authority::DeploymentHistory.stub(:load, original) do
              assert_raises(Ace::Support::Cli::Error) { Serve.new.call(authority: "authority") }
            end
          end
        end
        assert owner.closed?
      end

      def test_untyped_owner_cannot_attach
        assert_raises(ArgumentError) { Serve.with_original_launch(Object.new) { flunk } }
        assert_nil Thread.current[:ace_assign_original_launch_owner]
      end
    end
  end
end

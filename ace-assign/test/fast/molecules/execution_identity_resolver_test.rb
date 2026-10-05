# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Assign
    class ExecutionIdentityResolverTest < AceAssignTestCase
      def with_service_env(value)
        previous = ENV["ACE_TEST_SERVICE_IDENTITY"]
        ENV["ACE_TEST_SERVICE_IDENTITY"] = value
        yield
      ensure
        if previous.nil?
          ENV.delete("ACE_TEST_SERVICE_IDENTITY")
        else
          ENV["ACE_TEST_SERVICE_IDENTITY"] = previous
        end
      end

      def test_local_adapter_resolves_kernel_account_as_coordinator
        identity = Molecules::ExecutionIdentityResolver.new(adapter: "local").resolve

        assert_equal Etc.getpwuid(Process.euid).name, identity.actor
        assert_equal "coordinator", identity.role
        assert_includes identity.runtime, "local:"
        assert Molecules::ExecutionIdentityResolver.new(adapter: "local").trusted?(identity)
      end

      def test_native_runtime_produces_owner_without_changing_authorization_identity
        binding = {"runtime" => "tmux", "pane" => "%2", "process_identity" => {"pid" => 123}}
        native = Object.new
        native.define_singleton_method(:context) { {in_runtime: true, pane: "%2"} }
        native.define_singleton_method(:process_binding) do |pane:, caller_pid:|
          raise "wrong boundary" unless pane == "%2" && caller_pid == 456
          binding
        end
        runtime = Object.new
        runtime.define_singleton_method(:detect) { |env:| :tmux }
        runtime.define_singleton_method(:resolve) { |_name| native }
        identity = Molecules::ExecutionIdentityResolver.new(adapter: "local", runtime_resolver: runtime,
          caller_pid: 456, env: {"ACE_RUNTIME" => "tmux"}).resolve
        assert_equal 123, identity.process_pid
        assert_equal binding, identity.runtime_binding
        assert_equal "coordinator", identity.role
        assert_equal "local", identity.adapter
        assert_includes identity.runtime, "local:"
      end

      def with_login_environment(user, logname)
        previous = [ENV["USER"], ENV["LOGNAME"]]
        ENV["USER"] = user
        ENV["LOGNAME"] = logname
        yield
      ensure
        ENV["USER"] = previous[0]
        ENV["LOGNAME"] = previous[1]
      end

      def test_local_account_ignores_misleading_login_and_environment
        expected = Etc.getpwuid(Process.euid).name
        with_login_environment("forged-user", "forged-logname") do
          Etc.stub(:getlogin, "different-login") do
            assert_equal expected, Molecules::ExecutionIdentityResolver.new(adapter: "local").resolve.actor
          end
        end
      end

      def test_local_account_does_not_require_login_or_environment
        expected = Etc.getpwuid(Process.euid).name
        with_login_environment(nil, nil) do
          Etc.stub(:getlogin, nil) do
            assert_equal expected, Molecules::ExecutionIdentityResolver.new(adapter: "local").resolve.actor
          end
        end
      end

      def test_local_adapter_refuses_unresolved_or_invalid_account
        resolver = Molecules::ExecutionIdentityResolver.new(adapter: "local")
        entries = [nil, Struct.new(:uid, :name).new(Process.euid, ""),
          Struct.new(:uid, :name).new(Process.euid + 1, "other")]
        entries.each do |entry|
          Etc.stub(:getpwuid, entry) do
            error = assert_raises(AttemptErrors::UnauthorizedIdentity) { resolver.resolve }
            assert_equal 5, error.exit_code
          end
        end
        [ArgumentError.new("missing account"), Errno::EIO.new].each do |failure|
          Etc.stub(:getpwuid, ->(*) { raise failure }) do
            assert_raises(AttemptErrors::UnauthorizedIdentity) { resolver.resolve }
          end
        end
      end

      def test_local_adapter_refuses_real_effective_uid_mismatch_before_lookup
        Process.stub(:uid, Process.euid + 1) do
          Etc.stub(:getpwuid, ->(*) { flunk "unsupported identity must refuse before account lookup" }) do
            error = assert_raises(AttemptErrors::UnauthorizedIdentity) do
              Molecules::ExecutionIdentityResolver.new(adapter: "local").resolve
            end
            assert_equal 5, error.exit_code
          end
        end
      end

      def test_local_adapter_refuses_credentials_changed_during_resolution
        original_uid = Process.euid
        observed_uid = original_uid
        entry = Etc.getpwuid(original_uid)
        Process.stub(:uid, -> { observed_uid }) do
          Process.stub(:euid, -> { observed_uid }) do
            Etc.stub(:getpwuid, ->(*) { observed_uid += 1; entry }) do
              assert_raises(AttemptErrors::UnauthorizedIdentity) do
                Molecules::ExecutionIdentityResolver.new(adapter: "local").resolve
              end
            end
          end
        end
      end

      def test_local_adapter_refuses_credentials_changed_while_resolving_native_binding
        observed_uid = Process.euid
        native = Object.new
        native.define_singleton_method(:context) { {in_runtime: true, pane: "%2"} }
        native.define_singleton_method(:process_binding) do |**|
          observed_uid += 1
          {"runtime" => "tmux", "pane" => "%2", "process_identity" => {"pid" => 123}}
        end
        runtime = Object.new
        runtime.define_singleton_method(:detect) { |env:| :tmux }
        runtime.define_singleton_method(:resolve) { |_name| native }
        Process.stub(:uid, -> { observed_uid }) do
          Process.stub(:euid, -> { observed_uid }) do
            assert_raises(AttemptErrors::UnauthorizedIdentity) do
              Molecules::ExecutionIdentityResolver.new(adapter: "local", runtime_resolver: runtime,
                env: {"ACE_RUNTIME" => "tmux"}).resolve
            end
          end
        end
      end

      def test_unknown_adapter_fails_closed
        error = assert_raises(AttemptErrors::UnauthorizedIdentity) do
          Molecules::ExecutionIdentityResolver.new(adapter: "flag-magic").resolve
        end
        assert_includes error.message, "flag-magic"
      end

      def test_service_adapter_parses_trusted_executor_identity
        with_service_env({ "actor" => "herdr-worker-1", "role" => "service", "runtime" => "herdr:session-7" }.to_json) do
          resolver = Molecules::ExecutionIdentityResolver.new(adapter: "service", service_env: "ACE_TEST_SERVICE_IDENTITY")
          identity = resolver.resolve

          assert_equal "herdr-worker-1", identity.actor
          assert_equal "service", identity.role
          assert_equal "herdr:session-7", identity.runtime
          assert resolver.trusted?(identity)
        end
      end

      def test_service_worker_role_is_untrusted_but_resolvable
        with_service_env({ "actor" => "fork-9", "role" => "worker", "runtime" => "fork:9" }.to_json) do
          resolver = Molecules::ExecutionIdentityResolver.new(adapter: "service", service_env: "ACE_TEST_SERVICE_IDENTITY")
          identity = resolver.resolve

          assert_equal "worker", identity.role
          refute resolver.trusted?(identity)
        end
      end

      def test_service_identity_malformed_or_missing_fails_closed
        with_service_env("not-json") do
          resolver = Molecules::ExecutionIdentityResolver.new(adapter: "service", service_env: "ACE_TEST_SERVICE_IDENTITY")
          assert_raises(AttemptErrors::UnauthorizedIdentity) { resolver.resolve }
        end

        with_service_env("") do
          resolver = Molecules::ExecutionIdentityResolver.new(adapter: "service", service_env: "ACE_TEST_SERVICE_IDENTITY")
          assert_raises(AttemptErrors::UnauthorizedIdentity) { resolver.resolve }
        end

        with_service_env({ "actor" => "x", "role" => "emperor", "runtime" => "r" }.to_json) do
          resolver = Molecules::ExecutionIdentityResolver.new(adapter: "service", service_env: "ACE_TEST_SERVICE_IDENTITY")
          assert_raises(AttemptErrors::UnauthorizedIdentity) { resolver.resolve }
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "inbox"
require_relative "../molecules/protected_native_control"
require_relative "../molecules/herdr_executor"
require_relative "../molecules/native_queue_executor"
require_relative "../molecules/bounded_process"

module Ace
  module Herdr
    module Organisms
      # Fixed construction for the canonical authority consumer. Callers of the
      # public protocol cannot inject this factory or its collaborators.
      module ProtectedInbox
        class PaneReader
          def initialize(control)
            @control = control
          end

          def pane_get_bounded(pane)
            result = @control.request("pane.get", {"pane_id" => pane})
            Molecules::ExecutionResult.new(stdout: JSON.generate({"result" => result}), stderr: "",
              success: true, exit_code: 0)
          rescue Ace::Runtime::RuntimeUnavailableError
            raise ExecutorUnavailableError, "original protected native endpoint is unavailable"
          end
        end

        class PiIdentity
          def initialize(client)
            runner = lambda do |argv, stdin_data:, timeout_s:|
              unless argv == [client, "--identity"] && stdin_data.empty?
                raise ExecutorUnavailableError, "protected inbox permits identity inspection only"
              end
              result = Molecules::BoundedProcess.call(argv, stdin_data: stdin_data,
                timeout_s: timeout_s, environment: {})
              raise ExecutorError, "Pi identity output is oversized" if result.oversized
              [result.stdout, result.stderr, result.status]
            end
            @native = Molecules::NativeQueueExecutor.new(pi_client: client, runner: runner)
          end

          def pi_identity
            @native.pi_identity
          end
        end

        module_function

        # The Assign resolver has verified context paths/key/client. native is
        # the immutable canonical stage, not current process discovery. Endpoint
        # liveness is checked lazily only if Inbox actually observes replacement.
        def build(context:, mapping:, native:, kernel: Ace::Runtime::Molecules::ProtectedLinux.new)
          native_fields = %w[server_identity socket_identity workspace_id]
          unless native.is_a?(Hash) && native_fields.all? { |key| native.key?(key) }
            raise ValidationError, "canonical native stage is unavailable"
          end
          fixed = JSON.parse(JSON.generate(mapping))
          fixed["native"].merge!(native.slice(*native_fields))
          control = Molecules::ProtectedNativeControl.new(mapping: fixed, kernel: kernel)
          key = OpenSSL::PKey.read(File.binread(context.fetch("receipt_public_key")))
          unless key.is_a?(OpenSSL::PKey::RSA) && !key.private?
            raise ValidationError, "protected inbox requires a public RSA key"
          end
          Inbox.new(executor: PaneReader.new(control), native: PiIdentity.new(context.fetch("pi_queue_client")),
            deliveries_dir: context.fetch("deliveries_dir"), receipt_public_key: key)
        rescue KeyError, SystemCallError, OpenSSL::PKey::PKeyError
          raise ValidationError, "protected inbox fixed context is unavailable"
        end
      end
    end
  end
end

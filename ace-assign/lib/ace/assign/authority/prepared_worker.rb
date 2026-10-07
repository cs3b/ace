# frozen_string_literal: true

require_relative "prepared_input"
require_relative "prepared_queue"
require_relative "../molecules/fork_session_launcher"

module Ace
  module Assign
    module Authority
      # Fixed gate target. Environment identifiers are untrusted lookup hints;
      # the original issued capability and actual kernel birth decide admission.
      class PreparedWorker
        def initialize(kernel: Ace::Runtime::Molecules::ProtectedLinux.new, client_factory: nil, launcher: nil, env: ENV)
          @kernel, @launcher, @env = kernel, launcher, env
          @client_factory = client_factory || ->(mapping) { Client.new(mapping_id: mapping, kernel: @kernel) }
          @started = false
        end

        def run
          raise AttemptErrors::EvidenceUnavailable, "original adapter invocation already activated" if @started
          mapping, assignment, attempt = %w[ACE_ASSIGN_LAUNCH_MAPPING ACE_ASSIGN_ASSIGNMENT_ID ACE_ASSIGN_ATTEMPT_ID].map do |key|
            value = @env[key]
            unless value.is_a?(String) && value.match?(PreparedWork::TOKEN)
              raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: original worker selector"
            end
            value
          end
          input = PreparedInput.fetch(client: @client_factory.call(mapping), assignment_id: assignment, attempt_id: attempt)
          self_identity = @kernel.capture(Process.pid)
          @kernel.live!(self_identity)
          original = input.descriptor.fetch("original_worker_identity")
          unless @kernel.same?(self_identity, original)
            raise AttemptErrors::UnauthorizedIdentity, "prepared adapter requires exact original worker self"
          end
          input.drive_prompt
          @started = true
          queue = PreparedQueue.new(work: input.work, descriptor: input.descriptor)
          root = queue.activate_original!
          return {"state" => "completed"} unless root
          launcher = @launcher || Molecules::ForkSessionLauncher.new(config: {})
          result = launcher.launch_provider_session(assignment_id: assignment, fork_root: input.descriptor.fetch("scope"),
            provider: root.fork_provider || Molecules::ForkSessionLauncher::DEFAULT_PROVIDER, cache_dir: queue.directory,
            prepared_input: input)
          queue.with_executor do |executor|
            state = executor.status.fetch(:state)
            unless state.failed.empty? && state.subtree_complete?(input.descriptor.fetch("scope"))
              raise AttemptErrors::EvidenceUnavailable, "prepared provider exited before selected queue completed"
            end
          end
          result
        rescue SystemCallError, IOError
          raise AttemptErrors::EvidenceUnavailable, "prepared_input_unavailable: published worker queue or provider output is unavailable"
        end
      end
    end
  end
end

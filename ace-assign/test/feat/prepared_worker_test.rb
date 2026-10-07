# frozen_string_literal: true
require_relative "prepared_work_fetch_test"
require "ace/assign/authority/prepared_worker"

module Ace
  module Assign
    class PreparedWorkerTest < PreparedWorkFetchTest
      # Reuse the maintained actual Server/Client/Endcap/Git transfer fixture.
      # Every kernel identity/ancestry, installed deployment/directory boundary
      # and provider query is injected. No default installed-context loader,
      # ProcessIdentity, SessionFinder, runtime adapter or provider executes.
      def controlled_worker_kernel(identity)
        kernel = Kernel.new
        kernel.define_singleton_method(:capture) { |_| identity }
        kernel
      end

      def worker_env
        {"ACE_ASSIGN_LAUNCH_MAPPING" => "mapping", "ACE_ASSIGN_ASSIGNMENT_ID" => "assignment", "ACE_ASSIGN_ATTEMPT_ID" => @attempt}
      end

      def protected_cli_context(kernel)
        project = @project.merge("worker_uids" => [13001])
        @deployment.define_singleton_method(:data) { {"projects" => {"project" => project}} }
        deployment = @deployment
        history = Object.new
        history.define_singleton_method(:descriptors) { [deployment] }
        Authority::ProtectedAssignmentContext.new(deployment: deployment, history: history,
          uid: 13001, kernel: kernel, env: {})
      end

      def test_worker_actual_original_fetch_queue_inline_provider_and_scoped_cli_finish
        fixture do
          issue_original
          start_server
          identity = @worker
          kernel = controlled_worker_kernel(identity)
          kernel.peer_identity = @service.slice("uid", "gid", "groups")
          context = protected_cli_context(kernel)
          options = {assignment: "assignment@010", mapping: "mapping", attempt: @attempt}
          captured = []
          owner = self
          query = Object.new
          query.define_singleton_method(:query) do |provider, prompt, **parameters|
            captured << [provider, prompt, parameters]
            # No provider FD or environment admission is used: explicit scoped
            # CLI options trigger an independent real original fetch.
            status = CLI::Commands::Status.new
            status.instance_variable_set(:@protected_assignment_context, context)
            status.call(**options, quiet: true)
            step = CLI::Commands::Step.new
            step.instance_variable_set(:@protected_assignment_context, context)
            output, = owner.capture_io { step.call(**options) }
            owner.assert_includes output, "Exact fixture work."
            resume = CLI::Commands::Resume.new
            resume.instance_variable_set(:@protected_assignment_context, context)
            output, = owner.capture_io { resume.call(**options, dry_run: true) }
            owner.assert_equal owner.instance_variable_get(:@attempt), JSON.parse(output).fetch("attempt_id")
            owner.assert_raises(Ace::Support::Cli::Error) { resume.call(**options) }
            finish = CLI::Commands::Finish.new
            finish.instance_variable_set(:@protected_assignment_context, context)
            finish.call(**options, message: "Selected worker completed.", quiet: true)
            {text: "Finished captured subtree.", provider: provider, model: "controlled", metadata: {}}
          end
          launcher = Molecules::ForkSessionLauncher.new(config: {}, query_interface: query,
            runner: Object.new, interactive_builder: Object.new)
          launcher.define_singleton_method(:detect_provider_session) { |*| raise "forbidden native session discovery" }
          worker = Authority::PreparedWorker.new(kernel: kernel, env: worker_env,
            client_factory: ->(_) { @client }, launcher: launcher)
          before = @journal.ref_value
          assert_equal "Finished captured subtree.", worker.run.fetch(:text)
          assert_equal 1, captured.size
          prompt = captured.first[1]
          assert_includes prompt, "Exact fixture context."
          assert_includes prompt, "Exact fixture work."
          assert_includes prompt, "--mapping mapping --attempt #{@attempt}"
          refute_includes prompt, "/as-assign-drive"
          assert_equal false, captured.first[2].fetch(:fallback)
          assert_equal @attempt, captured.first[2].fetch(:subprocess_env).fetch("ACE_ASSIGN_ATTEMPT_ID")
          assert_raises(AttemptErrors::EvidenceUnavailable) { worker.run }
          assert_equal 1, captured.size
          assert_equal before, @journal.ref_value
        end
      end

      def test_worker_descendant_can_fetch_but_cannot_activate_or_materialize_queue
        fixture do
          issue_original
          child = @kernel.capture(92).merge("parent_pid" => @worker.fetch("pid"))
          anchor = @worker
          @kernel.define_singleton_method(:descendant?) { |peer, original| original == anchor && [anchor, child].include?(peer) }
          start_server
          @kernel.peer_identity = child
          kernel = controlled_worker_kernel(child)
          worker = Authority::PreparedWorker.new(kernel: kernel, env: worker_env,
            client_factory: ->(_) { @client }, launcher: Object.new)
          assert_raises(AttemptErrors::UnauthorizedIdentity) { worker.run }
          refute File.exist?(File.join(@root, "prepared-queues"))
          refute File.exist?(File.join(@root, "prepared-queue-exclusion"))
        end
      end

      def test_worker_different_birth_and_unissued_attempt_refuse_before_queue_effects
        fixture do
          start_server
          kernel = controlled_worker_kernel(@worker)
          worker = Authority::PreparedWorker.new(kernel: kernel, env: worker_env,
            client_factory: ->(_) { @client }, launcher: Object.new)
          assert_raises(AttemptErrors::EvidenceUnavailable) { worker.run }
          refute File.exist?(File.join(@root, "prepared-queues"))
          issue_original
          kernel.define_singleton_method(:capture) { |_| @wrong_identity }
          kernel.instance_variable_set(:@wrong_identity, @worker.merge("started_at" => "different-birth"))
          assert_raises(AttemptErrors::UnauthorizedIdentity) { worker.run }
          refute File.exist?(File.join(@root, "prepared-queues"))
        end
      end

      def test_worker_missing_published_queue_after_start_is_not_rebuilt_by_scoped_cli_or_duplicate_adapter
        fixture do
          issue_original
          start_server
          kernel = controlled_worker_kernel(@worker)
          kernel.peer_identity = @service.slice("uid", "gid", "groups")
          context = protected_cli_context(kernel)
          queue_path = File.join(@root, "prepared-queues", "mapping", @attempt, "assignment")
          calls = 0
          owner = self
          query = Object.new
          query.define_singleton_method(:query) do |*_, **_|
            calls += 1
            FileUtils.rm_rf(queue_path)
            status = CLI::Commands::Status.new
            status.instance_variable_set(:@protected_assignment_context, context)
            owner.assert_raises(AttemptErrors::EvidenceUnavailable) do
              status.call(assignment: "assignment@010", mapping: "mapping", attempt: owner.instance_variable_get(:@attempt), quiet: true)
            end
            owner.refute File.exist?(queue_path)
            {text: "Queue unavailable.", provider: "controlled", metadata: {}}
          end
          launcher = Molecules::ForkSessionLauncher.new(config: {}, query_interface: query,
            runner: Object.new, interactive_builder: Object.new)
          worker = Authority::PreparedWorker.new(kernel: kernel, env: worker_env,
            client_factory: ->(_) { @client }, launcher: launcher)
          assert_raises(AttemptErrors::EvidenceUnavailable) { worker.run }
          assert_raises(AttemptErrors::EvidenceUnavailable) { worker.run }
          assert_equal 1, calls
          refute File.exist?(queue_path)
        end
      end

      def test_scoped_fail_persists_failure_and_graph_changing_command_refuses_before_effect
        fixture do
          issue_original
          start_server
          kernel = controlled_worker_kernel(@worker)
          kernel.peer_identity = @service.slice("uid", "gid", "groups")
          context = protected_cli_context(kernel)
          options = {assignment: "assignment@010", mapping: "mapping", attempt: @attempt}
          owner = self
          query = Object.new
          query.define_singleton_method(:query) do |*_, **_|
            graph_command = Class.new(Ace::Support::Cli::Command) do
              include CLI::Commands::AssignmentTarget
              def call(**options); resolve_assignment_target(options); end
            end.new
            graph_command.instance_variable_set(:@protected_assignment_context, context)
            owner.assert_raises(AttemptErrors::EvidenceUnavailable) { graph_command.call(**options) }
            fail_command = CLI::Commands::Fail.new
            fail_command.instance_variable_set(:@protected_assignment_context, context)
            fail_command.call(**options, message: "Captured work failed.", quiet: true)
            input = context.resolve(options: options, assignment_id: "assignment", scope: "010")
            state = Authority::PreparedExecutor.new(input).status.fetch(:state)
            owner.assert_equal :failed, state.find_by_number("010").status
            {text: "Failed selected work.", provider: "controlled", metadata: {}}
          end
          launcher = Molecules::ForkSessionLauncher.new(config: {}, query_interface: query,
            runner: Object.new, interactive_builder: Object.new)
          worker = Authority::PreparedWorker.new(kernel: kernel, env: worker_env,
            client_factory: ->(_) { @client }, launcher: launcher)
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { worker.run }
          assert_equal before, @journal.ref_value
        end
      end

      def test_fixed_task_context_actual_descendant_fetch_requires_exact_original_source_hook
        fixture do
          issue_original
          start_server
          child = @kernel.capture(92).merge("parent_pid" => @worker.fetch("pid"))
          original = @worker
          @kernel.define_singleton_method(:descendant?) { |peer, anchor| anchor == original && [original, child].include?(peer) }
          @kernel.peer_identity = child
          kernel = controlled_worker_kernel(child)
          kernel.peer_identity = @service.slice("uid", "gid", "groups")
          command = CLI::Commands::Authority::TaskContext.new
          command.instance_variable_set(:@protected_assignment_context, protected_cli_context(kernel))
          options = {mapping: "mapping", assignment: "assignment@010", attempt: @attempt, task: "task"}
          before = @journal.ref_value
          assert_raises(Ace::Support::Cli::Error) { command.call(**options) }
          pin = JSON.parse(JSON.generate(@map.fetch("task_context_entry")))
          pending = [pin]
          until pending.empty?
            value = pending.pop
            pending.concat(value.keys + value.values) if value.is_a?(Hash)
            value.freeze
          end
          Object.const_set(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, pin)
          output, error = capture_io { assert_equal 0, command.call(**options) }
          assert_empty error
          assert_equal 1, output.lines.size
          record = JSON.parse(output)
          assert_equal Authority::PreparedTaskContext::SCHEMA, record.fetch("schema")
          assert_equal "Exact fixture context.\n", record.fetch("text")
          assert_equal @attempt, record.fetch("attempt_id")
          assert_equal "010", record.fetch("scope")
          assert_raises(Ace::Support::Cli::Error) { command.call(**options.merge(task: "uncaptured")) }
          Object.send(:remove_const, :ACE_PROTECTED_TASK_CONTEXT_ENTRY)
          changed = Marshal.load(Marshal.dump(pin))
          changed.fetch("wrapper")["sha256"] = "9" * 64
          pending = [changed]
          until pending.empty?
            value = pending.pop
            pending.concat(value.keys + value.values) if value.is_a?(Hash)
            value.freeze
          end
          Object.const_set(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, changed)
          assert_raises(Ace::Support::Cli::Error) { command.call(**options) }
          assert_equal before, @journal.ref_value
          refute File.exist?(File.join(@root, "prepared-queues"))
        ensure
          Object.send(:remove_const, :ACE_PROTECTED_TASK_CONTEXT_ENTRY) if Object.const_defined?(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, false)
        end
      end

      def test_fixed_principal_and_selection_use_retained_owner_and_return_original_entry_without_text
        fixture do
          issue_original
          start_server
          child = @kernel.capture(92).merge("parent_pid" => @worker.fetch("pid"))
          original = @worker
          @kernel.define_singleton_method(:descendant?) { |peer, anchor| anchor == original && [original, child].include?(peer) }
          @kernel.peer_identity = child
          kernel = controlled_worker_kernel(child)
          kernel.peer_identity = @service.slice("uid", "gid", "groups")
          context = protected_cli_context(kernel)
          current_entry = Marshal.load(Marshal.dump(@map.fetch("task_context_entry")))
          current_entry.fetch("wrapper")["sha256"] = "9" * 64
          pending = [current_entry]
          until pending.empty?
            value = pending.pop
            pending.concat(value.keys + value.values) if value.is_a?(Hash)
            value.freeze
          end
          Object.const_set(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, current_entry)
          principal = CLI::Commands::Authority::TaskContextPrincipal.new
          principal.instance_variable_set(:@protected_assignment_context, context)
          output, error = capture_io { assert_equal 0, principal.call }
          assert_empty error
          assert_equal({"schema" => Authority::PreparedTaskContext::PRINCIPAL_SCHEMA, "uid" => 13001, "protected_worker" => true}, JSON.parse(output))
          assert_raises(Ace::Support::Cli::Error) { principal.call(uid: 13002) }
          selection = CLI::Commands::Authority::TaskContextSelection.new
          selection.instance_variable_set(:@protected_assignment_context, context)
          options = {mapping: "mapping", assignment: "assignment@010", attempt: @attempt}
          before = @journal.ref_value
          output, error = capture_io { assert_equal 0, selection.call(**options) }
          assert_empty error
          record = JSON.parse(output)
          assert_equal %w[assignment_id attempt_id definition_digest mapping_id schema scope selection_sha256 task_context_entry], record.keys.sort
          assert_equal @map.fetch("task_context_entry"), record.fetch("task_context_entry")
          refute_equal current_entry, record.fetch("task_context_entry")
          assert_equal @attempt, record.fetch("attempt_id")
          assert_raises(Ace::Support::Cli::Error) { selection.call(**options.merge(task: "task")) }
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            Authority::PreparedTaskContext.new(context: context).call(**options, task: "task")
          end
          retained = Object.new
          retained.define_singleton_method(:data) { {"projects" => {"project" => {"worker_uids" => [13001]}}} }
          history = context.instance_variable_get(:@history)
          history.define_singleton_method(:descriptors) { [retained] }
          @deployment.define_singleton_method(:data) { {"projects" => {"project" => {"worker_uids" => []}}} }
          output, = capture_io { assert_equal 0, principal.call }
          assert_equal true, JSON.parse(output).fetch("protected_worker"), "removed current UID remains protected through retained history"
          empty = Authority::ProtectedAssignmentContext.new(deployment: nil, history: nil, env: {})
          assert_raises(AttemptErrors::EvidenceUnavailable) { Authority::PreparedTaskContext.new(context: empty).principal }
          assert_equal before, @journal.ref_value
          refute File.exist?(File.join(@root, "prepared-queues"))
        ensure
          Object.send(:remove_const, :ACE_PROTECTED_TASK_CONTEXT_ENTRY) if Object.const_defined?(:ACE_PROTECTED_TASK_CONTEXT_ENTRY, false)
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../../ace-assign/test/support/endcap_result_owner_fixture"
require_relative "../../../ace-assign/test/support/original_launch_driver_owner_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/client"
require "ace/overseer/organisms/protected_work_on"
require "ace/overseer/organisms/protected_steering"
require "stringio"

class ProtectedWorkOnCompositionTest < AceOverseerTestCase
  include Ace::Assign::EndcapResultOwnerFixture
  include Ace::Assign::OriginalLaunchDriverOwnerFixture

  # Only the excluded OS fork/wait boundary is replaced. The fixed loaded CLI,
  # argv, retained input reads, driver, wire/channel and canonical join are real.
  class LoadedProcess
    class Pipe
      attr_reader :string
      attr_accessor :on_flush
      def initialize; @string, @position, @closed = +"", 0, false; end
      def write(bytes); @string << bytes; bytes.bytesize; end
      def flush; on_flush&.call; self; end
      def read_nonblock(limit, exception: false)
        return nil if @position == string.bytesize
        chunk = string.byteslice(@position, limit)
        @position += chunk.bytesize
        chunk
      end
      def close; @closed = true; end
      def closed? = @closed
      def readable? = @position < string.bytesize
    end
    attr_accessor :on_ready
    attr_reader :argv, :code, :frame, :failure
    def initialize(driver:, output:, identity:)
      @driver, @output, @identity = driver, output, identity
    end
    def supported? = true
    def pipe
      @frame = Pipe.new
      # Writer close has no effect on the separate reader's captured bytes.
      writer = Pipe.new
      reader = @frame
      writer.define_singleton_method(:write) { |bytes| reader.write(bytes) }
      writer.on_flush = lambda do
        # Git subprocess setup may flush an empty caller stream too. Only the
        # actual complete readiness write ends this excluded lifetime boundary.
        if !@ready_announced && reader.string.include?('"type":"launch_ready"') && reader.string.end_with?("\n")
          @ready_announced = true
          if on_ready
            callback, self.on_ready = on_ready, nil
            callback.call
          else
            @driver.request_control_cancel
          end
        end
      end
      [reader, writer]
    end
    def fork_loaded(argv:, reader:, writer:)
      raise "mandatory identity was not flushed" unless @output.flushed&.include?("launch_inputs_retained")
      @argv = argv
      previous = $stdout
      $stdout = writer
      begin
        @code = Ace::Assign::CLI.start(argv)
      rescue StandardError => error
        @failure, @code = [error.class.name, error.message], 1
      end
      @identity.fetch("pid")
    ensure
      $stdout = previous
    end
    def readable?(reader, _timeout) = reader.readable?
    def wait(pid)
      raise "different original child" unless pid == @identity.fetch("pid")
      [pid, Struct.new(:exitstatus).new(code)]
    end
  end

  class Output < StringIO
    attr_reader :flushed
    def flush; @flushed = string.dup; super; end
  end

  def configure_result_owner_fixture
    @project.merge!("journal_repository" => @journal.repo_root, "evidence_git_ref" => @journal.ref,
      "evidence_checkout_root" => @journal.checkout_root)
    @project.fetch("peer_credentials")[@launcher.fetch("uid").to_s] =
      @launcher.slice("gid", "groups").merge("scratch_root" => @root)
    deployment, map, service = @deployment, @map, @service
    deployment.define_singleton_method(:data) { {"launch_mappings" => {"mapping" => map}} }
    deployment.define_singleton_method(:authority) { |_| service.merge("composition" => "launch") }
  end

  def start_public_server
    @kernel.peer_identity = @launcher
    @server = Ace::Assign::Authority::Server.new(authority_id: "authority", lifecycle: @router,
      deployment: @deployment, kernel: @kernel, composition: "launch")
    wire = Object.new
    wire.define_singleton_method(:root_path!) { |*_, **_| true }
    %i[socket_identity read write deadline].each do |name|
      wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
    end
    @server.define_singleton_method(:wire) { wire }
    @owner = Thread.new { @server.serve }
    Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
    StreamKernel.new(@kernel, me: @launcher, peer: @service)
  end

  def test_public_managed_inputs_fixed_cli_transport_and_exact_canonical_readiness
    exercise_public_composition
  end

  def test_public_prompt_status_replay_and_stop_use_same_original_live_driver
    exercise_public_composition(steering: true)
  end

  def exercise_public_composition(steering: false)
    fixture(prepare_attempt: false) do
      assert_empty @journal.read_events("assignment")
      client_kernel = start_public_server
      client = Ace::Assign::Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel)
      recorded = Queue.new
      calls = []
      actual_call = client.method(:call)
      client.define_singleton_method(:call) do |operation, params, **options|
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if operation == "register_assignment"
          raise "registration consumer did not select its existing admission budget" unless options[:timeout].is_a?(Numeric) && options[:timeout].positive? && options[:timeout] <= Ace::Assign::Authority::LaunchDriver::LAUNCH_DEADLINE
        end
        result = actual_call.call(operation, params, **options)
        recorded << result.data if operation == "record_launch"
        calls << [operation, "ok", Process.clock_gettime(Process::CLOCK_MONOTONIC) - started]
        result
      rescue StandardError => error
        calls << [operation, error.class.name, error.message, Process.clock_gettime(Process::CLOCK_MONOTONIC) - started]
        raise
      end
      gate_server, gate_worker = UNIXSocket.pair
      gate = Thread.new do
        state = Timeout.timeout(30) { recorded.pop }
        @launch.gate_ready(request: {"params" => {"mapping_id" => "mapping", "launch_ticket" => state.fetch("launch_ticket")}},
          peer: @worker, socket: gate_server, deadline: WIRE.deadline(30))
      end
      fixed = @map.merge("native" => @map.fetch("native").merge("server_identity" => @kernel.capture(90), "socket_identity" => [1, 2, 13001]))
      native = OriginalGuardedNative.new(mapping: fixed, kernel: @kernel)
      creations = []
      actual_create = native.method(:create)
      native.define_singleton_method(:create) { |**args| creations << args; actual_create.call(**args) }
      driver = Ace::Assign::Authority::LaunchDriver.new(mapping_id: "mapping", deployment: @deployment,
        kernel: client_kernel, client: client, native: native)

      task_root = File.join(@root, "tasks")
      task_directory = File.join(task_root, "8wr.t.abc-managed")
      FileUtils.mkdir_p(task_directory)
      spec = File.join(task_directory, "8wr.t.abc-managed.s.md")
      File.write(spec, "---\nid: 8wr.t.abc\ntitle: Composed public input\nstatus: pending\nneeds_review: false\ndependencies: []\n---\nReviewed public task instructions.\n")
      tasks = Ace::Task::Organisms::TaskManager.new(root_dir: task_root, config: {})
      cache = File.join(@root, "managed")
      # The selected source catalog is the real checkout, independent of whether
      # ace-test was invoked from its root or the ace-overseer package directory.
      catalog = Ace::Assign::Molecules::SkillAssignSourceResolver.new(project_root: File.expand_path("../../..", __dir__),
        skill_paths: [], workflow_paths: [])
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache, skill_source_resolver: catalog)
      executor.assignment_manager.define_singleton_method(:generate_assignment_id) { "assignment" }
      topology = Object.new
      topology.define_singleton_method(:agents) do |project:|
        Struct.new(:data) { def ok? = true }.new({"agents" => [{"id" => "mapping", "project" => project}]})
      end
      loader = -> { @deployment }
      selection = Ace::Overseer::Molecules::ProtectedSelection.new(topology: topology, deployment_loader: loader)
      status = Ace::Overseer::Organisms::ProtectedStatus.new(topology: topology, deployment_loader: loader,
        client_factory: ->(*) { client })
      output = Output.new
      process = LoadedProcess.new(driver: driver, output: output, identity: @launcher)
      child_kernel = Object.new
      original_launcher = @launcher
      child_kernel.define_singleton_method(:capture) do |pid|
        raise "unselected original child identity" unless pid == original_launcher.fetch("pid")
        original_launcher
      end
      child = Ace::Overseer::Molecules::OriginalLaunchChild.new(process: process, kernel: child_kernel,
        threads: -> { [Thread.current] }, quiescent: -> { true }, clock: -> { Process.clock_gettime(Process::CLOCK_MONOTONIC) })
      coordinator = Ace::Overseer::Organisms::ProtectedWorkOn.new(selection: selection, status: status,
        task_manager: tasks, request_root: File.join(@root, "retained"), pause: -> {},
        driver_factory: ->(*) { driver }, child_factory: -> { child },
        builder_factory: ->(root) { Ace::Assign::Organisms::PreparedWorkBuilder.new(export_root: root,
          task_manager: tasks, executor: executor, bundle_loader: Ace::Bundle::Organisms::BundleLoader.new(base_dir: @root)) })
      command = Ace::Overseer::CLI::Commands::WorkOn.new(protected_work_on: coordinator, config: {"runtime" => "auto"},
        orchestrator: Object.new, recovery: Object.new)
      if steering
        protected_steering = Ace::Overseer::Organisms::ProtectedSteering.new(selection: selection, status: status,
          client_factory: ->(*) { client })
        process.on_ready = lambda do
          steering_thread = Thread.new do
            begin
              ready = JSON.parse(process.frame.string)
              target = {project: "project", agent: "mapping", assignment: ready.fetch("assignment_id"),
                attempt: ready.fetch("attempt_id"), mutation: "public-steer", expected_generation: ready.fetch("generation")}
              prompt = Ace::Overseer::CLI::Commands::Prompt.new(steering: protected_steering, input: StringIO.new("exact public steering\n"))
              original_output = $stdout
              $stdout = StringIO.new
              prompt.call(**target, stdin: true)
              first = JSON.parse($stdout.string)
              assert_equal "submitted", first.fetch("outcome")
              assert_equal 1, native.prompt_calls.length
              $stdout = StringIO.new
              error = assert_raises(Ace::Support::Cli::Error) { prompt.call(**target, stdin: true) }
              assert_match(/bounded UTF-8/, error.message)
              $stdout = StringIO.new
              replay = Ace::Overseer::CLI::Commands::Prompt.new(steering: protected_steering, input: StringIO.new("exact public steering\n"))
              replay.call(**target, stdin: true)
              assert_equal first, JSON.parse($stdout.string)
              assert_equal 1, native.prompt_calls.length
              $stdout = StringIO.new
              replay.call(**target.reject { |key, _| key == :expected_generation }, status: true)
              assert_equal "submitted", JSON.parse($stdout.string).fetch("outcome")
              assert_equal 1, native.prompt_calls.length
              row = status.collect(project: "project", agent: "mapping").fetch("agents").first.fetch("inventory").fetch("items").find { |item| item["attempt_id"] == target.fetch(:attempt) }
              stop = Ace::Overseer::CLI::Commands::Stop.new(steering: protected_steering)
              $stdout = StringIO.new
              stop.call(**target.merge(mutation: "public-stop", expected_generation: row.fetch("generation")))
              stopped = JSON.parse($stdout.string)
              assert_equal "uncertain", stopped.fetch("state")
              assert_nil status.collect(project: "project", agent: "mapping").fetch("agents").first.fetch("inventory").fetch("items").find { |item| item["attempt_id"] == target.fetch(:attempt) }.fetch("reservation_release_event_id")
            ensure
              $stdout = original_output if original_output
              driver.request_control_cancel
            end
          end
          process.instance_variable_set(:@steering_thread, steering_thread)
        end
      end
      previous = $stdout
      $stdout = output
      # Source-owned constructor injection preserves the actual registered
      # Assign command and its complete fixed argv parser/retained input reads.
      Ace::Assign::Authority::LaunchDriver.stub(:new, ->(**) { driver }) do
        Ace::Assign.stub(:cache_dir, cache) do
          Dir.chdir(@journal.repo_root) do
            command.call(task: ["8wr.t.abc"], project: "project", mutation: "composed", quiet: true)
          end
        end
      end
      process.instance_variable_get(:@steering_thread)&.value
      identity, observation = output.string.lines.map { |line| JSON.parse(line) }
      assert_equal "launch_inputs_retained", identity.fetch("type")
      assert_equal "ready", observation.fetch("state"), {"child_failure" => process.failure, "calls" => calls}.inspect
      assert_equal 0, process.code
      assert_equal "exited", child.state
      assert_equal ["authority", "launch"], process.argv.first(2)
      ready = JSON.parse(process.frame.string)
      assert_equal "launch_ready", ready.fetch("type")
      assert_equal ready, child.ready
      canonical = status.join_ready!(project: "project", agent: "mapping", ready: ready).fetch("item")
      retained = Ace::Overseer::Molecules::LaunchRequest.new(root: File.dirname(identity.fetch("request_path"))).load(identity.fetch("request_path"))
      assert Ace::Overseer::Organisms::LaunchRecovery.verify_original!(request: retained, row: canonical)
      assert_equal "composed-reserve", canonical.fetch("reservation_mutation_id")
      assert_equal "8wr.t.abc", canonical.fetch("task_id")
      assert_equal File.binread(identity.fetch("prepared_bundle_path")),
        @journal.blob(canonical.fetch("prepared_bundle_ref"), commit: ready.fetch("journal_commit"))
      refute_equal "010", canonical.fetch("scope")
      assert_nil canonical.fetch("terminal_event_id")
      assert_nil canonical.fetch("reservation_release_event_id")
      assert_equal "ready", WIRE.read(gate_worker, deadline: WIRE.deadline(5)).dig("data", "phase")
      assert_equal "release", WIRE.read(gate_worker, deadline: WIRE.deadline(5)).fetch("operation")
      gate.join(2)
      refute gate.alive?
      assert_empty native.prompt_calls || [] unless steering
      before = @journal.ref_value
      File.write(spec, "Current instructions changed after original launch.\n")
      File.unlink(identity.fetch("prepared_bundle_path"))
      recovery = Ace::Overseer::Organisms::LaunchRecovery.new(status: status)
      recovery_command = Ace::Overseer::CLI::Commands::WorkOn.new(recovery: recovery,
        protected_work_on: coordinator, orchestrator: Object.new, config: {"runtime" => "auto"})
      output.truncate(0)
      output.rewind
      recovery_command.call(recover_request: identity.fetch("request_path"), quiet: true)
      recovered = JSON.parse(output.string)
      assert_equal "original_reservation", recovered.fetch("attribution")
      assert_equal "unavailable", recovered.fetch("local_bundle")
      assert_equal ready.fetch("attempt_id"), recovered.fetch("item").fetch("attempt_id")
      assert_equal before, @journal.ref_value
      assert_equal 1, coordinator.children.size
      assert_equal 1, creations.size
    ensure
      $stdout = previous if previous
      driver&.request_control_cancel
      gate_server&.close
      gate_worker&.close
      gate&.join(2)
      gate&.kill if gate&.alive?
    end
  end
end

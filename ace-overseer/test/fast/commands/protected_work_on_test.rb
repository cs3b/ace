# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../../../ace-assign/test/support/prepared_registration_fixture"
require "ace/overseer/organisms/protected_work_on"
require "etc"
require "stringio"

class ProtectedWorkOnCommandTest < AceOverseerTestCase
  class Output < StringIO
    attr_reader :flushed
    def flush
      @flushed = string.dup
      super
    end
  end
  class Child
    attr_reader :state, :pid, :ready, :error, :starts, :observations
    def initialize(output)
      @output, @starts, @observations, @state, @pid = output, [], 0, "not_started", 321
    end
    def start(**inputs)
      raise "identity must be written and flushed before child" unless @output.flushed&.include?("launch_inputs_retained")
      @starts << inputs
      @state = "uncertain"
      @error = "controlled original uncertainty"
      self
    end
    def await_ready(status:) = self
    def observe
      @observations += 1
      @state = "exited" if @observations == 2
      self
    end
  end

  def setup
    super
    @root = Dir.mktmpdir("public-protected-", Etc.getpwuid(Process.uid).dir)
    File.chmod(0700, @root)
    artifact = Ace::Assign::PreparedRegistrationFixture.build(root: @root, scope: "010", definition: {
      "session_id" => "assignment", "project_id" => "project", "task_id" => "task", "name" => "fixture",
      "created_at" => "2026-10-07T00:00:00Z", "source_config" => "job.yaml"})
    @prepared = {"bundle" => artifact.bundle, "bytes" => artifact.bundle.bytesize, "sha256" => Digest::SHA256.hexdigest(artifact.bundle),
      "definition_bytes" => artifact.definition_bytes, "assignment_id" => "assignment", "scope" => "010"}
    @output = Output.new
    @child = Child.new(@output)
    @preflights, @builds, @head_calls = [], [], 0
    @preflight_error = nil
    @head = "a" * 40
    @builder_effect = nil
  end

  def teardown
    FileUtils.rm_rf(@root)
    super
  end

  def owner(visible: %w[one two])
    selection = Object.new
    selection.define_singleton_method(:call) { |**| [Object.new, %w[one two], visible] }
    tasks = Object.new
    tasks.define_singleton_method(:show) { |_ref| Struct.new(:id).new("task") }
    test = self
    builder = Object.new
    builder.define_singleton_method(:call) do |**args|
      test.instance_variable_get(:@builds) << args
      test.instance_variable_get(:@builder_effect)&.call
      test.instance_variable_get(:@prepared)
    end
    driver_factory = lambda do |id, _deployment|
      driver = Object.new
      driver.define_singleton_method(:preflight) do
        test.instance_variable_get(:@preflights) << id
        error = test.instance_variable_get(:@preflight_error)
        raise error if error && id == "one"
        {"project_id" => "project", "runtime" => "herdr", "supported" => true}
      end
      driver
    end
    Ace::Overseer::Organisms::ProtectedWorkOn.new(selection: selection, status: Object.new, builder_factory: ->(_root) { builder },
      driver_factory: driver_factory, child_factory: -> { @child }, task_manager: tasks, request_root: @root,
      head_reader: -> { @head_calls += 1; @head }, pause: -> {})
  end

  def invoke(selected, **options)
    forbidden = Object.new
    forbidden.define_singleton_method(:call) { |**| raise "local fallback forbidden" }
    command = Ace::Overseer::CLI::Commands::WorkOn.new(orchestrator: forbidden, protected_work_on: selected,
      recovery: forbidden, config: {"runtime" => "auto"})
    saved = $stdout
    $stdout = @output
    command.call(**{task: ["short-task"], project: "project", mutation: "invocation", quiet: true}.merge(options))
  ensure
    $stdout = saved
  end

  def test_actual_public_retention_flush_uncertainty_and_original_foreground_observation
    selected = owner(visible: ["one"])
    invoke(selected, dependency_report: ["dependency:report-assignment:010"])
    lines = @output.string.lines.map { |line| JSON.parse(line) }
    identity = lines.first
    assert_equal "launch_inputs_retained", identity.fetch("type")
    assert_equal "partial", identity.fetch("visibility")
    assert_equal "one", identity.fetch("mapping_id")
    assert_equal "uncertain", lines.last.fetch("state")
    assert_equal @prepared.fetch("definition_bytes"), File.binread(identity.fetch("definition_path"))
    assert_equal @prepared.fetch("sha256"), identity.fetch("prepared_bundle").fetch("sha256")
    assert_equal [{"task_id" => "dependency", "assignment_id" => "report-assignment", "number" => "010"}], @builds.first.fetch(:dependency_reports)
    assert_equal @child, selected.children.fetch("invocation")
    assert_equal 1, @child.starts.size
    assert_equal 2, @child.observations
    assert_equal 3, @head_calls
  end

  def test_public_registry_parser_routes_current_protected_options
    selected = owner(visible: ["one"])
    forbidden = Object.new
    forbidden.define_singleton_method(:call) { |**| raise "local fallback forbidden" }
    command = Ace::Overseer::CLI::Commands::WorkOn.new(orchestrator: forbidden, protected_work_on: selected,
      recovery: forbidden, config: {"runtime" => "auto"})
    saved = $stdout
    $stdout = @output
    Ace::Overseer::CLI::Commands::WorkOn.stub(:new, -> { command }) do
      Ace::Support::Cli::Runner.new(Ace::Overseer::CLI).call(args: ["work-on", "--task", "short-task", "--project", "project",
        "--agent", "one", "--runtime", "herdr", "--mutation", "invocation", "--quiet", "--dependency-report", "dependency:report-assignment:010"])
    end
    assert_equal 1, @child.starts.size
    assert_equal "one", @child.starts.first.fetch(:request).fetch("mapping_id")
    assert_equal "task", @builds.first.fetch(:task_ref)
    assert_equal 2, @child.observations
  ensure
    $stdout = saved
  end

  def test_automatic_order_advances_only_after_attributable_readonly_refusal
    @preflight_error = Ace::Assign::AttemptErrors::UnauthorizedIdentity.new("controlled denial")
    invoke(owner)
    assert_equal %w[one two], @preflights
    assert_equal "two", @child.starts.first.fetch(:request).fetch("mapping_id")
  end

  def test_explicit_or_unavailable_preflight_never_switches_or_publishes
    @preflight_error = Ace::Assign::AttemptErrors::UnauthorizedIdentity.new("controlled denial")
    assert_raises(Ace::Support::Cli::Error) { invoke(owner, agent: "one") }
    assert_equal ["one"], @preflights
    assert_empty @builds
    assert_empty @child.starts
    @preflights.clear
    @preflight_error = Ace::Runtime::RuntimeUnavailableError.new("uncertain endpoint")
    assert_raises(Ace::Support::Cli::Error) { invoke(owner) }
    assert_equal ["one"], @preflights
    assert_empty Dir.children(@root)
  end

  def test_head_change_or_wrong_explicit_base_refuses_before_publication
    @builder_effect = -> { @head = "b" * 40 }
    assert_raises(Ace::Support::Cli::Error) { invoke(owner) }
    assert_empty Dir.children(@root)
    assert_empty @child.starts
    @builder_effect = nil
    assert_raises(Ace::Support::Cli::Error) { invoke(owner, base_head: "c" * 40) }
    assert_empty @child.starts
  end

  def test_invalid_mutation_refuses_before_builder_or_publication
    assert_raises(Ace::Support::Cli::Error) { invoke(owner, mutation: "../other") }
    assert_empty @builds
    assert_empty @child.starts
    assert_empty Dir.children(@root)
  end

  def test_code_head_change_after_identity_output_refuses_before_fork
    test = self
    @output.define_singleton_method(:flush) do
      test.instance_variable_set(:@head, "b" * 40) if string.include?("launch_inputs_retained")
      super()
    end
    assert_raises(Ace::Support::Cli::Error) { invoke(owner) }
    assert_empty @child.starts
    assert File.exist?(File.join(@root, "invocation.json"))
  end

  def test_post_child_output_failure_still_observes_the_same_original
    @output.define_singleton_method(:flush) do
      raise IOError, "controlled post-child output failure" if string.include?("original_launch_observation")
      super()
    end
    selected = owner
    assert_raises(Ace::Support::Cli::Error) { invoke(selected) }
    assert_equal @child, selected.children.fetch("invocation")
    assert_equal 1, @child.starts.size
    assert_equal 2, @child.observations
    assert_equal "exited", @child.state
  end

  def test_output_failure_and_protected_tmux_refuse_before_child
    @output.define_singleton_method(:flush) do
      raise IOError, "controlled output failure" if string.include?("launch_inputs_retained")
      super()
    end
    assert_raises(Ace::Support::Cli::Error) { invoke(owner) }
    assert_empty @child.starts
    assert File.exist?(File.join(@root, "invocation.json"))
    assert_raises(Ace::Support::Cli::Error) { invoke(owner, runtime: "tmux", mutation: "other") }
    assert_empty @child.starts
  end
end

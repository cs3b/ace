# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/ordinary_owner_fixture"
require "ace/lab/organisms/ordinary_assignment_client"

class OrdinaryAssignmentClientTest < Minitest::Test
  include OrdinaryOwnerFixture
  C = Ace::Lab::Organisms::OrdinaryAssignmentClient
  A = Ace::Assign::Authority

  class Selection < Ace::Lab::Molecules::OrdinaryOwnerConfig
    def initialize(...)
      @state = {valid: true}
      super
    end
    def revoke = @state[:valid] = false
    def verify_owner!
      raise Ace::Lab::InvalidConfigurationError, "fixture revoked" unless @state[:valid]
      true
    end
  end

  def setup
    @previous_project_root = ENV["PROJECT_ROOT_PATH"]
    ENV["PROJECT_ROOT_PATH"] = File.expand_path("../../..", __dir__)
    parent = File.expand_path("../../.ace-local", __dir__)
    FileUtils.mkdir_p(parent)
    @root = Dir.mktmpdir("ordinary-client-", parent)
    File.chmod(0o700, @root)
    @config = Selection.new(ordinary_owner_document(peer: {"uid" => 41001, "gid" => 41001,
      "pid" => 123, "host" => "lab", "started_at" => "birth"}), project: "atlas", source: Selection::PATH)
    @calls = []
    calls = @calls
    @transport = Object.new
    @transport.define_singleton_method(:call) do |operation, params, **options|
      calls << [operation, params, options]
      A::OrdinaryClient::Reply.new(data: {"generation" => 3}, replayed: calls.size > 1)
    end
    @factory = lambda do |**options|
      options.fetch(:verify_selection).call
      @client_options = options
      @transport
    end
  end

  def teardown
    ENV["PROJECT_ROOT_PATH"] = @previous_project_root
    FileUtils.remove_entry(@root)
  end

  def client(project = "atlas")
    C.new(project: project, config: @config, client_factory: @factory)
  end

  def document(operation = "queue_start", params = {"assignment_id" => "assign1", "attempt_id" => "attempt1",
    "expected_generation" => 2, "pane" => "w1:p1", "step" => nil})
    {"version" => 1, "project_id" => "atlas", "operation" => operation,
      "mutation_id" => "mutation1", "params" => params, "parts" => []}
  end

  def save(value)
    path = File.join(@root, "request.json")
    File.write(path, JSON.generate(value))
    path
  end

  def test_replay_keeps_exact_mutation_and_generation_with_no_local_execution_state
    input = save(document)
    first = client.request(input: input)
    second = client.request(input: input)
    assert_equal false, first.dig("transport", "replayed")
    assert_equal true, second.dig("transport", "replayed")
    assert_equal @calls.first, @calls.last
    assert_equal 2, @calls.last[1]["expected_generation"]
    assert_equal "mutation1", @calls.last[2][:mutation_id]
    assert_equal ["request.json"], Dir.children(@root)
    assert_equal @config.service, @client_options.fetch(:service)
  end

  def test_selection_revocation_or_transport_loss_never_retries_or_falls_back
    input = save(document)
    @transport.define_singleton_method(:call) do |*|
      raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "reply lost"
    end
    original = File.binread(input)
    assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) { client.request(input: input) }
    @config.revoke
    assert_raises(Ace::Lab::InvalidConfigurationError) { client.request(input: input) }
    assert_equal original, File.binread(input)
    assert_equal ["request.json"], Dir.children(@root)
  end

  def test_upload_matches_retained_inventory_before_connecting
    bytes = "exact report\n"
    path = File.join(@root, "report.md")
    File.write(path, bytes)
    value = document("queue_finish")
    value["parts"] = [{"file" => "report.md", "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}]
    input = save(value)
    client.request(input: input)
    assert_equal [bytes], @calls.last[2][:upload_parts]
    assert_equal :artifacts, @calls.last[2][:purpose]
    File.write(path, "changed report\n")
    assert_raises(ArgumentError) { client.request(input: input) }
    assert_equal 1, @calls.size
    File.unlink(path)
    File.symlink(input, path)
    assert_raises(SystemCallError) { client.request(input: input) }
    assert_equal 1, @calls.size
  end

  def test_foreign_project_unretained_mutation_unknown_operation_and_download_misuse_refuse
    variants = [document.merge("project_id" => "foreign"), document.merge("mutation_id" => nil),
      document.merge("operation" => "shell"), document.merge("extra" => true),
      document("registration_status", {"assignment_id" => "assign1"})]
    variants.each { |value| assert_raises(ArgumentError) { client.request(input: save(value)) } }
    value = document("assignment_snapshot", {"assignment_id" => "assign1", "attempt_id" => nil, "kind" => "queue"})
    value["mutation_id"] = nil
    assert_raises(ArgumentError) { client.request(input: save(value)) }
    assert_raises(ArgumentError) { client("foreign") }
    assert_empty @calls
  end

  def test_download_is_private_projection_and_existing_output_is_never_overwritten
    value = document("result_snapshot", {"assignment_id" => "assign1", "attempt_id" => "attempt1", "result_id" => "result1"})
    value["mutation_id"] = nil
    input = save(value)
    @transport.define_singleton_method(:call) do |*, **|
      A::OrdinaryClient::Reply.new(data: {"result_id" => "result1"}, replayed: false, parts: ["receipt", "artifact"])
    end
    output = File.join(@root, "download")
    result = client.request(input: input, output: output)
    assert_equal %w[receipt artifact], result.fetch("files").map { |entry| File.binread(entry.fetch("file")) }
    assert_equal 0o700, File.stat(output).mode & 0o777
    result.fetch("files").each { |entry| assert_equal 0o600, File.stat(entry.fetch("file")).mode & 0o777 }
    assert_equal result, JSON.parse(File.read(File.join(output, "response.json")))
    assert_raises(Errno::EEXIST) { client.request(input: input, output: output) }
    assert_equal "receipt", File.read(File.join(output, "part-00.bytes"))
  end

  def test_preparation_uses_real_managed_builder_and_retains_exact_register_input_once
    task_root = File.join(@root, "tasks")
    FileUtils.mkdir_p(File.join(task_root, "8wr.t.abc-fixture"))
    File.write(File.join(task_root, "8wr.t.abc-fixture/8wr.t.abc-fixture.s.md"),
      "---\nid: 8wr.t.abc\ntitle: Fixture\nstatus: pending\nneeds_review: false\ndependencies: []\n---\nReviewed task.\n")
    tasks = Ace::Task::Organisms::TaskManager.new(root_dir: task_root, config: {})
    cache = File.join(@root, "assign")
    executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache)
    bundles = Ace::Bundle::Organisms::BundleLoader.new(base_dir: @root)
    constructor = Ace::Assign::Organisms::PreparedWorkBuilder.method(:new)
    factory = ->(**options) { constructor.call(**options, task_manager: tasks, executor: executor, bundle_loader: bundles) }
    output = File.join(@root, "prepared")
    Ace::Assign.stub(:cache_dir, cache) do
      Ace::Assign::Organisms::PreparedWorkBuilder.stub(:new, factory) do
        result = C.prepare(project: "atlas", task: "8wr.t.abc", pane: "w1:pS", output: output)
        request = JSON.parse(File.read(result.fetch("request")))
        definition = File.binread(File.join(output, "definition.json"))
        assert_equal Digest::SHA256.hexdigest(definition), request.dig("params", "definition_digest")
        client.request(input: result.fetch("request"))
        assert_equal "register_assignment", @calls.last[0]
        assert_equal [File.binread(File.join(output, "prepared.bundle"))], @calls.last[2][:upload_parts]
        assert_equal result.fetch("assignment_id"), @calls.last[1].fetch("assignment_id")
        assert_raises(Errno::EEXIST) { C.prepare(project: "atlas", task: "8wr.t.abc", pane: "w1:pS", output: output) }
        assert_equal request, JSON.parse(File.read(result.fetch("request")))
      end
    end
  end
end

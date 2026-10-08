# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/organisms/authority_composition"

class PublicationCompositionTest < Minitest::Test
  class Deployment
    attr_reader :data
    def initialize(root)
      @root = root
      @data = {"launch_mappings" => {"mapping" => {"authority_id" => "authority", "project_id" => "ace"}}}
    end
    def verify_composition!(*, **); true; end
    def verify_receiver_paths!(*); true; end
    def project(_)
      {"journal_repository" => @root, "evidence_checkout_root" => File.join(@root, "checkout"),
        "evidence_git_ref" => "refs/ace/execution", "service_receivers" => {"executor" => {}}}
    end
    def authority(_)
      {"uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort,
        "socket_path" => File.join(@root, "authority.sock")}
    end
  end
  class Sibling
    attr_reader :started, :stopped
    def initialize(failure: false)
      @failure = failure
      @mutex, @condition = Mutex.new, ConditionVariable.new
    end
    def run(on_ready:)
      @started = true
      raise IOError, "fixture startup failure" if @failure
      on_ready.call
      @mutex.synchronize { @condition.wait(@mutex) until @stopped }
    end
    def stop
      @mutex.synchronize { @stopped = true; @condition.broadcast }
    end
  end

  def setup
    @root = Dir.mktmpdir("publication-composition", "/tmp")
    File.chmod(0o700, @root)
    @deployment = Deployment.new(@root)
  end
  def teardown
    @server&.stop
    @thread&.join(5)
    FileUtils.remove_entry(@root)
  end

  def test_actual_constructor_selects_fixed_service_and_same_project_journal
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {"hitl" => {"service_uid" => Process.uid}})
    selected = []
    factory = lambda { |**options| selected << options; policy }
    provider = Ace::Hitl::Providers::Lab
    Ace::Assign::Authority::DeploymentHistory.stub(:load, nil) do
      provider.stub(:grants_policy, factory) do
        @server = Ace::Lab::Organisms::AuthorityComposition.new(authority_id: "authority", deployment: @deployment).build
      end
    end
    assert_instance_of Ace::Assign::Authority::Server, @server
    service = @server.instance_variable_get(:@hitl_service)
    assert_instance_of Ace::Hitl::Lifecycle::Service, service
    assert_equal [{grants_path: provider::DEFAULT_GRANTS_PATH}], selected
    assert_equal provider::DEFAULT_SOCKET_PATH, service.socket_path
    assert_equal provider::DEFAULT_STORE_ROOT, service.instance_variable_get(:@root)
    binding = service.instance_variable_get(:@binding)
    assert_instance_of Ace::Hitl::Lifecycle::ServicePublicationBinding, binding
    assert_equal ["ace"], binding.proposal_projects
    original = binding.proposal_journal(project: "ace")
    assert_equal @root, original.repo_root
    assert_equal :protected, original.evidence_mode
    assert_raises(Ace::Hitl::Lifecycle::BindingError) { binding.proposal_journal(project: "foreign") }
  end

  def test_foreign_hitl_service_principal_refuses_in_real_constructor
    policy = Ace::Hitl::Lifecycle::GrantsPolicy.new(document: {"hitl" => {"service_uid" => Process.uid + 1}})
    Ace::Assign::Authority::DeploymentHistory.stub(:load, nil) do
      Ace::Hitl::Providers::Lab.stub(:grants_policy, policy) do
        assert_raises(Ace::Lab::InvalidConfigurationError) do
          Ace::Lab::Organisms::AuthorityComposition.new(authority_id: "authority", deployment: @deployment).build
        end
      end
    end
  end

  def server_with(sibling)
    peer = {"uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort}
    kernel = Object.new
    kernel.define_singleton_method(:supported!) { true }
    kernel.define_singleton_method(:capture) { |_| peer }
    lifecycle = Object.new
    lifecycle.define_singleton_method(:close) { @closed = true }
    @server = Ace::Assign::Authority::Server.new(authority_id: "authority", deployment: @deployment,
      kernel: kernel, lifecycle: lifecycle, composition: "services", hitl_service: sibling)
    lifecycle
  end

  def test_start_failure_stops_sibling_and_never_opens_authority_ingress
    sibling = Sibling.new(failure: true)
    server_with(sibling)
    Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, true) do
      assert_raises(IOError) { @server.serve }
    end
    assert sibling.started
    assert sibling.stopped
    refute File.exist?(File.join(@root, "authority.sock"))
    refute @server.instance_variable_get(:@hitl_thread).alive?
  end

  def test_normal_stop_joins_sibling_before_original_owner_lock_releases
    sibling = Sibling.new
    lifecycle = server_with(sibling)
    Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, true) do
    @thread = Thread.new { @server.serve }
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 2
    until File.socket?(File.join(@root, "authority.sock"))
      raise "fixture authority startup timeout" unless @thread.alive? && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
      sleep 0.005
    end
    assert sibling.started
    @server.stop
    assert @thread.join(2)
    assert sibling.stopped
    refute @server.instance_variable_get(:@hitl_thread).alive?
    assert lifecycle.instance_variable_get(:@closed)
    refute File.exist?(File.join(@root, "authority.sock"))
    end
  end
end

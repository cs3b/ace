# frozen_string_literal: true

require "test_helper"
require_relative "../../support/inbox_context_service_selection_fixture"
require "ace/herdr/organisms/inbox_context_listener"
require_relative "../../support/inbox_context_owner_fixture"

class InboxContextListenerTest < Minitest::Test
  include InboxContextServiceSelectionFixture
  Listener = Ace::Herdr::Organisms::InboxContextListener
  Configuration = Ace::Herdr::Molecules::InboxContextServiceConfiguration
  ERROR = Ace::Herdr::ValidationError

  class Kernel
    attr_accessor :foreign, :dead
    def capture(_pid)
      {"uid" => foreign ? Process.uid + 1 : Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort.uniq}
    end
    def live!(_peer)
      raise Ace::Runtime::RuntimeUnavailableError, "controlled dead original" if dead
      true
    end
  end

  class Protection < InboxContextOwnerFixture::FixturePaths
    def socket_identity(path) = Ace::Runtime::Molecules::ProtectedSocket.socket_identity(path)
  end

  class Server
    attr_reader :entered, :release
    def initialize = (@entered, @release = Queue.new, Queue.new)
    def handle(socket)
      entered << true
      release.pop
      socket.write("fixed reply")
    end
  end

  def setup
    @root = File.realpath(Dir.mktmpdir("ic", "/tmp"))
    File.chown(nil, Process.gid, @root)
    File.chmod(0o750, @root)
    @path = File.join(@root, "control.sock")
    @server, @kernel = Server.new, Kernel.new
    data = {"schema" => "ace.herdr.inbox-context-service/v1", "project_id" => "project", "inbox_context_id" => "ctx", "native_clients" => native_client_selection,
      "native_mapping_id" => "map", "control_socket_path" => @path, "state_root" => File.join(@root, "state"),
      "deliveries_dir" => File.join(@root, "events"), "socket_gid" => Process.gid,
      "owner_credentials" => {"uid" => Process.uid, "gid" => Process.gid, "groups" => Process.groups.sort.uniq},
      "key" => {"public_key_path" => File.join(@root, "public.pem"), "configuration_path" => File.join(@root, "key.json")},
      "authority" => {"uid" => Process.uid + 100, "gid" => Process.gid, "groups" => [], "socket_path" => File.join(@root, "authority.sock")},
      "grants" => [{"uid" => Process.uid + 100, "gid" => Process.gid, "groups" => [], "role" => "authority", "purposes" => %w[deliver enqueue reconcile]}]}
    bytes = JSON.generate(data)
    path = File.join(@root, "service.json")
    File.write(path, bytes)
    File.chmod(0o600, path)
    stage = {"schema" => "ace.herdr.inbox-context-stage/v1", "project_id" => "project", "inbox_context_id" => "ctx",
      "configuration" => {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}}
    @configuration = Configuration.load(stage: stage, artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new(
      protection: InboxContextOwnerFixture::FixtureArtifacts.new(@root)))
    @listener = Listener.new(configuration: @configuration, server: @server, kernel: @kernel, protection: Protection.new)
    @clients = []
  end

  def teardown
    8.times { @server.release << true }
    @listener.stop if @thread&.alive?
    @thread&.join(1)
    @clients.each(&:close)
    FileUtils.remove_entry(@root)
  end

  def start
    @thread = Thread.new do
      @listener.serve
    rescue ERROR => error
      @serve_error = error
    end
    Timeout.timeout(2) do
      loop do
        raise @serve_error if @serve_error
        break if File.socket?(@path) && File.lstat(@path).then { |stat| stat.gid == Process.gid && (stat.mode & 0o777) == 0o660 }
        Thread.pass
      end
    end
  end

  def connect
    socket = UNIXSocket.new(@path)
    @clients << socket
    socket
  end

  def test_actual_socket_has_exact_group_and_bounded_handler_population
    start
    stat = File.lstat(@path)
    assert_equal Process.gid, stat.gid
    assert_equal 0o660, stat.mode & 0o777
    8.times do
      connect
      Timeout.timeout(2) { @server.entered.pop }
    end
    extra = connect
    assert_nil Timeout.timeout(2) { extra.read(1) }
    8.times { @server.release << true }
    assert @listener.stop
    assert @thread.join(2)
    assert_nil @serve_error
    refute File.exist?(@path)
  end

  def test_stop_deadline_cannot_be_refreshed_and_retains_unresolved_handler
    start
    connect
    Timeout.timeout(2) { @server.entered.pop }
    assert_raises(ERROR) { @listener.stop(deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC)) }
    assert_raises(ERROR) { @listener.stop }
    @server.release << true
    Timeout.timeout(2) do
      loop do
        begin
          break if @listener.stop
        rescue ERROR
          Thread.pass
        end
      end
    end
  end

  def test_foreign_principal_and_regular_endpoint_are_refused_without_unlink
    @kernel.foreign = true
    assert_raises(ERROR) { @listener.serve }
    refute File.exist?(@path)
    @kernel.foreign = false
    File.write(@path, "foreign")
    assert_raises(ERROR) { @listener.serve }
    assert_equal "foreign", File.read(@path)
  end

  def test_exclusive_lease_and_replacement_endpoint_keep_exact_identity
    start
    contender = Listener.new(configuration: @configuration, server: @server, kernel: @kernel, protection: Protection.new)
    assert_raises(ERROR) { contender.serve }
    original = File.lstat(@path).ino
    File.unlink(@path)
    replacement = UNIXServer.new(@path)
    assert @listener.stop
    assert @thread.join(2)
    assert File.socket?(@path)
    refute_equal original, File.lstat(@path).ino
  ensure
    replacement&.close
  end

  def test_dead_observed_owner_never_publishes_endpoint
    @kernel.dead = true
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { @listener.serve }
    refute File.exist?(@path)
    refute File.exist?("#{@path}.lock")
  end

  def test_private_socket_parent_cannot_hide_cross_principal_inaccessibility
    File.chmod(0o700, @root)
    assert_raises(ERROR) { @listener.serve }
    refute File.exist?(@path)
    refute File.exist?("#{@path}.lock")
  end
end

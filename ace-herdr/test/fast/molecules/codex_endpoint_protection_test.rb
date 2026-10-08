# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/herdr/molecules/codex_runtime_selection"

class CodexEndpointProtectionTest < Minitest::Test
  Protection = Ace::Herdr::Molecules::CodexRuntimeSelection::EndpointProtection
  ERROR = Ace::Herdr::ValidationError
  UID = GID = 13001
  ADVERTISED = "/run/codex/server.sock"
  DAEMON = "/tmp/codex-daemon-#{UID}"
  PHYSICAL = "#{DAEMON}/#{Digest::SHA256.hexdigest(ADVERTISED)}"

  Stat = Struct.new(:dev, :ino, :uid, :gid, :mode) do
    def directory? = (mode & 0o170000) == 0o040000
    def socket? = (mode & 0o170000) == 0o140000
    def symlink? = (mode & 0o170000) == 0o120000
  end
  Handle = Struct.new(:stat, :mount, :closed) do
    def close = self.closed = true
    def closed? = closed
  end
  class Files
    attr_reader :handles, :nodes, :mounts, :acls
    attr_accessor :target
    def initialize
      @handles, @nodes, @mounts, @acls = [], {}, {}, []
      {"/" => [0, 0, 0o040755], "/run" => [0, 0, 0o040755], "/run/codex" => [UID, GID, 0o040750],
        "/tmp" => [0, 0, 0o041777], DAEMON => [UID, GID, 0o040700],
        ADVERTISED => [UID, GID, 0o120777], PHYSICAL => [UID, GID, 0o140600]}.each_with_index do |(path, (uid, gid, mode)), i|
        @nodes[path] = Stat.new(1, i + 1, uid, gid, mode).freeze
        @mounts[path] = {"mount_id" => 4, "filesystem_type" => "ext4"}.freeze
      end
      @target = PHYSICAL
    end
    def realpath(path) = path
    def lstat(path) = nodes.fetch(path)
    def readlink(path) = path == ADVERTISED ? target : raise("unselected alias")
    def open_node(path)
      handle = Handle.new(lstat(path), mounts.fetch(path), false)
      handles << handle
      handle
    end
    def acl_absent!(path, attribute, symlink: false)
      raise ERROR, "controlled ACL present" if acls.include?([path, attribute])
    end
    def replace(path, **changes)
      nodes[path] = Stat.new(**nodes.fetch(path).to_h.merge(changes)).freeze
    end
  end
  class Mounts
    def mount_identity(handle) = handle.mount
  end
  def setup
    @files = Files.new
    @protection = Protection.new(files: @files, mounts: Mounts.new)
  end
  def with_endpoint(&block) = @protection.with(ADVERTISED, uid: UID, gid: GID, &block)

  def test_native_rendezvous_resolves_and_holds_both_nodes_and_protected_directories
    selected = nil
    with_endpoint do |endpoint|
      selected = endpoint
      assert_equal PHYSICAL, endpoint.fetch(:physical_path)
      assert @protection.verify!(endpoint)
      assert @files.handles.any? { |handle| handle.stat.symlink? && !handle.closed? }
      assert @files.handles.any? { |handle| handle.stat.socket? && !handle.closed? }
    end
    assert @files.handles.all?(&:closed?)
    assert_raises(ERROR) { @protection.verify!(selected) }
  end

  def test_exact_native_alias_in_fixed_root_sticky_tmp_is_protected
    advertised = "/tmp/selected-codex.sock"
    physical = "#{DAEMON}/#{Digest::SHA256.hexdigest(advertised)}"
    @files.nodes[advertised] = @files.nodes.delete(ADVERTISED)
    @files.nodes[physical] = @files.nodes.delete(PHYSICAL)
    @files.mounts[advertised] = @files.mounts.fetch(ADVERTISED)
    @files.mounts[physical] = @files.mounts.fetch(PHYSICAL)
    @files.target = physical
    @files.define_singleton_method(:readlink) { |_path| target }
    @protection.with(advertised, uid: UID, gid: GID) do |endpoint|
      assert_equal physical, endpoint.fetch(:physical_path)
      assert @protection.verify!(endpoint)
    end
    assert @files.handles.all?(&:closed?)
  end

  def test_wrong_alias_native_modes_principal_or_writable_ancestry_refuse
    [-> { @files.target = "#{DAEMON}/unselected" },
      -> { @files.replace(PHYSICAL, mode: 0o140660) },
      -> { @files.replace(DAEMON, mode: 0o040750) },
      -> { @files.replace(ADVERTISED, uid: UID + 1) },
      -> { @files.replace("/run/codex", mode: 0o040770) },
      -> { @files.replace("/tmp", mode: 0o040777) }].each do |corrupt|
      setup
      corrupt.call
      assert_raises(ERROR) { with_endpoint { flunk "unprotected endpoint admitted" } }
      assert @files.handles.all?(&:closed?)
    end
  end

  def test_alias_or_socket_replacement_and_mount_alias_refuse_before_scope_exit
    [-> { @files.replace(ADVERTISED, ino: 100) },
      -> { @files.replace(PHYSICAL, ino: 101) },
      -> { @files.mounts[PHYSICAL] = {"mount_id" => 99, "filesystem_type" => "ext4"} }].each do |replace|
      setup
      assert_raises(ERROR) { with_endpoint { replace.call } }
      assert @files.handles.all?(&:closed?)
    end
  end

  def test_new_default_acl_and_callback_error_close_every_original_handle
    assert_raises(ERROR) do
      with_endpoint { @files.acls << [DAEMON, "system.posix_acl_default"] }
    end
    assert @files.handles.all?(&:closed?)
    setup
    assert_raises(IOError) { with_endpoint { raise IOError, "caller failed" } }
    assert @files.handles.all?(&:closed?)
  end
end

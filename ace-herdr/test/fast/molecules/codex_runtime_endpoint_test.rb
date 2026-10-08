# frozen_string_literal: true

require "test_helper"
require "socket"
require "delegate"
require "ace/herdr/molecules/codex_runtime_selection"

# Filesystem identities are real; Linux ACL/mount and root ancestry ownership
# observations are injected. The selected native directory/socket owner is real.
class CodexRuntimeEndpointTest < Minitest::Test
  Protection = Ace::Herdr::Molecules::CodexRuntimeSelection::EndpointProtection
  ERROR = Ace::Herdr::ValidationError

  def setup
    @root = File.realpath(Dir.mktmpdir("cx", "/tmp"))
    @parent = File.join(@root, "parent")
    Dir.mkdir(@parent)
    File.chown(-1, Process.gid, @parent)
    File.chmod(0o750, @parent)
    @path = File.join(@parent, "server.sock")
    @server = UNIXServer.new(@path)
    File.chmod(0o660, @path)
    @directory = File.open(@parent, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
    @selected = {path: @path, socket: identity(File.lstat(@path)),
      ancestors: [[@parent, @directory, identity(@directory.stat)]]}
    mounts = Object.new
    mounts.define_singleton_method(:mount_identity) { |_| {"filesystem_type" => "ext4"} }
    @protection = Protection.new(mounts: mounts)
  end

  def teardown
    @directory.close unless @directory.closed?
    @server.close unless @server.closed?
    @replacement&.close
    FileUtils.remove_entry(@root)
  end

  def test_rechecks_original_socket_and_held_parent_without_native_acl_probe
    without_acl { assert @protection.verify!(@selected) }
    File.chmod(0o600, @path)
    without_acl { assert_raises(ERROR) { @protection.verify!(@selected) } }
  end

  def test_replaced_socket_inode_refuses_even_with_identical_mode
    File.unlink(@path)
    @replacement = UNIXServer.new(@path)
    File.chmod(0o660, @path)
    without_acl { assert_raises(ERROR) { @protection.verify!(@selected) } }
  end

  def test_renamed_parent_cannot_redirect_held_endpoint_to_replacement
    File.rename(@parent, @parent + "-old")
    Dir.mkdir(@parent)
    @replacement = UNIXServer.new(@path)
    File.chmod(0o660, @path)
    without_acl { assert_raises(ERROR) { @protection.verify!(@selected) } }
  end

  def test_closed_parent_handle_and_acl_refusal_fail_closed
    @directory.close
    without_acl { assert_raises(ERROR) { @protection.verify!(@selected) } }
    @directory = File.open(@parent, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
    @selected[:ancestors] = [[@parent, @directory, identity(@directory.stat)]]
    @protection.stub(:acl_absent!, ->(*) { raise ERROR, "controlled ACL refusal" }) do
      assert_raises(ERROR) { @protection.verify!(@selected) }
    end
  end

  def test_positive_native_owner_creates_socket_under_only_selected_directory_exception
    assert_operator Process.uid, :>, 0
    assert_equal Process.uid, File.stat(@parent).uid
    assert_equal Process.uid, File.lstat(@path).uid
    held = nil
    with_controlled_ancestry do
      @protection.with(@path, uid: Process.uid, gid: Process.gid) do |selected|
        held = selected.fetch(:ancestors).map { |_, handle, _| handle }
        assert @protection.verify!(selected)
        assert_equal identity(File.lstat(@path)), selected.fetch(:socket)
      end
    end
    assert held.all?(&:closed?)
  end

  def test_wrong_native_owner_and_native_owned_or_writable_ancestor_refuse
    [{wrong_native_owner: true}, {native_ancestor: true}, {writable_ancestor: true}].each do |options|
      with_controlled_ancestry(**options) do
        assert_raises(ERROR) do
          @protection.with(@path, uid: Process.uid, gid: Process.gid) { flunk "unsafe ancestry admitted" }
        end
      end
    end
  end

  def test_admitted_native_directory_cannot_redirect_socket_to_same_uid_replacement
    with_controlled_ancestry do
      assert_raises(ERROR) do
        @protection.with(@path, uid: Process.uid, gid: Process.gid) do
          File.unlink(@path)
          @replacement = UNIXServer.new(@path)
          File.chmod(0o660, @path)
          assert_equal Process.uid, File.lstat(@path).uid
        end
      end
    end
  end

  def test_root_native_principal_refuses_before_directory_open
    assert_raises(ERROR) { @protection.with(@path, uid: 0, gid: Process.gid) { flunk "root native admitted" } }
  end

  private

  def identity(stat) = [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode].freeze
  def without_acl(&block) = @protection.stub(:acl_absent!, ->(*) { true }, &block)

  def with_controlled_ancestry(wrong_native_owner: false, native_ancestor: false, writable_ancestor: false)
    original_open, original_lstat = File.method(:open), File.method(:lstat)
    observed = lambda do |path, stat|
      value = SimpleDelegator.new(stat)
      native = [@parent, @path].include?(path)
      owner = native ? stat.uid : 0
      owner = Process.uid + 1 if wrong_native_owner && path == @parent
      owner = Process.uid if native_ancestor && path == @root
      mode = native ? stat.mode : stat.mode & ~0o022
      mode |= 0o020 if writable_ancestor && path == @root
      value.define_singleton_method(:uid) { owner }
      value.define_singleton_method(:mode) { mode }
      value
    end
    opener = lambda do |path, *arguments|
      handle = original_open.call(path, *arguments)
      selected = SimpleDelegator.new(handle)
      selected.define_singleton_method(:stat) { observed.call(path, handle.stat) }
      selected
    end
    root_policy = lambda do |path, directory:|
      assert directory
      assert_equal File.dirname(@parent), path
    end
    Ace::Runtime::Molecules::ProtectedSocket.stub(:root_path!, root_policy) do
      File.stub(:open, opener) do
        File.stub(:lstat, ->(path) { observed.call(path, original_lstat.call(path)) }) do
          without_acl { yield }
        end
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"
require "socket"
require "ace/herdr/molecules/codex_runtime_selection"

# Filesystem identities are real; only the Linux ACL observation is injected.
class CodexRuntimeEndpointTest < Minitest::Test
  Protection = Ace::Herdr::Molecules::CodexRuntimeSelection::EndpointProtection
  ERROR = Ace::Herdr::ValidationError

  def setup
    @root = File.realpath(Dir.mktmpdir("cx", "/tmp"))
    @parent = File.join(@root, "parent")
    Dir.mkdir(@parent)
    @path = File.join(@parent, "server.sock")
    @server = UNIXServer.new(@path)
    File.chmod(0o660, @path)
    @directory = File.open(@parent, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
    @selected = {path: @path, socket: identity(File.lstat(@path)),
      ancestors: [[@parent, @directory, identity(@directory.stat)]]}
    @protection = Protection.new
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

  private

  def identity(stat) = [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode].freeze
  def without_acl(&block) = @protection.stub(:acl_absent!, ->(*) { true }, &block)
end

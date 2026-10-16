# frozen_string_literal: true

require "test_helper"
require "timeout"
require "ace/hitl/lifecycle/tls_authority"

class TlsAuthorityTest < AceHitlTestCase
  Authority = Ace::Hitl::Lifecycle::TlsAuthority
  Artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet
  Error = Ace::Hitl::Lifecycle::TransportError

  # Host tests exercise real bounded descriptors and inode checks; the Linux
  # installer fixture separately proves root ownership and filesystem policy.
  class FixtureProtection
    def initialize(root) = @root = root
    def root_path!(_path); end
    def verify!(path, handle, directory:)
      return unless path == @root || path.start_with?(@root + "/")
      if (handle.stat.mode & 0o022).positive?
        raise Ace::Runtime::RuntimeUnavailableError, "fixture path is writable"
      end
    end
  end

  def setup
    @root = File.realpath(Dir.mktmpdir("hitl-tls-authority"))
    @path = File.join(@root, "authority.json")
    @document = {"schema" => Authority::SCHEMA, "project_id" => "atlas", "listen" => "127.0.0.1",
      "port" => 8431, "service_user" => "atlas-owner", "service_group" => "atlas-owner",
      "tls_server_credential" => {
        "certificate_file" => "/etc/ace-hitl/atlas/server.pem", "private_key_file" => "/etc/ace-hitl/atlas/key.pem",
        "ca_file" => "/etc/ace-hitl/atlas/ca.pem", "server_uri_san" => "urn:ace:hitl:atlas:lifecycle-server",
        "allowed_client_uri_san" => "urn:ace:hitl:atlas:hermes-client", "allowed_client_certificate_sha256" => "a" * 64}}
    File.write(@path, JSON.generate(@document))
    File.chmod(0o640, @path)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def load_fixture(path = @path, during_mode_check: nil)
    reader = Artifacts.new(protection: FixtureProtection.new(@root), file_limit: Authority::MAX_BYTES,
      total_limit: Authority::MAX_BYTES)
    check = lambda do |selected, service_group:|
      assert_equal path, selected
      assert_equal "atlas-owner", service_group
      assert_equal 0o640, File.stat(selected).mode & 0o7777
      during_mode_check&.call
    end
    Artifacts.stub(:new, reader) do
      Ace::Hitl::Lifecycle::CredentialPathPolicy.stub(:verify_runtime_file!, check) { Authority.load(path) }
    end
  end

  def test_parses_the_retained_bytes_and_preserves_exact_runtime_mode_check
    authority = load_fixture
    assert_equal "atlas", authority.project_id
    assert_equal @path, authority.path
    assert_equal 8431, authority.port
  end

  def test_regular_file_size_is_bounded_before_json_parsing
    File.write(@path, " " * (Authority::MAX_BYTES + 1))
    assert_raises(Error) { load_fixture }
  end

  def test_fifo_is_refused_without_waiting_for_a_writer
    File.unlink(@path)
    File.mkfifo(@path, 0o640)
    Timeout.timeout(1) { assert_raises(Error) { load_fixture } }
  end

  def test_symlink_leaf_and_ancestor_are_refused
    File.rename(@path, @path + ".real")
    File.symlink(@path + ".real", @path)
    assert_raises(Error) { load_fixture }
    File.unlink(@path)
    nested = File.join(@root, "nested")
    Dir.mkdir(nested, 0o750)
    File.rename(@path + ".real", File.join(nested, "authority.json"))
    File.symlink(nested, File.join(@root, "redirect"))
    assert_raises(Error) { load_fixture(File.join(@root, "redirect", "authority.json")) }
  end

  def test_writable_ancestor_cannot_authorize_configuration
    File.chmod(0o770, @root)
    assert_raises(Error) { load_fixture }
  ensure
    File.chmod(0o700, @root)
  end

  def test_leaf_replacement_between_parse_and_exact_mode_check_is_refused
    replacement = -> do
      File.rename(@path, @path + ".old")
      File.write(@path, JSON.generate(@document))
      File.chmod(0o640, @path)
    end
    assert_raises(Error) { load_fixture(during_mode_check: replacement) }
  end

  def test_content_change_and_newly_writable_ancestor_before_return_are_refused
    change = -> { File.write(@path, JSON.generate(@document.merge("port" => 8432))) }
    assert_raises(Error) { load_fixture(during_mode_check: change) }
    assert_raises(Error) { load_fixture(during_mode_check: -> { File.chmod(0o770, @root) }) }
  ensure
    File.chmod(0o700, @root)
  end

  def test_default_reader_refuses_caller_owned_runtime_without_a_test_seam
    skip "requires unprivileged caller" if Process.uid.zero?
    assert_raises(Error) { Authority.load(@path) }
  end
end

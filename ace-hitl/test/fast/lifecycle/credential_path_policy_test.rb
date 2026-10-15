# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "etc"

# The exact provisioning layout of the crossing (spec 8xa.t.nh0): one
# ownership/mode matrix, fail closed, no alternatives. The exact-owner
# matrix requires root to construct (root:root ancestors, root:group
# leaf, service-owned key) and joins gad.8/gad.b installed acceptance;
# the structural refusals (missing, symlinked, non-regular objects and
# unknown service identities) are verified unprivileged.
class CredentialPathPolicyTest < AceHitlTestCase
  SERVICE_USER = "daemon"
  SERVICE_GROUP = "daemon"

  def setup
    skip "the daemon fixture account is unavailable" unless account_available?
    @scratch = Dir.mktmpdir("ace-hitl-credpath", "/tmp")
  end

  def teardown
    FileUtils.remove_entry(@scratch) if @scratch && File.exist?(@scratch)
  end

  def test_missing_files_are_refused
    tree = build_layout
    File.delete(tree[:key])
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) do
      verify(tree)
    end
    assert_match(/does not exist/, error.message)
  end

  def test_symlinked_files_and_components_are_refused
    tree = build_layout
    real = File.join(@scratch, "real-key.pem")
    FileUtils.mv(tree[:key], real)
    File.symlink(real, tree[:key])
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) do
      verify(tree)
    end
    assert_match(/symlink|regular file/, error.message)

    tree = build_layout
    link_dir = File.join(@scratch, "link")
    File.symlink(File.dirname(tree[:cert]), link_dir)
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) do
      verify(tree.merge(cert: File.join(link_dir, "server.pem")))
    end
    # Unprivileged runs hit the ownership refusal first; the exact
    # symlinked-ancestor refusal joins the root-gated matrix.
    assert_match(/ancestor|wrong owner|symlink/, error.message)
  end

  def test_non_regular_files_are_refused
    tree = build_layout
    File.delete(tree[:cert])
    File.mkfifo(tree[:cert])
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) do
      verify(tree)
    end
    assert_match(/regular file/, error.message)
  end

  def test_unknown_service_identities_fail_closed
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) do
      Ace::Hitl::Lifecycle::CredentialPathPolicy.verify_credential_tree!(
        credential: credential_hash(build_layout), service_user: "no-such-ace-hitl-user",
        service_group: SERVICE_GROUP)
    end
    assert_match(/service user does not exist/, error.message)

    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) do
      Ace::Hitl::Lifecycle::CredentialPathPolicy.verify_runtime_file!(
        File.join(@scratch, "runtime.json"), service_group: "no-such-ace-hitl-group")
    end
    assert_match(/service group does not exist/, error.message)
  end

  def test_runtime_file_rejects_wrong_owner_mode_or_type
    path = File.join(@scratch, "runtime.json")
    File.write(path, "{}")
    File.chmod(0o640, path)
    # Never root-owned in an unprivileged test run: the exact positive
    # layout joins the root-gated matrix below.
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) do
      Ace::Hitl::Lifecycle::CredentialPathPolicy.verify_runtime_file!(path, service_group: "daemon")
    end
    assert_match(/root:<service-group> mode 0640/, error.message)

    File.chmod(0o644, path)
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) do
      Ace::Hitl::Lifecycle::CredentialPathPolicy.verify_runtime_file!(path, service_group: "daemon")
    end
    assert_match(/root:<service-group> mode 0640/, error.message)
  end

  # ---- exact owner/mode matrix: requires root (joins gad.8/gad.b) ----

  def test_exact_layout_is_accepted_for_the_service_identity
    skip "exact provisioning layout requires root (re-run under sudo/CI); joins gad.8/gad.b" unless Process.euid.zero?

    tree = build_layout
    verify(tree)

    positive = build_layout(key_mode: 0o400)
    verify(positive)
  end

  def test_over_broad_or_wrong_modes_are_refused
    skip "exact provisioning layout requires root (re-run under sudo/CI); joins gad.8/gad.b" unless Process.euid.zero?

    [[0o440, /wrong owner or mode/], [0o444, /wrong owner or mode/], [0o400 & ~0o100, /wrong owner or mode/]].each do |mode, expected|
      tree = build_layout(key_mode: mode)
      error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) { verify(tree) }
      assert_match(expected, error.message)
    end

    tree = build_layout(cert_mode: 0o644)
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) { verify(tree) }
    assert_match(/wrong owner or mode/, error.message)

    tree = build_layout(leaf_mode: 0o770)
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) { verify(tree) }
    assert_match(/root:<service-group> mode 0750/, error.message)

    tree = build_layout(ancestor_mode: 0o775)
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) { verify(tree) }
    assert_match(/root:root mode 0755/, error.message)
  end

  def test_wrong_ownership_substitution_is_refused
    skip "exact provisioning layout requires root (re-run under sudo/CI); joins gad.8/gad.b" unless Process.euid.zero?

    tree = build_layout
    File.chown(0, 0, tree[:key])
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) { verify(tree) }
    assert_match(/wrong owner or mode/, error.message)

    tree = build_layout
    File.chown(0, gid_of(SERVICE_GROUP), tree[:cert])
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) { verify(tree) }
    assert_match(/wrong owner or mode/, error.message)

    tree = build_layout
    File.chown(0, gid_of(SERVICE_GROUP), File.dirname(tree[:cert]))
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) { verify(tree) }
    assert_match(/root:<service-group> mode 0750/, error.message)
  end

  def test_hard_linked_private_key_is_refused
    skip "exact provisioning layout requires root (re-run under sudo/CI); joins gad.8/gad.b" unless Process.euid.zero?

    tree = build_layout
    File.link(tree[:key], File.join(@scratch, "hardlink.pem"))
    error = assert_raises(Ace::Hitl::Lifecycle::CredentialPathPolicy::Error) { verify(tree) }
    assert_match(/hard-linked/, error.message)
  end

  def test_exact_root_owned_runtime_file_is_accepted
    skip "exact provisioning layout requires root (re-run under sudo/CI); joins gad.8/gad.b" unless Process.euid.zero?

    path = File.join(@scratch, "runtime.json")
    File.write(path, "{}")
    File.chown(0, gid_of(SERVICE_GROUP), path)
    File.chmod(0o640, path)
    assert_same Ace::Hitl::Lifecycle::CredentialPathPolicy,
      Ace::Hitl::Lifecycle::CredentialPathPolicy.verify_runtime_file!(path, SERVICE_GROUP).class
  end

  # ---- fixtures ----

  # Ownership is applied only where the OS permits: the structural
  # refusals (missing, symlink, non-regular) fire before the ownership
  # check, so unprivileged runs exercise them against an unprivileged
  # tree; the exact owner/mode matrix runs only under root.
  def build_layout(key_mode: 0o400, cert_mode: 0o444, leaf_mode: 0o750, ancestor_mode: 0o755)
    service_gid = Process.euid.zero? ? gid_of(SERVICE_GROUP) : Process.gid
    root_dir = File.join(@scratch, "tree")
    project_dir = File.join(root_dir, "proj")
    FileUtils.mkdir_p(project_dir)
    File.chmod(ancestor_mode, root_dir)
    File.chmod(leaf_mode, project_dir)

    cert = File.join(project_dir, "server.pem")
    key = File.join(project_dir, "server-key.pem")
    ca = File.join(project_dir, "ca.pem")
    FileUtils.rm_f([cert, key, ca])
    File.write(cert, "certificate")
    File.write(key, "private key")
    File.write(ca, "bundle")
    File.chmod(cert_mode, cert)
    File.chmod(cert_mode, ca)
    File.chmod(key_mode, key)
    if Process.euid.zero?
      File.chown(0, 0, root_dir)
      File.chown(0, service_gid, project_dir)
      File.chown(0, 0, cert)
      File.chown(0, 0, ca)
      File.chown(uid_of(SERVICE_USER), service_gid, key)
    end
    {cert: cert, key: key, ca: ca}
  end

  def credential_hash(tree)
    {
      "certificate_file" => tree[:cert], "private_key_file" => tree[:key], "ca_file" => tree[:ca],
      "server_uri_san" => "urn:ace:hitl:proj:lifecycle-server",
      "allowed_client_uri_san" => "urn:ace:hitl:proj:hermes-client",
      "allowed_client_certificate_sha256" => "a" * 64
    }
  end

  def verify(tree)
    Ace::Hitl::Lifecycle::CredentialPathPolicy.verify_credential_tree!(
      credential: credential_hash(tree), service_user: SERVICE_USER, service_group: SERVICE_GROUP)
  end

  def uid_of(name)
    Etc.getpwnam(name).uid
  end

  def gid_of(name)
    Etc.getgrnam(name).gid
  end

  def account_available?
    Etc.getpwnam(SERVICE_USER) && Etc.getgrnam(SERVICE_GROUP)
  rescue ArgumentError
    false
  end
end

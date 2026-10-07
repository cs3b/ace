# frozen_string_literal: true

module InboxContextOwnerFixture
  Owner = Ace::Herdr::Organisms::InboxContextOwner
  Store = Ace::Herdr::Molecules::InboxContextStore
  Keys = Ace::Herdr::Molecules::InboxContextKey
  KEY = OpenSSL::PKey::RSA.new(2048)
  NEXT_KEY = OpenSSL::PKey::RSA.new(2048)
  ERROR = Ace::Herdr::ValidationError

  # Only kernel/protected-install observations are injected. Storage, hashes,
  # public RSA/signature checks, retained inventory, fsync and flocks are real.
  class Kernel
    attr_accessor :dead
    def live!(peer)
      raise Ace::Runtime::RuntimeUnavailableError, "injected unreadable original process" if dead == peer["pid"]
      true
    end
    def same?(left, right) = left == right
  end

  class FixturePaths
    def root_path!(path, directory:, owner:)
      stat = File.lstat(path)
      raise ERROR, "fixture root is unsafe" unless directory && stat.directory? && !stat.symlink? && stat.uid == owner
    end
  end

  class FixtureArtifacts
    def initialize(root) = @root = root
    def root_path!(path)
      raise ERROR, "unexpected fixture path" unless path.start_with?(@root + "/")
    end
    def verify!(path, handle, directory:)
      stat = handle.stat
      raise ERROR, "fixture artifact type differs" unless directory ? stat.directory? : stat.file?
      if path.start_with?(@root)
        raise ERROR, "fixture artifact protection differs" unless stat.uid == Process.uid && (stat.mode & 0o022).zero?
      end
    end
  end

  class NativeFixture
    def submit(**_arguments) = {"accepted" => true, "stdout" => "controlled receipt"}
  end

  class PaneFixture
    def pane_get_bounded(_id)
      pane = {"pane_id" => "p1", "workspace_id" => "ws1", "terminal_id" => "term1",
        "agent" => "codex", "agent_status" => "busy",
        "agent_session" => {"agent" => "codex", "kind" => "id", "value" => "0123abcd-0000-4000-8000-000000000001"}}
      Ace::Herdr::Molecules::ExecutionResult.new(stdout: JSON.generate("result" => {"pane" => pane}),
        stderr: "", success: true, exit_code: 0)
    end
  end

  def setup
    @root = File.realpath(Dir.mktmpdir("context-owner"))
    @state = File.join(@root, "state")
    @events = File.join(@root, "events")
    [@state, @events].each { |path| Dir.mkdir(path, 0o700) }
    @key_path, @config_path = %w[public.pem key.json].map { |name| File.join(@root, name) }
    @kernel = Kernel.new
    @normal, @maintenance, @signer = [101, 202, 303].map { |uid| peer(uid) }
    @grants = [[@normal, "authority", %w[deliver enqueue reconcile]],
      [@maintenance, "maintenance", ["maintenance_inventory"]], [@signer, "signer", ["observe_to_sign"]]].map do |identity, role, purposes|
      identity.slice("uid", "gid", "groups").merge("role" => role, "purposes" => purposes)
    end
    install(KEY, 1)
    start_owner
    @owner.provision!
  end

  def teardown
    @store&.close
    FileUtils.remove_entry(@root)
  end

  def peer(uid)
    {"pid" => uid + 1000, "uid" => uid, "gid" => uid, "groups" => [uid], "parent_pid" => 1,
      "host" => "controlled", "started_at" => "linux:00000000-0000-0000-0000-000000000001:42"}
  end

  def start_owner
    artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: FixtureArtifacts.new(@root))
    @keys = Keys.new(context_id: "ctx", public_key_path: @key_path, config_path: @config_path, artifacts: artifacts)
    @store = Store.new(root: @state, uid: Process.uid, protection: FixturePaths.new)
    @owner = Owner.new(context_id: "ctx", deliveries_dir: @events, grants: @grants,
      store: @store, keys: @keys, kernel: @kernel, inbox: @source_inbox, completion: @completion)
  end

  def restart
    @store.close
    start_owner
  end

  def install(key, generation)
    bytes = key.public_key.to_pem
    File.write(@key_path, bytes)
    config = {"schema" => "ace.herdr.inbox-key/v1", "context_id" => "ctx", "key_generation" => generation,
      "public_key_sha256" => Digest::SHA256.hexdigest(bytes)}
    File.write(@config_path, JSON.generate(config))
    @config_digest = Digest::SHA256.file(@config_path).hexdigest
  end

  def prepare_reconciliation(inbox_class = Ace::Herdr::Organisms::Inbox)
    @source_inbox = inbox_class.new(executor: PaneFixture.new, native: NativeFixture.new,
      deliveries_dir: @events, receipt_public_key: KEY.public_key)
    @source_inbox.enqueue(event: "event1", attempt: "attempt1", ref: {"session" => "ws1", "pane" => "p1"}, payload: "controlled secret message")
    delivered = @source_inbox.deliver(event: "event1")
    receipt = delivered.slice("event_id", "attempt_id", "claim_generation", "payload_sha256", "binding").merge(
      "outcome" => "consumed", "observer" => {"role" => "supervisor", "id" => "controlled"},
      "evidence" => {"kind" => "consumed_acknowledged", "native_reference" => "controlled-item", "observation" => "completed"})
    @signed_bytes = JSON.generate(receipt)
    @signature = KEY.sign(OpenSSL::Digest::SHA256.new, @signed_bytes)
    restart
    operation = begin_operation("reconcile")
    @effect_binding = {"schema" => "ace.herdr.inbox-context-effect/v1", "project_id" => "project", "assignment_id" => "assignment",
      "attempt_id" => "attempt1", "mapping_id" => "mapping", "inbox_context_id" => "ctx", "event_id" => "event1", "mutation_id" => "mutation",
      "operation_id" => operation.fetch("operation_id"), "key_generation" => 1,
      "registration" => delivered.slice("event_id", "attempt_id", "payload_sha256", "receipt_key_sha256"),
      "receipt_sha256" => Digest::SHA256.hexdigest(@signed_bytes), "signature_sha256" => Digest::SHA256.hexdigest(@signature)}
  end

  def begin_operation(purpose = "enqueue", identity = @normal)
    @owner.begin_context_operation(context_id: "ctx", purpose: purpose, event_id: "event1", process_binding: identity, peer: identity)
  end

  def begin_rotation
    @owner.begin_rotation(context_id: "ctx", expected_key_generation: 1, peer: @maintenance)
  end

  def attestation(rotation, key, disposition: "replacement", identity: @signer)
    params = {rotation_id: rotation.fetch("rotation_id"), new_public_key_bytes: key.public_key.to_pem,
      installed_config_digest: @config_digest, disposition: disposition}
    body = @owner.rotation_challenge(**params, peer: identity)
    signature = [key.sign(OpenSSL::Digest::SHA256.new, JSON.generate(body))].pack("m0")
    @owner.attest_rotation(**params, expected_key_generation: 1, signature: signature, peer: identity)
  end

  def commit(rotation, accepted)
    @owner.commit_rotation(rotation_id: rotation.fetch("rotation_id"), expected_key_generation: 1,
      new_public_key_bytes: NEXT_KEY.public_key.to_pem, installed_config_digest: @config_digest,
      signer_keypair_attestation: accepted, peer: @maintenance)
  end

end

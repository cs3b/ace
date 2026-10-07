# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/protected_task_context_entry"
require "tmpdir"
require "fileutils"
require "fcntl"

class ProtectedTaskContextEntryTest < AceRuntimeTestCase
  Owner = Ace::Runtime::Molecules::ProtectedTaskContextEntry

  # Root/mount enforcement is injected; real held descriptors, bounded bytes,
  # digests, ancestor snapshots and same-inode handoff remain the source owner.
  class Protection
    def root_path!(_path); true; end
    def verify!(_path, handle, directory:)
      raise "wrong controlled artifact kind" unless directory ? handle.stat.directory? : handle.stat.file?
    end
  end

  class Artifacts
    def initialize(projection)
      @projection = projection
      @owner = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: Protection.new,
        file_limit: Owner::FILE_LIMIT, total_limit: Owner::TOTAL_LIMIT, count_limit: Owner::COUNT_LIMIT)
    end
    def with
      @owner.with { yield self }
    end
    def read_path!(path, limit:)
      raise "unexpected fixed projection" unless path == Owner::PATH
      @owner.read_path!(@projection, limit: limit)
    end
    def read!(reference); @owner.read!(reference); end
    def verify_unchanged!; @owner.verify_unchanged!; end
    def with_readonly_handle!(reference, &block); @owner.with_readonly_handle!(reference, &block); end
  end

  def artifact(root, name, bytes, executable: false)
    path = File.join(root, name)
    File.binwrite(path, bytes)
    File.chmod(executable ? 0o755 : 0o644, path)
    {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
  end

  def fixture
    Dir.mktmpdir("ace-entry-fixture-", File.realpath("/tmp")) do |root|
      wrapper = artifact(root, "wrapper.py", "# Exact accepted wrapper bytes.\n")
      interpreter = artifact(root, "python", "controlled interpreter", executable: true)
      bootstrap = %w[original_source owner preparation].to_h { |name| [name, artifact(root, "#{name}.json", "held #{name}")] }
      bootstrap["startup_entries"] = {"ace-assign" => artifact(root, "assign.rb", "held staged assign"), "thinking" => {}}
      manifest = {"schema" => Owner::MANIFEST_SCHEMA, "role" => Owner::ROLE, "wrapper" => wrapper, "interpreter" => interpreter, "bootstrap" => bootstrap}
      manifest_ref = artifact(root, "manifest.json", JSON.generate(manifest))
      pin = {"manifest" => manifest_ref, "wrapper" => wrapper}
      projection = File.join(root, "projection.json")
      File.binwrite(projection, JSON.generate("schema" => Owner::SCHEMA, "task_context_entry" => pin))
      owner = Owner.new(artifacts_factory: -> { Artifacts.new(projection) }, stat: ->(path) {
        raise "unexpected presence path" unless path == Owner::PATH
        File.lstat(projection)
      })
      yield owner, pin, manifest, projection
    end
  end

  def test_genuinely_absent_discovery_does_not_initialize_installed_artifacts
    paths = []
    owner = Owner.new(artifacts_factory: -> { raise "uninstalled must not probe artifacts" }, stat: ->(path) {
      paths << path
      raise Errno::ENOENT
    })
    assert_nil owner.with { |selection| selection }
    assert_equal [Owner::PATH, *Owner::PRESENCE_PATHS], paths
  end

  def test_present_or_inaccessible_installed_sentinel_refuses_absent_projection
    Owner::PRESENCE_PATHS.each do |sentinel|
      owner = Owner.new(artifacts_factory: -> { raise "no projection to authenticate" }, stat: ->(path) {
        next Object.new if path == sentinel
        raise Errno::ENOENT
      })
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { owner.with { flunk "must not fall back" } }
    end
    owner = Owner.new(stat: ->(_path) { raise Errno::EACCES }, artifacts_factory: -> { raise "must not probe" })
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { owner.with { flunk "must not fall back" } }
  end

  def test_exact_protected_role_retains_readonly_interpreter_and_raw_wrapper_for_callback_only
    fixture do |owner, pin, manifest, _|
      handle = nil
      owner.with do |selected|
        assert_equal pin, selected
        assert selected.frozen?
        owner.with_entry(selected) do |entry|
          assert_equal manifest, entry.manifest
          assert_equal "# Exact accepted wrapper bytes.\n", entry.body
          handle = entry.interpreter
          assert_equal Fcntl::O_RDONLY, handle.fcntl(Fcntl::F_GETFL) & Fcntl::O_ACCMODE
          assert entry.pin.fetch("manifest").frozen?
          assert entry.frozen?
        end
        assert handle.closed?
      end
    end
  end

  def test_duplicate_projection_and_tampered_interpreter_refuse_without_handoff
    fixture do |owner, _, _, projection|
      bytes = File.binread(projection)
      File.binwrite(projection, bytes.sub("{", '{"schema":"duplicate",'))
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { owner.with { flunk "duplicate projection admitted" } }
    end
    fixture do |owner, pin, manifest, _|
      File.binwrite(manifest.fetch("interpreter").fetch("path"), "changed interpreter")
      assert_raises(Ace::Runtime::RuntimeUnavailableError) do
        owner.with { owner.with_entry(pin) { flunk "changed interpreter handed off" } }
      end
    end
  end

  def test_changed_held_interpreter_is_detected_after_callback_and_handle_closed
    fixture do |owner, pin, manifest, _|
      handle = nil
      assert_raises(Ace::Runtime::RuntimeUnavailableError) do
        owner.with do
          owner.with_entry(pin) do |entry|
            handle = entry.interpreter
            File.binwrite(manifest.fetch("interpreter").fetch("path"), "changed during callback")
          end
        end
      end
      assert handle.closed?
    end
  end

  def test_valid_protected_manifest_for_worker_role_cannot_enter_task_context_boundary
    fixture do |owner, pin, manifest, projection|
      manifest["role"] = "ace-assign-worker"
      bytes = JSON.generate(manifest)
      File.binwrite(pin.fetch("manifest").fetch("path"), bytes)
      pin.fetch("manifest").merge!("bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes))
      File.binwrite(projection, JSON.generate("schema" => Owner::SCHEMA, "task_context_entry" => pin))
      assert_raises(Ace::Runtime::RuntimeUnavailableError) do
        owner.with { |selected| owner.with_entry(selected) { flunk "worker role entered context boundary" } }
      end
    end
  end
end

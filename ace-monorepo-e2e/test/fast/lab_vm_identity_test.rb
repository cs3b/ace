# frozen_string_literal: true
require_relative "../test_helper"
require "tmpdir"
require "fileutils"
load File.expand_path("../../bin/lab-vm", __dir__)

class LabVmIdentityTest < AceMonorepoE2eTestCase
  UUID = "F822848D-DA8E-4F74-894B-9CB7B7D6DBC1"

  def setup
    skip "UTM identity inspection requires macOS plutil" unless RUBY_PLATFORM.include?("darwin")
    @root = Dir.mktmpdir("lab-vm-identity")
    @name = "ace-e2e-work-fixture"
    @package = File.join(@root, "#{@name}.utm")
    FileUtils.mkdir_p(@package)
    File.write(File.join(@package, "config.plist"), <<~PLIST)
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0"><dict><key>Information</key><dict><key>UUID</key><string>#{UUID}</string></dict></dict></plist>
    PLIST
    @record = {"name" => @name, "uuid" => UUID}
  end

  def teardown
    FileUtils.remove_entry(@root) if @root && File.directory?(@root)
  end

  def test_inventory_rejects_error_text_and_malformed_rows
    assert_raises(RuntimeError) { LabVm.parse_inventory("Error from event: unavailable\n") }
    assert_raises(RuntimeError) { LabVm.parse_inventory("UUID Status Name\nnot-a-uuid stopped fixture\n") }
    assert_empty LabVm.parse_inventory("UUID Status Name\n")
  end

  def test_accepts_package_with_matching_uuid_beneath_utm_root
    assert_equal File.realpath(@package), LabVm.verify_package!("work", @record, root: @root)
  end

  def test_refuses_traversal_mismatched_uuid_and_wrong_role
    [{"name" => "ace-e2e-work-../other", "uuid" => UUID},
      {"name" => @name, "uuid" => "00000000-0000-0000-0000-000000000000"},
      {"name" => "ace-e2e-base-fixture", "uuid" => UUID}].each do |record|
      assert_raises(RuntimeError) { LabVm.verify_package!("work", record, root: @root) }
    end
  end

  def test_fingerprint_detects_content_changes_and_refuses_symlinks
    data = File.join(@package, "disk")
    File.write(data, "before")
    original = LabVm.package_fingerprint(@package)
    File.write(data, "after")
    refute_equal original, LabVm.package_fingerprint(@package)
    File.symlink("/dev/null", File.join(@package, "foreign"))
    assert_raises(RuntimeError) { LabVm.package_fingerprint(@package) }
  end

  def test_lifecycle_rejects_concurrent_commands_and_symlinked_lock
    LabVm.stub(:local_dir, @root) do
      LabVm.with_lifecycle_lock do
        assert_raises(RuntimeError) { LabVm.with_lifecycle_lock {} }
      end
      File.unlink(File.join(@root, "lifecycle.lock"))
      File.symlink("/dev/null", File.join(@root, "lifecycle.lock"))
      assert_raises(RuntimeError) { LabVm.with_lifecycle_lock {} }
    end
  end

  def test_timed_out_host_command_is_reaped_without_hanging
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    error = assert_raises(RuntimeError) do
      LabVm.capture_with_timeout(0.1, RbConfig.ruby, "-e", "sleep 30")
    end
    assert_includes error.message, "did not finish"
    assert_operator Process.clock_gettime(Process::CLOCK_MONOTONIC) - started, :<, 5
  end

  def test_staging_rejects_traversal_and_shell_metacharacters
    ["relative/path", "/tmp/../other", "/tmp/$(touch bad)", "/tmp/line\nbreak"].each do |path|
      assert_raises(RuntimeError) { LabVm.staging_command(path, "/tmp/destination") }
      assert_raises(RuntimeError) { LabVm.staging_command("/tmp/source", path) }
    end
  end

  def test_runtime_fingerprint_binds_scripts_manifest_and_lockfile
    LabVm::RUNTIME_INPUTS.each do |relative|
      path = File.join(@root, relative)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, relative)
    end
    before = LabVm.runtime_configuration_fingerprint(root: @root)
    lockfile = File.join(@root, "ace-monorepo-e2e/lab-vm/pi/package-lock.json")
    File.write(lockfile, "changed")
    refute_equal before, LabVm.runtime_configuration_fingerprint(root: @root)
    File.unlink(lockfile)
    File.symlink("/dev/null", lockfile)
    assert_raises(RuntimeError) { LabVm.runtime_configuration_fingerprint(root: @root) }
  end

  def test_failed_base_preparation_requests_shutdown_and_preserves_it
    operations = []
    LabVm.stub(:with_lifecycle_lock, ->(&block) { block.call }) do
      LabVm.stub(:prepare_base, -> { raise "readiness failed" }) do
        LabVm.stub(:status, {"base" => {"uuid" => UUID, "status" => "started"}}) do
          LabVm.stub(:utm_call, ->(*args) { operations << args }) do
            LabVm.stub(:wait_stopped, ->(role) { operations << ["wait", role] }) do
              _out, err = capture_io { assert_equal 1, LabVm.run(["prepare"]) }
              assert_includes err, "readiness failed"
            end
          end
        end
      end
    end
    assert_equal [["stop", UUID, "--request"], ["wait", "base"]], operations
  end

  def test_missing_work_is_never_forgotten_without_the_verified_export
    state = {"work" => @record.merge("phase" => "created")}
    current = {"work" => @record.merge("status" => "missing")}
    LabVm.stub(:evidence_dir, @root) do
      assert_raises(RuntimeError) { LabVm.remove_work(state, current) }
      assert_equal UUID, state.dig("work", "uuid")

      FileUtils.cp_r(@package, File.join(@root, "#{UUID}.utm"))
      state["work"]["phase"] = "exported"
      state["work"]["evidence_fingerprint"] = "incorrect"
      assert_raises(RuntimeError) { LabVm.remove_work(state, current) }
      assert_equal UUID, state.dig("work", "uuid")
    end
  end

  def test_missing_work_is_recovered_after_a_confirmed_export
    exported = File.join(@root, "#{UUID}.utm")
    FileUtils.cp_r(@package, exported)
    record = @record.merge("phase" => "exported", "evidence_fingerprint" => LabVm.package_fingerprint(exported))
    state = {"work" => record}
    current = {"work" => @record.merge("status" => "missing")}
    saved = nil
    LabVm.stub(:evidence_dir, @root) do
      LabVm.stub(:save_state, ->(value) { saved = value.dup }) do
        LabVm.remove_work(state, current)
      end
    end
    assert_equal({}, state)
    assert_equal({}, saved)
    assert File.directory?(exported)
  end

  def test_reset_rejects_changed_base_before_touching_work
    base = {"name" => "ace-e2e-base-fixture", "uuid" => UUID, "phase" => "ready", "fingerprint" => "prior",
      "configuration_fingerprint" => LabVm.base_configuration_fingerprint}
    state = {"base" => base, "work" => {"name" => @name, "uuid" => UUID}}
    current = {"base" => base.merge("status" => "stopped"), "work" => {"status" => "started"}}
    touched = false
    LabVm.stub(:read_state, state) do
      LabVm.stub(:status, current) do
        LabVm.stub(:verify_package!, @package) do
          LabVm.stub(:package_fingerprint, "changed") do
            LabVm.stub(:remove_work, ->(*) { touched = true }) do
              assert_raises(RuntimeError) { LabVm.reset }
            end
          end
        end
      end
    end
    refute touched
    assert_equal UUID, state.dig("work", "uuid")
  end

  def test_cloud_image_is_verified_and_symlinks_are_refused
    downloads = File.join(@root, "downloads")
    FileUtils.mkdir_p(downloads)
    image = File.join(downloads, "fixture.qcow2")
    File.write(image, "verified image")
    data = {"system" => {"cloud_image_url" => "https://cloud.debian.org/fixture.qcow2",
      "cloud_image_sha256" => Digest::SHA256.file(image).hexdigest}}
    LabVm.stub(:local_dir, @root) do
      LabVm.stub(:profile, data) do
        assert_equal image, LabVm.cloud_image
        File.write(image, "modified image")
        assert_raises(RuntimeError) { LabVm.cloud_image }
        File.unlink(image)
        File.symlink("/dev/null", image)
        assert_raises(RuntimeError) { LabVm.cloud_image }
      end
    end
  end

  def test_cloud_config_replaces_default_debian_sources_with_pinned_snapshot
    apt = LabVm.cloud_config("ssh-ed25519 fixture").fetch("apt")
    manifest = JSON.parse(File.read(File.join(LabVm::ROOT, "ace-monorepo-e2e/lab-vm/release-manifest.json")))
    snapshot = manifest.fetch("apt_snapshot").fetch("timestamp")
    assert_equal false, apt.fetch("preserve_sources_list")
    assert_equal false, apt.fetch("generate_mirrorlists")
    sources = apt.fetch("sources_list")
    assert_includes sources, "Types: deb\n"
    assert_includes sources, "https://snapshot.debian.org/archive/debian/#{snapshot}/"
    assert_includes sources, "https://snapshot.debian.org/archive/debian-security/#{snapshot}/"
    refute_includes sources, "deb.debian.org"
  end

  def test_incomplete_operator_key_pair_is_refused_without_overwriting_it
    bootstrap = File.join(@root, "bootstrap")
    Dir.mkdir(bootstrap, 0o700)
    key = File.join(bootstrap, "operator_ed25519")
    File.write(key, "preserve this file")
    File.chmod(0o600, key)
    LabVm.stub(:local_dir, @root) do
      assert_raises(RuntimeError) { LabVm.operator_public_key }
      assert_equal "preserve this file", File.read(key)
    end
  end

  def test_refuses_symlinked_package_and_configuration
    FileUtils.rm_rf(@package)
    Dir.mktmpdir("outside-vm") do |outside|
      File.symlink(outside, @package)
      assert_raises(RuntimeError) { LabVm.verify_package!("work", @record, root: @root) }
    end
    File.unlink(@package)
    FileUtils.mkdir_p(@package)
    File.symlink("/dev/null", File.join(@package, "config.plist"))
    assert_raises(RuntimeError) { LabVm.verify_package!("work", @record, root: @root) }
  end
end

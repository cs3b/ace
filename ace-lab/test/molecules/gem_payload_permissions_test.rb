# frozen_string_literal: true
require_relative "../test_helper"
require "ace/lab/molecules/gem_payload_permissions"

module Molecules
  class GemPayloadPermissionsTest < Minitest::Test
    def setup
      @home = Dir.mktmpdir
      @root = File.join(@home, "gems", "fixture-1.0")
      @payload = File.join(@root, "lib", "fixture.rb")
      @spec = File.join(@home, "specifications", "fixture-1.0.gemspec")
      @extension = File.join(@home, "extensions", "platform", "abi", "fixture-1.0")
      FileUtils.mkdir_p([File.dirname(@payload), File.dirname(@spec), @extension])
      [@payload, @spec, File.join(@extension, "fixture.so")].each { |p| File.write(p, "public"); File.chmod(0o640, p) }
      @wrapper = File.join(@home, "bin", "fixture")
      @executable = File.join(@root, "bin", "fixture")
      [@wrapper, @executable].each do |path|
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "public executable")
        File.chmod(0o640, path)
      end
      @unknown = File.join(@root, "private-local")
      File.write(@unknown, "private"); File.chmod(0o600, @unknown)
      @rows = [{"root" => @root, "spec" => @spec, "files" => ["lib/fixture.rb"],
                "executables" => ["fixture"], "bindir" => "bin", "extension" => @extension}]
    end

    def teardown
      FileUtils.remove_entry(@home)
    end

    def provisioner(dry_run: false)
      Ace::Lab::Molecules::GemPayloadPermissions.new(gem_home: @home, dry_run: dry_run, privileged: false)
    end

    def test_public_payload_and_native_outputs_converge_without_touching_unknown_files
      File.chmod(0o700, File.dirname(@payload))
      predicted = provisioner(dry_run: true).converge(@rows)
      assert_equal 0o640, File.stat(@payload).mode & 0o777
      assert_equal 0o700, File.stat(File.dirname(@payload)).mode & 0o777
      applied = provisioner.converge(@rows)
      assert_equal predicted.map { |r| r["path"] }, applied.map { |r| r["path"] }
      assert_equal 0o644, File.stat(@payload).mode & 0o777
      assert_equal 0o755, File.stat(File.dirname(@payload)).mode & 0o777
      assert_equal 0o644, File.stat(File.join(@extension, "fixture.so")).mode & 0o777
      assert_equal 0o600, File.stat(@unknown).mode & 0o777
      assert_equal 0o755, File.stat(@wrapper).mode & 0o777
      assert_equal 0o755, File.stat(@executable).mode & 0o777
      assert_empty provisioner.converge(@rows)
    end

    def test_symlink_refusal_is_identical_in_dry_run_and_apply_before_any_changes
      Dir.mktmpdir do |outside|
        File.write(File.join(outside, "secret"), "private")
        File.symlink(outside, File.join(@root, "escape"))
        @rows[0]["files"] << "escape/secret"
        [true, false].each do |dry_run|
          assert_raises(Ace::Lab::Molecules::GemPayloadPermissions::Error) { provisioner(dry_run: dry_run).converge(@rows) }
          assert_equal 0o640, File.stat(@payload).mode & 0o777
        end
      end
    end
  end
end

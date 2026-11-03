# frozen_string_literal: true

require_relative "../../test_helper"
require "tmpdir"
require "ace/herdr/molecules/installed_pi_extensions"

class InstalledPiExtensionsTest < Minitest::Test
  Extensions = Ace::Herdr::Molecules::InstalledPiExtensions

  def test_development_and_non_lab_sessions_do_not_override_extensions
    assert_empty Extensions.arguments(env: {}, platform: "linux")
    Dir.mktmpdir do |dir|
      assert_empty Extensions.arguments(env: {"ACE_TOOLCHAIN" => "installed"}, platform: "linux", manifest_dir: File.join(dir, "absent"))
    end
  end

  def test_installed_lab_refuses_unprotected_manifest
    Dir.mktmpdir do |dir|
      manifest = File.join(dir, "install.yml")
      File.write(manifest, "gemset: {}\n")
      assert_raises(Ace::Herdr::ExecutorUnavailableError) do
        Extensions.arguments(env: {"ACE_TOOLCHAIN" => "installed"}, platform: "linux", manifest_dir: dir, manifest: manifest)
      end
    end
  end

  def test_isolated_session_requires_installed_linux_runtime_and_manifest
    Dir.mktmpdir do |dir|
      absent = File.join(dir, "absent")
      [
        [{"ACE_LAB_SESSION" => "1"}, "linux"],
        [{"ACE_LAB_SESSION" => "1", "ACE_TOOLCHAIN" => "installed"}, "darwin"],
        [{"ACE_LAB_SESSION" => "1", "ACE_TOOLCHAIN" => "installed"}, "linux"]
      ].each do |env, platform|
        assert_raises(Ace::Herdr::ExecutorUnavailableError) do
          Extensions.arguments(env: env, platform: platform, manifest_dir: absent)
        end
      end
    end
  end

  def test_extension_overrides_are_refused
    %w[--no-extensions -ne --extension --extension=/tmp/x -e -e/tmp/x].each do |argument|
      assert_raises(Ace::Herdr::ExecutorUnavailableError) { Extensions.reject_override!([argument]) }
    end
    Extensions.reject_override!(["--model", "zai/test"])
  end
end

# frozen_string_literal: true
require_relative "../test_helper"
require "rubygems/package"
require "digest"
require "tmpdir"

class NativeArtifactTest < AceRuntimeTestCase
  def test_built_gem_ships_exact_native_source_and_executable_build_inputs
    package = File.expand_path("../..", __dir__)
    Dir.mktmpdir("ace-runtime-artifact") do |root|
      archive = File.join(root, "runtime.gem")
      Dir.chdir(package) do
        spec = Gem::Specification.load("ace-runtime.gemspec")
        assert spec
        %w[native/worker_gate.c native/build-worker-gate native/README.md].each { |file| assert_includes spec.files, file }
        capture_io { Gem::Package.build(spec, false, false, archive) }
      end
      unpacked = File.join(root, "installed")
      Gem::Package.new(archive).extract_files(unpacked)
      %w[native/worker_gate.c native/build-worker-gate native/README.md].each do |file|
        assert_equal Digest::SHA256.file(File.join(package, file)).hexdigest,
          Digest::SHA256.file(File.join(unpacked, file)).hexdigest
      end
      assert File.executable?(File.join(unpacked, "native/build-worker-gate"))
      refute File.exist?(File.join(unpacked, "test/fixtures/protected_gate/primitives.c")), "test-only primitive harness is not the deployed bootstrap"
    end
  end
end

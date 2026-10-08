# frozen_string_literal: true
require_relative "../test_helper"
require "rubygems/package"
require "digest"
require "tmpdir"

class NativeArtifactTest < AceRuntimeTestCase
  def test_compact_release_source_schema_matches_original_prepared_input_producer
    root = File.expand_path("../../..", __dir__)
    gate = File.read(File.join(root, "ace-runtime/native/worker_gate.c"))
    producer = File.read(File.join(root, "ace-assign/lib/ace/assign/authority/launch_prepared_work.rb"))
    compact = producer.split("def compact_prepared_input(projection)", 2).fetch(1)
    ruby_keys = compact.scan(/"([a-z_0-9]+)"\s*=>/).flatten
    c_keys = gate.match(/input_keys\[\]=\{([^}]+)\}/).captures.first.scan(/"([a-z_0-9]+)"/).flatten
    assert_equal ruby_keys.sort, c_keys.sort
    assert_equal 10, c_keys.length
    assert_includes gate, "closed(input,input_keys,10)"
    assert_includes gate, 'workspace_exclusion(field(input,"workspace_exclusion",json_type_object),mapping_id)'
    assert_includes gate, 'prepared_permission(permission,argv[1])'
    assert_includes gate, "+1>16384"
    # This is a shipped-source join check, not native parser/execution evidence.
    workspace = gate.split("static void workspace_exclusion", 2).fetch(1).split("static void prepared_permission", 2).first
    assert_equal %w[authority_gid authority_uid key root_resource worker_cwd_resource],
      workspace.match(/keys\[\]=\{([^}]+)\}/).captures.first.scan(/"([a-z_0-9]+)"/).flatten.sort
    resource = gate.split("static void workspace_resource", 2).fetch(1).split("static void workspace_exclusion", 2).first
    assert_equal %w[device filesystem_type gid host_path inode mount_id uid view_path],
      resource.match(/keys\[\]=\{([^}]+)\}/).captures.first.scan(/"([a-z_0-9]+)"/).flatten.sort
  end

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

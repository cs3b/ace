# frozen_string_literal: true

require "test_helper"
require "open3"

class NativeSourceBuilderTest < Minitest::Test
  Source = Ace::Herdr::Molecules::NativeSource
  Builder = Ace::Herdr::Organisms::NativeSourceBuilder
  Result = Struct.new(:stdout, :stderr, :status, :oversized, keyword_init: true)
  Status = Struct.new(:ok) { def success? = ok }

  # Source-only fixture: no run/spawn/PTY owner or product entry point is invoked.
  class ControlledBuilder < Builder
    private
    def validate_native_host!(_target); end
    def build_environment = super.merge("PATH" => @fixture_tools)
    def executable(name) = name == "git" ? @fixture_git : super
    def linker_path = File.join(@fixture_tools, "zig-linker")
  end

  def setup
    @tmp = File.realpath(Dir.mktmpdir("native-builder-source"))
    @git = ENV.fetch("PATH").split(File::PATH_SEPARATOR).map { |d| File.join(d, "git") }
      .find { |p| File.executable?(p) && File.file?(p) }
    @git = File.realpath(@git)
    @repo = File.join(@tmp, "repository")
    Dir.mkdir(@repo)
    @committer = {"name" => "Source Fixture", "email" => "fixture@example.invalid", "date" => "2026-10-07T01:02:03+00:00"}
    @git_env = {"GIT_CONFIG_GLOBAL" => "/dev/null", "GIT_CONFIG_NOSYSTEM" => "1",
      "GIT_AUTHOR_NAME" => @committer["name"], "GIT_AUTHOR_EMAIL" => @committer["email"],
      "GIT_AUTHOR_DATE" => @committer["date"], "GIT_COMMITTER_NAME" => @committer["name"],
      "GIT_COMMITTER_EMAIL" => @committer["email"], "GIT_COMMITTER_DATE" => @committer["date"]}
    git("init", "--quiet")
    File.write(File.join(@repo, "Cargo.lock"), "controlled source lock\n")
    File.write(File.join(@repo, "rust-toolchain.toml"), "controlled toolchain\n")
    File.write(File.join(@repo, "marker"), "before\n")
    git("add", ".")
    git("commit", "--quiet", "-m", "fixture baseline")
    baseline = git("rev-parse", "HEAD").strip
    File.write(File.join(@repo, "marker"), "after\n")
    git("add", "marker")
    git("commit", "--quiet", "-m", "fixture accepted producer")
    candidate = git("rev-parse", "HEAD").strip
    tree = git("rev-parse", "HEAD^{tree}").strip
    patch = git("format-patch", "--stdout", "-1", "HEAD")
    git("checkout", "--quiet", "--detach", baseline)
    @assets = File.join(@tmp, "assets")
    Dir.mkdir(@assets)
    File.write(File.join(@assets, "guarded-prompt.patch"), patch)
    selection = JSON.parse(JSON.generate(Source.new.selection))
    selection.merge!("baseline_commit" => baseline, "source_commit" => candidate, "source_tree" => tree,
      "patch_sha256" => Digest::SHA256.hexdigest(patch), "committer" => @committer,
      "cargo_lock_sha256" => Digest::SHA256.file(File.join(@repo, "Cargo.lock")).hexdigest,
      "rust_toolchain_sha256" => Digest::SHA256.file(File.join(@repo, "rust-toolchain.toml")).hexdigest)
    File.write(File.join(@assets, "selection.json"), JSON.generate(selection))
    @source = Source.new(assets: @assets)
    @tools = File.join(@tmp, "tools")
    Dir.mkdir(@tools)
    %w[rustup cargo rustc zig zig-linker].each do |name|
      File.write(File.join(@tools, name), "CONTROLLED_NONEXECUTED_TOOL_#{name}")
      File.chmod(0o700, File.join(@tools, name))
    end
    @calls = []
    @compile_failure = false
    @runner = lambda do |argv, environment:, chdir:, timeout_s:|
      @calls << [argv, environment, chdir]
      if argv.first == @git
        Ace::Herdr::Molecules::BoundedProcess.call(argv, environment: environment, chdir: chdir, timeout_s: timeout_s)
      elsif File.basename(argv.first) == "rustup"
        result(File.join(@tools, argv.last) + "\n")
      elsif argv[1] == "--version"
        result("#{File.basename(argv.first)} 1.96.1 (controlled)\n")
      elsif File.basename(argv.first) == "zig"
        result("0.16.0\n")
      else
        assert_equal File.join(@tools, "cargo"), argv.first
        assert_equal 7200, timeout_s, "cold native builds require a realistic bounded deadline"
        assert_equal %w[build --release --locked --target x86_64-unknown-linux-musl], argv.drop(1)
        assert_equal "after\n", File.read(File.join(chdir, "marker"))
        assert_equal File.join(@tools, "zig"), environment.fetch("ZIG")
        assert_equal File.join(@tools, "rustc"), environment.fetch("RUSTC")
        assert_equal File.join(@tools, "zig-linker"), environment.fetch("CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER")
        assert_equal "x86_64-linux-musl", environment.fetch("ACE_NATIVE_ZIG_TARGET")
        assert_equal File.join(@tools, "zig-linker"), environment.fetch("CC_x86_64_unknown_linux_musl")
        refute environment.key?("RUSTFLAGS")
        staging = File.dirname(environment.fetch("CARGO_TARGET_DIR"))
        assert_equal "--remap-path-prefix=#{staging}=/ace-native-build\x1f-Clink-self-contained=no", environment.fetch("CARGO_ENCODED_RUSTFLAGS")
        return_result = result("", !@compile_failure)
        unless @compile_failure
          artifact = File.join(environment.fetch("CARGO_TARGET_DIR"), "x86_64-unknown-linux-musl", "release", "herdr")
          FileUtils.mkdir_p(File.dirname(artifact))
          File.binwrite(artifact, elf_fixture)
        end
        return_result
      end
    end
  end

  def teardown = FileUtils.remove_entry(@tmp)

  def git(*args)
    output, error, status = Open3.capture3(@git_env, @git, "-c", "core.hooksPath=/dev/null", "-C", @repo, *args)
    raise error unless status.success?
    output
  end

  def result(output, success = true) = Result.new(stdout: output, status: Status.new(success), oversized: false)

  def elf_fixture
    bytes = "\0".b * 64
    bytes[0, 7] = "\x7fELF\x02\x01\x01".b
    bytes[16, 2] = [2].pack("v")
    bytes[18, 2] = [62].pack("v")
    bytes + "CONTROLLED_NONEXECUTED_PRODUCT"
  end

  def builder
    instance = ControlledBuilder.new(selection: @source, runner: @runner)
    instance.instance_variable_set(:@fixture_tools, @tools)
    instance.instance_variable_set(:@fixture_git, @git)
    instance
  end

  def output = File.join(@tmp, "output")
  def build = builder.build(source: @repo, output: output, target: "x86_64-unknown-linux-musl")

  def test_real_git_reproduction_and_controlled_compiler_produce_verified_immutable_artifact
    verified = build
    assert_equal @source.selection.fetch("source_commit"), verified.fetch("source").fetch("source_commit")
    assert_equal Digest::SHA256.file(File.join(@tools, "zig-linker")).hexdigest, verified.fetch("build").fetch("tools_sha256").fetch("linker")
    assert_equal %w[herdr provenance.json], Dir.children(output).sort
    before = File.binread(File.join(output, "herdr"))
    assert_raises(Source::Error) { build }
    assert_equal before, File.binread(File.join(output, "herdr"))
  end

  def test_compile_failure_retains_claim_and_never_returns_partial_success
    @compile_failure = true
    assert_raises(Source::Error) { build }
    assert Dir.exist?(output)
    refute File.exist?(File.join(output, "provenance.json"))
    assert_raises(Source::Error) { build }
  end

  def test_dirty_local_source_refuses_before_output_claim_or_compiler
    File.write(File.join(@repo, "marker"), "changed")
    assert_raises(Source::Error) { build }
    refute Dir.exist?(output)
    refute @calls.any? { |argv, _, _| argv[1] == "build" }
  end

  def test_wrong_exact_patched_revision_refuses_before_compilation
    path = File.join(@assets, "selection.json")
    selection = JSON.parse(File.read(path))
    selection["source_commit"] = "a" * 40
    File.write(path, JSON.generate(selection))
    @source = Source.new(assets: @assets)
    assert_raises(Source::Error) { build }
    assert Dir.exist?(output)
    refute @calls.any? { |argv, _, _| argv[1] == "build" }
  end

  def test_missing_selected_linker_refuses_before_output_claim
    File.unlink(File.join(@tools, "zig-linker"))
    assert_raises(Source::Error) { build }
    refute Dir.exist?(output)
  end

  def test_failed_command_keeps_bounded_compiler_reason_without_claiming_artifact
    original = @runner
    @runner = lambda do |argv, **options|
      if argv[1] == "build"
        Result.new(stdout: "", stderr: "x" * 20_000 + "\nlinker: missing target library", status: Status.new(false), oversized: false)
      else
        original.call(argv, **options)
      end
    end
    error = assert_raises(Source::Error) { build }
    assert_includes error.message, "linker: missing target library"
    assert_operator error.message.bytesize, :<, 8500
    refute File.exist?(File.join(output, "provenance.json"))
  end

  def test_failed_command_bounds_invalid_utf8_and_multibyte_boundaries
    ["\xff".b * 10_000, "€" * 10_000].each do |bytes|
      @runner = ->(*) { Result.new(stdout: "", stderr: bytes + "END", status: Status.new(false), oversized: false) }
      error = assert_raises(Source::Error) { builder.send(:run, ["cargo"], environment: {}) }
      assert error.message.valid_encoding?
      assert_operator error.message.bytesize, :<, 8500
      assert error.message.end_with?("END")
    end
  end

  def test_compiler_tool_changed_after_invocation_refuses_success
    original = @runner
    @runner = lambda do |argv, **options|
      answer = original.call(argv, **options)
      File.write(File.join(@tools, "zig"), "changed selected tool") if argv[1] == "build"
      answer
    end
    assert_raises(Source::Error) { build }
    assert Dir.exist?(output)
    refute File.exist?(File.join(output, "provenance.json"))
  end

  def test_real_builder_accepts_linux_and_macos_for_explicit_zig_targets
    skip "Unix build hosts only" unless RbConfig::CONFIG.fetch("host_os").match?(/linux|darwin/)
    instance = Builder.new(selection: @source, runner: ->(*) { flunk "host validation executes no tools" })
    assert_nil instance.send(:validate_native_host!, "x86_64-unknown-linux-musl")
    assert_nil instance.send(:validate_native_host!, "aarch64-unknown-linux-musl")
  end
end

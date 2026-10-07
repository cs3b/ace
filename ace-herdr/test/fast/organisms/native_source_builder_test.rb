# frozen_string_literal: true

require "test_helper"
require "open3"

class NativeSourceBuilderTest < Minitest::Test
  Source = Ace::Herdr::Molecules::NativeSource
  Builder = Ace::Herdr::Organisms::NativeSourceBuilder
  Result = Struct.new(:stdout, :status, :oversized, keyword_init: true)
  Status = Struct.new(:ok) { def success? = ok }

  # Source-only fixture: no run/spawn/PTY owner or product entry point is invoked.
  class ControlledBuilder < Builder
    private
    def validate_native_host!(_target); end
    def build_environment = super.merge("PATH" => @fixture_tools)
    def executable(name) = name == "git" ? @fixture_git : super
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
    %w[rustup cargo rustc zig musl-gcc].each do |name|
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
        assert_equal %w[build --release --locked --target x86_64-unknown-linux-musl], argv.drop(1)
        assert_equal "after\n", File.read(File.join(chdir, "marker"))
        assert_equal File.join(@tools, "zig"), environment.fetch("ZIG")
        assert_equal File.join(@tools, "rustc"), environment.fetch("RUSTC")
        assert_equal File.join(@tools, "musl-gcc"), environment.fetch("CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER")
        refute environment.key?("RUSTFLAGS")
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
    assert_equal Digest::SHA256.file(File.join(@tools, "musl-gcc")).hexdigest, verified.fetch("build").fetch("tools_sha256").fetch("linker")
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
    File.unlink(File.join(@tools, "musl-gcc"))
    assert_raises(Source::Error) { build }
    refute Dir.exist?(output)
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

  def test_real_builder_rejects_macos_cross_host_without_running_any_tool
    skip "matching native host is separately controlled" if RbConfig::CONFIG.fetch("host_os").include?("linux")
    instance = Builder.new(selection: @source, runner: ->(*) { flunk "host refusal must precede tool execution" })
    assert_raises(Source::Error) { instance.build(source: @repo, output: output, target: "x86_64-unknown-linux-musl") }
    refute Dir.exist?(output)
  end
end

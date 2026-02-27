# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"

class RunCommandTest < AceSimTestCase
  class FakeRunner
    attr_reader :seen_session

    def initialize(success: true)
      @success = success
    end

    def run(session)
      @seen_session = session
      {
        success: @success,
        status: @success ? "ok" : "failed",
        run_id: session.run_id,
        run_dir: ".cache/ace-sim/simulations/#{session.run_id}",
        error: @success ? nil : "boom"
      }
    end
  end

  def setup
    super
    @preset = File.join(Dir.pwd, ".ace", "sim", "presets", "validate-idea.yml")
    @steps_dir = File.join(Dir.pwd, ".ace", "sim", "steps")
    @source = File.join(Dir.pwd, ".ace", "sim", "source.md")
    FileUtils.mkdir_p(File.dirname(@preset))
    FileUtils.mkdir_p(@steps_dir)
    File.write(
      @preset,
      "steps:\n  - draft\n  - plan\nprovider:\n  - codex:mini\nrepeat: 1\nsynthesis_workflow: wfi://task/review-work\n"
    )
    File.write(File.join(@steps_dir, "draft.md"), "---\nbundle:\n  embed_document_source: true\n---\n")
    File.write(File.join(@steps_dir, "plan.md"), "---\nbundle:\n  embed_document_source: true\n---\n")
    File.write(@source, "source content")
  end

  def teardown
    FileUtils.rm_rf(File.join(Dir.pwd, ".ace"))
    super
  end

  def test_requires_source
    cmd = Ace::Sim::CLI::Commands::Run.new(runner: FakeRunner.new)

    err = assert_raises(Ace::Core::CLI::Error) do
      cmd.call(preset: "validate-idea", provider: ["codex:mini"], quiet: true)
    end

    assert_match(/--source is required/, err.message)
  end

  def test_cli_overrides_preset_defaults
    fake = FakeRunner.new
    cmd = Ace::Sim::CLI::Commands::Run.new(runner: fake)

    cmd.call(
      preset: "validate-idea",
      source: @source,
      steps: "draft,plan",
      provider: ["google:gflash"],
      repeat: 2,
      dry_run: true,
      quiet: true
    )

    assert_equal "validate-idea", fake.seen_session.preset
    assert_equal %w[draft plan], fake.seen_session.steps
    assert_equal ["google:gflash"], fake.seen_session.providers
    assert_equal 2, fake.seen_session.repeat
    assert fake.seen_session.dry_run?
  end

  def test_cli_can_override_synthesis_options
    fake = FakeRunner.new
    cmd = Ace::Sim::CLI::Commands::Run.new(runner: fake)

    cmd.call(
      preset: "validate-idea",
      source: @source,
      provider: ["google:gflash"],
      synthesis_workflow: "wfi://task/review-plan",
      synthesis_provider: "claude:haiku",
      quiet: true
    )

    assert_equal "wfi://task/review-plan", fake.seen_session.synthesis_workflow
    assert_equal "claude:haiku", fake.seen_session.synthesis_provider
  end

  def test_rejects_unknown_preset
    cmd = Ace::Sim::CLI::Commands::Run.new(runner: FakeRunner.new)

    err = assert_raises(Ace::Core::CLI::Error) do
      cmd.call(preset: "missing", source: @source, provider: ["codex:mini"], quiet: true)
    end

    assert_match(/Unknown preset 'missing'/, err.message)
  end

  def test_errors_when_runner_fails
    cmd = Ace::Sim::CLI::Commands::Run.new(runner: FakeRunner.new(success: false))

    err = assert_raises(Ace::Core::CLI::Error) do
      cmd.call(preset: "validate-idea", source: @source, provider: ["codex:mini"], quiet: true)
    end

    assert_match(/boom/, err.message)
  end

  def test_rejects_synthesis_provider_without_workflow
    cmd = Ace::Sim::CLI::Commands::Run.new(runner: FakeRunner.new)

    err = assert_raises(Ace::Core::CLI::Error) do
      cmd.call(
        preset: "validate-idea",
        source: @source,
        provider: ["codex:mini"],
        synthesis_workflow: "",
        synthesis_provider: "glite",
        quiet: true
      )
    end

    assert_match(/synthesis_provider requires synthesis_workflow/, err.message)
  end
end

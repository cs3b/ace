# frozen_string_literal: true

require "test_helper"
require "ace/handbook/cli"

class Ace::Handbook::CLI::Commands::SyncTest < Minitest::Test
  def test_outputs_sync_lines_for_each_provider
    syncer = stub_syncer(
      {
        provider: "pi",
        relative_output_dir: ".pi/skills",
        projected_skills: 4,
        updated_files: 1,
        removed_entries: 0,
        source_breakdown: {"ace-handbook" => 4, "ace-task" => 2}
      },
      {
        provider: "codex",
        relative_output_dir: ".codex/skills",
        projected_skills: 4,
        updated_files: 1,
        removed_entries: 0,
        source_breakdown: {"ace-handbook" => 4, "ace-task" => 2}
      }
    )
    command = Ace::Handbook::CLI::Commands::Sync.new(syncer: syncer)

    stdout, = capture_io { command.call }

    assert_includes stdout, "synced pi -> .pi/skills (4 skills, 1 updated, 0 removed)"
    assert_includes stdout, "synced codex -> .codex/skills (4 skills, 1 updated, 0 removed)"
    assert_includes stdout, "inventory sources: ace-handbook:4, ace-task:2"
    refute_includes stdout, "only 'ace-handbook' skills were discovered"
  end

  def test_outputs_rerun_hint_when_only_one_source_detected
    syncer = stub_syncer(
      {
        provider: "pi",
        relative_output_dir: ".pi/skills",
        projected_skills: 4,
        updated_files: 1,
        removed_entries: 0,
        source_breakdown: {"ace-handbook" => 4}
      }
    )
    command = Ace::Handbook::CLI::Commands::Sync.new(syncer: syncer)

    stdout, = capture_io { command.call }

    assert_includes stdout, "inventory sources: ace-handbook:4"
    assert_includes stdout, "note: only 'ace-handbook' skills were discovered."
  end

  def test_quiet_suppresses_sync_summary_output
    syncer = stub_syncer(
      {
        provider: "pi",
        relative_output_dir: ".pi/skills",
        projected_skills: 4,
        updated_files: 1,
        removed_entries: 0,
        source_breakdown: {"ace-handbook" => 4}
      }
    )
    command = Ace::Handbook::CLI::Commands::Sync.new(syncer: syncer)

    stdout, = capture_io { command.call(quiet: true) }

    assert_equal "", stdout
  end

  private

  def stub_syncer(*results)
    Object.new.tap do |syncer|
      syncer.define_singleton_method(:sync) do |provider: nil|
        return results if provider.nil?

        results.select { |entry| entry[:provider] == provider.to_s }
      end
    end
  end
end

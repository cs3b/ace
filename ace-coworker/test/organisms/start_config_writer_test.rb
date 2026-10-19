# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "yaml"

module Ace
  module Coworker
    module Organisms
      class StartConfigWriterTest < AceCoworkerTestCase
        # Mimics CommissionOrchestrator: resolves and validates on
        # dry_run, writes exactly YAML.safe_dump(config) otherwise.
        FakeCommission = Struct.new(:worktree_path, :target, :writes) do
          def call(role:, task:, assignment:, overseer:, force:, dry_run:)
            config = {"role" => role, "instructions" => "roles/#{role}.md",
                      "start_prompt" => "Drive #{assignment} as #{role} for #{overseer}.",
                      "task" => task, "assignment" => assignment, "overseer" => overseer}
            unless dry_run
              writes << target
              FileUtils.mkdir_p(File.dirname(target))
              File.write(target, YAML.safe_dump(config))
            end
            Struct.new(:config).new(config)
          end
        end

        def writer(worktree)
          writes = []
          factory = ->(wt, target) { FakeCommission.new(wt, target, writes) }
          [StartConfigWriter.new(worktree_path: worktree, commission_factory: factory), writes]
        end

        def sequence
          [{"role" => "worker", "assignment" => "seq1"},
           {"role" => "reviewer", "assignment" => "seq2"}]
        end

        def test_creates_one_config_per_leg
          worktree = Dir.mktmpdir("scw")
          writer, writes = writer(worktree)

          entries = writer.call(task: "8xg.t.aaa", sequence: sequence,
            overseer: "overseer@lab", dry_run: false)

          assert_equal ["created", "created"], entries.map { |e| e["disposition"] }
          assert_equal %w[worker reviewer], entries.map { |e| e["role"] }
          assert_equal [File.join(".ace-local", "coworker", "prepare", "worker.yml"),
                        File.join(".ace-local", "coworker", "prepare", "reviewer.yml")],
            entries.map { |e| e["path"] }
          assert_equal 2, writes.length, "one write per leg"
          written = YAML.safe_load_file(writes.first)
          assert_equal "worker", written["role"]
          assert_equal "8xg.t.aaa", written["task"]
          assert_equal "seq1", written["assignment"]
          assert_equal "overseer@lab", written["overseer"]
          assert_equal "roles/worker.md", written["instructions"]
        ensure
          FileUtils.remove_entry(worktree) if worktree
        end

        def test_identical_existing_config_is_reused_without_write
          worktree = Dir.mktmpdir("scw")
          writer, writes = writer(worktree)
          writer.call(task: "8xg.t.aaa", sequence: sequence.take(1),
            overseer: "overseer@lab", dry_run: false)
          writes.clear

          entries = writer.call(task: "8xg.t.aaa", sequence: sequence.take(1),
            overseer: "overseer@lab", dry_run: false)

          assert_equal ["reused"], entries.map { |e| e["disposition"] }
          assert_empty writes, "identical content is never rewritten"
        ensure
          FileUtils.remove_entry(worktree) if worktree
        end

        def test_changed_content_is_updated
          worktree = Dir.mktmpdir("scw")
          writer, writes = writer(worktree)
          writer.call(task: "8xg.t.aaa", sequence: sequence.take(1),
            overseer: "overseer@lab", dry_run: false)
          writes.clear

          entries = writer.call(task: "8xg.t.aaa", sequence: sequence.take(1),
            overseer: "other-overseer", dry_run: false)

          assert_equal ["updated"], entries.map { |e| e["disposition"] }
          assert_equal 1, writes.length
          assert_equal "other-overseer", YAML.safe_load_file(writes.first)["overseer"]
        ensure
          FileUtils.remove_entry(worktree) if worktree
        end

        def test_dry_run_resolves_without_writes
          worktree = Dir.mktmpdir("scw")
          writer, writes = writer(worktree)

          entries = writer.call(task: "8xg.t.aaa", sequence: sequence.take(1),
            overseer: "overseer@lab", dry_run: true)

          assert_equal ["planned"], entries.map { |e| e["disposition"] }
          assert_empty writes
          refute File.exist?(File.join(worktree, ".ace-local", "coworker", "prepare", "worker.yml"))
        ensure
          FileUtils.remove_entry(worktree) if worktree
        end
      end
    end
  end
end

# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Molecules
      class WorktreeExecutorProbeTest < AceCoworkerTestCase
        FakeRunner = Struct.new(:calls) do
          Status = Struct.new(:success?)

          attr_accessor :out, :err, :success

          def initialize(out: "[]", err: "", success: true)
            super([])
            @out = out
            @err = err
            @success = success
          end

          def call(argv, cwd)
            calls << {argv: argv, cwd: cwd}
            [out, err, Status.new(success)]
          end
        end

        def write_config(dir, content)
          path = File.join(dir, ".ace-local", "coworker", "config.yml")
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
          path
        end

        def test_argv_shape_and_cwd
          Dir.mktmpdir("coworker-exec") do |dir|
            runner = FakeRunner.new(out: "[]")
            probe = WorktreeExecutorProbe.new(project_root: dir, runner: runner)
            probe.probe(dir)

            call = runner.calls.first
            assert_equal dir, call[:cwd]
            assert_equal ["ace-assign", "list", "--all", "--format", "json"], call[:argv]
          end
        end

        def test_prefers_repo_binstub_when_executable
          Dir.mktmpdir("coworker-exec") do |dir|
            FileUtils.mkdir_p(File.join(dir, "bin"))
            binstub = File.join(dir, "bin", "ace-assign")
            File.write(binstub, "#!/bin/sh\n")
            FileUtils.chmod(0o755, binstub)

            runner = FakeRunner.new(out: "[]")
            WorktreeExecutorProbe.new(project_root: dir, runner: runner).probe(dir)

            assert_equal binstub, runner.calls.first[:argv].first
          end
        end

        def test_parses_assignments_json
          Dir.mktmpdir("coworker-exec") do |dir|
            payload = JSON.generate([
              {id: "abc123", name: "work", state: "running", progress: "1/2 done",
               active_steps: ["impl"], next_step: nil, updated_at: "2026-10-18T00:00:00Z",
               is_current: true}
            ])
            result = WorktreeExecutorProbe.new(project_root: dir,
              runner: FakeRunner.new(out: payload)).probe(dir)

            assert_equal [{"id" => "abc123", "name" => "work", "state" => "running",
                           "progress" => "1/2 done"}], result[:assignments]
            assert_nil result[:config]
          end
        end

        def test_config_present_parses_leniently
          Dir.mktmpdir("coworker-exec") do |dir|
            write_config(dir, "role: worker\ntask: 8xg.t.aaa\nassignment: abc123\n")
            result = WorktreeExecutorProbe.new(project_root: dir,
              runner: FakeRunner.new(out: "[]")).probe(dir)

            assert_equal "abc123", result[:config]["assignment"]
          end
        end

        def test_config_read_through_configured_config_path
          Dir.mktmpdir("coworker-exec") do |dir|
            # The worktree's own cascade redirects the coworker config to
            # a non-default location, as a commission with a configured
            # config_path writes it.
            override = File.join(dir, ".ace", "coworker")
            FileUtils.mkdir_p(override)
            File.write(File.join(override, "config.yml"),
              "config_path: .ace-local/coworker/worker.yml\n")
            worker = File.join(dir, ".ace-local", "coworker", "worker.yml")
            FileUtils.mkdir_p(File.dirname(worker))
            File.write(worker, "role: worker\ntask: 8xg.t.aaa\nassignment: abc123\n")

            result = WorktreeExecutorProbe.new(project_root: dir,
              runner: FakeRunner.new(out: "[]")).probe(dir)

            assert_equal "abc123", result[:config]["assignment"]
          end
        end

        def test_garbage_config_is_unparseable
          Dir.mktmpdir("coworker-exec") do |dir|
            write_config(dir, "::: not yaml [\n")
            result = WorktreeExecutorProbe.new(project_root: dir,
              runner: FakeRunner.new(out: "[]")).probe(dir)

            assert_equal Atoms::ActiveExecutorRule::UNPARSEABLE, result[:config]
          end
        end

        def test_non_mapping_config_is_unparseable
          Dir.mktmpdir("coworker-exec") do |dir|
            write_config(dir, "- just\n- a list\n")
            result = WorktreeExecutorProbe.new(project_root: dir,
              runner: FakeRunner.new(out: "[]")).probe(dir)

            assert_equal Atoms::ActiveExecutorRule::UNPARSEABLE, result[:config]
          end
        end

        # 8xi16mz3: a non-mapping layer (a YAML list) at the NEAREST
        # cascade tier must be skipped, not wipe the valid mapping from
        # the farther tier — the probe still honors the farther
        # config_path override.
        def test_non_mapping_nearest_cascade_layer_keeps_farther_tier_override
          Dir.mktmpdir("coworker-exec") do |dir|
            outer = File.join(dir, ".ace", "coworker")
            FileUtils.mkdir_p(outer)
            File.write(File.join(outer, "config.yml"),
              "config_path: .ace-local/coworker/worker.yml\n")
            worktree = File.join(dir, "worktree")
            inner = File.join(worktree, ".ace", "coworker")
            FileUtils.mkdir_p(inner)
            File.write(File.join(inner, "config.yml"), "- just\n- a list\n")
            worker = File.join(worktree, ".ace-local", "coworker", "worker.yml")
            FileUtils.mkdir_p(File.dirname(worker))
            File.write(worker, "role: worker\ntask: 8xg.t.aaa\nassignment: abc123\n")

            result = WorktreeExecutorProbe.new(project_root: worktree,
              runner: FakeRunner.new(out: "[]")).probe(worktree)

            assert_equal "abc123", result[:config]["assignment"]
          end
        end

        # 8xi1p4z2: a nearest cascade tier with unparseable YAML
        # (unresolved merge-conflict markers) must be skipped
        # per-layer, exactly like a non-mapping layer — the farther
        # tier's config_path override must survive.
        def test_broken_yaml_nearest_cascade_layer_keeps_farther_tier_override
          Dir.mktmpdir("coworker-exec") do |dir|
            outer = File.join(dir, ".ace", "coworker")
            FileUtils.mkdir_p(outer)
            File.write(File.join(outer, "config.yml"),
              "config_path: .ace-local/coworker/worker.yml\n")
            worktree = File.join(dir, "worktree")
            inner = File.join(worktree, ".ace", "coworker")
            FileUtils.mkdir_p(inner)
            File.write(File.join(inner, "config.yml"),
              "<<<<<<< HEAD\nrole: worker\n=======\n>>>>>>> other\n")
            worker = File.join(worktree, ".ace-local", "coworker", "worker.yml")
            FileUtils.mkdir_p(File.dirname(worker))
            File.write(worker, "role: worker\ntask: 8xg.t.aaa\nassignment: abc123\n")

            result = WorktreeExecutorProbe.new(project_root: worktree,
              runner: FakeRunner.new(out: "[]")).probe(worktree)

            assert_equal "abc123", result[:config]["assignment"]
          end
        end

        # 8xi1p4z8: the user tier (~/.ace with a stubbed HOME) is the
        # farthest cascade layer — its config_path override applies when
        # no nearer project tier carries one.
        def test_user_tier_config_path_override_with_stubbed_home
          Dir.mktmpdir("coworker-exec") do |dir|
            home = File.join(dir, "home")
            user_tier = File.join(home, ".ace", "coworker")
            FileUtils.mkdir_p(user_tier)
            File.write(File.join(user_tier, "config.yml"),
              "config_path: .ace-local/coworker/worker.yml\n")
            worktree = File.join(dir, "worktree")
            FileUtils.mkdir_p(worktree)
            worker = File.join(worktree, ".ace-local", "coworker", "worker.yml")
            FileUtils.mkdir_p(File.dirname(worker))
            File.write(worker, "role: worker\ntask: 8xg.t.aaa\nassignment: abc123\n")

            old_home = ENV["HOME"]
            ENV["HOME"] = home
            begin
              result = WorktreeExecutorProbe.new(project_root: worktree,
                runner: FakeRunner.new(out: "[]")).probe(worktree)
            ensure
              ENV["HOME"] = old_home
            end

            assert_equal "abc123", result[:config]["assignment"]
          end
        end

        def test_assignments_failure_raises_specific_error
          Dir.mktmpdir("coworker-exec") do |dir|
            probe = WorktreeExecutorProbe.new(project_root: dir,
              runner: FakeRunner.new(out: "", err: "boom", success: false))

            error = assert_raises(Error) { probe.probe(dir) }
            assert_includes error.message, "cannot list assignments"
            assert_includes error.message, "boom"
          end
        end
      end
    end
  end
end

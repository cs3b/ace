# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"
require "open3"
require "json"
require "digest"
require "ace/git/worktree"

module Ace
  module Coworker
    module CLI
      module Commands
        # End-to-end preparation fixture: a real temp git project, real
        # repo binstubs (ace-coworker, ace-assign, ace-hitl), and a
        # project-level .ace/git/worktree.yml that disables all push/PR/
        # bookkeeping automation for offline determinism. Covers the leaf
        # .3.0 acceptance: idempotent re-preparation reuses the worktree,
        # active-executor and mismatched-worktree conflicts escalate via
        # ace-hitl instead of overwriting work, dry-run and invalid input.
        class PrepareIntegrationTest < AceCoworkerTestCase
          REPO_ROOT = File.expand_path("../../..", __dir__)
          ASSIGN_BIN = File.join(REPO_ROOT, "bin", "ace-assign")
          COWORKER_BIN = File.join(REPO_ROOT, "bin", "ace-coworker")

          def setup
            super
            @dir = Dir.mktmpdir("coworker-prepare-e2e")
            FileUtils.mkdir_p(File.join(@dir, ".ace-tasks"))
            run_git("init", "-q", "-b", "main", @dir)
            File.write(File.join(@dir, ".gitignore"), ".ace-local/\n")
            @task_ref = "8xh.t.aaa"
            CoworkerFixture.build_task(@dir, id: @task_ref)
            write_worktree_config
            copy_binstubs
            commit_all("tasks")
            write_hitl_config
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def test_prepare_sends_readiness_report_to_the_overseer
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,reviewer", "--to", "overseer", "--format", "json")
            assert status.success?, "prepare failed: #{out}#{err}"
            payload = JSON.parse(out)

            # L4.4: the commission ends with a READINESS report (no reply
            # expected): worktree, per-role assignments, start configs,
            # and the exact first step — the overseer never composes
            # ace-assign details itself.
            report = payload["report"]
            assert_equal "readiness", report["kind"]
            assert report["event"], "readiness event created"

            assert_equal 1, hitl_events.size
            content = hitl_events.map { |p| File.read(p) }.join
            assert_includes content, "type: report"
            assert_includes content, "result: success"
            assert_includes content, "task: #{@task_ref}"
            assert_includes content, "recipient_machine: lab01", "addressed to the configured overseer recipient"
            assert_includes content, "Preparation ready"
            assert_includes content, payload["worktree"]["path"]
            worker_assignment = payload["assignments"].first["assignment"]
            assert_includes content, "worker: #{worker_assignment}"
            assert_includes content, "start config worker: .ace-local/coworker/prepare/worker.yml"
            assert_includes content, "first leg: ace-coworker start --config " \
              ".ace-local/coworker/prepare/worker.yml"
          end

          def test_prepare_creates_then_reuses_idempotently
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,reviewer", "--to", "overseer", "--format", "json")
            assert status.success?, "prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "created", payload["worktree"]["disposition"]
            worktree = payload["worktree"]["path"]
            assert File.directory?(worktree), "worktree created on disk"
            assert_equal %w[worker reviewer], payload["roles"]

            task_file = Dir.glob(File.join(@dir, ".ace-tasks", "#{@task_ref}-*",
              "#{@task_ref}-*.s.md")).first
            status_before = run_git("-C", worktree, "status", "--porcelain")[0]
            bytes_before = File.read(task_file)

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,reviewer", "--to", "overseer", "--format", "json")
            assert status.success?, "re-prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "reused", payload["worktree"]["disposition"]
            assert_equal worktree, payload["worktree"]["path"]
            assert_nil payload["conflict"]
            assert_equal %w[reused reused], payload["start_configs"].map { |c| c["disposition"] },
              "identical leg configs are never rewritten"

            # Zero writes on reuse: same worktree state, same task file.
            assert_equal status_before, run_git("-C", worktree, "status", "--porcelain")[0]
            assert_equal bytes_before, File.read(task_file)
          end

          def test_prepare_composes_the_whole_role_sequence_usable_by_commission
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,reviewer,integrator",
              "--to", "overseer", "--format", "json")
            assert status.success?, "prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            worktree = payload["worktree"]["path"]

            # One assignment per role, in dependency order, in the
            # worktree's ace-assign storage.
            assignments = payload["assignments"]
            assert_equal %w[worker reviewer integrator], assignments.map { |a| a["role"] }
            assert_equal [1, 2, 3], assignments.map { |a| a["position"] }
            assert_equal %w[created created created], assignments.map { |a| a["disposition"] }
            ids = assignments.map { |a| a["assignment"] }
            ids.each do |id|
              assert File.file?(File.join(worktree, ".ace-local", "assign", id, "assignment.yaml"))
            end

            # Worker and reviewer get DIFFERENT processes matched to the
            # same task; reviewer embeds the 3/2/10 round rule.
            worker_steps = Dir.glob(File.join(worktree, ".ace-local", "assign",
              ids[0], "steps", "*.md")).map { |p| File.read(p) }.join
            reviewer_steps = Dir.glob(File.join(worktree, ".ace-local", "assign",
              ids[1], "steps", "*.md")).map { |p| File.read(p) }.join
            integrator_steps = Dir.glob(File.join(worktree, ".ace-local", "assign",
              ids[2], "steps", "*.md")).map { |p| File.read(p) }.join
            assert_includes worker_steps, "bin/ace-test"
            assert_includes worker_steps, @task_ref
            assert_includes reviewer_steps, "3/2/10"
            assert_includes reviewer_steps, "ace-coworker rounds record"
            assert_includes reviewer_steps, ids[0], "reviewer entry condition names the worker assignment"
            assert_includes integrator_steps, "ace-coworker gate"
            assert_includes integrator_steps, ids[1]

            # The composed assignment is consumable by the next tool:
            # commission verifies the task match inside the worktree.
            out, err, status = run_cli(COWORKER_BIN, "commission",
              "--role", "worker", "--task", @task_ref, "--assignment", ids[0],
              "--overseer", "overseer", chdir: worktree)
            assert status.success?, "commission rejected the composed assignment: #{out}#{err}"
            assert File.file?(File.join(worktree, ".ace-local", "coworker", "config.yml"))
          end

          def test_prepare_writes_start_configs_that_start_accepts
            # Project worker preset with file instructions, so `start`
            # resolves the instruction source in-process (no ace-nav).
            roles_dir = File.join(@dir, ".ace", "coworker", "roles")
            FileUtils.mkdir_p(roles_dir)
            File.write(File.join(roles_dir, "worker.yml"), <<~YAML)
              ---
              name: worker
              description: Fixture worker with file instructions
              instructions: roles/worker.md
              start_prompt: >-
                Drive assignment {{assignment}} for task {{task}} as {{role}},
                reporting to {{overseer}}.
              reporting:
                channel: hitl
              errors:
                on_failure: report
            YAML
            FileUtils.mkdir_p(File.join(@dir, "roles"))
            File.write(File.join(@dir, "roles", "worker.md"), "# Worker instructions\n")
            commit_all("project worker preset with file instructions")

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,reviewer", "--to", "overseer", "--format", "json")
            assert status.success?, "prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            worktree = payload["worktree"]["path"]
            worker_assignment = payload["assignments"].first["assignment"]

            configs = payload["start_configs"]
            assert_equal %w[worker reviewer], configs.map { |c| c["role"] }
            assert_equal %w[created created], configs.map { |c| c["disposition"] }
            assert_equal ".ace-local/coworker/prepare/worker.yml", configs.first["path"]

            # The leg config carries exactly the documented fields — no
            # secrets, no assignment steps — with the composed identity.
            config_path = File.join(worktree, ".ace-local", "coworker", "prepare", "worker.yml")
            assert File.file?(config_path)
            config = YAML.safe_load_file(config_path)
            assert_equal @task_ref, config["task"]
            assert_equal worker_assignment, config["assignment"]
            assert_equal "overseer", config["overseer"]
            assert_equal "roles/worker.md", config["instructions"]
            assert_includes config["start_prompt"], worker_assignment
            assert (config.keys - %w[role instructions start_prompt task assignment overseer
              reporting errors]).empty?, "no undocumented fields leak into the leg config"

            # Round-trip guarantee: what prepare writes, start accepts —
            # the next role starts from its own context, no ad-hoc setup.
            out, err, status = run_cli(COWORKER_BIN, "start",
              "--config", ".ace-local/coworker/prepare/worker.yml", chdir: worktree)
            assert status.success?, "start rejected the prepared leg config: #{out}#{err}"
            assert_includes out, worker_assignment
          end

          def test_prepare_without_overseer_writes_no_start_configs
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--format", "json")
            refute status.success?, "start configs need an overseer address: #{out}#{err}"
            assert_includes err, "preparation conflict: missing_overseer"
            assert_includes err, "no overseer address for the start configs"

            payload = JSON.parse(out)
            assert_equal "missing_overseer", payload["conflict"]["kind"]
            assert_includes payload["conflict"]["detail"], "NOT ready"
            assert_includes payload["conflict"]["detail"],
              "prepared: worktree", "the gap states what IS prepared"
            assert_nil payload["report"], "a gap never sends a readiness report"

            worktree = Dir.glob(File.join(@dir, ".ace-wt", "*")).first
            refute_nil worktree, "the worktree itself is still prepared"
            refute File.exist?(File.join(worktree, ".ace-local", "coworker", "prepare")),
              "no leg config is written without an overseer address"
          end

          def test_dry_run_on_existing_worktree_writes_no_assignments_or_configs
            # Reuse AND extension paths: the worker assignment exists from a
            # real prepare; the dry-run extension with the reviewer leg must
            # plan everything (zero writes) instead of composing a real
            # reviewer assignment.
            worktree = prepare_worktree(@task_ref)
            assignments_before = Dir.glob(File.join(worktree, ".ace-local", "assign", "*", "assignment.yaml")).sort
            files_before = Dir.glob(File.join(worktree, ".ace-local", "**", "*")).select { |p| File.file?(p) }.sort
            events_before = hitl_events.length

            out, err, status = run_cli(COWORKER_BIN, "prepare", "--task", @task_ref,
              "--roles", "worker,reviewer", "--to", "overseer", "--dry-run", "--format", "json")
            assert status.success?, "dry-run failed: #{out}#{err}"
            payload = JSON.parse(out)

            assert_equal "reused", payload["worktree"]["disposition"]
            assert_equal %w[existing planned], payload["assignments"].map { |a| a["disposition"] },
              "existing legs are read-only reused, missing legs are planned"
            assert_equal %w[planned planned], payload["start_configs"].map { |c| c["disposition"] }

            assignments_after = Dir.glob(File.join(worktree, ".ace-local", "assign", "*", "assignment.yaml")).sort
            assert_equal assignments_before, assignments_after,
              "dry-run extension must not create the reviewer assignment"
            files_after = Dir.glob(File.join(worktree, ".ace-local", "**", "*")).select { |p| File.file?(p) }.sort
            assert_equal files_before, files_after, "dry-run on an existing worktree writes nothing"
            assert_equal events_before, hitl_events.length, "dry-run sends nothing"
          end

          def test_missing_role_instruction_source_is_never_ready
            roles_dir = File.join(@dir, ".ace", "coworker", "roles")
            FileUtils.mkdir_p(roles_dir)
            File.write(File.join(roles_dir, "worker.yml"), <<~YAML)
              ---
              name: worker
              description: Worker with missing instruction source
              instructions: roles/nonexistent.md
              start_prompt: >-
                Drive {{assignment}} for {{task}} as {{role}}, reporting to {{overseer}}.
              reporting:
                channel: hitl
              errors:
                on_failure: report
            YAML
            commit_all("missing instructions fixture")

            out, err, status = run_cli(COWORKER_BIN, "prepare", "--task", @task_ref,
              "--roles", "worker", "--to", "overseer", "--format", "json")

            # Never-ready-on-missing-context: the emitted first-leg start
            # command would fail immediately ("instruction file not found"),
            # so prepare reports a role_instructions gap instead of readiness.
            refute status.success?, "prepare must not report ready: #{out}#{err}"
            assert_includes err, "preparation conflict: role_instructions"
            payload = JSON.parse(out)
            assert_equal "role_instructions", payload["conflict"]["kind"]
            assert_includes payload["conflict"]["detail"], "roles/nonexistent.md"
            assert_includes payload["conflict"]["detail"], "not found in this worktree"
            assert_includes payload["conflict"]["detail"], "NOT ready"
            assert_nil payload["report"], "a gap never sends a readiness report"

            worktree = Dir.glob(File.join(@dir, ".ace-wt", "*")).first
            refute_nil worktree, "the worktree itself stays prepared"
            refute File.exist?(File.join(worktree, ".ace-local", "coworker", "prepare", "worker.yml")),
              "no leg config is written for an unresolvable instruction source"

            # The gap reaches the overseer as a decision question.
            assert_equal 1, hitl_events.size
            content = File.read(hitl_events.first)
            assert_includes content, "type: question"
            assert_includes content, "role_instructions"
            assert_includes content, "roles/nonexistent.md"
          end

          def test_missing_instruction_source_in_a_later_leg_blocks_readiness
            roles_dir = File.join(@dir, ".ace", "coworker", "roles")
            FileUtils.mkdir_p(roles_dir)
            File.write(File.join(roles_dir, "reviewer.yml"), <<~YAML)
              ---
              name: reviewer
              description: Reviewer with missing instruction source
              instructions: roles/nonexistent-reviewer.md
              start_prompt: >-
                Review {{assignment}} for {{task}} as {{role}}, reporting to {{overseer}}.
              reporting:
                channel: hitl
              errors:
                on_failure: report
            YAML
            commit_all("reviewer with missing instructions fixture")

            out, err, status = run_cli(COWORKER_BIN, "prepare", "--task", @task_ref,
              "--roles", "worker,reviewer", "--to", "overseer", "--format", "json")

            refute status.success?, "a broken later leg must block readiness: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "role_instructions", payload["conflict"]["kind"]
            assert_includes payload["conflict"]["detail"], "role 'reviewer'"
            assert_includes payload["conflict"]["detail"], "roles/nonexistent-reviewer.md"
            worktree = Dir.glob(File.join(@dir, ".ace-wt", "*")).first
            assert_empty Dir.glob(File.join(worktree, ".ace-local", "coworker", "prepare", "*.yml")),
              "no leg config is written while any leg's context is missing"
          end

          def test_reprepare_before_commission_reuses_composed_sequence
            worktree = prepare_worktree(@task_ref)
            ids = Dir.glob(File.join(worktree, ".ace-local", "assign", "*",
              "assignment.yaml")).map { |p| File.basename(File.dirname(p)) }
            assert_equal 1, ids.length, "fixture prepare composed the worker assignment"

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,reviewer", "--to", "overseer", "--format", "json")
            assert status.success?, "re-prepare failed: #{out}#{err}"
            payload = JSON.parse(out)
            assignments = payload["assignments"]
            assert_equal "existing", assignments[0]["disposition"]
            assert_equal ids.first, assignments[0]["assignment"]
            assert_equal "created", assignments[1]["disposition"],
              "the reviewer leg is composed once its role joins the sequence"
            assert File.file?(File.join(worktree, ".ace-local", "assign",
              assignments[1]["assignment"], "assignment.yaml"))
          end

          def test_missing_role_process_reports_and_writes_no_assignments
            # A project-defined role preset without a matching sequence
            # definition: reported, never substituted with another role's
            # process.
            roles_dir = File.join(@dir, ".ace", "coworker", "roles")
            FileUtils.mkdir_p(roles_dir)
            File.write(File.join(roles_dir, "tailor.yml"), <<~YAML)
              ---
              name: tailor
              description: Project-only role without a shipped process
              instructions: roles/tailor.md
              start_prompt: >-
                Work as the {{role}} on task {{task}}, reporting to the
                overseer at {{overseer}}.
              reporting:
                channel: hitl
              errors:
                on_failure: report
            YAML
            commit_all("project tailor role preset")

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,tailor", "--to", "overseer", "--format", "json")
            refute status.success?, "a missing process never exits 0: #{out}#{err}"
            assert_includes err, "preparation conflict: role_sequence"
            assert_includes err, "role 'tailor' has no assignment process"
            assert_includes err, "refusing to substitute"
            payload = JSON.parse(out)
            assert_equal "role_sequence", payload["conflict"]["kind"]
            assert_nil payload["report"], "a gap never sends a readiness report"

            # All-or-nothing: even the worker's assignment was not written.
            worktrees = Dir.glob(File.join(@dir, ".ace-wt", "*"))
            assert_equal 1, worktrees.length, "worktree itself is prepared and kept"
            assert_empty Dir.glob(File.join(worktrees.first, ".ace-local", "assign", "*")),
              "no partial sequence on a missing process"

            # L4.4: the role error reaches the overseer as a decision
            # question (a decision is needed), with the concrete reason.
            assert_equal 1, hitl_events.size
            content = File.read(hitl_events.first)
            assert_includes content, "type: question"
            assert_includes content, "kind: decision"
            assert_includes content, "role_sequence"
            assert_includes content, "role 'tailor' has no assignment process"
          end

          def test_unknown_role_in_sequence_is_reported
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker,planner", "--format", "json")
            refute status.success?
            assert_includes err, "unknown role 'planner'"
            assert_empty hitl_events
          end

          def test_active_executor_conflict_escalates_without_overwriting
            worktree = prepare_worktree(@task_ref)
            assignment_id = create_running_assignment(worktree)

            snapshot = worktree_snapshot(worktree)

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--to", "overseer", "--format", "json")
            refute status.success?, "conflict never exits 0: #{out}#{err}"
            assert_includes err, "active_executor"
            payload = JSON.parse(out)
            assert_equal "active_executor", payload["conflict"]["kind"]
            assert_includes payload["conflict"]["detail"], assignment_id
            assert_nil payload["worktree"]
            assert payload["conflict"]["hitl_event"], "escalation event created"

            # One conflict question on top of the fixture's readiness
            # report — never the other way around.
            contents = hitl_events.map { |p| File.read(p) }
            questions = contents.select { |c| c.include?("type: question") }
            assert_equal 1, questions.size
            content = questions.first
            assert_includes content, "kind: decision"
            assert_includes content, "task: #{@task_ref}"

            # The executor's work is preserved untouched.
            assert_equal snapshot, worktree_snapshot(worktree)
          end

          def test_mismatched_worktree_conflict_escalates
            # The task's expected worktree location is occupied by a foreign
            # (non-empty, non-task) directory, so creation cannot take its
            # slot and preparation must escalate instead of overwriting.
            expected = expected_worktree_path(@task_ref)
            FileUtils.mkdir_p(expected)
            File.write(File.join(expected, "occupant"), "foreign worktree data")

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--to", "overseer", "--format", "json")
            refute status.success?, "mismatch conflict never exits 0: #{out}#{err}"
            assert_includes err, "mismatched_worktree"
            payload = JSON.parse(out)
            assert_equal "mismatched_worktree", payload["conflict"]["kind"]
            assert payload["conflict"]["hitl_event"], "escalation event created"
            assert_equal 1, hitl_events.size
          end

          def test_stale_metadata_dry_run_reports_would_recover_and_real_run_recovers
            worktree = prepare_worktree(@task_ref)
            events_before = hitl_events.length
            # Stale metadata: the registration survives, the directory is gone.
            FileUtils.remove_entry(worktree)
            refute File.directory?(worktree)

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--dry-run", "--format", "json")
            assert status.success?, "stale dry-run is a would-be recovery: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "would_recover", payload["worktree"]["disposition"]
            assert_equal worktree, payload["worktree"]["path"]
            refute File.directory?(worktree), "dry-run never materializes the worktree"
            assert_equal events_before, hitl_events.length, "dry-run sends no readiness report"

            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--to", "overseer", "--format", "json")
            assert status.success?, "real prepare recovers stale metadata: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "recovered", payload["worktree"]["disposition"]
            assert_equal worktree, payload["worktree"]["path"]
            assert File.directory?(worktree), "worktree materialized again"
          end

          def test_dry_run_resolves_without_effects
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "worker", "--dry-run", "--format", "json")
            assert status.success?, "dry-run of a fresh task would create: #{out}#{err}"
            payload = JSON.parse(out)
            assert_equal "would_create", payload["worktree"]["disposition"]

            assert_empty Dir.glob(File.join(@dir, ".ace-wt", "*")), "no worktree materialized"
            assert_empty hitl_events
          end

          def test_unknown_task_fails_without_events
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", "8xh.t.zzz", "--roles", "worker")
            refute status.success?
            assert_equal "task '8xh.t.zzz' not found in this worktree", err.strip
            assert_empty hitl_events
          end

          def test_commission_under_custom_config_path_is_seen_by_prepare
            # The project cascade overrides the coworker config location;
            # it is committed before the first prepare so the worktree
            # carries the same override the executor would use.
            coworker_dir = File.join(@dir, ".ace", "coworker")
            FileUtils.mkdir_p(coworker_dir)
            File.write(File.join(coworker_dir, "config.yml"), <<~YAML)
              config_path: .ace-local/coworker/worker.yml
            YAML
            commit_all("coworker config override")

            worktree = prepare_worktree(@task_ref)
            assignment_id = create_pending_assignment(worktree)

            # Commission runs inside the worktree and must write to the
            # configured worker.yml, not the default config.yml.
            out, err, status = run_cli(COWORKER_BIN, "commission",
              "--role", "worker", "--task", @task_ref, "--assignment", assignment_id,
              "--overseer", "overseer", chdir: worktree)
            assert status.success?, "commission failed: #{out}#{err}"
            custom = File.join(worktree, ".ace-local", "coworker", "worker.yml")
            assert File.file?(custom), "commission wrote the configured config_path"
            refute File.exist?(File.join(worktree, ".ace-local", "coworker", "config.yml"))

            # From the project root, prepare must see the commissioned
            # executor through the same configured path.
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", @task_ref, "--roles", "reviewer", "--dry-run", "--format", "json")
            refute status.success?, "commissioned worktree never prepares cleanly: #{out}#{err}"
            assert_includes err, "active_executor"
            payload = JSON.parse(out)
            assert_equal "active_executor", payload["conflict"]["kind"]
            assert_includes payload["conflict"]["detail"], assignment_id
          end

          private

          def create_pending_assignment(worktree)
            job = File.join(@dir, "job.yaml")
            File.write(job, <<~YAML)
              assignment:
                name: fixture-executor
                description: Occupy the worktree as a commissioned executor
                task_id: #{@task_ref}
              steps:
                - name: work-step
                  instructions: |
                    Do the work.
            YAML
            out, err, _status = run_cli(ASSIGN_BIN, "create", "--yaml", job, chdir: worktree)
            assignment_id = out[/Assignment: .* \((\w+)\)/, 1]
            refute_nil assignment_id, "ace-assign create returned no id: #{err}#{out}"
            assignment_id
          end

          def prepare_worktree(task_ref)
            out, err, status = run_cli(COWORKER_BIN, "prepare",
              "--task", task_ref, "--roles", "worker", "--to", "overseer", "--format", "json")
            assert status.success?, "fixture prepare failed: #{out}#{err}"
            JSON.parse(out)["worktree"]["path"]
          end

          def expected_worktree_path(task_ref)
            Dir.chdir(@dir) do
              manager = Ace::Git::Worktree::Organisms::WorktreeManager.new(project_root: @dir)
              preview = manager.create_task(task_ref, {dry_run: true})
              assert preview[:success], "dry-run preview failed: #{preview.inspect}"
              preview.dig(:would_create, :worktree_path)
            end
          end

          def create_running_assignment(worktree)
            job = File.join(@dir, "job.yaml")
            File.write(job, <<~YAML)
              assignment:
                name: fixture-executor
                description: Occupy the worktree as a commissioned executor
                task_id: #{@task_ref}
              steps:
                - name: work-step
                  instructions: |
                    Do the work.
            YAML
            out, err, _status = run_cli(ASSIGN_BIN, "create", "--yaml", job, chdir: worktree)
            assignment_id = out[/Assignment: .* \((\w+)\)/, 1]
            refute_nil assignment_id, "ace-assign create returned no id: #{err}#{out}"

            config_dir = File.join(worktree, ".ace-local", "coworker")
            FileUtils.mkdir_p(config_dir)
            File.write(File.join(config_dir, "config.yml"), <<~YAML)
              role: worker
              instructions: roles/worker.md
              start_prompt: "Drive assignment #{assignment_id}."
              task: #{@task_ref}
              assignment: #{assignment_id}
              overseer: overseer
            YAML

            run_cli(ASSIGN_BIN, "start", "--assignment", assignment_id, chdir: worktree)
            assignment_id
          end

          def worktree_snapshot(worktree)
            Dir.glob(File.join(worktree, "**", "*"), File::FNM_DOTMATCH)
              .reject { |p| File.basename(p) == ".git" }
              .sort
              .map { |p| [p, File.file?(p) ? Digest::MD5.file(p).to_s : :dir] }
          end

          def write_worktree_config
            dir = File.join(@dir, ".ace", "git")
            FileUtils.mkdir_p(dir)
            File.write(File.join(dir, "worktree.yml"), <<~YAML)
              git:
                worktree:
                  task:
                    auto_mark_in_progress: false
                    auto_commit_task: false
                    add_worktree_metadata: false
                    auto_push_task: false
                    auto_setup_upstream: false
                    auto_create_pr: false
                  hooks:
                    after_create: []
            YAML
          end

          def write_hitl_config
            hitl_dir = File.join(@dir, ".ace", "hitl")
            FileUtils.mkdir_p(hitl_dir)
            File.write(File.join(hitl_dir, "config.yml"), YAML.dump(
              "hitl" => {
                "machine" => "lab01",
                "recipients" => {"overseer" => {"machine" => "lab01", "folder" => ".ace-local/hitl"}}
              }
            ))
          end

          def hitl_events
            Dir.glob(File.join(@dir, ".ace-local", "hitl", "**", "*.hitl.s.md"))
          end

          # The executor/HITL probes prefer a project-root binstub; provide
          # wrappers delegating to the repo's pinned binstubs so subprocesses
          # never resolve stale installed gems through mise shims.
          def copy_binstubs
            bin_dir = File.join(@dir, "bin")
            FileUtils.mkdir_p(bin_dir)
            %w[ace-assign ace-hitl].each do |name|
              wrapper = File.join(bin_dir, name)
              File.write(wrapper, <<~SH)
                #!/bin/sh
                exec "#{File.join(REPO_ROOT, 'bin', name)}" "$@"
              SH
              FileUtils.chmod(0o755, wrapper)
            end
          end

          def commit_all(message)
            run_git("-C", @dir, "add", "-A")
            run_git("-C", @dir, "-c", "user.email=t@t", "-c", "user.name=t",
              "commit", "-q", "-m", message)
          end

          def run_cli(*argv, chdir: @dir)
            previous = ENV["BUNDLE_GEMFILE"]
            ENV["BUNDLE_GEMFILE"] = File.join(REPO_ROOT, "Gemfile")
            Open3.capture3(*argv, chdir: chdir)
          ensure
            ENV["BUNDLE_GEMFILE"] = previous
          end

          def run_git(*argv)
            Open3.capture3("git", *argv)
          end
        end
      end
    end
  end
end

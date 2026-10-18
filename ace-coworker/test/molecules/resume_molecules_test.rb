# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Molecules
      class GitStateProbeTest < AceCoworkerTestCase
        Status = Struct.new(:success?)

        def probe(outcomes = {})
          @calls = []
          runner = lambda do |argv, cwd|
            @calls << {argv: argv, cwd: cwd}
            o = if argv[1] == "status"
              outcomes[:status] || {out: "## main\n", err: "", success: true}
            else
              outcomes[:log] || {out: "abc1234 last commit", err: "", success: true}
            end
            [o[:out], o[:err], Status.new(o[:success])]
          end
          GitStateProbe.new(project_root: "/proj", runner: runner)
        end

        def test_parses_branch_tracking_and_dirty_entries
          git = probe(status: {success: true, out: "## feature...origin/feature [ahead 1]\n M lib/a.rb\n?? new.txt\n", err: ""})
          state = git.state

          assert_equal "feature", state["branch"]
          assert_equal "ahead 1", state["ahead_behind"]
          assert_equal ["M lib/a.rb", "?? new.txt"], state["dirty_entries"]
          assert_equal "abc1234 last commit", state["last_commit"]
        end

        def test_clean_tree_has_no_dirty_entries
          git = probe(status: {success: true, out: "## main...origin/main\n", err: ""})
          assert_empty git.state["dirty_entries"]
        end

        def test_only_read_only_subcommands_are_used
          git = probe(status: {success: true, out: "## main\n", err: ""})
          git.state
          argvs = @calls.map { |c| c[:argv][1] }
          assert_equal %w[log status], argvs.sort
          @calls.each { |c| assert_equal %w[git] + [c[:argv][1]], c[:argv][0, 2] }
          @calls.each { |c| assert_equal "/proj", c[:cwd] }
        end

        def test_failure_raises_explicit_error
          git = probe(status: {success: false, out: "", err: "fatal: not a git repository"})
          error = assert_raises(Error) { git.state }
          assert_includes error.message, "not a git repository"
        end
      end

      class StepReportReaderTest < AceCoworkerTestCase
        def test_finds_report_with_peek
          Dir.mktmpdir("coworker-resume") do |dir|
            reports = File.join(dir, ".ace-local", "assign", "abc123", "reports")
            FileUtils.mkdir_p(reports)
            File.write(File.join(reports, "020-verify.r.md"), "# Report\n\nstep output details\n")

            reader = StepReportReader.new(project_root: dir)
            result = reader.read("abc123", "020")
            assert_equal File.join(reports, "020-verify.r.md"), result["path"]
            assert_equal "# Report", result["peek"]
          end
        end

        def test_missing_report_returns_nil
          Dir.mktmpdir("coworker-resume") do |dir|
            assert_nil StepReportReader.new(project_root: dir).read("abc123", "020")
            assert_nil StepReportReader.new(project_root: dir).read("abc123", nil)
          end
        end

        def test_invalid_assignment_id_is_rejected
          Dir.mktmpdir("coworker-resume") do |dir|
            error = assert_raises(Error) { StepReportReader.new(project_root: dir).read("../evil", "020") }
            assert_includes error.message, "invalid assignment id"
          end
        end
      end
    end
  end
end

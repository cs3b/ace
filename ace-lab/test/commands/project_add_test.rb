# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

module Ace
  module Lab
    module CLI
      module Commands
        class ProjectAddCommandTest < Minitest::Test
          def setup
            @tmp = Dir.mktmpdir("project-add-cmd")
            @source = File.join(@tmp, "atlas.git")
            Open3.capture3("git", "init", "--bare", "-q", @source)
            @path = File.join(@tmp, "atlas")
            @organism = Ace::Lab::Organisms::ProjectAdd.new
            @command = ProjectAdd.new(project_add: @organism)
          end

          def teardown
            FileUtils.remove_entry(@tmp)
          end

          def call(**options)
            @command.call(id: "atlas", path: @path, remote: @source, label: nil,
              dry_run: nil, format: nil, quiet: nil, **options)
          end

          def test_table_output_names_each_step_and_the_result
            out, = capture_io { call }

            assert_includes out, "Project: atlas"
            assert_includes out, "Repository:"
            assert_includes out, "Overseer:"
            assert_includes out, "Registry:"
            assert_includes out, "Result: ok"
            assert File.file?(File.join(@path, ".ace", "lab", "config.yml"))
          end

          def test_json_output_matches_report_schema
            out, = capture_io { call(format: "json") }

            report = JSON.parse(out)
            assert_equal "atlas", report["project"]
            assert report["ok"]
            assert_equal %w[repository overseer registry owner],
              report.keys - %w[ok dry_run project path remote]
          end

          def test_dry_run_predicts_without_mutating
            out, = capture_io { call(dry_run: true) }

            assert_includes out, "(dry run)"
            assert_includes out, "would_create"
            refute File.exist?(@path)
          end

          def test_foreign_location_raises_with_the_conflict_named
            FileUtils.mkdir_p(File.join(@path, "payload"))
            File.write(File.join(@path, "payload", "keep.txt"), "team data\n")

            error = assert_raises(Ace::Support::Cli::Error) { call }

            assert_includes error.message, "project add failed"
            assert_includes error.message, "refusing to take over"
            assert File.file?(File.join(@path, "payload", "keep.txt"))
          end

          def test_unsupported_format_is_rejected
            error = assert_raises(Ace::Support::Cli::Error) { call(format: "yaml") }

            assert_includes error.message, "table or json"
          end

          def test_quiet_suppresses_output_but_still_prepares
            out, = capture_io { call(quiet: true) }

            assert_equal "", out
            assert File.directory?(File.join(@path, ".ace-tasks", "_overseer"))
          end
        end
      end
    end
  end
end

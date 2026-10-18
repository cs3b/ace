# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Lab
    module Organisms
      class StatusTest < Minitest::Test
        def configured_documents(path)
          [{path: path, document: {}, defaults: false}]
        end

        def test_configured_state_reports_sources_and_counts
          Dir.mktmpdir("lab-status") do |dir|
            status = Status.new(
              project_dir: dir,
              documents: configured_documents(File.join(dir, ".ace/lab/config.yml")),
              config: {"schema_version" => 1, "topology" => {
                "projects" => [{"id" => "atlas"}],
                "agents" => [
                  {"id" => "a1", "project" => "atlas", "role" => "worker",
                   "capabilities" => ["work"], "binding" => {"kind" => "runtime"}},
                  {"id" => "a2", "project" => "atlas", "role" => "worker",
                   "capabilities" => ["work"], "binding" => {"kind" => "runtime"}},
                  {"id" => "a3", "project" => "atlas", "role" => "worker",
                   "capabilities" => ["work"], "binding" => {"kind" => "runtime"}}
                ],
                "services" => [
                  {"id" => "s1", "project" => "atlas", "capabilities" => ["search"],
                   "endpoint" => {"kind" => "http", "url" => "https://s1.example/internal"},
                   "binding" => {"kind" => "service"}},
                  {"id" => "s2", "project" => "atlas", "capabilities" => ["index"],
                   "endpoint" => {"kind" => "http", "url" => "https://s2.example/internal"},
                   "binding" => {"kind" => "service"}}
                ]
              }}
            )
            section = status.snapshot["configuration"]

            assert_equal "configured", section["state"], section["error"]
            assert_equal [File.join(dir, ".ace/lab/config.yml")], section["sources"]
            assert_equal({"projects" => 1, "agents" => 3, "services" => 2}, section["topology"])
          end
        end

        def test_only_default_documents_is_not_configured_not_empty_ready
          Dir.mktmpdir("lab-status") do |dir|
            status = Status.new(
              project_dir: dir,
              documents: [{path: File.join(Ace::Lab.gem_root, ".ace-defaults/lab/config.yml"),
                           document: {}, defaults: true}]
            )
            section = status.snapshot["configuration"]

            assert_equal "not_configured", section["state"]
            assert_nil section["topology"]
          end
        end

        def test_malformed_document_is_an_error_state
          Dir.mktmpdir("lab-status") do |dir|
            status = Status.new(
              project_dir: dir,
              documents: nil
            )
            def status.explicit_documents
              raise InvalidConfigurationError, "invalid lab configuration: broken.yml could not be parsed as YAML"
            end
            section = status.snapshot["configuration"]

            assert_equal "error", section["state"]
            assert_includes section["error"], "broken.yml"
          end
        end

        def test_invalid_schema_is_an_error_state
          Dir.mktmpdir("lab-status") do |dir|
            status = Status.new(
              project_dir: dir,
              documents: configured_documents(File.join(dir, ".ace/lab/config.yml")),
              config: {"schema_version" => 99}
            )
            section = status.snapshot["configuration"]

            assert_equal "error", section["state"]
            assert_includes section["error"], "schema_version"
          end
        end

        def test_state_files_report_presence_counts_and_notes
          Dir.mktmpdir("lab-status") do |dir|
            FileUtils.mkdir_p(File.join(dir, ".ace-tasks"))
            FileUtils.mkdir_p(File.join(dir, ".ace-local", "assign"))
            %w[a b].each { |id| FileUtils.mkdir_p(File.join(dir, ".ace-local", "assign", id)) }
            FileUtils.mkdir_p(File.join(dir, ".ace-wt"))
            %w[w1 w2 w3].each { |w| FileUtils.mkdir_p(File.join(dir, ".ace-wt", w)) }

            entries = Status.new(project_dir: dir).snapshot["state_files"]
            by_path = entries.to_h { |e| [e["path"], e] }

            assert by_path[".ace-tasks"]["present"]
            assert_equal 0, by_path[".ace-tasks"]["entries"]
            assert_equal 2, by_path[".ace-local/assign"]["entries"]
            assert_equal 3, by_path[".ace-wt"]["entries"]

            refute by_path[".ace-local/coworker"]["present"]
            assert_includes by_path[".ace-local/coworker"]["note"], "coworker start/status is planned"
            refute by_path[".ace-tasks/_overseer"]["present"]
            assert_includes by_path[".ace-tasks/_overseer"]["note"], "private overseer list"
          end
        end

        def test_worktree_view_points_at_existing_command
          Dir.mktmpdir("lab-status") do |dir|
            snapshot = Status.new(project_dir: dir).snapshot
            assert_equal "ace-git-worktree list", snapshot["worktree_view"]
          end
        end

        def test_state_files_resolve_from_subdirectory_of_the_project
          Dir.mktmpdir("lab-status-root") do |dir|
            system("git", "-C", dir, "init", "--quiet", out: File::NULL, err: File::NULL)
            FileUtils.mkdir_p(File.join(dir, ".ace-tasks"))
            subdir = File.join(dir, "deep", "sub")
            FileUtils.mkdir_p(subdir)

            entries = nil
            Dir.chdir(subdir) { entries = Status.new.snapshot["state_files"] }
            by_path = entries.to_h { |e| [e["path"], e] }

            assert by_path[".ace-tasks"]["present"],
              "expected .ace-tasks resolved against the project root, got: #{entries.inspect}"
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Cli::Commands::Nav::Tree do
  let(:command) { described_class.new }
  let(:mock_config_loader) { double("TreeConfigLoader") }
  let(:mock_path_resolver) { double("PathResolver") }
  let(:temp_dir) { Dir.mktmpdir }

  let(:default_config) do
    {
      "default_depth" => 3,
      "contexts" => {
        "default" => {
          "max_depth" => 3,
          "excludes" => ["node_modules", ".git"]
        },
        "dev" => {
          "max_depth" => 5,
          "excludes" => ["coverage", "tmp"]
        },
        "tasks" => {
          "max_depth" => 2,
          "excludes" => ["done"]
        }
      },
      "global_excludes" => [".DS_Store", "*.tmp"],
      "repositories" => {
        "specific_excludes" => {
          "repo1" => ["vendor"],
          "repo2" => ["dist"]
        }
      }
    }
  end

  before do
    allow(CodingAgentTools::Molecules::TreeConfigLoader).to receive(:new).and_return(mock_config_loader)
    allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)
    allow(mock_config_loader).to receive(:load).and_return(default_config)
    allow(Dir).to receive(:exist?).and_call_original
    # Mock global status

    # Default stubs for path resolver methods
    allow(mock_path_resolver).to receive(:resolve_scoped_pattern).and_return(success: false, error: "Not found")
    allow(mock_path_resolver).to receive(:find_matching_paths).and_return([])
    allow(mock_path_resolver).to receive(:resolve_path).and_return(success: false, error: "Not found")
    allow(mock_path_resolver).to receive(:find_directories_by_name).and_return(success: false, error: "Not found")
    allow(mock_path_resolver).to receive(:prioritize_matches).and_return(best: "default", alternatives: [])
    allow(mock_path_resolver).to receive(:format_alternative_matches).and_return("")

    # Mock $? to return a successful exit status for all tests
    allow($?).to receive(:exitstatus).and_return(0)
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#call" do
    context "with no path (current directory)" do
      it "uses current directory with default configuration" do
        expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '.'"
        allow(command).to receive(:`).with(expected_command).and_return(".\n└── file.txt\n")

        output = capture_stdout { command.call }

        expect(output).to include(".\n└── file.txt")
      end
    end

    context "with existing path" do
      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
      end

      it "uses specified directory" do
        expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("#{temp_dir}\n└── existing_file.txt\n")

        output = capture_stdout { command.call(path: temp_dir) }

        expect(output).to include("existing_file.txt")
      end

      it "does not attempt path resolution for existing directories" do
        expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("output")

        capture_stdout { command.call(path: temp_dir) }

        expect(mock_path_resolver).not_to have_received(:resolve_scoped_pattern)
        expect(mock_path_resolver).not_to have_received(:find_matching_paths)
      end
    end

    context "with context option" do
      it "uses dev context configuration" do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        expected_command = "tree -L 5 -I '.DS_Store' -I '*.tmp' -I 'coverage' -I 'tmp' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("dev context output")

        output = capture_stdout { command.call(path: temp_dir, context: "dev") }

        expect(output).to include("dev context output")
      end

      it "uses tasks context configuration" do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        expected_command = "tree -L 2 -I '.DS_Store' -I '*.tmp' -I 'done' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("tasks context output")

        output = capture_stdout { command.call(path: temp_dir, context: "tasks") }

        expect(output).to include("tasks context output")
      end

      it "falls back to default context for unknown context" do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("fallback output")

        output = capture_stdout { command.call(path: temp_dir, context: "unknown") }

        expect(output).to include("fallback output")
      end
    end

    context "with depth option" do
      it "overrides context depth with custom depth" do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        expected_command = "tree -L 7 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("deep tree output")

        output = capture_stdout { command.call(path: temp_dir, depth: 7) }

        expect(output).to include("deep tree output")
      end
    end

    context "with autocorrect disabled" do
      it "shows error for nonexistent path" do
        nonexistent_path = "nonexistent_directory"
        allow(Dir).to receive(:exist?).with(nonexistent_path).and_return(false)

        output = capture_stdout { command.call(path: nonexistent_path, autocorrect: false) }

        expect(output).to include("Error: Directory 'nonexistent_directory' not found and autocorrection is disabled")
        expect(mock_path_resolver).not_to have_received(:resolve_scoped_pattern)
        expect(mock_path_resolver).not_to have_received(:find_matching_paths)
      end
    end

    context "with scoped pattern path" do
      let(:scoped_path) { "scope:pattern" }

      context "when scoped pattern resolves to directory" do
        it "uses resolved directory path" do
          resolved_path = "resolved/directory"
          allow(Dir).to receive(:exist?).with(scoped_path).and_return(false)
          allow(Dir).to receive(:exist?).with(resolved_path).and_return(true)
          allow(mock_path_resolver).to receive(:resolve_scoped_pattern).with(scoped_path)
            .and_return(
              success: true,
              path: resolved_path,
              autocorrect_message: "Scope resolved: 'scope:pattern' → 'resolved/directory'"
            )

          expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{resolved_path}'"
          allow(command).to receive(:`).with(expected_command).and_return("scoped directory output")

          output = capture_stdout { command.call(path: scoped_path, autocorrect: true) }

          expect(output).to include("Scope resolved: 'scope:pattern' → 'resolved/directory'")
          expect(output).to include("Best match: '#{resolved_path}'")
          expect(output).to include("scoped directory output")
        end
      end

      context "when scoped pattern resolves to file" do
        it "uses parent directory of resolved file" do
          resolved_file = "resolved/directory/file.txt"
          resolved_dir = "resolved/directory"
          allow(Dir).to receive(:exist?).with(scoped_path).and_return(false)
          allow(Dir).to receive(:exist?).with(resolved_file).and_return(false)
          allow(File).to receive(:dirname).with(resolved_file).and_return(resolved_dir)
          allow(mock_path_resolver).to receive(:resolve_scoped_pattern).with(scoped_path)
            .and_return(
              success: true,
              path: resolved_file,
              autocorrect_message: "Scope resolved: 'scope:pattern' → 'resolved/directory/file.txt'"
            )

          expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{resolved_dir}'"
          allow(command).to receive(:`).with(expected_command).and_return("parent directory output")

          output = capture_stdout { command.call(path: scoped_path, autocorrect: true) }

          expect(output).to include("Scope resolved: 'scope:pattern' → 'resolved/directory/file.txt'")
          expect(output).to include("Best match: '#{resolved_dir}' (parent directory of found file)")
          expect(output).to include("parent directory output")
        end
      end

      context "when scoped pattern has alternatives" do
        it "stores and displays alternatives" do
          resolved_path = "resolved/directory"
          alternatives = ["alternative1", "alternative2"]
          allow(Dir).to receive(:exist?).with(scoped_path).and_return(false)
          allow(Dir).to receive(:exist?).with(resolved_path).and_return(true)
          allow(Dir).to receive(:exist?).with("alternative1").and_return(true)
          allow(Dir).to receive(:exist?).with("alternative2").and_return(true)
          allow(mock_path_resolver).to receive(:resolve_scoped_pattern).with(scoped_path)
            .and_return(
              success: true,
              type: :scoped_multiple,
              path: resolved_path,
              alternatives: alternatives,
              autocorrect_message: "Scope resolved"
            )
          allow(mock_path_resolver).to receive(:format_alternative_matches).with(alternatives)
            .and_return("Alternative matches:\n  - alternative1\n  - alternative2")

          expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{resolved_path}'"
          allow(command).to receive(:`).with(expected_command).and_return("tree output")

          output = capture_stdout { command.call(path: scoped_path, autocorrect: true) }

          expect(output).to include("Alternative matches:")
          expect(output).to include("alternative1")
          expect(output).to include("alternative2")
        end
      end

      context "when scoped pattern fails" do
        it "shows error message" do
          allow(Dir).to receive(:exist?).with(scoped_path).and_return(false)
          allow(mock_path_resolver).to receive(:resolve_scoped_pattern).with(scoped_path)
            .and_return(success: false, error: "Scoped pattern not found")

          output = capture_stdout { command.call(path: scoped_path, autocorrect: true) }

          expect(output).to include("Error: Scoped pattern not found")
        end
      end
    end

    context "with directory search" do
      let(:search_path) { "search_dir" }

      context "when single directory match found" do
        it "uses the matched directory" do
          matched_dir = "matched/directory"
          allow(Dir).to receive(:exist?).with(search_path).and_return(false)
          allow(mock_path_resolver).to receive(:find_matching_paths)
            .with(search_path, include_directories: true, max_results: 5)
            .and_return([matched_dir])
          allow(Dir).to receive(:exist?).with(matched_dir).and_return(true)

          expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{matched_dir}'"
          allow(command).to receive(:`).with(expected_command).and_return("matched directory output")

          output = capture_stdout { command.call(path: search_path, autocorrect: true) }

          expect(output).to include("Autocorrected: 'search_dir' → '#{matched_dir}'")
          expect(output).to include("matched directory output")
        end
      end

      context "when multiple directory matches found" do
        it "uses prioritized best match and shows alternatives" do
          matched_dirs = ["dir1", "dir2", "dir3"]
          prioritized_result = {
            best: "dir1",
            alternatives: ["dir2", "dir3"]
          }

          # Mock find_directories_by_name for autocorrection path
          allow(mock_path_resolver).to receive(:find_directories_by_name)
            .with(search_path, autocorrect: true)
            .and_return(success: true, path: "dir1", alternatives: ["dir2", "dir3"])

          allow(Dir).to receive(:exist?).with(search_path).and_return(false)
          allow(mock_path_resolver).to receive(:find_matching_paths)
            .with(search_path, include_directories: true, max_results: 5)
            .and_return(matched_dirs)
          matched_dirs.each { |dir| allow(Dir).to receive(:exist?).with(dir).and_return(true) }
          allow(mock_path_resolver).to receive(:prioritize_matches).with(matched_dirs)
            .and_return(prioritized_result)
          allow(mock_path_resolver).to receive(:format_alternative_matches).with(["dir2", "dir3"])
            .and_return("Alternative matches:\n  - dir2\n  - dir3")

          expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' 'dir1'"
          allow(command).to receive(:`).with(expected_command).and_return("best match output")

          output = capture_stdout { command.call(path: search_path, autocorrect: true) }

          expect(output).to include("Autocorrected: 'search_dir' → 'dir1'")
          expect(output).to include("best match output")
          expect(output).to include("Alternative matches:")
          expect(output).to include("dir2")
          expect(output).to include("dir3")
        end
      end
    end

    context "with file search fallback" do
      let(:search_path) { "search_file" }

      context "when file search returns single match" do
        context "when resolved path is directory" do
          it "uses the directory directly" do
            resolved_dir = "resolved/directory"
            allow(Dir).to receive(:exist?).with(search_path).and_return(false)
            allow(mock_path_resolver).to receive(:find_matching_paths)
              .with(search_path, include_directories: true, max_results: 5)
              .and_return([])
            allow(mock_path_resolver).to receive(:resolve_path).with(search_path, type: :file)
              .and_return(success: true, type: :single, path: resolved_dir)
            allow(Dir).to receive(:exist?).with(resolved_dir).and_return(true)

            expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{resolved_dir}'"
            allow(command).to receive(:`).with(expected_command).and_return("directory tree output")

            output = capture_stdout { command.call(path: search_path, autocorrect: true) }

            expect(output).to include("Autocorrected: 'search_file' → '#{resolved_dir}'")
            expect(output).to include("directory tree output")
          end
        end

        context "when resolved path is file" do
          it "uses parent directory of the file" do
            resolved_file = "resolved/directory/file.txt"
            resolved_dir = "resolved/directory"
            allow(Dir).to receive(:exist?).with(search_path).and_return(false)
            allow(mock_path_resolver).to receive(:find_matching_paths)
              .with(search_path, include_directories: true, max_results: 5)
              .and_return([])
            allow(mock_path_resolver).to receive(:resolve_path).with(search_path, type: :file)
              .and_return(success: true, type: :single, path: resolved_file)
            allow(Dir).to receive(:exist?).with(resolved_file).and_return(false)
            allow(File).to receive(:dirname).with(resolved_file).and_return(resolved_dir)

            expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{resolved_dir}'"
            allow(command).to receive(:`).with(expected_command).and_return("parent directory output")

            output = capture_stdout { command.call(path: search_path, autocorrect: true) }

            expect(output).to include("Autocorrected: 'search_file' → '#{resolved_dir}' (parent directory of found file)")
            expect(output).to include("parent directory output")
          end
        end
      end

      context "when file search returns multiple matches" do
        it "uses prioritized match and shows alternatives" do
          file_paths = ["file1.txt", "dir2/file2.txt", "file3.txt"]
          dir_paths = [".", "dir2", "."]
          unique_dirs = [".", "dir2"]
          prioritized_result = {
            best: "dir2",
            alternatives: ["."]
          }

          allow(Dir).to receive(:exist?).with(search_path).and_return(false)
          allow(mock_path_resolver).to receive(:find_matching_paths)
            .with(search_path, include_directories: true, max_results: 5)
            .and_return([])
          allow(mock_path_resolver).to receive(:resolve_path).with(search_path, type: :file)
            .and_return(success: true, type: :multiple, paths: file_paths)

          file_paths.each_with_index do |file_path, index|
            dir_path = dir_paths[index]
            is_dir = Dir.exist?(file_path)
            allow(Dir).to receive(:exist?).with(file_path).and_return(is_dir)
            unless is_dir
              allow(File).to receive(:dirname).with(file_path).and_return(dir_path)
            end
          end

          allow(mock_path_resolver).to receive(:prioritize_matches).with(unique_dirs)
            .and_return(prioritized_result)
          allow(mock_path_resolver).to receive(:format_alternative_matches).with(["."])
            .and_return("Alternative matches:\n  - .")

          expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' 'dir2'"
          allow(command).to receive(:`).with(expected_command).and_return("multiple match output")

          output = capture_stdout { command.call(path: search_path, autocorrect: true) }

          expect(output).to include("Autocorrected: 'search_file' → 'dir2' (parent directory of found file)")
          expect(output).to include("multiple match output")
          expect(output).to include("Alternative matches:")
        end
      end

      context "when file search fails" do
        it "shows error message" do
          allow(Dir).to receive(:exist?).with(search_path).and_return(false)
          allow(mock_path_resolver).to receive(:find_matching_paths)
            .with(search_path, include_directories: true, max_results: 5)
            .and_return([])
          allow(mock_path_resolver).to receive(:resolve_path).with(search_path, type: :file)
            .and_return(success: false, error: "No files found matching pattern")

          output = capture_stdout { command.call(path: search_path, autocorrect: true) }

          expect(output).to include("Error: No files found matching pattern")
        end
      end
    end

    context "when tree command fails" do
      it "shows error message and output" do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("tree command error output")
        allow($?).to receive(:exitstatus).and_return(1)

        output = capture_stdout { command.call(path: temp_dir) }

        expect(output).to include("Error executing tree command: #{expected_command}")
        expect(output).to include("Output: tree command error output")
      end

      it "handles empty error output" do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("   ")
        allow($?).to receive(:exitstatus).and_return(1)

        output = capture_stdout { command.call(path: temp_dir) }

        expect(output).to include("Error executing tree command: #{expected_command}")
        expect(output).not_to include("Output:")
      end
    end

    context "when an exception occurs" do
      it "handles exceptions gracefully" do
        allow(mock_config_loader).to receive(:load).and_raise(StandardError, "Config loading failed")

        output = capture_stdout { command.call }

        expect(output).to include("Error: Config loading failed")
      end
    end

    context "with edge case configurations" do
      context "when config is missing default context" do
        let(:minimal_config) do
          {
            "default_depth" => 2,
            "contexts" => {},
            "global_excludes" => []
          }
        end

        it "handles missing default context gracefully" do
          allow(mock_config_loader).to receive(:load).and_return(minimal_config)
          expected_command = "tree -L 2 '.'"
          allow(command).to receive(:`).with(expected_command).and_return("minimal output")

          output = capture_stdout { command.call }

          expect(output).to include("minimal output")
        end
      end

      context "when config has no excludes" do
        let(:no_excludes_config) do
          {
            "default_depth" => 3,
            "contexts" => {
              "default" => {
                "max_depth" => 3
              }
            }
          }
        end

        it "handles missing excludes gracefully" do
          allow(mock_config_loader).to receive(:load).and_return(no_excludes_config)
          expected_command = "tree -L 3 '.'"
          allow(command).to receive(:`).with(expected_command).and_return("no excludes output")

          output = capture_stdout { command.call }

          expect(output).to include("no excludes output")
        end
      end
    end

    context "command building" do
      it "properly escapes path with spaces" do
        spaced_path = "path with spaces"
        allow(Dir).to receive(:exist?).with(spaced_path).and_return(true)
        expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{spaced_path}'"
        allow(command).to receive(:`).with(expected_command).and_return("spaced path output")

        output = capture_stdout { command.call(path: spaced_path) }

        expect(output).to include("spaced path output")
      end

      it "properly escapes exclude patterns" do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        expected_command = "tree -L 3 -I '.DS_Store' -I '*.tmp' -I 'node_modules' -I '.git' -I 'vendor' -I 'dist' '#{temp_dir}'"
        allow(command).to receive(:`).with(expected_command).and_return("escaped output")

        output = capture_stdout { command.call(path: temp_dir) }

        expect(output).to include("escaped output")
      end
    end
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end

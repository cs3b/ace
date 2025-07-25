# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe CodingAgentTools::Cli::Commands::Nav::Ls do
  let(:command) { described_class.new }
  let(:temp_dir) { Dir.mktmpdir }
  let(:mock_path_resolver) { instance_double("CodingAgentTools::Molecules::PathResolver") }

  before do
    allow(CodingAgentTools::Molecules::PathResolver).to receive(:new).and_return(mock_path_resolver)
  end

  after do
    FileUtils.rm_rf(temp_dir) if Dir.exist?(temp_dir)
  end

  describe "#call" do
    context "with no path (current directory)" do
      it "lists current directory by default" do
        allow(command).to receive(:`).with("ls '.'").and_return("file1.txt\nfile2.txt\n")
        allow($?).to receive(:exitstatus).and_return(0)

        output = capture_stdout { command.call }

        expect(output).to include("file1.txt")
        expect(output).to include("file2.txt")
      end
    end

    context "with existing path" do
      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(command).to receive(:`).with("ls '#{temp_dir}'").and_return("existing_file.txt\n")
        allow($?).to receive(:exitstatus).and_return(0)
      end

      it "lists the specified directory" do
        output = capture_stdout { command.call(path: temp_dir) }

        expect(output).to include("existing_file.txt")
      end

      it "does not attempt autocorrection for existing paths" do
        capture_stdout { command.call(path: temp_dir) }

        expect(mock_path_resolver).not_to have_received(:resolve_scoped_pattern)
        expect(mock_path_resolver).not_to have_received(:find_matching_paths)
      end
    end

    context "with long format option" do
      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(command).to receive(:`).with("ls -l '#{temp_dir}'").and_return("drwxr-xr-x 2 user group 4096 Jan 1 12:00 dir1\n")
        allow($?).to receive(:exitstatus).and_return(0)
      end

      it "uses long format flag" do
        output = capture_stdout { command.call(path: temp_dir, long: true) }

        expect(output).to include("drwxr-xr-x")
        expect(output).to include("dir1")
      end
    end

    context "with show all option" do
      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(command).to receive(:`).with("ls -a '#{temp_dir}'").and_return(".hidden\nvisible.txt\n")
        allow($?).to receive(:exitstatus).and_return(0)
      end

      it "shows hidden files" do
        output = capture_stdout { command.call(path: temp_dir, all: true) }

        expect(output).to include(".hidden")
        expect(output).to include("visible.txt")
      end
    end

    context "with combined options" do
      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(command).to receive(:`).with("ls -la '#{temp_dir}'").and_return("total 8\ndrwxr-xr-x 2 user group 4096 Jan 1 12:00 .\n")
        allow($?).to receive(:exitstatus).and_return(0)
      end

      it "combines multiple flags correctly" do
        output = capture_stdout { command.call(path: temp_dir, long: true, all: true) }

        expect(output).to include("total 8")
        expect(output).to include("drwxr-xr-x")
      end
    end

    context "with autocorrection enabled (default)" do
      let(:nonexistent_path) { "nonexistent_dir" }

      before do
        allow(Dir).to receive(:exist?).with(nonexistent_path).and_return(false)
      end

      context "with scoped pattern" do
        let(:scoped_path) { "dev:tools" }
        let(:resolved_path) { "/project/dev-tools" }

        before do
          allow(mock_path_resolver).to receive(:resolve_scoped_pattern).with(scoped_path).and_return({
            success: true,
            path: resolved_path,
            type: :scoped_single,
            autocorrect_message: "Resolved 'dev:tools' to dev-tools scope"
          })
          allow(Dir).to receive(:exist?).with(resolved_path).and_return(true)
          allow(command).to receive(:`).with("ls '#{resolved_path}'").and_return("file1.rb\nfile2.rb\n")
          allow($?).to receive(:exitstatus).and_return(0)
        end

        it "resolves scoped patterns" do
          output = capture_stdout { command.call(path: scoped_path) }

          expect(output).to include("Resolved 'dev:tools' to dev-tools scope")
          expect(output).to include("Best match: '#{resolved_path}'")
          expect(output).to include("file1.rb")
          expect(mock_path_resolver).to have_received(:resolve_scoped_pattern).with(scoped_path)
        end

        it "handles multiple alternatives for scoped patterns" do
          allow(mock_path_resolver).to receive(:resolve_scoped_pattern).and_return({
            success: true,
            path: resolved_path,
            type: :scoped_multiple,
            alternatives: ["/project/dev-tools", "/other/dev-tools"]
          })
          allow(mock_path_resolver).to receive(:format_alternative_matches).with([resolved_path, "/other/dev-tools"]).and_return("Alternative matches:\n  /other/dev-tools")

          output = capture_stdout { command.call(path: scoped_path) }

          expect(output).to include("Alternative matches:")
          expect(mock_path_resolver).to have_received(:format_alternative_matches)
        end
      end

      context "with directory search" do
        let(:matching_dirs) { ["/project/some/directory", "/project/other/directory"] }

        before do
          allow(mock_path_resolver).to receive(:find_matching_paths).with(
            nonexistent_path,
            include_directories: true,
            max_results: 5
          ).and_return(matching_dirs)

          matching_dirs.each do |dir|
            allow(Dir).to receive(:exist?).with(dir).and_return(true)
          end
        end

        context "with single directory match" do
          let(:matching_dirs) { ["/project/some/directory"] }

          before do
            allow(command).to receive(:`).with("ls '/project/some/directory'").and_return("content.txt\n")
            allow($?).to receive(:exitstatus).and_return(0)
          end

          it "autocorrects to single matching directory" do
            output = capture_stdout { command.call(path: nonexistent_path) }

            expect(output).to include("Autocorrected: '#{nonexistent_path}' → '/project/some/directory'")
            expect(output).to include("content.txt")
          end
        end

        context "with multiple directory matches" do
          let(:prioritized_result) do
            {
              best: "/project/some/directory",
              alternatives: ["/project/other/directory"]
            }
          end

          before do
            allow(mock_path_resolver).to receive(:prioritize_matches).with(matching_dirs).and_return(prioritized_result)
            allow(command).to receive(:`).with("ls '/project/some/directory'").and_return("content.txt\n")
            allow($?).to receive(:exitstatus).and_return(0)
            allow(mock_path_resolver).to receive(:format_alternative_matches).with(["/project/other/directory"]).and_return("Alternatives:\n  /project/other/directory")
          end

          it "uses prioritized best match and shows alternatives" do
            output = capture_stdout { command.call(path: nonexistent_path) }

            expect(output).to include("Autocorrected: '#{nonexistent_path}' → '/project/some/directory'")
            expect(output).to include("content.txt")
            expect(output).to include("Alternatives:")
            expect(mock_path_resolver).to have_received(:prioritize_matches).with(matching_dirs)
          end
        end
      end

      context "with file fallback" do
        let(:file_result) do
          {
            success: true,
            type: :single,
            path: "/project/some/file.rb"
          }
        end

        before do
          allow(mock_path_resolver).to receive(:find_matching_paths).and_return([])
          allow(mock_path_resolver).to receive(:resolve_path).with(nonexistent_path, type: :file).and_return(file_result)
          allow(Dir).to receive(:exist?).with("/project/some/file.rb").and_return(false)
          allow(File).to receive(:dirname).with("/project/some/file.rb").and_return("/project/some")
          allow(command).to receive(:`).with("ls '/project/some'").and_return("file.rb\nother_file.rb\n")
          allow($?).to receive(:exitstatus).and_return(0)
        end

        it "falls back to parent directory of found file" do
          output = capture_stdout { command.call(path: nonexistent_path) }

          expect(output).to include("Autocorrected: '#{nonexistent_path}' → '/project/some' (parent directory of found file)")
          expect(output).to include("file.rb")
          expect(output).to include("other_file.rb")
        end

        context "with multiple file matches" do
          let(:file_result) do
            {
              success: true,
              type: :multiple,
              paths: ["/project/some/file1.rb", "/project/other/file2.rb"]
            }
          end

          let(:prioritized_result) do
            {
              best: "/project/some",
              alternatives: ["/project/other"]
            }
          end

          before do
            allow(File).to receive(:dirname).with("/project/some/file1.rb").and_return("/project/some")
            allow(File).to receive(:dirname).with("/project/other/file2.rb").and_return("/project/other")
            allow(mock_path_resolver).to receive(:prioritize_matches).with(["/project/some", "/project/other"]).and_return(prioritized_result)
            allow(command).to receive(:`).with("ls '/project/some'").and_return("file1.rb\n")
            allow($?).to receive(:exitstatus).and_return(0)
            allow(mock_path_resolver).to receive(:format_alternative_matches).with(["/project/other"]).and_return("Alternatives:\n  /project/other")
          end

          it "prioritizes parent directories and shows alternatives" do
            output = capture_stdout { command.call(path: nonexistent_path) }

            expect(output).to include("Autocorrected: '#{nonexistent_path}' → '/project/some' (parent directory of found file)")
            expect(output).to include("file1.rb")
            expect(output).to include("Alternatives:")
          end
        end
      end
    end

    context "with autocorrection disabled" do
      let(:nonexistent_path) { "nonexistent_dir" }

      before do
        allow(Dir).to receive(:exist?).with(nonexistent_path).and_return(false)
      end

      it "shows error without attempting autocorrection" do
        output = capture_stdout { command.call(path: nonexistent_path, autocorrect: false) }

        expect(output).to include("Error: Directory '#{nonexistent_path}' not found and autocorrection is disabled")
        expect(mock_path_resolver).not_to have_received(:resolve_scoped_pattern)
        expect(mock_path_resolver).not_to have_received(:find_matching_paths)
      end
    end

    context "with command execution errors" do
      before do
        allow(Dir).to receive(:exist?).with(temp_dir).and_return(true)
        allow(command).to receive(:`).with("ls '#{temp_dir}'").and_return("Permission denied")
        allow($?).to receive(:exitstatus).and_return(1)
      end

      it "handles ls command failures" do
        output = capture_stdout { command.call(path: temp_dir) }

        expect(output).to include("Error executing ls command:")
        expect(output).to include("Output: Permission denied")
      end
    end

    context "with resolution errors" do
      let(:error_result) { {success: false, error: "No matching paths found"} }

      before do
        allow(Dir).to receive(:exist?).with("nonexistent").and_return(false)
        allow(mock_path_resolver).to receive(:find_matching_paths).and_return([])
        allow(mock_path_resolver).to receive(:resolve_path).and_return(error_result)
      end

      it "displays resolution errors" do
        output = capture_stdout { command.call(path: "nonexistent") }

        expect(output).to include("Error: No matching paths found")
      end
    end

    context "with exceptions" do
      before do
        allow(Dir).to receive(:exist?).with("error_path").and_return(true)
        allow(command).to receive(:`).and_raise(StandardError, "Command execution failed")
      end

      it "handles exceptions gracefully" do
        output = capture_stdout { command.call(path: "error_path") }

        expect(output).to include("Error: Command execution failed")
      end
    end
  end

  describe "private methods" do
    describe "#build_ls_command" do
      it "builds basic ls command" do
        result = command.send(:build_ls_command, "/some/path", {})
        expect(result).to eq("ls '/some/path'")
      end

      it "adds long format flag" do
        result = command.send(:build_ls_command, "/some/path", {long: true})
        expect(result).to eq("ls -l '/some/path'")
      end

      it "adds all files flag" do
        result = command.send(:build_ls_command, "/some/path", {all: true})
        expect(result).to eq("ls -a '/some/path'")
      end

      it "combines multiple flags" do
        result = command.send(:build_ls_command, "/some/path", {long: true, all: true})
        expect(result).to eq("ls -la '/some/path'")
      end

      it "properly quotes path with spaces" do
        result = command.send(:build_ls_command, "/path with spaces", {})
        expect(result).to eq("ls '/path with spaces'")
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

# frozen_string_literal: true

require_relative "../../test_helper"
require "pty"
require "timeout"
require "ace/overseer/molecules/project_bundle"

module Molecules
  class RuntimeSetupTransportTest < AceOverseerTestCase
    def setup
      @root = Dir.mktmpdir("runtime setup ")
    end

    def teardown
      FileUtils.remove_entry(@root)
    end

    def test_long_environment_survives_real_canonical_terminal_and_finds_harness
      bin = File.join(@root, "harness-bin")
      FileUtils.mkdir_p(bin)
      File.write(File.join(bin, "pi"), "#!/bin/sh\nprintf 'HARNESS_FOUND:%s:%s\\n' \"$ACE_TOOLCHAIN\" \"${BUNDLE_PATH-unset}\"\n")
      File.chmod(0o755, File.join(bin, "pi"))
      old_path = ENV["PATH"]
      ENV["PATH"] = (["/missing/" + "x" * 80] * 100 + [bin, "/usr/bin", "/bin"]).join(":")
      Ace::Support::Cli::Toolchain.stub(:installed?, true) do
        bundle = Ace::Overseer::Molecules::ProjectBundle
        assert_operator bundle.shell_setup(@root).bytesize, :>, 4096
        PTY.spawn({"PS1" => "", "BUNDLE_PATH" => "/foreign/server/bundle"},
          "/bin/bash", "--noprofile", "--norc", "--noediting", "-i", chdir: @root) do |reader, writer, pid|
          begin
            writer.write("/bin/stty icanon -echo; printf 'PTY_READY\\n'\n")
            read_until(reader, /^PTY_READY\r?$/)
            bundle.with_shell_setup(@root) do |command, marker|
              assert_operator command.bytesize, :<, 256
              refute_includes command, marker
              file = Dir.glob(File.join(@root, ".ace-local/overseer/runtime-start/*.sh")).fetch(0)
              assert_equal 0o600, File.stat(file).mode & 0o777
              writer.write(command + "\n")
              read_until(reader, /^#{Regexp.escape(marker)}\r?$/)
            end
            assert_empty Dir.glob(File.join(@root, ".ace-local/overseer/runtime-start/*.sh"))
            writer.write("pi\n")
            read_until(reader, /^HARNESS_FOUND:installed:unset\r?$/)
          ensure
            Process.kill("KILL", pid) rescue Errno::ESRCH
            Process.wait(pid) rescue Errno::ECHILD
          end
        end
      end
    ensure
      ENV["PATH"] = old_path
    end

    def test_failed_setup_never_prints_ready_and_file_is_removed
      bundle = Ace::Overseer::Molecules::ProjectBundle
      bundle.stub(:shell_setup, "false") do
        bundle.with_shell_setup(@root) do |command, marker|
          out, _err, status = Open3.capture3("/bin/sh", "-c", command, chdir: @root)
          refute status.success?
          refute_includes out, marker
        end
      end
      assert_empty Dir.glob(File.join(@root, ".ace-local/overseer/runtime-start/*.sh"))
    end

    def test_readonly_inherited_selector_prevents_ready_marker
      Ace::Overseer::Molecules::ProjectBundle.with_shell_setup(@root) do |command, marker|
        out, _err, status = Open3.capture3("/bin/bash", "--noprofile", "--norc", "-c",
          "readonly BUNDLE_PATH=/foreign; #{command}", chdir: @root)
        refute status.success?
        refute_includes out, marker
      end
    end

    def test_refuses_symlink_and_nonprivate_handoff_directory_without_chmod
      File.symlink(Dir.tmpdir, File.join(@root, ".ace-local"))
      assert_raises(Ace::Overseer::Error) { Ace::Overseer::Molecules::ProjectBundle.with_shell_setup(@root) {} }
      File.unlink(File.join(@root, ".ace-local"))
      directory = File.join(@root, ".ace-local/overseer/runtime-start")
      FileUtils.mkdir_p(directory)
      File.chmod(0o755, directory)
      assert_raises(Ace::Overseer::Error) { Ace::Overseer::Molecules::ProjectBundle.with_shell_setup(@root) {} }
      assert_equal 0o755, File.stat(directory).mode & 0o777
    end

    private

    def read_until(reader, pattern)
      output = +""
      Timeout.timeout(10) do
        loop do
          output << reader.readpartial(4096)
          return output if output.match?(pattern)
        end
      end
    rescue Timeout::Error
      flunk "terminal did not produce #{pattern.inspect}: #{output.inspect}"
    end
  end
end

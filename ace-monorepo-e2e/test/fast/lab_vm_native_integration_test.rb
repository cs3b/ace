# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class LabVmNativeIntegrationTest < AceMonorepoE2eTestCase
  def setup
    @root = Dir.mktmpdir("fixture-native-integration-")
    @bin = File.join(@root, "bin")
    @agent = File.join(@root, "pi-agent")
    FileUtils.mkdir_p([@bin, File.join(@agent, "extensions")])
    source = File.read(File.expand_path("../../bin/lab-vm-fixture", __dir__))
    @script = source.split("        # Use Herdr's own pinned native integration", 2).last.split("        cd /lab", 2).first
    @script = "set -eu\n# Use Herdr's own pinned native integration" + @script.gsub("/opt/ace/runtime/pi-agent", @agent)
    File.write(File.join(@bin, "stat"), "#!/bin/sh\nprintf '%s\\n' root:root\n")
    File.write(File.join(@bin, "chown"), "#!/bin/sh\nexit 0\n")
    File.write(File.join(@bin, "runuser"), "#!/bin/sh\nshift 3\nexec \"$@\"\n")
    File.write(File.join(@bin, "herdr"), <<~'SH')
      #!/bin/sh
      set -eu
      target="$PI_CODING_AGENT_DIR/extensions/herdr-agent-state.ts"
      case "$*" in
        'integration install pi') printf '%s\n' 'pinned-native-extension' > "$target" ;;
        'integration status')
          if test "${TEST_STATUS:-current}" = current && test "$(cat "$target")" = pinned-native-extension; then
            printf '%s\n' 'pi: current (fixture)'
          else
            printf '%s\n' 'pi: needs repair (fixture)'
          fi ;;
        *) exit 2 ;;
      esac
    SH
    Dir.children(@bin).each { |name| File.chmod(0o755, File.join(@bin, name)) }
  end

  def teardown
    FileUtils.remove_entry(@root) if @root && File.directory?(@root)
  end

  def run_setup(status: "current")
    Open3.capture3({"PATH" => "#{@bin}:#{ENV.fetch('PATH')}", "TEST_STATUS" => status}, "/bin/sh", "-c", @script)
  end

  def test_retained_integration_is_reinstalled_and_verified_on_repeat
    2.times do
      _, error, status = run_setup
      assert status.success?, error
      assert_equal "pinned-native-extension\n", File.read(File.join(@agent, "extensions/herdr-agent-state.ts"))
    end
  end

  def test_noncurrent_native_status_blocks_setup
    _, _, status = run_setup(status: "outdated")
    refute status.success?
  end

  def test_symlinked_retained_extension_is_refused_before_native_install
    outside = File.join(@root, "unrelated")
    File.write(outside, "unchanged")
    File.symlink(outside, File.join(@agent, "extensions/herdr-agent-state.ts"))
    _, _, status = run_setup
    refute status.success?
    assert_equal "unchanged", File.read(outside)
  end
end

# frozen_string_literal: true

require_relative "../test_helper"
require "open3"

class LabVmSudoPolicyTest < Minitest::Test
  def test_runtime_provisioning_requires_an_explicit_denied_sudo_policy
    source = File.read(File.expand_path("../../lab-vm/provision-runtime.sh", __dir__))
    rule = source[/^sudo_listing=\$\(LC_ALL=C sudo -n -l -U mo\).*?^esac$/m]
    refute_nil rule

    denied = "sudo() { printf 'User mo is not allowed to run sudo on test.\\n'; }"
    granted = "sudo() { printf 'User mo may run the following commands: ALL\\n'; }"
    unavailable = "sudo() { return 1; }"
    [denied, granted, unavailable].each_with_index do |mock, index|
      _, _, status = Open3.capture3("/bin/sh", "-c", "set -eu\n#{mock}\n#{rule}\n")
      assert_equal index.zero?, status.success?
    end
  end
end

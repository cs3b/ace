# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/session_namespace"

module Ace
  module Lab
    module Auth
      class SessionNamespaceTest < Minitest::Test
        def test_rejects_invalid_process_and_closed_namespace
          assert_raises(ArgumentError) { SessionNamespace.capture(0) }
          file = File.open(File::NULL)
          file.close
          refute SessionNamespace.matches?(file, Process.pid)
          assert_raises(ArgumentError) { SessionNamespace.enter!(file) }
        end

        def test_rejects_the_initial_mount_namespace
          skip "Linux namespace API required" unless RUBY_PLATFORM.include?("linux")
          current = File.stat("/proc/self/ns/mnt")
          initial = File.stat("/proc/1/ns/mnt")
          skip "test process already has a private mount namespace" unless [current.dev, current.ino] == [initial.dev, initial.ino]
          assert_raises(ArgumentError) { SessionNamespace.capture(Process.pid) }
        end

        def test_detects_replacement_of_the_process_namespace
          Dir.mktmpdir do |dir|
            namespace = File.join(dir, "123", "ns", "mnt")
            FileUtils.mkdir_p(File.dirname(namespace))
            File.write(namespace, "original")
            File.open(namespace) do |handle|
              assert SessionNamespace.matches?(handle, 123, proc_root: dir)
              File.rename(namespace, namespace + ".old")
              File.write(namespace, "replacement")
              refute SessionNamespace.matches?(handle, 123, proc_root: dir)
            end
          end
        end
      end
    end
  end
end

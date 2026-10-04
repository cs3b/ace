# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Runtime
    class ProcessIdentityTest < AceRuntimeTestCase
      def test_live_identity_is_verified_without_command_line_data
        observer = Ace::Runtime::Molecules::ProcessIdentity.new
        identity = observer.capture(Process.pid)
        assert_equal %w[host pid started_at uid], identity.keys.sort
        assert_equal "live", observer.observe(identity)["liveness"]
      end

      def test_reused_pid_wrong_host_and_missing_identity_remain_unknown
        observer = Ace::Runtime::Molecules::ProcessIdentity.new
        identity = observer.capture(Process.pid)
        [nil, identity.merge("started_at" => "other"), identity.merge("host" => "other")].each do |value|
          assert_equal "unknown", observer.observe(value)["liveness"]
        end
      end

      class ProcessTable
        Status = Struct.new(:ok) { def success? = ok }
        attr_accessor :rows
        def initialize(rows)
          @rows = rows
        end
        def capture2(*args, **options)
          row = rows[args[2].to_i]
          return ["", Status.new(false)] unless row
          output = if args[-1] == "ppid="
            row[:parent].to_s
          else
            "#{args[2]} #{row[:uid]} #{row[:state] || 'S'} #{row[:birth]}"
          end
          [output, Status.new(true)]
        end
      end

      def test_owner_requires_descendant_of_native_shell_with_same_uid
        table = ProcessTable.new(10 => {parent: 1, uid: 100, birth: "shell"},
          11 => {parent: 10, uid: 100, birth: "agent"}, 12 => {parent: 11, uid: 100, birth: "tool"})
        observer = Ace::Runtime::Molecules::ProcessIdentity.new(executor: table, birth_reader: ->(pid) { table.rows.dig(pid, :birth) })
        owner = observer.owner(shell_pid: 10, caller_pid: 12)
        assert_equal 11, owner.dig("process_identity", "pid")
        assert_equal 10, owner.dig("shell_identity", "pid")
        assert_nil observer.owner(shell_pid: 10, caller_pid: 10)
        table.rows[11][:uid] = 101
        assert_nil observer.owner(shell_pid: 10, caller_pid: 12)
      end

      def test_shell_surviving_dead_agent_or_reparented_child_is_not_owner
        table = ProcessTable.new(10 => {parent: 1, uid: 100, birth: "shell"},
          12 => {parent: 1, uid: 100, birth: "orphan"})
        observer = Ace::Runtime::Molecules::ProcessIdentity.new(executor: table, birth_reader: ->(pid) { table.rows.dig(pid, :birth) })
        assert_nil observer.owner(shell_pid: 10, caller_pid: 11)
        assert_nil observer.owner(shell_pid: 10, caller_pid: 12)
        table.rows[11] = {parent: 10, uid: 100, birth: "agent", state: "Z"}
        assert_nil observer.owner(shell_pid: 10, caller_pid: 11)
      end

      def test_same_second_birth_change_is_pid_reuse
        table = ProcessTable.new(10 => {parent: 1, uid: 100, birth: "darwin:42:1"})
        observer = Ace::Runtime::Molecules::ProcessIdentity.new(executor: table,
          birth_reader: ->(pid) { table.rows.dig(pid, :birth) })
        saved = observer.capture(10)
        table.rows[10][:birth] = "darwin:42:2"
        assert_equal "unknown", observer.observe(saved)["liveness"]
      end

      def test_ancestry_revalidation_rejects_changed_incarnation
        table = ProcessTable.new(10 => {parent: 1, uid: 100, birth: "shell"},
          11 => {parent: 10, uid: 100, birth: "agent"})
        count = 0
        observer = Ace::Runtime::Molecules::ProcessIdentity.new(executor: table,
          birth_reader: ->(pid) {
            count += 1 if pid == 11
            table.rows[11][:birth] = "reused" if count >= 3
            table.rows.dig(pid, :birth)
          })
        assert_nil observer.owner(shell_pid: 10, caller_pid: 11)
      end

      def test_unreadable_observation_does_not_prove_termination
        executor = Object.new
        executor.define_singleton_method(:capture2) { |*args, **options| raise IOError }
        observer = Ace::Runtime::Molecules::ProcessIdentity.new(executor: executor)
        identity = Ace::Runtime::Molecules::ProcessIdentity.new.capture(Process.pid)
        assert_equal "unknown", observer.observe(identity)["liveness"]
      end
    end
  end
end

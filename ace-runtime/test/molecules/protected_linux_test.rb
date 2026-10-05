# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/protected_linux"

class ProtectedLinuxTest < AceRuntimeTestCase
  def setup
    @identity = {"pid" => 42, "uid" => 13001, "host" => "linux-host", "started_at" => "linux:boot:991"}
    adapter = Object.new
    value = @identity
    adapter.define_singleton_method(:capture) { |_pid| value }
    @kernel = Ace::Runtime::Molecules::ProtectedLinux.new(identity: adapter)
  end

  def status(cap_bnd: "0000000000000000", uid: "13001 13001 13001 13001")
    ["Uid:\t#{uid}\n", "Gid:\t13001 13001 13001 13001\n", "Groups:\t13001 13005\n", "PPid:\t90\n", "NoNewPrivs:\t1\n"] +
      %w[CapInh CapPrm CapEff CapBnd CapAmb].map { |key| "#{key}:\t#{key == 'CapBnd' ? cap_bnd : '0'}\n" }
  end

  def test_capture_requires_all_credentials_and_capability_sets
    File.stub(:readlines, status) do
      observed = @kernel.capture(42)
      assert_equal [13001, 13005], observed.fetch("groups")
      assert_equal 90, observed.fetch("parent_pid")
      assert_equal @identity.fetch("started_at"), observed.fetch("started_at")
    end
    File.stub(:readlines, status(cap_bnd: "0000000000080000")) do
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.capture(42) }
    end
    File.stub(:readlines, status(cap_bnd: "0000000000000080")) do
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.capture(42) }
    end
    File.stub(:readlines, status(cap_bnd: "0000000000000002")) do
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.capture(42) }
    end
    File.stub(:readlines, status.map { |line| line.start_with?("NoNewPrivs:") ? "NoNewPrivs:\t0\n" : line }) do
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.capture(42) }
    end
    File.stub(:readlines, status(uid: "13001 13002 13001 13001")) do
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.capture(42) }
    end
    File.stub(:readlines, status(uid: "13002 13002 13002 13002")) do
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.capture(42) }
    end
  end

  def test_birth_and_lineage_are_part_of_exact_identity
    value = @identity.merge("gid" => 13001, "groups" => [13001], "parent_pid" => 90)
    assert @kernel.same?(value, value.dup)
    %w[started_at parent_pid groups gid].each do |field|
      refute @kernel.same?(value, value.merge(field => "replacement")), field
    end
  end

  def test_support_refuses_missing_pidfd_before_reporting_capability
    klass = Ace::Runtime::Molecules::ProtectedLinux
    klass.const_set(:RUBY_PLATFORM, "linux-fixture")
    calls = 0
    unavailable = ->(*) { calls += 1; raise Fiddle::DLError, "pidfd unavailable" }
    File.stub(:read, "2\n") do
      Fiddle.stub(:dlopen, unavailable) do
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.supported! }
      end
    end
    assert_equal 1, calls
  ensure
    klass.send(:remove_const, :RUBY_PLATFORM) if klass&.const_defined?(:RUBY_PLATFORM, false)
  end

  def test_support_closes_probe_after_live_poll_and_after_poll_refusal
    klass = Ace::Runtime::Molecules::ProtectedLinux
    klass.const_set(:RUBY_PLATFORM, "linux-fixture")
    read = write = nil
    [false, true].each do |refused|
      read, write = IO.pipe
      seen = []
      @kernel.define_singleton_method(:pidfd_handle) { |pid| seen << pid; read }
      @kernel.define_singleton_method(:exited?) do |handle, **|
        raise IOError, "poll refused" if refused
        !IO.select([handle], nil, nil, 0).nil?
      end
      File.stub(:read, "2\n") do
        if refused
          assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.supported! }
        else
          assert @kernel.supported!
        end
      end
      assert_equal [Process.pid], seen
      assert read.closed?
      write.close
    end
  ensure
    read&.close unless read&.closed?
    write&.close unless write&.closed?
    klass.send(:remove_const, :RUBY_PLATFORM) if klass&.const_defined?(:RUBY_PLATFORM, false)
  end

  def test_unsupported_host_never_reports_secure_policy
    skip "Linux host tests real deployed policy separately" if RUBY_PLATFORM.include?("linux")
    assert_raises(Ace::Runtime::RuntimeUnavailableError) { @kernel.supported! }
  end
end

class ProtectedLinuxTest
  def test_exact_live_ancestry_attributes_descendant_and_refuses_same_uid_sibling_or_pid_reuse
    native = @identity.merge("gid" => 13001, "groups" => [13001], "parent_pid" => 90)
    child = native.merge("pid" => 43, "parent_pid" => 42, "started_at" => "linux:boot:992")
    sibling = child.merge("pid" => 44, "parent_pid" => 90)
    values = {42 => native, 43 => child, 44 => sibling}
    @kernel.define_singleton_method(:capture) do |pid|
      values.fetch(pid) { raise Ace::Runtime::RuntimeUnavailableError, "not observed" }
    end
    assert @kernel.descendant?(child, native)
    assert @kernel.descendant?(native, native)
    refute @kernel.descendant?(sibling, native)
    refute @kernel.descendant?(child, native.merge("started_at" => "linux:boot:another-incarnation"))
    calls = 0
    @kernel.define_singleton_method(:capture) do |pid|
      calls += 1
      pid == 43 && calls > 2 ? child.merge("started_at" => "linux:boot:replacement") : values.fetch(pid)
    end
    refute @kernel.descendant?(child, native), "a reused leaf PID during final validation cannot inherit authority"
  end
end

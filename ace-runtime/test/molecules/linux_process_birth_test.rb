# frozen_string_literal: true

require_relative "../test_helper"

class LinuxProcessBirthTest < AceRuntimeTestCase
  def birth_for(comm, ticks)
    klass = Ace::Runtime::Molecules::ProcessIdentity
    klass.const_set(:RUBY_PLATFORM, 'x86_64-linux')
    fields = (4..52).map { |index| index == 22 ? ticks.to_s : index.to_s }
    stat = "123 (#{comm}) S #{fields.join(' ')}"
    reader = ->(path) { path.include?('boot_id') ? 'test-boot-id' : stat }
    File.stub(:read, reader) { klass.new.native_birth(123) }
  ensure
    klass.send(:remove_const, :RUBY_PLATFORM) if klass.const_defined?(:RUBY_PLATFORM, false)
  end

  def test_linux_comm_with_spaces_and_parentheses_uses_exact_start_ticks
    assert_equal 'linux:test-boot-id:777', birth_for('odd (worker) name', 777)
  end

  def test_linux_non_utf8_comm_preserves_start_ticks
    assert_equal 'linux:test-boot-id:779', birth_for("worker\xFF".b, 779)
  end

  def test_linux_invalid_start_ticks_are_unknown
    assert_nil birth_for('worker', 'not-a-number')
    assert_nil birth_for('worker', '-1')
  end

  def test_linux_comm_with_closing_parenthesis_and_newline_preserves_ticks
    assert_equal 'linux:test-boot-id:778', birth_for("odd)\n(worker)", 778)
  end

  def test_linux_comm_with_newline_cannot_hide_pid_incarnation_change
    old = birth_for("odd\nworker", 777)
    fresh = birth_for("odd\nworker", 778)
    assert old.nil? || fresh.nil? || old != fresh, 'Distinct Linux start ticks became identical trusted birth when comm includes newline'
  end
end

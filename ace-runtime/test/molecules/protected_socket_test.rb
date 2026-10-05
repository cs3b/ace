# frozen_string_literal: true
require_relative "../test_helper"
require "ace/runtime/molecules/protected_socket"

class ProtectedSocketTest < AceRuntimeTestCase
  WIRE = Ace::Runtime::Molecules::ProtectedSocket

  def with_pair
    left, right = UNIXSocket.pair
    yield left, right
  ensure
    left&.close
    right&.close
  end

  def test_bounded_frame_round_trip
    with_pair do |left, right|
      WIRE.write(left, {"operation" => "gate_ready", "ticket" => "abc"}, deadline: WIRE.deadline)
      assert_equal({"operation" => "gate_ready", "ticket" => "abc"}, WIRE.read(right, deadline: WIRE.deadline))
    end
  end

  def test_eof_and_deadline_do_not_create_a_permission
    with_pair do |left, right|
      left.close
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { WIRE.read(right, deadline: WIRE.deadline) }
    end
    with_pair do |_left, right|
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { WIRE.read(right, deadline: WIRE.deadline(0.01)) }
    end
  end

  def test_oversize_and_malformed_frames_fail_closed
    with_pair do |left, right|
      left.write("x" * 33 + "\n")
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { WIRE.read(right, deadline: WIRE.deadline, limit: 32) }
    end
    with_pair do |left, right|
      left.write("{bad}\n")
      assert_raises(Ace::Runtime::RuntimeUnavailableError) { WIRE.read(right, deadline: WIRE.deadline) }
    end
  end
end

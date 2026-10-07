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
  def test_raw_duplicate_keys_invalid_utf8_comments_and_excessive_nesting_refuse
    frames = ["{\"operation\":\"safe\",\"operation\":\"other\"}\n",
      "{\"origin\":{\"pid\":1,\"pid\":2}}\n", "{\"text\":\"\xff\"}\n".b,
      "{/*comment*/\"operation\":\"safe\"}\n", "[" * 33 + "0" + "]" * 33 + "\n"]
    frames.each do |frame|
      with_pair do |left, right|
        left.write(frame)
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { WIRE.read(right, deadline: WIRE.deadline) }
      end
    end
  end

  def test_utf8_frame_size_and_following_frame_remain_exact
    with_pair do |left, right|
      first = "{\"text\":\"żółć\"}\n"
      left.write(first + "{\"next\":true}\n")
      assert_equal({data: {"text" => "żółć"}, bytesize: first.bytesize}, WIRE.read(right, deadline: WIRE.deadline, with_size: true))
      assert_equal({"next" => true}, WIRE.read(right, deadline: WIRE.deadline))
    end
  end

  def test_fixed_endpoint_mode_is_exact_and_typed_without_changing_identity_shape
    Dir.mktmpdir("socket-mode") do |root|
      path = File.join(root, "mode.sock")
      listener = UNIXServer.new(path)
      File.chmod(0o660, path)
      assert_equal WIRE.socket_identity(path), WIRE.socket_identity(path, mode: 0o660)
      [false, 0o660.to_f, -1, 0o666].each do |mode|
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { WIRE.socket_identity(path, mode: mode) }
      end
    ensure
      listener&.close
    end
  end

end

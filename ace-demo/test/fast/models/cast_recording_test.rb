# frozen_string_literal: true

require_relative "../../test_helper"

class CastRecordingTest < AceDemoTestCase
  def test_exposes_header_and_events
    event = Ace::Demo::Models::CastEvent.new(time: 0.1, type: "o", data: "ok")
    recording = Ace::Demo::Models::CastRecording.new(
      header: {"version" => 2, "width" => 80, "height" => 24},
      events: [event]
    )

    assert_equal 2, recording.header["version"]
    assert_equal [event], recording.events
  end
end

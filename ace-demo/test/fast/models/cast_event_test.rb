# frozen_string_literal: true

require_relative "../../test_helper"

class CastEventTest < AceDemoTestCase
  def test_exposes_event_fields
    event = Ace::Demo::Models::CastEvent.new(time: 1.25, type: "i", data: "echo hi")

    assert_equal 1.25, event.time
    assert_equal "i", event.type
    assert_equal "echo hi", event.data
  end
end

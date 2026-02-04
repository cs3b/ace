# frozen_string_literal: true

module Ace
  module E2eRunner
    module Formatters
      class BaseFormatter
        attr_accessor :report_path

        def initialize(options = {})
          @options = options
        end

        def on_start(_total_tests); end
        def on_test_start(_test_id, _package); end
        def on_test_complete(_test_id, _status, _duration, _report_path); end
        def on_finish(_summary); end
      end
    end
  end
end

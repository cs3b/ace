# frozen_string_literal: true

require "ace/test_support"
require "ace/hitl/contract"

class AceHitlContractTestCase < AceTestCase
  def with_env(values)
    saved = values.to_h { |key, _| [key, ENV[key]] }
    values.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    saved.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end
end

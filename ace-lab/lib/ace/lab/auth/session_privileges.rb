# frozen_string_literal: true
require "fiddle"

module Ace
  module Lab
    module Auth
      # Shared Linux privilege restriction for fixed session helpers.
      module SessionPrivileges
        def self.restrict!
          raise ArgumentError, "session execution requires Linux" unless RUBY_PLATFORM.include?("linux")
          prctl = Fiddle::Function.new(Fiddle::Handle::DEFAULT["prctl"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG, Fiddle::TYPE_LONG], Fiddle::TYPE_INT)
          last_capability = Integer(File.read("/proc/sys/kernel/cap_last_cap").strip, 10)
          raise ArgumentError, "invalid capability range" unless last_capability.between?(0, 255)
          (0..last_capability).each do |capability|
            raise ArgumentError, "cannot restrict session capabilities" unless prctl.call(24, capability, 0, 0, 0).zero? # PR_CAPBSET_DROP
          end
          raise ArgumentError, "cannot restrict session privileges" unless prctl.call(38, 1, 0, 0, 0).zero? # PR_SET_NO_NEW_PRIVS
        rescue Fiddle::DLError
          raise ArgumentError, "cannot restrict session privileges"
        end
      end
    end
  end
end

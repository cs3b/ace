# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Formats a commit age as one compact unit for the `Age` table column.
        #
        # Ladder (floor of the current unit, no `ago` suffix):
        #   0-59m   -> "Nm"     1-23h -> "Nh"
        #   1-13d   -> "Nd"     14-59d -> "Nw"
        #   60-364d -> "Nmo"    >=365d -> "Ny"
        #
        # `nil` means the branch has no commits ("never"); clock skew/future
        # timestamps render "0m" so the row still reads as active.
        #
        # @example
        #   RelativeAgeFormatter.format(9 * 24 * 3600) # => "9d"
        #   RelativeAgeFormatter.format(nil)           # => "never"
        module RelativeAgeFormatter
          MINUTE = 60
          HOUR = 60 * MINUTE
          DAY = 24 * HOUR
          WEEK = 7 * DAY

          # Unit thresholds in seconds, largest unit last.
          # The day->week switch is at 14 days and week->month at 60 days so
          # short-lived worktrees keep a day count (e.g. "9d") while older
          # ones step up to weeks ("3w") and then months ("2mo").
          WEEK_THRESHOLD = 14 * DAY
          MONTH_THRESHOLD = 60 * DAY
          MONTH = 30 * DAY
          YEAR_THRESHOLD = 365 * DAY

          class << self
            # @param age_seconds [Numeric, nil] age in seconds (nil = no commits)
            # @return [String] compact age label
            def format(age_seconds)
              return "never" if age_seconds.nil?

              seconds = age_seconds.to_f
              return "0m" if seconds.negative?

              case seconds
              when 0...MINUTE then "0m"
              when MINUTE...HOUR then "#{(seconds / MINUTE).floor}m"
              when HOUR...DAY then "#{(seconds / HOUR).floor}h"
              when DAY...WEEK_THRESHOLD then "#{(seconds / DAY).floor}d"
              when WEEK_THRESHOLD...MONTH_THRESHOLD then "#{(seconds / WEEK).floor}w"
              when MONTH_THRESHOLD...YEAR_THRESHOLD then "#{(seconds / MONTH).floor}mo"
              else "#{(seconds / YEAR_THRESHOLD).floor}y"
              end
            end
          end
        end
      end
    end
  end
end

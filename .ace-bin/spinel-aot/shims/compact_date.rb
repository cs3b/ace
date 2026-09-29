# frozen_string_literal: true

# Minimal Date shim for Spinel-compiled ace binaries.
#
# Implements the surface ace-b36ts uses for month/week/day formats:
#   CompactDate.new(y, m, d)  (d may be negative: -1 = last day of month)
#   #year #month #day #wday #to_s
#   Date#+ Integer, Date#- Integer/Date (Date#- returns day count)
#   Date.jd
#
# Proleptic Gregorian calendar only (same as CRuby's Date default).

class CompactDate
  MONTH_DAYS = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  attr_reader :year, :month, :day

  def self.leap?(year)
    year = year.to_i
    (year % 4).zero? && !(year % 100).zero? || (year % 400).zero?
  end

  def self.days_in_month(year, month)
    year = year.to_i
    month = month.to_i
    if month == 2 && leap?(year)
      29
    else
      MONTH_DAYS[month - 1]
    end
  end

  def initialize(year, month, day = 1)
    year = year.to_i
    month = month.to_i
    day = day.to_i
    if day < 0
      day = CompactDate.days_in_month(year, month) + day + 1
    end
    @year = year
    @month = month
    @day = day
    @jd = CompactDate.civil_to_jd(year, month, day)
  end

  def self.civil_to_jd(year, month, day)
    year = year.to_i
    month = month.to_i
    day = day.to_i
    a = (14 - month) / 12
    y2 = year + 4800 - a
    m2 = month + (12 * a) - 3
    (day + ((153 * m2 + 2) / 5) + (365 * y2) + (y2 / 4) - (y2 / 100) +
      (y2 / 400) - 32045)
  end

  def self.jd_to_civil(jd)
    jd = jd.to_i
    a = jd + 32044
    b = (4 * a + 3) / 146097
    c = a - (146097 * b) / 4
    d = (4 * c + 3) / 1461
    e = c - (1461 * d) / 4
    m = (5 * e + 2) / 153
    day = e - ((153 * m + 2) / 5) + 1
    month = m + 3 - (12 * (m / 10))
    year = (100 * b) + d - 4800 + (m / 10)
    [year, month, day]
  end

  def self.from_jd(jd)
    parts = jd_to_civil(jd)
    CompactDate.new(parts[0], parts[1], parts[2])
  end

  def jd
    # +0 forces a boxed polymorphic return (bare-ivar returns misbox in
    # Spinel poly dispatch)
    j = @jd
    j + 0
  end

  def wday
    (jd + 1) % 7
  end

  # NOTE: not +/-. Spinel's polymorphic dispatch generates broken C for
  # user-defined operators on custom classes (boxing mismatch); explicit
  # method names sidestep it. Call sites updated accordingly.
  def add_days(n)
    CompactDate.from_jd(jd + n.to_i)
  end

  # Returns Integer day-count when given a Date (like CRuby Date#-),
  # a new Date when given an Integer.
  def sub_days(other)
    # double dispatch: never call .jd polymorphically (bare-ivar readers
    # misbox in Spinel poly dispatch). days_until(0) is other's jd, so
    # this is jd - other.jd.
    jd - other.days_until(0)
  end

  def days_until(target_jd)
    jd - target_jd
  end

  def to_s
    "#{@year}-#{pad2(@month)}-#{pad2(@day)}"
  end

  def pad2(n)
    n = n.to_i
    n < 10 ? "0#{n}" : "#{n}"
  end

end


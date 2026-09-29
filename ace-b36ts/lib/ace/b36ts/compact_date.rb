# frozen_string_literal: true

# CRuby counterpart of the compiled builds' CompactDate shim: the codec
# code calls add_days/sub_days, which CRuby expresses as +/-. Guarded so
# compiled builds keep their standalone shim class (see REPORT.md).
unless defined?(SPINEL)
  require "date"

  class CompactDate < ::Date
    def add_days(n)
      self + n
    end

    def sub_days(other)
      self - other
    end
  end
end

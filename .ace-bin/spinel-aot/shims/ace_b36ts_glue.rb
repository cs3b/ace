# frozen_string_literal: true

# Type-flow glue + Time.parse replacement for Spinel-compiled ace-b36ts.
#
# 1. box_time launders parse output to a polymorphic slot so the encode
#    chain infers consistently (Spinel pins params to concrete types and
#    one mixed caller trips C slot mismatches). Runtime-identical.
#
# 2. parse_time_string replaces Time.parse (absent in Spinel, and
#    reopening class Time makes the compiler synthesize a broken
#    Time_new in dynamic Class#new dispatch tables). Subset covered:
#   YYYY-MM-DD[THH:MM[:SS[.frac]]][Z|UTC|GMT|±HH:MM|±HHMM]
#   zone-ful strings return the instant as UTC (field reads on offset
#   zones diverge from CRuby; instant arithmetic is identical). Naive
#   strings are treated as UTC fields, matching the ace call sites.
#   Unparseable input raises ArgumentError like CRuby.

module Ace
  module B36ts
    module Glue
      def self.box_time(t)
        [t.to_i, t].last
      end

      # Unique-name delegates: EncodeCommand/DecodeCommand/ConfigCommand
      # all define class-method execute with different arities; Spinel
      # merges same-name methods into one poly dispatch, so entry calls
      # go through distinct names.
      def self.show_b36ts_config
        config = resolve_b36ts_config_cli
        puts "Current ace-b36ts configuration:"
        puts ""
        puts "  year_zero: #{config[:year_zero]}"
        puts "  alphabet: #{config[:alphabet]}"
        0
      end

      def self.resolve_b36ts_config_cli
        defaults = [
          [:"year_zero", 2000],
          [:"alphabet", "0123456789abcdefghijklmnopqrstuvwxyz"],
          [:"default_format", "2sec"]
        ]
        resolve_b36ts_config(gem_root_for_b36ts, defaults, {})
      end

      def self.gem_root_for_b36ts
        File.expand_path("../../../..", __dir__)
      end

      def self.run_encode(time_string, options)
        Ace::B36ts::Commands::EncodeCommand.execute(time_string, options)
      end

      def self.run_decode(compact_id, options)
        Ace::B36ts::Commands::DecodeCommand.execute(compact_id, options)
      end

      def self.run_config(options)
        Ace::B36ts::Commands::ConfigCommand.execute(options)
      end

      # Statically-typed resolver construction: Config.create returns a
      # polymorphic slot, and poly dispatch mishandles the splat+keyword
      # arity of resolve_namespace. Build the organism directly.
      def self.wrap_b36ts_config(base, overrides)
        Ace::Support::Config::Models::Config.wrap(base, overrides, source: "ace-b36ts")
      end

      # Gate-A config cascade for b36ts: defaults file -> user file ->
      # project file -> runtime overrides (nearest wins, flat merge --
      # b36ts config is flat). Reads real YAML through the shim,
      # bypassing the generic discovery organisms (see REPORT.md).
      def self.resolve_b36ts_config(gem_root, defaults, overrides)
        merged = {}
        default_pairs = defaults.to_a
        default_pairs.each do |pair|
          merged[pair[0].to_sym] = pair[1]
        end

        sources = [
          gem_root + "/.ace-defaults/b36ts/config.yml",
          File.expand_path("~/.ace/b36ts/config.yml"),
          Dir.pwd + "/.ace/b36ts/config.yml"
        ]
        sources.each do |path|
          next unless File.file?(path)

          section = YAML.safe_load(File.read(path))
          next if section.nil?

          values = section["b36ts"]
          next if values.nil?

          entries = values.to_a
          entries.each do |pair|
            merged[pair[0].to_sym] = pair[1]
          end
        end

        override_pairs = overrides.to_a
        override_pairs.each do |pair|
          merged[pair[0].to_sym] = pair[1] unless pair[1].nil?
        end
        merged
      end

      def self.load_b36ts_config(gem_root)
        resolver = Ace::Support::Config::Organisms::ConfigResolver.new(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )
        loaded = resolver.resolve_namespace("b36ts")
        loaded.data
      end

      def self.parse_time_string(str)
        s = str.to_s.strip

        year = digits_at(s, 0, 4)
        month = digits_at(s, 5, 2)
        day = digits_at(s, 8, 2)
        if year.nil? || s[4] != "-" || month.nil? || s[7] != "-" || day.nil?
          raise ArgumentError, "no time information: #{str}"
        end

        sep = s[10]
        if sep.nil? || sep == ""
          return Time.utc(year, month, day, 0, 0, 0)
        end
        unless sep == "T" || sep == "t" || sep == " "
          raise ArgumentError, "no time information: #{str}"
        end

        hour = digits_at(s, 11, 2)
        if hour.nil? || s[13] != ":"
          raise ArgumentError, "no time information: #{str}"
        end
        minute = digits_at(s, 14, 2)
        if minute.nil?
          raise ArgumentError, "no time information: #{str}"
        end

        pos = 16
        second = 0
        if s[16] == ":"
          second = digits_at(s, 17, 2)
          if second.nil?
            raise ArgumentError, "no time information: #{str}"
          end
          pos = 19
        end

        offset_seconds = 0
        if pos < s.length
          rest = s[pos, s.length - pos]
          if rest.start_with?(".")
            pos += 1
            while pos < s.length && digit?(s[pos])
              pos += 1
            end
            rest = pos < s.length ? s[pos, s.length - pos] : ""
          end
          if rest != ""
            offset_seconds = zone_offset(rest, str)
          end
        end

        naive = Time.utc(year, month, day, hour, minute, second)
        if offset_seconds.zero?
          naive
        else
          Time.at(naive.to_i - offset_seconds)
        end
      end

      def self.zone_offset(token, original)
        if token == "Z" || token == "UTC" || token == "GMT" || token == "utc" || token == "gmt"
          return 0
        end

        sign = token[0]
        if sign != "+" && sign != "-"
          raise ArgumentError, "no time information: #{original}"
        end

        body = token[1, token.length - 1]
        if body.length == 5 && body[2] == ":"
          hh = digits_at(body, 0, 2)
          mm = digits_at(body, 3, 2)
        elsif body.length == 4
          hh = digits_at(body, 0, 2)
          mm = digits_at(body, 2, 2)
        else
          raise ArgumentError, "no time information: #{original}"
        end
        return 0 if hh.nil? || mm.nil?

        total = hh * 3600 + mm * 60
        sign == "+" ? total : -total
      end

      def self.digit?(ch)
        !ch.nil? && ch >= "0" && ch <= "9"
      end

      def self.digits_at(s, start, length)
        return nil if start + length > s.length

        value = 0
        i = start
        while i < start + length
          ch = s[i]
          return nil unless digit?(ch)

          value = value * 10 + (ch.ord - 48)
          i += 1
        end
        value
      end
    end
  end
end

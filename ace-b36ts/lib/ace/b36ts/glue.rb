# frozen_string_literal: true

module Ace
  module B36ts
    # Compiled-binary (Spinel) support glue. Under CRuby the class methods
    # here are unused -- resolve falls back to the ADR-022 cascade via
    # ace-support-config. See .ace-local/ace-aot/REPORT.md in the
    # spinel-aot-pilot worktree for the divergence catalog.
    module Glue
      # Gate-A config cascade: defaults file -> user file -> project file
      # -> runtime overrides (nearest wins, flat merge -- b36ts config is
      # flat). Reads real YAML through the compiled yaml-subset shim.
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

      # ISO-8601 subset parser used by compiled builds (Spinel has no
      # Time.parse). CRuby path keeps Time.parse.
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
            while pos < s.length && digit_at?(s, pos)
              pos += 1
            end
            rest = pos < s.length ? s[pos, s.length - pos] : ""
          end
          if rest != ""
            offset_seconds = zone_offset(rest, str)
          end
        end

        # CRuby Time.parse keeps offset-zone wall-clock fields; mirrored.
        Time.utc(year, month, day, hour, minute, second)
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

      def self.digit_at?(s, pos)
        ch = s[pos]
        !ch.nil? && ch >= "0" && ch <= "9"
      end

      def self.digits_at(s, start, length)
        return nil if start + length > s.length

        value = 0
        i = start
        while i < start + length
          ch = s[i]
          return nil unless digit_at?(s, i)

          value = value * 10 + (ch.ord - 48)
          i += 1
        end
        value
      end

      # Compiled-build config display (mirrors ConfigCommand#execute).
      def self.show_b36ts_config
        config = resolve_b36ts_config(gem_root_for_b36ts, b36ts_defaults, {})
        puts "Current ace-b36ts configuration:"
        puts ""
        puts "  year_zero: #{config[:year_zero]}"
        puts "  alphabet: #{config[:alphabet]}"
        0
      end

      def self.b36ts_defaults
        [
          [:"year_zero", 2000],
          [:"alphabet", "0123456789abcdefghijklmnopqrstuvwxyz"],
          [:"default_format", "2sec"]
        ]
      end

      def self.gem_root_for_b36ts
        File.expand_path("../../../..", __dir__)
      end

      # Merged config for the compiled entry (defaults -> user -> project).
      def self.entry_config
        resolve_b36ts_config(gem_root_for_b36ts, b36ts_defaults, {})
      end
    end
  end
end

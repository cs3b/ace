# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module ArgvCollector
        def self.call(argv, flags:, separator: ",")
          normalized = normalize_flags(flags)
          accum = normalized.values.to_h { |canonical| [canonical, []] }
          passthrough = []

          i = 0
          while i < argv.length
            token = argv[i]
            flag = token.include?("=") ? token.split("=", 2)[0] : token
            canonical = normalized[flag]

            if canonical
              value = extract_value(token, argv, i)
              accum[canonical] << value unless value.to_s.empty?
              i = next_index(token, argv, i)
            else
              passthrough << token
              i += 1
            end
          end

          result = passthrough.dup
          accum.each do |canonical, values|
            next if values.empty?

            result << canonical
            result << values.join(separator)
          end
          result
        end

        def self.normalize_flags(flags)
          flags.each_with_object({}) do |(canonical, aliases), memo|
            memo[canonical] = canonical
            aliases.each { |entry| memo[entry] = canonical }
          end
        end
        private_class_method :normalize_flags

        def self.extract_value(token, argv, index)
          return token.split("=", 2)[1] if token.include?("=")
          return argv[index + 1] if index + 1 < argv.length && !argv[index + 1].start_with?("-")

          ""
        end
        private_class_method :extract_value

        def self.next_index(token, argv, index)
          return index + 1 if token.include?("=")
          return index + 2 if index + 1 < argv.length && !argv[index + 1].start_with?("-")

          index + 1
        end
        private_class_method :next_index
      end
    end
  end
end

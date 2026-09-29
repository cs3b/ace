# frozen_string_literal: true

# Minimal OptionParser shim for Spinel-compiled ace binaries.
#
# Implements exactly the API ace-support-cli's Parser uses:
#   OptionParser.new (block optional) / #on(*switches, klass?, desc?) { |v| }
#   #banner= / #version= / #parse!(argv)  (mutates argv in place)
#   OptionParser::ParseError / ::InvalidOption / ::MissingArgument /
#   ::InvalidArgument / ::AmbiguousOption, errors carry #args.
#
# Supported switch forms: -s, -s VALUE, -sVALUE, --long, --long VALUE,
# --long=VALUE, --long [VALUE] (optional), --[no-]long (boolean).
# Type coercion via class arguments: Integer, Float, String, Array.
# NOT implemented: abbreviations, subcommands, @argfile, locales.

class OptionParser
  class ParseError < StandardError
    def initialize(message = nil, *extra_args)
      super(message)
      @extra_args = extra_args
    end

    def args
      @extra_args
    end
  end

  class InvalidOption < ParseError; end
  class MissingArgument < ParseError; end
  class InvalidArgument < ParseError; end
  class AmbiguousOption < ParseError; end

  def initialize(&block)
    @specs = []
    @banner = nil
    @version = nil
    block.call(self) if block
  end

  def banner=(text)
    @banner = text
  end

  def banner
    @banner
  end

  def version=(text)
    @version = text
  end

  def version
    @version
  end

  def on(*arguments, &block)
    spec = { patterns: [], klass: :string, optional: false, boolean: false,
             block: block }
    arguments.each do |arg|
      next if arg.nil?

      if arg.is_a?(String)
        add_pattern(spec, arg)
      elsif arg == Integer
        spec[:klass] = :integer
      elsif arg == Float
        spec[:klass] = :float
      elsif arg == Array
        spec[:klass] = :array
      end
      # String class argument: leave default :string
    end
    @specs << spec
    self
  end
  alias def_option on

  def parse!(argv)
    idx = 0
    while idx < argv.length
      token = argv[idx]
      break if token == "--"

      if token.start_with?("--")
        consumed = handle_long(argv, idx, token)
        idx += consumed ? 0 : 1
      elsif token.length > 1 && token.start_with?("-")
        consumed = handle_short(argv, idx, token)
        idx += consumed ? 0 : 1
      else
        idx += 1
      end
    end
    argv
  end

  def parse(argv)
    argv.dup
  end

  private

  def add_pattern(spec, pattern)
    spec[:patterns] << pattern
    if pattern.start_with?("--")
      body = pattern[2, pattern.length - 2]
      if body.start_with?("[no-]")
        spec[:boolean] = true
        spec[:long] = "--" + body[5, body.length - 5]
      elsif body.include?(" ")
        head = body.split(" ")[0]
        spec[:long] = "--" + head
        spec[:optional] = true if body.include?("[")
      else
        spec[:long] = "--" + body
      end
    elsif pattern.start_with?("-")
      head = pattern.split(" ")[0]
      spec[:short] = head
      spec[:optional] = true if pattern.include?("[")
    end
  end

  def find_long(name_with_dashes)
    # name_with_dashes includes leading "--"
    @specs.each do |spec|
      next unless spec[:long] == name_with_dashes

      return [spec, false]
    end
    if name_with_dashes.start_with?("--no-")
      base = "--" + name_with_dashes[5, name_with_dashes.length - 5]
      @specs.each do |spec|
        next unless spec[:boolean] && spec[:long] == base

        return [spec, true]
      end
    end
    nil
  end

  def find_short(flag)
    @specs.each do |spec|
      next unless spec[:short] == flag

      return spec
    end
    nil
  end

  # Returns true when the whole token (plus value token) was consumed.
  def handle_long(argv, idx, token)
    body = token[2, token.length - 2]
    name_part = body
    inline_value = nil
    eq = body.index("=")
    if eq
      name_part = body[0, eq]
      inline_value = body[eq + 1, body.length - eq - 1]
    end

    found = find_long("--" + name_part)
    if found.nil?
      raise InvalidOption.new("invalid option: #{token}", token)
    end

    spec = found[0]
    negated = found[1]

    if spec[:boolean]
      value = negated ? false : true
      spec[:block].call(value)
      argv.delete_at(idx)
      return true
    end

    value = inline_value
    if value.nil?
      nxt = argv[idx + 1]
      if nxt.nil? || nxt.start_with?("-")
        if spec[:optional]
          value = nil
        else
          raise MissingArgument.new("missing argument: #{spec[:long]}", spec[:long])
        end
      else
        value = nxt
        argv.delete_at(idx + 1)
      end
    end
    spec[:block].call(coerce(spec, value))
    argv.delete_at(idx)
    true
  end

  def handle_short(argv, idx, token)
    flag = token[0, 2]
    attached = nil
    if token.length > 2
      rest = token[2, token.length - 2]
      if rest.start_with?("=")
        attached = rest[1, rest.length - 1]
      else
        attached = rest
      end
    end

    spec = find_short(flag)
    if spec.nil?
      raise InvalidOption.new("invalid option: #{flag}", flag)
    end

    if spec[:boolean]
      spec[:block].call(true)
      argv.delete_at(idx)
      return true
    end

    value = attached
    if value.nil?
      nxt = argv[idx + 1]
      if nxt.nil? || nxt.start_with?("-")
        if spec[:optional]
          value = nil
        else
          raise MissingArgument.new("missing argument: #{flag}", flag)
        end
      else
        value = nxt
        argv.delete_at(idx + 1)
      end
    end
    spec[:block].call(coerce(spec, value))
    argv.delete_at(idx)
    true
  end

  def coerce(spec, value)
    return nil if value.nil?
    return value if spec[:klass] == :string

    if spec[:klass] == :integer
      unless integer_string?(value)
        raise InvalidArgument.new("invalid argument: #{value}", value)
      end
      return value.to_i
    end

    if spec[:klass] == :float
      unless float_string?(value)
        raise InvalidArgument.new("invalid argument: #{value}", value)
      end
      return value.to_f
    end

    if spec[:klass] == :array
      parts = value.split(",")
      out = []
      parts.each { |p| out << p.strip }
      return out
    end

    value
  end

  def integer_string?(text)
    body = text
    if body.start_with?("-") || body.start_with?("+")
      body = body[1, body.length - 1]
    end
    return false if body.nil? || body.empty?

    body.each_char do |ch|
      return false unless ch >= "0" && ch <= "9"
    end
    true
  end

  def float_string?(text)
    seen_digit = false
    seen_dot = false
    i = 0
    if i < text.length && (text[i] == "-" || text[i] == "+")
      i += 1
    end
    while i < text.length
      ch = text[i]
      if ch == "." && !seen_dot
        seen_dot = true
      elsif ch >= "0" && ch <= "9"
        seen_digit = true
      else
        return false
      end
      i += 1
    end
    seen_digit && seen_dot
  end
end

# frozen_string_literal: true

require "optparse"
require "json"

# Time-boxed spike command to validate OptionParser behavior for ace-support-cli.
class OptionParserCliSpike
  ParseError = Class.new(StandardError)

  OptionDefinition = Struct.new(:name, :type, :default, :desc, :required, :flag, keyword_init: true)
  ArgumentDefinition = Struct.new(:name, :required, :desc, keyword_init: true)

  class << self
    def option_definitions
      @option_definitions ||= []
    end

    def argument_definitions
      @argument_definitions ||= []
    end

    def option(name, type: :string, default: nil, desc: "", required: false, flag: nil)
      option_definitions << OptionDefinition.new(
        name: name.to_sym,
        type: type,
        default: default,
        desc: desc,
        required: required,
        flag: flag
      )
    end

    def argument(name, required: true, desc: "")
      argument_definitions << ArgumentDefinition.new(name: name.to_sym, required: required, desc: desc)
    end

    def run(argv)
      new.run(argv)
    end
  end

  option :timeout, type: :integer, default: 30, desc: "Timeout in seconds"
  option :rate, type: :float, default: 1.0, desc: "Rate limit"
  option :verbose, type: :boolean, default: false, desc: "Verbose output"
  option :tags, type: :array, default: [], flag: "tag", desc: "Tags to apply"
  option :format, type: :string, default: "json", desc: "Output format"
  option :header, type: :hash, default: {}, desc: "Header key:value"

  argument :input, required: true, desc: "Input file"
  argument :output, required: false, desc: "Output file"

  def run(argv)
    @values = defaults
    leftovers = parse(argv.dup)
    assign_positionals(leftovers)
    validate_required!

    call(**@values)
  rescue OptionParser::ParseError => e
    raise ParseError, e.message
  end

  private

  def parse(args)
    parser = OptionParser.new do |opts|
      self.class.option_definitions.each do |definition|
        register_option(opts, definition)
      end
    end

    parser.parse!(args)
    args
  end

  def register_option(opts, definition)
    long_name = definition.flag || definition.name.to_s.tr("_", "-")

    case definition.type
    when :boolean
      opts.on("--[no-]#{long_name}", definition.desc) do |value|
        @values[definition.name] = value
      end
    when :integer
      opts.on("--#{long_name} VALUE", Integer, definition.desc) do |value|
        @values[definition.name] = value
      end
    when :float
      opts.on("--#{long_name} VALUE", Float, definition.desc) do |value|
        @values[definition.name] = value
      end
    when :array
      opts.on("--#{long_name} VALUE", String, definition.desc) do |value|
        @values[definition.name] ||= []
        @values[definition.name] << value
      end
    when :hash
      opts.on("--#{long_name} KEY:VALUE", String, definition.desc) do |value|
        key, val = value.split(":", 2)
        raise ParseError, "Invalid value for --#{long_name}: expected key:value" if key.nil? || val.nil?

        @values[definition.name] ||= {}
        @values[definition.name][key] = val
      end
    else
      opts.on("--#{long_name} VALUE", String, definition.desc) do |value|
        @values[definition.name] = value
      end
    end
  end

  def assign_positionals(leftovers)
    self.class.argument_definitions.each do |definition|
      @values[definition.name] = leftovers.shift
    end

    @values[:extra] = leftovers unless leftovers.empty?
  end

  def validate_required!
    self.class.argument_definitions.each do |definition|
      next unless definition.required
      next unless blank?(@values[definition.name])

      raise ParseError, "Missing required argument: #{definition.name}"
    end

    self.class.option_definitions.each do |definition|
      next unless definition.required
      next unless blank?(@values[definition.name])

      raise ParseError, "Missing required option: --#{definition.name.to_s.tr('_', '-')}"
    end
  end

  def blank?(value)
    value.nil? || (value.respond_to?(:empty?) && value.empty?)
  end

  def defaults
    self.class.option_definitions.each_with_object({}) do |definition, memo|
      memo[definition.name] = deep_dup(definition.default)
    end
  end

  def deep_dup(value)
    case value
    when Array
      value.dup
    when Hash
      value.dup
    else
      value
    end
  end

  def call(input:, output: nil, timeout:, rate:, verbose:, tags:, format:, header:, extra: nil)
    {
      input: input,
      output: output,
      timeout: timeout,
      rate: rate,
      verbose: verbose,
      tags: tags,
      format: format,
      header: header,
      extra: extra,
      types: {
        timeout: timeout.class.to_s,
        rate: rate.class.to_s,
        verbose: verbose.class.to_s,
        tags: tags.class.to_s,
        format: format.class.to_s,
        header: header.class.to_s,
        input: input.class.to_s,
        output: output.nil? ? "NilClass" : output.class.to_s
      }
    }
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    result = OptionParserCliSpike.run(ARGV)
    puts JSON.pretty_generate(result)
  rescue OptionParserCliSpike::ParseError => e
    warn "ParseError: #{e.message}"
    exit 1
  end
end

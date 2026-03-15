# frozen_string_literal: true

require_relative "option_parser_cli_spike"
require "json"

begin
  result = OptionParserCliSpike.run(ARGV)
  puts JSON.pretty_generate(result)
rescue OptionParserCliSpike::ParseError => e
  warn "ParseError: #{e.message}"
  exit 1
end

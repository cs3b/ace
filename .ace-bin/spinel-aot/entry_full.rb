# frozen_string_literal: true

# Run 4 experiment: full ace-support-cli stack (Parser, TwoTierHelp,
# command classes) instead of the Gate A thin dispatch. Command RESOLUTION
# stays top-level (mono dispatch): a class value returned across an
# extended-module boundary dispatches class-attr reads on the BASE class
# under Spinel (self collapses to Ace::Support::Cli::Command), so the
# runtime Registry/Runner pair cannot resolve commands in compiled builds.
# Mirrors ace-b36ts/exe/ace-b36ts behavior.

SPINEL = true

require_relative "shims/yaml"
require_relative "shims/compact_date"
require_relative "shims/date"
require_relative "shims/rubygems"

require "ace/support/cli"
require "ace/b36ts"
require "ace/b36ts/cli"

USAGE = "Usage: ace-b36ts [COMMAND]\n"

def find_command_class(name)
  case name
  when "encode" then Ace::B36ts::CLI::Commands::Encode
  when "decode" then Ace::B36ts::CLI::Commands::Decode
  when "config" then Ace::B36ts::CLI::Commands::Config
  when "version", "--version" then Ace::B36ts::CLI::SpinVersion
  when "help", "-h" then Ace::B36ts::CLI::SpinHelp
  else
    raise Ace::Support::Cli::CommandNotFoundError, "unknown command"
  end
end

def root_help_requested?(args)
  args.empty? || args.first == "--help" || args.first == "-h"
end

def show_root_help
  Ace::B36ts::CLI::SpinUsage.new.call
end

args = ARGV.empty? ? ["--help"] : ARGV

if root_help_requested?(args)
  show_root_help
  exit(0)
end

name = args.first
rest = args.drop(1)
klass = find_command_class(name)

begin
  parsed = Ace::Support::Cli::Parser.new(klass, command_name: "ace-b36ts #{name}").parse(rest)
  code = klass.new.call(**parsed)
  if code.nil?
    exit(0)
  else
    exit(code + 0)
  end
rescue Ace::Support::Cli::HelpRendered => e
  puts e.output
  exit(0)
rescue Ace::Support::Cli::CommandNotFoundError => e
  $stderr.puts e.to_s
  exit(1)
rescue Ace::Support::Cli::ParseError => e
  $stderr.puts e.message
  exit(1)
rescue Ace::Support::Cli::Error => e
  $stderr.puts e.to_s
  exit(1)
end

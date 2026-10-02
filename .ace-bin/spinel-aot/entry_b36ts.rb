# frozen_string_literal: true

# Spinel compile entry for ace-b36ts — Gate A (thin dispatch).
#
# Spinel strips argument types through constant-receiver dispatch and
# cannot call methods on its builtin Time struct polymorphically, so
# the entry passes only strings/hashes across the boundary and lets
# CompactIdEncoder#encode_cli/#decode_cli keep Time handling in one
# static context. Config resolution runs in Glue off the yaml shim.
# See REPORT.md for the full divergence list.

SPINEL = true

require_relative "shims/yaml"
require_relative "shims/optparse"
require_relative "shims/compact_date"
require_relative "shims/date"
require_relative "shims/rubygems"
require_relative "shims/timeout"
require_relative "shims/dir_glob"

require_relative "gemlib/ace-b36ts/lib/ace/b36ts"

USAGE = "Usage: ace-b36ts <encode|decode|config> [args] [options]\n"

def copy_rest(argv)
  out = []
  i = 0
  while i < argv.length
    out << argv[i]
    i += 1
  end
  out
end

def show_help
  puts USAGE
  puts "  encode [timestamp]   Encode timestamp (default: now)"
  puts "  decode <id>          Decode compact ID to timestamp"
  puts "  config               Show current configuration"
  puts "Run ace-b36ts via Ruby for full help."
end

# Compact per-command help (Gate A). The rich two-tier renderer is a
# documented Ruby-channel feature; this mirrors its key content.
def show_command_help(command)
  case command
  when "encode"
    puts "NAME"
    puts "  ace-b36ts encode - Encode a timestamp to a compact ID"
    puts ""
    puts "USAGE"
    puts "  ace-b36ts encode [TIMESTAMP] [OPTIONS]"
    puts ""
    puts "ARGUMENTS"
    puts "  [TIMESTAMP]                       Timestamp (ISO, readable, 'now', or empty for current time)"
    puts ""
    puts "OPTIONS"
    puts "  --format=VALUE, -f                Output format: 2sec (default), month, week, day, 40min, 50ms, ms"
    puts "  --year-zero=VALUE, -y             Base year for encoding (default: 2000)"
    puts "  --[no-]quiet, -q                  Suppress non-essential output"
    puts "  --help, -h                        Show this help"
    puts ""
    puts "EXAMPLES"
    puts "  $ ace-b36ts encode now                       # Encode current time"
    puts "  $ ace-b36ts encode '2025-01-06 12:30:00'     # Encode readable timestamp"
    puts "  $ ace-b36ts encode --format day '2025-01-06' # Encode to day format"
    puts ""
    puts "Native build (Gate A): --count and --split stay on the Ruby channel."
  when "decode"
    puts "NAME"
    puts "  ace-b36ts decode - Decode a compact ID to a timestamp"
    puts ""
    puts "USAGE"
    puts "  ace-b36ts decode ID [OPTIONS]"
    puts ""
    puts "OPTIONS"
    puts "  --format=VALUE, -f                Output format (readable, iso, timestamp)"
    puts "  --year-zero=VALUE, -y             Base year for decoding (default: 2000)"
    puts "  --[no-]quiet, -q                  Suppress non-essential output"
    puts "  --help, -h                        Show this help"
    puts ""
    puts "EXAMPLES"
    puts "  $ ace-b36ts decode 8c5ir0                    # Decode to timestamp (auto-detects format)"
    puts "  $ ace-b36ts decode 8c5ir0 --format iso       # Decode to ISO format"
  when "config"
    puts "NAME"
    puts "  ace-b36ts config - Show current configuration"
    puts ""
    puts "USAGE"
    puts "  ace-b36ts config [OPTIONS]"
    puts ""
    puts "OPTIONS"
    puts "  --[no-]quiet, -q                  Suppress non-essential output"
    puts "  --help, -h                        Show this help"
  end
end

argv = copy_rest(ARGV)
command = argv.shift
options = {}

# Hand-rolled option parsing: the optparse shim routes through
# poly-dispatch on the dyn-new-boxed parser and hits arity-union bugs.
positional = []
help_requested = false
i = 0
while i < argv.length
  tok = argv[i]
  if tok == "--help" || tok == "-h"
    help_requested = true
    i += 1
  elsif tok == "-f" || tok == "--format"
    options[:format] = argv[i + 1]
    i += 2
  elsif tok == "-n" || tok == "--count"
    options[:count] = argv[i + 1].to_i
    i += 2
  elsif tok == "--split"
    options[:split] = argv[i + 1]
    i += 2
  elsif tok == "--path-only"
    options[:path_only] = true
    i += 1
  elsif tok == "--json"
    options[:json] = true
    i += 1
  elsif tok == "-y" || tok == "--year-zero"
    options[:year_zero] = argv[i + 1].to_i
    i += 2
  elsif tok == "-q" || tok == "--quiet"
    options[:quiet] = true
    i += 1
  elsif tok == "-v" || tok == "--verbose"
    options[:verbose] = true
    i += 1
  elsif tok == "-d" || tok == "--debug"
    options[:debug] = true
    i += 1
  else
    positional << tok
    i += 1
  end
end

if help_requested && (command == "encode" || command == "decode" || command == "config")
  show_command_help(command)
  exit(0)
end

begin
  case command
  when "encode"
    cfg = Ace::B36ts::Glue.entry_config
    fmt = options[:format]
    fmt = cfg[:default_format].to_s if fmt.nil? && !cfg[:default_format].nil?
    fmt = "2sec" if fmt.nil?
    yz = options[:year_zero]
    yz = cfg[:year_zero].to_i if yz.nil? && !cfg[:year_zero].nil?
    yz = 2000 if yz.nil?
    if options[:count].nil? && options[:split].nil?
        id = Ace::B36ts::Atoms::CompactIdEncoder.encode_cli(positional[0], fmt.to_s, yz, Ace::B36ts::Atoms::CompactIdEncoder::DEFAULT_ALPHABET)
      puts id
      exit(0)
    end
    warn "native binary: --count/--split not supported in Gate A"
    exit(1)
  when "decode"
    cfg = Ace::B36ts::Glue.entry_config
    yz = options[:year_zero]
    yz = cfg[:year_zero].to_i if yz.nil? && !cfg[:year_zero].nil?
    yz = 2000 if yz.nil?
    out_fmt = options[:format]
    out_fmt = "readable" if out_fmt.nil?
    puts Ace::B36ts::Atoms::CompactIdEncoder.decode_cli(positional[0], "auto", yz, out_fmt, Ace::B36ts::Atoms::CompactIdEncoder::DEFAULT_ALPHABET)
    exit(0)
  when "config"
    Ace::B36ts::Glue.show_b36ts_config
    exit(0)
  when "--help", "-h", "help", nil, ""
    show_help
    exit(0)
  when "--version", "version"
    puts "ace-b36ts #{Ace::B36ts::VERSION}"
    exit(0)
  else
    warn "unknown command: #{command}"
    show_help
    exit(1)
  end
rescue ArgumentError => e
  warn e.message
  exit(1)
end

#!/bin/sh
# Run 4: full ace-support-cli stack build (Parser/TwoTierHelp/command
# classes instead of the Gate A thin entry dispatch). See REPORT.md.
set -e
WT="$(cd "$(dirname "$0")/../.." && pwd)"
SPINEL=/tmp/spinel/spinel
OUT="$WT/.ace-local/ace-aot/ace-b36ts-full"  # binary stays in scratch (artifact)
COPY="$WT/.ace-bin/spinel-aot/gemlib"

rm -rf "$COPY"
mkdir -p "$COPY"
for g in ace-b36ts ace-support-cli ace-support-core ace-support-config ace-support-fs; do
  mkdir -p "$COPY/$g"
  cp -R "$WT/$g/lib" "$COPY/$g/"
done
rm "$COPY/ace-b36ts/lib/ace/b36ts/atoms/compact_id_encoder_api.rb"
# CRuby-only Date wrapper: the standalone CompactDate shim (entry shims)
# must not be reopened with a ::Date superclass in compiled builds.
rm "$COPY/ace-b36ts/lib/ace/b36ts/compact_date.rb"
# and leave a stub so the encoder's require resolves
printf '# frozen_string_literal: true\n# CRuby-only wrapper excluded from compiled builds (see REPORT.md).\n' > "$COPY/ace-b36ts/lib/ace/b36ts/compact_date.rb"
# EncodeCommand.execute's CRuby Time.parse path cannot type-check under
# Spinel; the compiled CLI uses CompactIdEncoder.encode_cli instead.
# PYSTUB1 (Run 4): keep the real EncodeCommand.execute; under SPINEL the
# readable-timestamp path uses the Glue ISO parser instead of Time.parse.
# PYSTUB1 (Run 4): keep the real EncodeCommand.execute for CRuby; under
# SPINEL route through execute_compiled — the default encode path uses the
# Gate-A-proven encode_cli (parse+encode in one static Time context), and
# count/split parse through a single-source parse_compiled to keep `time`
# monomorphic (poly-typed Time arguments refuse to compile).
python3 - "$COPY/ace-b36ts/lib/ace/b36ts/commands/encode_command.rb" <<'PYSTUB'
import sys
p = sys.argv[1]
s = open(p).read()
s = s.replace("Molecules::ConfigResolver", "::Ace::B36ts::Molecules::ConfigResolver")
s = s.replace("Atoms::CompactIdEncoder", "::Ace::B36ts::Atoms::CompactIdEncoder")
s = s.replace("Atoms::Formats", "::Ace::B36ts::Atoms::Formats")
old = """          def execute(time_string, options = {})
            time = parse_time(time_string)"""
new = """          def execute(time_string, options = {})
            if defined?(SPINEL)
              return execute_compiled(time_string, options)
            end

            time = parse_time(time_string)"""
assert old in s, "execute anchor"
s = s.replace(old, new)
compiled = """
          # Compiled-build entry: see PYSTUB1 note in build_full.sh.
          def execute_compiled(time_string, options = {})
            if options[:split]
              raise ArgumentError, "--split and --format are mutually exclusive" if options[:format]
              raise ArgumentError, "--split and --count are mutually exclusive" if options[:count]
            end

            config = ::Ace::B36ts::Molecules::ConfigResolver.resolve(options)

            display_config_summary("encode", config, options)

            if options[:split]
              time = parse_compiled(time_string)
              levels = parse_split_levels(options[:split])
              output = ::Ace::B36ts::Atoms::CompactIdEncoder.encode_split(
                time,
                levels: levels,
                year_zero: config[:year_zero],
                alphabet: config[:alphabet]
              )

              if options[:path_only]
                puts output[:path]
              elsif options[:json]
                puts JSON.generate(output.transform_keys(&:to_s))
              else
                display_split_output(levels, output)
              end
              return 0
            end

            format = options[:format]
            format = format.to_s.tr("-", "_").to_sym if format
            format ||= config[:default_format]&.to_sym || :"2sec"

            if options[:count]
              time = parse_compiled(time_string)
              ids = ::Ace::B36ts::Atoms::CompactIdEncoder.encode_sequence(
                time,
                count: options[:count].to_i,
                format: format,
                year_zero: config[:year_zero],
                alphabet: config[:alphabet]
              )

              if options[:json]
                puts JSON.generate(ids)
              else
                ids.each { |id| puts id }
              end
              return 0
            end

            if ::Ace::B36ts::Atoms::Formats.timestamp?(time_string)
              time = parse_compiled(time_string)
              puts ::Ace::B36ts::Atoms::CompactIdEncoder.encode_with_format(
                time,
                format: format,
                year_zero: config[:year_zero],
                alphabet: config[:alphabet]
              )
              return 0
            end

            puts ::Ace::B36ts::Atoms::CompactIdEncoder.encode_cli(
              time_string,
              format.to_s,
              config[:year_zero],
              ::Ace::B36ts::Atoms::CompactIdEncoder::DEFAULT_ALPHABET
            )
            0
          end

          def parse_compiled(time_string)
            if time_string.nil? || time_string.empty? || time_string == "now"
              Time.now.utc
            elsif ::Ace::B36ts::Atoms::Formats.timestamp?(time_string)
              ::Ace::B36ts::Atoms::Formats.parse_timestamp(time_string)
            else
              ::Ace::B36ts::Glue.parse_time_string(time_string)
            end
          end
"""
anchor = "          def execute(time_string, options = {})"
s = s.replace(anchor, compiled + "\n" + anchor, 1)
open(p, "w").write(s)
print("execute_compiled added")
PYSTUB
# SetupDoctor.parse_time's Time.parse branch is CRuby-only generic code,
# off the compiled CLI path; new Spinel refuses Time.parse at compile
# time, so stub the parse like other dead generic callers (REPORT.md).
python3 - "$COPY/ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb" <<'PYSTUB2'
import sys
p = sys.argv[1]
s = open(p).read()
old = "            Time.parse(value.to_s)\n"
new = "            raise NotImplementedError, \"Time.parse is CRuby-only in compiled builds\"\n"
assert s.count(old) == 1, "setup_doctor Time.parse anchor not found"
open(p, "w").write(s.replace(old, new))
PYSTUB2
# SetupDoctor's dead generic Hash#merge calls: rewrite to dup+each
# (Hash#merge is refused by the AOT compiler; these paths are CRuby-only).
python3 - "$COPY/ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb" <<'PYSTUB3'
import sys
p = sys.argv[1]
s = open(p).read()
repl = [
    ("            result = build_summary(checks).merge(\n"
     "              valid: !health_blocking?(checks),\n"
     "              duration: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at,\n"
     "              stats: build_stats(checks)\n"
     "            )\n",
     "            result = build_summary(checks)\n"
     "            result[:valid] = !health_blocking?(checks)\n"
     "            result[:duration] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at\n"
     "            result[:stats] = build_stats(checks)\n"),
    ("              target.merge(provider_kind: provider_kind, timeout_seconds: timeout_seconds, _order: index)\n",
     "              ordered_target = target.dup\n"
     "              ordered_target[:provider_kind] = provider_kind\n"
     "              ordered_target[:timeout_seconds] = timeout_seconds\n"
     "              ordered_target[:_order] = index\n"
     "              ordered_target\n"),
    ("            {id: id, kind: kind, status: status, message: message, next_action: next_action}.merge(extra)\n",
     "            check_hash = {id: id, kind: kind, status: status, message: message, next_action: next_action}\n"
     "            extra.each { |extra_key, extra_value| check_hash[extra_key] = extra_value }\n"
     "            check_hash\n"),
]
for old, new in repl:
    assert s.count(old) == 1, "setup_doctor merge anchor not found: %r" % old[:60]
    s = s.replace(old, new)
open(p, "w").write(s)
PYSTUB3
# ConfigSummaryMixin::GemClassMixin is dead in compiled builds (no summary
# display); its dynamic `self.class.gem_class` dispatch cannot type-check.
python3 - "$COPY/ace-support-core/lib/ace/core/cli/config_summary_mixin.rb" <<'PYSTUB4'
import sys
p = sys.argv[1]
s = open(p).read()
old = "            self.class.gem_class.config\n"
new = "            raise NotImplementedError, \"ConfigSummary is CRuby-only in compiled builds\"\n"
assert s.count(old) == 1, "gem_class config anchor not found"
s = s.replace(old, new)
old2 = "            self.class.gem_class.default_config\n"
new2 = "            raise NotImplementedError, \"ConfigSummary is CRuby-only in compiled builds\"\n"
assert s.count(old2) == 1, "gem_class default_config anchor not found"
s = s.replace(old2, new2)
open(p, "w").write(s)
PYSTUB4
perl -pi -e 's/^require_relative "compact_id_encoder_api"\n//' \
  "$COPY/ace-b36ts/lib/ace/b36ts/atoms/compact_id_encoder.rb"


# PYSTUB5 (Run 4): help/usage.rb all_commands — Spinel refuses the poly
# is_a? chain and the duck-registry `registry.commands` call. Under SPINEL
# the CLI registry is the RegistryDsl module, so CRuby AND compiled builds
# take the const_defined? REGISTERED_COMMANDS branch anyway (duck registries
# are test mocks only). Guarded rewrite keeps CRuby byte-identical.
python3 - "$COPY/ace-support-cli/lib/ace/support/cli/help/usage.rb" <<'PYSTUB5'
import sys
p = sys.argv[1]
s = open(p).read()
old = """          def all_commands
            commands =
              if registry.is_a?(Ace::Support::Cli::Registry)
                convert_commands_hash(registry.commands)
              elsif registry.is_a?(Hash)
                convert_commands_hash(registry)
              elsif registry.respond_to?(:commands)
"""
new = """          def all_commands
            commands =
              if defined?(SPINEL)
                if registry.const_defined?(:REGISTERED_COMMANDS)
                  convert_registered_commands(registry.const_get(:REGISTERED_COMMANDS))
                else
                  []
                end
              elsif registry.is_a?(Ace::Support::Cli::Registry)
                convert_commands_hash(registry.commands)
              elsif registry.is_a?(Hash)
                convert_commands_hash(registry)
              elsif registry.respond_to?(:commands)
"""
assert old in s, "usage.rb anchor not found"
s = s.replace(old, new)
old2 = """          def duck_commands
            registry.commands
          end
"""
new2 = """          def duck_commands
            return {} if defined?(SPINEL)

            registry.commands
          end
"""
assert old2 in s, "duck_commands anchor not found"
s = s.replace(old2, new2)
open(p, "w").write(s)
PYSTUB5


# PYSTUB6 (Run 4): duck_commands never runs in compiled builds (registry is
# the RegistryDsl module, which has no #commands); drop the poly call.
# PYSTUB7 (Run 4): ConfigResolver.resolve — the CRuby Config.wrap branch
# poisons type inference for the module singleton dispatch; compiled builds
# use the SPINEL glue cascade only.
python3 - "$COPY/ace-support-cli/lib/ace/support/cli/help/usage.rb" <<'PYSTUB6'
import sys
p = sys.argv[1]
s = open(p).read()
old = """          def duck_commands
            return {} if defined?(SPINEL)

            registry.commands
          end
"""
new = """          def duck_commands
            {}
          end
"""
assert old in s, "duck_commands anchor not found"
open(p, "w").write(s.replace(old, new))
PYSTUB6
cat > "$COPY/ace-b36ts/lib/ace/b36ts/molecules/config_resolver.rb" <<'RB'
# frozen_string_literal: true

# Compiled-build variant (Run 4): module-level `def self.` methods.
# The original `class << self` module singleton poisons Spinel's
# dispatch inference when Commands::* are reachable (CRuby source is
# unchanged; this file is rewritten inside build_full.sh's copy).
module Ace
  module B36ts
    module Molecules
      module ConfigResolver
        FALLBACK_DEFAULTS = {
          year_zero: 2000,
          alphabet: "0123456789abcdefghijklmnopqrstuvwxyz",
          default_format: :"2sec"
        }.freeze

        def self.resolve(overrides = {})
          Ace::B36ts::Glue.resolve_b36ts_config(
            gem_root, FALLBACK_DEFAULTS.to_a, overrides
          )
        end

        def self.gem_root
          Gem.loaded_specs["ace-b36ts"]&.gem_dir ||
            File.expand_path("../../../..", __dir__)
        end
      end
    end
  end
end
RB


# PYSTUB8 (Run 4): constants referenced inside `class << self` bodies must
# use absolute paths for Spinel's constant-path typing (relative
# Molecules::/Atoms::/ConfigResolver:: lookups refuse or warn).
python3 - "$COPY/ace-b36ts/lib/ace/b36ts/commands/decode_command.rb" "$COPY/ace-b36ts/lib/ace/b36ts/commands/config_command.rb" <<'PYSTUB8'
import sys
for p in sys.argv[1:]:
    s = open(p).read()
    s = s.replace("Molecules::ConfigResolver", "::Ace::B36ts::Molecules::ConfigResolver")
    s = s.replace("Atoms::Formats", "::Ace::B36ts::Atoms::Formats")
    s = s.replace("Atoms::CompactIdEncoder", "::Ace::B36ts::Atoms::CompactIdEncoder")
    open(p, "w").write(s)
PYSTUB8






# PYSTUB12 (Run 4): compiled builds resolve commands through the CLI
# module's spinel_command_for table (classes only) — the runtime Registry
# resolve returns a poly Class|Instance|nil local whose class-attr reads
# misbox under Spinel (see ace-b36ts cli.rb / REPORT.md).
python3 - "$COPY/ace-support-cli/lib/ace/support/cli/runner.rb" <<'PYSTUB12'
import sys
p = sys.argv[1]
s = open(p).read()
old = """        def resolve_target(args)
          program = resolve_program_name
"""
new = """        def resolve_target(args)
          if defined?(SPINEL)
            name = args.first
            command_class = @registry.spinel_command_for(name)
            [command_class, args.drop(1), "#{resolve_program_name} #{name}"]
          else
            resolve_target_registry(args)
          end
        end

        def resolve_target_registry(args)
          program = resolve_program_name
"""
assert old in s, "runner anchor missing"
open(p, "w").write(s.replace(old, new))
print("runner guarded")
PYSTUB12



# PYSTUB13 (Run 4): compiled builds always render rich help (all b36ts
# commands have desc/examples), and no b36ts command takes an :args
# keyword; the CRuby introspection paths refuse to compile.
python3 - "$COPY/ace-support-cli/lib/ace/support/cli/parser.rb" <<'PYSTUB13'
import sys
p = sys.argv[1]
s = open(p).read()
old = """        def rich_help?
          has_desc = command_class.respond_to?(:description) && !command_class.description.nil?
"""
new = """        def rich_help?
          return true if defined?(SPINEL)

          has_desc = command_class.respond_to?(:description) && !command_class.description.nil?
"""
assert old in s, "rich_help anchor"
s = s.replace(old, new)
old2 = """        def accepts_args_keyword?
          command_class.instance_method(:call).parameters.any? do |kind, name|"""
new2 = """        def accepts_args_keyword?
          return false if defined?(SPINEL)

          command_class.instance_method(:call).parameters.any? do |kind, name|"""
assert old2 in s, "accepts anchor"
s = s.replace(old2, new2)
open(p, "w").write(s)
print("parser guarded")
PYSTUB13

# PYSTUB14 (Run 4): Array#each_with_object is unsupported in Spinel;
# rewrite to each + accumulator (identical semantics on CRuby).
python3 - "$COPY" <<'PYSTUB14'
import sys, os
root = sys.argv[1]

def sub(path, old, new):
    p = os.path.join(root, path)
    s = open(p).read()
    assert old in s, "anchor missing in " + path
    open(p, "w").write(s.replace(old, new))

sub("ace-support-cli/lib/ace/support/cli/argv_coalescer.rb",
"""          flags.each_with_object({}) do |(canonical, aliases), memo|
            memo[canonical] = canonical
            aliases.each { |entry| memo[entry] = canonical }
          end""",
"""          memo = {}
          flags.each do |canonical, aliases|
            memo[canonical] = canonical
            aliases.each { |entry| memo[entry] = canonical }
          end
          memo""")

sub("ace-support-core/lib/ace/core/atoms/config_summary.rb",
"""          hash.each_with_object({}) do |(key, value), result|
            full_key = prefix ? "#{prefix}.#{key}" : key.to_s
            if value.is_a?(Hash)
              result.merge!(flatten_hash(value, full_key))
            else
              result[full_key] = value
            end
          end""",
"""          result = {}
          hash.each do |key, value|
            full_key = prefix ? "#{prefix}.#{key}" : key.to_s
            if value.is_a?(Hash)
              flatten_hash(value, full_key).each { |k2, v2| result[k2] = v2 }
            else
              result[full_key] = value
            end
          end
          result""")

sub("ace-support-cli/lib/ace/support/cli/registry.rb",
"""          @root.children.each_with_object({}) do |(name, node), hash|
            hash[name] = node.command || NestedRegistry.new(node)
          end""",
"""          hash = {}
          @root.children.each do |name, node|
            hash[name] = node.command || NestedRegistry.new(node)
          end
          hash""")

sub("ace-support-cli/lib/ace/support/cli/parser.rb",
"""          command_class.options.each_with_object({}) do |option, hash|""",
"""          hash = {}
          command_class.options.each do |option|""")
p = os.path.join(root, "ace-support-cli/lib/ace/support/cli/parser.rb")
s = open(p).read()
old = """            next if option.default.nil?

            hash[option.name] = duplicate_default(option.default)
          end
        end"""
new = """            next if option.default.nil?

            hash[option.name] = duplicate_default(option.default)
          end
          hash
        end"""
assert old in s, "build_defaults tail"
open(p, "w").write(s.replace(old, new))
print("rewritten")
PYSTUB14

# PYSTUB15 (Run 4): bare attr_reader :description misboxes on poly
# class values (REPORT.md bare-ivar bug); explicit nil-guarded reader.
python3 - "$COPY/ace-support-cli/lib/ace/support/cli/command.rb" <<'PYSTUB15'
import sys
p = sys.argv[1]
s = open(p).read()
old = """      class Command
        class << self
          attr_reader :description
"""
new = """      class Command
        class << self
          def description
            d = @description
            (d.nil? || d == false) ? nil : d
          end
"""
assert old in s, "attr_reader anchor"
open(p, "w").write(s.replace(old, new))
print("description reader explicit")
PYSTUB15

# PYSTUB16 (Run 4): Banner helpers guard attr reads behind respond_to?,
# which boxes the poly class value and misboxes the read to Integer.
# Compiled builds read the attributes directly (all b36ts commands are
# Ace::Support::Cli::Command subclasses).
python3 - "$COPY/ace-support-cli/lib/ace/support/cli/help/banner.rb" <<'PYSTUB16'
import sys
p = sys.argv[1]
s = open(p).read()
pairs = [
("""          def self.description(command)
            command.respond_to?(:description) ? command.description : nil
          end""",
"""          def self.description(command)
            if defined?(SPINEL)
              d = command.description
              d.nil? ? nil : d
            else
              command.respond_to?(:description) ? command.description : nil
            end
          end"""),
("""          def self.options(command)
            command.respond_to?(:options) ? command.options : []
          end""",
"""          def self.options(command)
            if defined?(SPINEL)
              o = command.options
              o.nil? ? [] : o
            else
              command.respond_to?(:options) ? command.options : []
            end
          end"""),
("""          def self.examples(command)
            command.respond_to?(:examples) ? command.examples : []
          end""",
"""          def self.examples(command)
            if defined?(SPINEL)
              e = command.examples
              e.nil? ? [] : e
            else
              command.respond_to?(:examples) ? command.examples : []
            end
          end"""),
("""          def self.arguments(command)
            return command.arguments if command.respond_to?(:arguments)""",
"""          def self.arguments(command)
            if defined?(SPINEL)
              a = command.arguments
              return a.nil? ? [] : a
            end
            return command.arguments if command.respond_to?(:arguments)"""),
]
for old, new in pairs:
    assert old in s, "anchor missing: " + old[:60]
    s = s.replace(old, new)
open(p, "w").write(s)
print("banner guarded")
PYSTUB16

# PYSTUB17 (Run 4): poly class values crossing a module boundary box and
# misbox attr reads to Integer. Parser (a CLASS — safe context) reads the
# command's attributes and stashes them in mono-typed constant hashes;
# Banner helpers under SPINEL read the stash instead of the command.
python3 - "$COPY" <<'PYSTUB17'
import sys, os
root = sys.argv[1]

banner_p = os.path.join(root, "ace-support-cli/lib/ace/support/cli/help/banner.rb")
s = open(banner_p).read()
old = """        module Banner
"""
new = """        module Banner
          # Run 4: compiled builds receive precomputed attribute data via
          # mono-typed stashes (see parser.rb render_help).
          STASH_D = {}
          STASH_O = {}
          STASH_A = {}
          STASH_E = {}
"""
assert old in s, "banner module anchor"
s = s.replace(old, new)

pairs = [
("""          def self.description(command)
            if defined?(SPINEL)
              d = command.description
              d.nil? ? nil : d
            else
              command.respond_to?(:description) ? command.description : nil
            end
          end""",
"""          def self.description(command)
            return STASH_D[:value] if defined?(SPINEL)

            command.respond_to?(:description) ? command.description : nil
          end"""),
("""          def self.options(command)
            if defined?(SPINEL)
              o = command.options
              o.nil? ? [] : o
            else
              command.respond_to?(:options) ? command.options : []
            end
          end""",
"""          def self.options(command)
            if defined?(SPINEL)
              o = STASH_O[:value]
              return o.nil? ? [] : o
            end

            command.respond_to?(:options) ? command.options : []
          end"""),
("""          def self.examples(command)
            if defined?(SPINEL)
              e = command.examples
              e.nil? ? [] : e
            else
              command.respond_to?(:examples) ? command.examples : []
            end
          end""",
"""          def self.examples(command)
            if defined?(SPINEL)
              e = STASH_E[:value]
              return e.nil? ? [] : e
            end

            command.respond_to?(:examples) ? command.examples : []
          end"""),
("""          def self.arguments(command)
            if defined?(SPINEL)
              a = command.arguments
              return a.nil? ? [] : a
            end
            return command.arguments if command.respond_to?(:arguments)""",
"""          def self.arguments(command)
            if defined?(SPINEL)
              a = STASH_A[:value]
              return a.nil? ? [] : a
            end
            return command.arguments if command.respond_to?(:arguments)"""),
]
for old, new in pairs:
    assert old in s, "anchor missing: " + old[:50]
    s = s.replace(old, new)
open(banner_p, "w").write(s)

parser_p = os.path.join(root, "ace-support-cli/lib/ace/support/cli/parser.rb")
s = open(parser_p).read()
old6 = """        def render_help(args)
          name = resolved_command_name
          output = Ace::Support::Cli::Help::TwoTierHelp.render(command_class, name, args: args)
          raise HelpRendered.new(output)
        end"""
new6 = """        def render_help(args)
          name = resolved_command_name
          if defined?(SPINEL)
            # Parser is a class context: attr reads on the poly command
            # class work here; across module boundaries they misbox.
            d = command_class.description
            ::Ace::Support::Cli::Help::Banner::STASH_D[:value] = d.nil? ? "" : d
            o = command_class.options
            ::Ace::Support::Cli::Help::Banner::STASH_O[:value] = o.nil? ? [] : o
            a = command_class.arguments
            ::Ace::Support::Cli::Help::Banner::STASH_A[:value] = a.nil? ? [] : a
            e = command_class.examples
            ::Ace::Support::Cli::Help::Banner::STASH_E[:value] = e.nil? ? [] : e
          end
          output = Ace::Support::Cli::Help::TwoTierHelp.render(command_class, name, args: args)
          raise HelpRendered.new(output)
        end"""
assert old6 in s, "render_help anchor"
open(parser_p, "w").write(s.replace(old6, new6))
print("stash wired")
PYSTUB17

cd "$WT"
exec "$SPINEL" .ace-bin/spinel-aot/entry_full.rb \
  -I .ace-bin/spinel-aot/shims \
  -I "$COPY/ace-b36ts/lib" \
  -I "$COPY/ace-support-cli/lib" \
  -I "$COPY/ace-support-core/lib" \
  -I "$COPY/ace-support-config/lib" \
  -I "$COPY/ace-support-fs/lib" \
  --rbs .ace-bin/spinel-aot/rbs \
  --jobs=1 --require-gate --defer-refusals -o "$OUT"

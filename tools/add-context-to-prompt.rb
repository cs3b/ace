#!/usr/bin/env ruby
# frozen_string_literal: true
# -----------------------------------------------------------------------------
# add-context-to-prompt.rb  – v0.5  (2025‑04‑22)
#
# PURPOSE
#   • Take one prompt file (or every prompt under docs-dev/zed/prompts/)
#   • Treat every  /file <path>  line that lives **outside** <context> … </context>
#     as a *seed* document.  Order is preserved.
#   • For each seed, follow every Markdown link found inside it (recursively),
#     treating links as *project‑root–relative* paths.
#   • Build one /file <path> line per unique referenced file (seeds excluded)
#     and write them into <context>, preserving discovery order.
#   • Warn about, or optionally delete (‑d), /file lines in <context> that are
#     no longer referenced.
#
# USAGE
#   docs-dev/tools/add-context-to-prompt.rb load-env
#   docs-dev/tools/add-context-to-prompt.rb all --delete-not-referenced
#
# NOTES
#   • Only local files that actually exist are kept.
#   • By default only .md files are parsed for links; adjust EXT_FILTER if needed.
# -----------------------------------------------------------------------------

require 'optparse'
require 'pathname'
require 'set'

# -------- CLI options --------------------------------------------------------
opts = { delete_unreferenced: false }
OptionParser.new do |o|
  o.banner = 'Usage: add-context-to-prompt.rb [options] <prompt_path | all>'
  o.on('-d', '--delete-not-referenced',
       'Delete /file lines in <context> that are not referenced') { opts[:delete_unreferenced] = true }
  o.on('-h', '--help', 'Show this help') { puts o; exit }
end.parse!
selector = ARGV.shift or abort 'ERROR: supply a prompt path or "all"'

# -------- project paths ------------------------------------------------------
SCRIPT_DIR  = Pathname.new(__dir__).freeze
ROOT        = (SCRIPT_DIR + '..' + '..').cleanpath.freeze
PROMPTS_DIR = ROOT + 'docs-dev/zed/prompts'

def resolve_prompt(arg)
  [
    Pathname.new(arg),
    Pathname.new("#{arg}.txt"),
    PROMPTS_DIR + arg,
    PROMPTS_DIR + "#{arg}.txt"
  ].map(&:cleanpath).find(&:file?)
end

# -------- regexes ------------------------------------------------------------
SEED_RX      = /^\s*\/file\s+(.+?)\s*$/
LINK_RX      = /!?\[[^\]]+\]\(([^)]+)\)/
CTX_BLOCK_RX = /<context>(.*?)<\/context>/m
CTX_FILE_RX  = /^\s*\/file\s+(.+?)\s*$/

# -------- helper functions ---------------------------------------------------
EXT_FILTER = ['.md'].freeze   # only files with these extensions are parsed for links

def markdown_links(text)
  text.scan(LINK_RX).flatten.reject do |h|
    h =~ %r{^\w+://} || h.start_with?('#', 'mailto:')
  end
end

def crawl(seed_paths)
  seen = Set.new
  order = []

  walker = lambda do |rel|
    return if seen.include?(rel)

    seen << rel
    order << rel
    abs = ROOT + rel
    return unless abs.file? && EXT_FILTER.include?(abs.extname.downcase)

    markdown_links(abs.read).each do |href|
      candidate = (ROOT + href).cleanpath          # interpret as project‑root relative
      next unless candidate.file?

      walker.call(candidate.relative_path_from(ROOT))
    end
  end

  seed_paths.each { walker.call(_1) }
  order
end

def ctx_paths(body)
  body.lines.filter_map { |l| l[CTX_FILE_RX, 1] }
            .map { |p| Pathname.new(p).cleanpath }
end

def rebuild_context(orig_body, final_paths)
  preserved = orig_body.lines
                       .reject { |l| l =~ CTX_FILE_RX }    # drop old /file lines
                       .reject { |l| l.strip.empty? }      # drop pure blank lines
  (preserved + final_paths.map { |p| "/file #{p}\n" })
    .join.rstrip + "\n"
end

def update_prompt(prompt_path, delete_unref:)
  raw = prompt_path.read

  # ------ grab seed paths (outside <context>)
  seeds = raw.gsub(CTX_BLOCK_RX, '').scan(SEED_RX)
             .flatten.map { |p| Pathname.new(p).cleanpath }
  if seeds.empty?
    warn "WARN: no /file lines found in #{prompt_path}"
    return
  end

  unless raw =~ CTX_BLOCK_RX
    warn "WARN: <context> not found in #{prompt_path}"
    return
  end
  ctx_body = Regexp.last_match(1)
  existing = ctx_paths(ctx_body)

  required = crawl(seeds) - seeds    # exclude seeds themselves

  missing = required - existing
  extras  = existing - required

  puts "• #{prompt_path.relative_path_from(ROOT)}  (+#{missing.size}, -#{extras.size})" \
       unless missing.empty? && extras.empty?

  final_paths = existing + missing
  final_paths.reject! { |p| extras.include?(p) } if delete_unref

  new_ctx = rebuild_context(ctx_body, final_paths)
  updated = raw.sub(CTX_BLOCK_RX) { "<context>\n#{new_ctx}</context>" }

  prompt_path.write(updated) if updated != raw
end

# -------- run ----------------------------------------------------------------
prompt_files =
  if selector == 'all'
    Dir.glob((PROMPTS_DIR + '**/*').to_s)
       .select { |f| File.file?(f) }
       .sort
       .map { Pathname.new(_1) }
  else
    [resolve_prompt(selector) || abort("ERROR: prompt '#{selector}' not found")]
  end

prompt_files.each { |p| update_prompt(p, delete_unref: opts[:delete_unreferenced]) }

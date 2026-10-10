# frozen_string_literal: true

# Dir.glob shim for Spinel-compiled ace binaries.
#
# Spinel's runtime has no Dir.glob; it exposes Dir.new/Dir.children.
# This implements the subset ace uses:
#   Dir.glob(pattern)                      -> Array<String>
#   Dir.glob(pattern, flags, base: dir)    -> Array<String> (flags ignored)
#   Dir.glob(pattern, base: dir) { |f| }   -> block form
# Pattern support: literal segments, *, **, ?, and single {a,b}
# alternates per segment. No character classes, no escapes.
# Results are sorted like Ruby's glob; hidden files are NOT matched
# by wildcards unless the leading directory segment is literal.
#
# Loaded before ace sources via the shims -I dir.

class Dir
  def self.globAceExpandSeg(segment)
    if segment.include?("{") && segment.include?("}")
      head = segment[0, segment.index("{")]
      tail_start = segment.index("}")
      tail = segment[(tail_start + 1)..]
      alts = segment[(segment.index("{") + 1)...tail_start].split(",")
      out = []
      alts.each do |alt|
        out.concat(globAceExpandSeg(head + alt + tail))
      end
      out
    else
      [segment]
    end
  end

  def self.globAceMatch?(segment, name)
    return false if name.start_with?(".") && !segment.start_with?("{") &&
                    !segment.start_with?(".")

    regex = ""
    i = 0
    while i < segment.length
      ch = segment[i]
      if ch == "*"
        regex += "[^/]*"
      elsif ch == "?"
        regex += "[^/]"
      elsif ch == "." || ch == "["
        regex += "\\" + ch
      else
        regex += ch
      end
      i += 1
    end
    name.match?("\\A" + regex + "\\z")
  end

  def self.globAceJoin(base, rel)
    "#{base}/#{rel}"
  end

  def self.globAceWalk(dir_abs, segments, seg_idx, acc)
    return if seg_idx >= segments.length

    seg = segments[seg_idx]
    last = seg_idx == segments.length - 1

    if seg == "**"
      # ** matches zero or more directory levels
      globAceWalk(dir_abs, segments, seg_idx + 1, acc)
      entries = globAceChildren(dir_abs)
      entries.each do |name|
        sub = dir_abs + "/" + name
        next unless File.directory?(sub)

        if last
          acc << name
        else
          rel_prefix = name
          collect_under(sub, segments, seg_idx + 1, rel_prefix, acc)
        end
      end
    elsif seg.include?("*") || seg.include?("?") || seg.include?("{")
      expanded = globAceExpandSeg(seg)
      entries = globAceChildren(dir_abs)
      entries.each do |name|
        matched = false
        expanded.each do |candidate|
          matched = true if globAceMatch?(candidate, name)
        end
        next unless matched

        sub = dir_abs + "/" + name
        if last
          acc << name
        elsif File.directory?(sub)
          rel_prefix = name
          collect_under(sub, segments, seg_idx + 1, rel_prefix, acc)
        end
      end
    else
      sub = dir_abs + "/" + seg
      return unless File.exist?(sub)

      if last
        acc << seg
      elsif File.directory?(sub)
        collect_under(sub, segments, seg_idx + 1, seg, acc)
      end
    end
  end

  def self.collect_under(dir_abs, segments, seg_idx, rel_prefix, acc)
    return if seg_idx >= segments.length

    seg = segments[seg_idx]
    last = seg_idx == segments.length - 1

    if seg == "**"
      acc << rel_prefix if last
      entries = globAceChildren(dir_abs)
      entries.each do |name|
        sub = dir_abs + "/" + name
        next unless File.directory?(sub)

        deeper = rel_prefix + "/" + name
        if last
          acc << deeper
        else
          collect_under(sub, segments, seg_idx + 1, deeper, acc)
        end
        collect_under(sub, segments, seg_idx, deeper, acc)
      end
      return
    end

    if seg.include?("*") || seg.include?("?") || seg.include?("{")
      expanded = globAceExpandSeg(seg)
      entries = globAceChildren(dir_abs)
      entries.each do |name|
        matched = false
        expanded.each do |candidate|
          matched = true if globAceMatch?(candidate, name)
        end
        next unless matched

        deeper = rel_prefix + "/" + name
        sub = dir_abs + "/" + name
        if last
          acc << deeper
        elsif File.directory?(sub)
          collect_under(sub, segments, seg_idx + 1, deeper, acc)
        end
      end
    else
      sub = dir_abs + "/" + seg
      return unless File.exist?(sub)

      deeper = rel_prefix + "/" + seg
      if last
        acc << deeper
      elsif File.directory?(sub)
        collect_under(sub, segments, seg_idx + 1, deeper, acc)
      end
    end
  end

  def self.globAceChildren(dir_abs)
    d = Dir.new(dir_abs)
    out = []
    d.each do |name|
      out << name unless name == "." || name == ".."
    end
    out
  rescue StandardError
    []
  end

  def self.globAceRun(pattern, base)
    normalized = pattern
    if normalized.start_with?("./")
      normalized = normalized[2, normalized.length - 2]
    end
    segments = normalized.split("/")
    acc = []
    root = base.nil? || base.empty? ? "." : base
    globAceWalk(root, segments, 0, acc)
    acc.sort
  end

  def self.glob(pattern, flags = nil, base: nil, sort: true, &block)
    results = globAceRun(pattern, base)
    out = [""]
    out.pop
    results.each do |path|
      out << globAceJoin(base, path)
    end
    if block
      out.each do |path|
        block.call(path)
      end
    end
    out
  end
end

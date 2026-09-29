# frozen_string_literal: true

# Minimal YAML-subset reader for Spinel-compiled ace binaries.
#
# Covers ace's config-cascade surface (ADR-022 files): nested maps,
# block lists, and scalars (integer, float, true/false/null, quoted and
# plain strings), with full-line and trailing comments. NOT a general
# YAML implementation: no anchors/aliases, flow collections, multi-doc,
# tags, or block scalars. Correctness is gated by the conformance
# oracle (.ace-local/ace-aot/conformance.sh).
#
# API surface used by ace-support-config / ace-support-core:
#   YAML.safe_load(str, permitted_classes:, aliases:)
#   YAML.load_file(path) / YAML.safe_load_file(path, ...)
#   YAML.dump(data)
#   Psych::SyntaxError

module Psych
  class Exception < StandardError; end
  class SyntaxError < Exception; end
end

# NOTE: Encoding::CompatibilityError / InvalidByteSequenceError are
# rescued by ace yaml_parser.rb. Spinel ships a builtin Encoding that
# is not a module, so we cannot add these constants here; if the
# compile fails on that rescue clause, revisit (constant assignment).

module YAML
  module_function

  def safe_load(text, permitted_classes: [], aliases: false)
    doc = Parser.new(text).parse
    doc.nil? ? {} : doc
  end

  def load_file(path)
    safe_load(File.read(path))
  end

  def safe_load_file(path, permitted_classes: [], aliases: false)
    safe_load(File.read(path))
  end

  def dump(data)
    emit_value(data, 0) + "\n"
  end

  # ---------- emitter (subset: maps/lists/scalars, for display only) ----------

  def emit_value(value, indent)
    pad = " " * indent
    out = ""
    if value.is_a?(Hash)
      return "{}\n" if value.length.zero?

      parts = []
      value.each do |k, v|
        key = k.to_s
        if v.is_a?(Hash) || v.is_a?(Array)
          parts << pad + key + ":\n" + emit_value(v, indent + 2)
        else
          parts << pad + key + ": " + scalar_repr(v)
        end
      end
      out = parts.join
    elsif value.is_a?(Array)
      return "[]\n" if value.length.zero?

      parts = []
      value.each do |v|
        if v.is_a?(Hash) || v.is_a?(Array)
          parts << pad + "-\n" + emit_value(v, indent + 2)
        else
          parts << pad + "- " + scalar_repr(v) + "\n"
        end
      end
      out = parts.join
    else
      out = pad + scalar_repr(value) + "\n"
    end
    out
  end

  def scalar_repr(value)
    if value.nil?
      "null"
    elsif value == true
      "true"
    elsif value == false
      "false"
    elsif value.is_a?(String)
      needs_quotes(value) ? value.inspect : value
    else
      value.to_s
    end
  end

    def needs_quotes(str)
      return true if str.empty? || str.include?(": ") || str.end_with?(":")
      return true if str.end_with?(" ") || str.include?("\n")

      first = str[0]
      "#-*&!%@`\"'[]{}|>, ?:".include?(first)
    end

  # ---------- parser ----------

  class Parser
    def initialize(text)
      @lines = text.split("\n")
      @pos = 0
    end

    def parse
      skip_ignorable
      return nil if @pos >= @lines.length

      parse_collection(line_indent(@lines[@pos]))
    end

    private

    def skip_ignorable
      while @pos < @lines.length
        content = @lines[@pos].strip
        break unless content.empty? || content.start_with?("#")

        @pos += 1
      end
    end

    def line_indent(line)
      count = 0
      line.each_char do |ch|
        break unless ch == " "

        count += 1
      end
      count
    end

    def parse_collection(indent)
      content = @lines[@pos].strip
      if content == "-" || content.start_with?("- ")
        parse_list(indent)
      else
        parse_map(indent)
      end
    end

    def parse_map(indent)
      hash = {}
      while @pos < @lines.length
        skip_ignorable
        break if @pos >= @lines.length

        line = @lines[@pos]
        cur = line_indent(line)
        break if cur < indent
        if cur > indent
          raise Psych::SyntaxError, "unexpected indentation: #{line.strip.inspect}"
        end

        content = line.strip
        if content == "-" || content.start_with?("- ")
          break
        end

        key, rest = split_kv(content)
        @pos += 1

        if rest.nil?
          hash[key] = parse_value_below(indent)
        else
          hash[key] = parse_scalar(strip_comment(rest))
        end
      end
      hash
    end

    def parse_value_below(map_indent)
      skip_ignorable
      return nil if @pos >= @lines.length

      next_indent = line_indent(@lines[@pos])
      next_content = @lines[@pos].strip
      if next_indent > map_indent
        parse_collection(next_indent)
      elsif next_indent == map_indent && (next_content == "-" || next_content.start_with?("- "))
        parse_list(map_indent)
      else
        nil
      end
    end

    def parse_list(indent)
      items = []
      while @pos < @lines.length
        skip_ignorable
        break if @pos >= @lines.length

        line = @lines[@pos]
        cur = line_indent(line)
        break if cur < indent

        content = line.strip
        unless content == "-" || content.start_with?("- ")
          break if cur == indent

          raise Psych::SyntaxError, "unexpected line in list: #{content.inspect}"
        end

        item = content == "-" ? "" : content[2, content.length - 2]
        @pos += 1

        if item.strip.empty?
          items << nested_after_dash(indent)
        else
          items << parse_scalar(strip_comment(item.strip))
        end
      end
      items
    end

    def nested_after_dash(dash_indent)
      skip_ignorable
      return nil if @pos >= @lines.length

      next_indent = line_indent(@lines[@pos])
      return nil if next_indent <= dash_indent

      parse_collection(next_indent)
    end

    # Returns [key, rest] where rest is nil when the value is nested/empty.
    def split_kv(content)
      if content.start_with?('"') || content.start_with?("'")
        quote = content[0]
        close = content.index(quote, 1)
        raise Psych::SyntaxError, "unterminated quoted key" if close.nil?

        key = unquote(content[0, close + 1])
        tail = content[close + 1, content.length - close - 1].strip
        if tail == ":"
          return [key, nil]
        elsif tail.start_with?(": ")
          return [key, tail[2, tail.length - 2]]
        end
        raise Psych::SyntaxError, "malformed mapping: #{content.inspect}"
      end

      idx = content.index(": ")
      if idx
        [content[0, idx].strip, content[idx + 2, content.length - idx - 2]]
      elsif content.end_with?(":")
        [content[0, content.length - 1].strip, nil]
      else
        raise Psych::SyntaxError, "could not find expected ':' in #{content.inspect}"
      end
    end

    def strip_comment(text)
      if text.start_with?('"') || text.start_with?("'")
        return text
      end

      idx = text.index(" #")
      idx.nil? ? text : text[0, idx]
    end

    def unquote(quoted)
      quote = quoted[0]
      body = quoted[1, quoted.length - 2]
      if quote == "'"
        collapse_escaped_quotes(body)
      else
        unescape(body)
      end
    end

    def collapse_escaped_quotes(str)
      out = ""
      i = 0
      while i < str.length
        if str[i] == "'" && i + 1 < str.length && str[i + 1] == "'"
          out += "'"
          i += 2
        else
          out += str[i]
          i += 1
        end
      end
      out
    end

    def unescape(str)
      out = ""
      i = 0
      while i < str.length
        ch = str[i]
        if ch == "\\" && i + 1 < str.length
          nxt = str[i + 1]
          out += case nxt
                 when "n" then "\n"
                 when "t" then "\t"
                 when '"' then '"'
                 when "\\" then "\\"
                 else nxt
                 end
          i += 2
        else
          out += ch
          i += 1
        end
      end
      out
    end

    def parse_scalar(text)
      text = text.strip
      if text.empty? || text == "null" || text == "~" || text == "Null" || text == "NULL"
        nil
      elsif text == "true" || text == "True" || text == "TRUE"
        true
      elsif text == "false" || text == "False" || text == "FALSE"
        false
      elsif text.start_with?('"') || text.start_with?("'")
        if text.length < 2
          raise Psych::SyntaxError, "unquoted scalar: #{text.inspect}"
        end
        unquote(text)
      elsif all_digits_with_sign?(text)
        text.to_i
      elsif looks_like_float?(text)
        text.to_f
      else
        text
      end
    end

    def all_digits_with_sign?(text)
      body = text.start_with?("-") || text.start_with?("+") ? text[1, text.length - 1] : text
      return false if body.nil? || body.empty?

      body.each_char do |ch|
        return false unless ch >= "0" && ch <= "9"
      end
      true
    end

    def looks_like_float?(text)
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
end

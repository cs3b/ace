#!/usr/bin/env ruby
# frozen_string_literal: true

# Manual test script for ace-support-mac-clipboard
# Usage: echo "test" | pbcopy && ruby bin/inspect_clipboard.rb

require_relative "../lib/ace/support/mac_clipboard"

puts "=" * 60
puts "macOS Clipboard Inspector"
puts "=" * 60
puts

# Read raw clipboard
raw_result = Ace::Support::MacClipboard::Reader.read

unless raw_result[:success]
  puts "❌ Failed to read clipboard: #{raw_result[:error]}"
  exit 1
end

# Show available types
puts "Available UTI Types:"
puts "-" * 60
if raw_result[:types].empty?
  puts "  (none - clipboard is empty)"
else
  raw_result[:types].each_with_index do |uti, i|
    category = Ace::Support::MacClipboard::ContentType.classify(uti)
    puts "  #{i + 1}. #{uti} → #{category}"
  end
end
puts

# Parse content
parsed = Ace::Support::MacClipboard::ContentParser.parse(raw_result)

# Show text content
puts "Text Content:"
puts "-" * 60
if parsed[:text]
  preview = parsed[:text][0...200]
  preview += "..." if parsed[:text].length > 200
  puts preview
else
  puts "  (none)"
end
puts

# Show attachments
puts "Attachments:"
puts "-" * 60
if parsed[:attachments].empty?
  puts "  (none)"
else
  parsed[:attachments].each_with_index do |att, i|
    puts "  #{i + 1}. #{att[:filename]} (#{att[:type]})"

    case att[:type]
    when :image
      puts "     Format: #{att[:format]}, Size: #{att[:data].bytesize} bytes"
    when :file
      puts "     Source: #{att[:source_path]}"
      puts "     Exists: #{File.exist?(att[:source_path])}"
    when :rtf, :html
      puts "     Size: #{att[:data].bytesize} bytes"
    end
  end
end
puts

# Summary
puts "Summary:"
puts "-" * 60
puts "  Types found: #{raw_result[:types].length}"
puts "  Text present: #{parsed[:text] ? 'Yes' : 'No'}"
puts "  Attachments: #{parsed[:attachments].length}"
puts

#!/usr/bin/env ruby
# frozen_string_literal: true

require "ffi"

module Debug
  extend FFI::Library
  ffi_lib "/usr/lib/libobjc.dylib"

  attach_function :objc_getClass, [:string], :pointer
  attach_function :sel_registerName, [:string], :pointer
  attach_function :objc_msgSend, [:pointer, :pointer], :pointer
  attach_function :objc_msgSend_uint, :objc_msgSend, [:pointer, :pointer], :uint
  attach_function :objc_msgSend_uint64, :objc_msgSend, [:pointer, :pointer, :uint64], :pointer

  # Load AppKit framework
  ffi_lib "/System/Library/Frameworks/AppKit.framework/AppKit"

  def self.test_clipboard
    puts "Getting NSPasteboard class..."
    ns_pasteboard_class = objc_getClass("NSPasteboard")
    puts "  Class pointer: #{ns_pasteboard_class.inspect}"

    puts "\nGetting generalPasteboard..."
    sel = sel_registerName("generalPasteboard")
    puts "  Selector: #{sel.inspect}"
    pasteboard = objc_msgSend(ns_pasteboard_class, sel)
    puts "  Pasteboard pointer: #{pasteboard.inspect}"
    puts "  Is null? #{pasteboard.null?}"

    return if pasteboard.null?

    puts "\nGetting types..."
    types_sel = sel_registerName("types")
    types_array = objc_msgSend(pasteboard, types_sel)
    puts "  Types array pointer: #{types_array.inspect}"
    puts "  Is null? #{types_array.null?}"

    return if types_array.null?

    puts "\nGetting count..."
    count_sel = sel_registerName("count")
    count = objc_msgSend_uint(types_array, count_sel)
    puts "  Count: #{count}"

    if count > 0
      puts "\nGetting first type..."
      obj_at_index_sel = sel_registerName("objectAtIndex:")
      first_obj = objc_msgSend_uint64(types_array, obj_at_index_sel, 0)
      puts "  First object pointer: #{first_obj.inspect}"
      puts "  Is null? #{first_obj.null?}"

      unless first_obj.null?
        utf8_sel = sel_registerName("UTF8String")
        cstr = objc_msgSend(first_obj, utf8_sel)
        puts "  C string pointer: #{cstr.inspect}"
        unless cstr.null?
          str = cstr.read_string
          puts "  First type: #{str}"
        end
      end
    end
  end
end

Debug.test_clipboard

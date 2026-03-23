# frozen_string_literal: true

require "ffi"

module Ace
  module Support
    module MacClipboard
      class Reader
        extend FFI::Library

        # Load Objective-C runtime and AppKit framework
        ffi_lib "/usr/lib/libobjc.dylib"
        ffi_lib "/System/Library/Frameworks/AppKit.framework/AppKit"

        # Objective-C runtime functions
        attach_function :objc_getClass, [:string], :pointer
        attach_function :sel_registerName, [:string], :pointer
        attach_function :objc_msgSend, [:pointer, :pointer], :pointer
        attach_function :objc_msgSend_id, :objc_msgSend, [:pointer, :pointer, :pointer], :pointer
        attach_function :objc_msgSend_uint, :objc_msgSend, [:pointer, :pointer], :uint
        attach_function :objc_msgSend_uint64, :objc_msgSend, [:pointer, :pointer, :uint64], :pointer

        # Helper to send Objective-C messages
        def self.objc_send(obj, selector, *args)
          sel = sel_registerName(selector.to_s)
          if args.empty?
            objc_msgSend(obj, sel)
          else
            objc_msgSend_id(obj, sel, *args)
          end
        end

        # Read clipboard content
        def self.read
          return {success: false, error: "Not on macOS"} unless RUBY_PLATFORM.match?(/darwin/)

          pasteboard = get_general_pasteboard
          return {success: false, error: "Could not access pasteboard"} unless pasteboard

          types = available_types(pasteboard)
          return {success: true, types: [], text: nil, attachments: []} if types.empty?

          {success: true, types: types, raw_pasteboard: pasteboard}
        rescue => e
          {success: false, error: e.message}
        end

        # Get the general (system) pasteboard
        def self.get_general_pasteboard
          ns_pasteboard_class = objc_getClass("NSPasteboard")
          objc_send(ns_pasteboard_class, "generalPasteboard")
        end

        # Get all available UTI types on the pasteboard
        def self.available_types(pasteboard)
          types_array = objc_send(pasteboard, "types")
          return [] unless types_array && !types_array.null?

          count = objc_msgSend_uint(types_array, sel_registerName("count"))
          return [] if count.zero?

          types = []
          count.times do |i|
            type_obj = objc_msgSend_uint64(types_array, sel_registerName("objectAtIndex:"), i)
            next unless type_obj && !type_obj.null?

            utf8_selector = sel_registerName("UTF8String")
            type_cstr = objc_msgSend(type_obj, utf8_selector)
            next if type_cstr.null?

            types << type_cstr.read_string
          end

          types
        rescue => e
          warn "Error in available_types: #{e.message}"
          warn e.backtrace.first(5)
          []
        end

        # Read data for a specific UTI type
        def self.read_type(pasteboard, uti)
          # Create NSString for the UTI
          objc_getClass("NSString")
          uti_str = create_nsstring(uti)
          return nil unless uti_str

          # Get data from pasteboard
          data = objc_msgSend_id(pasteboard, sel_registerName("dataForType:"), uti_str)
          return nil unless data && !data.null?

          # Get byte length
          length = objc_msgSend_uint(data, sel_registerName("length"))
          return nil if length.zero?

          # Get bytes pointer
          bytes = objc_msgSend(data, sel_registerName("bytes"))
          return nil if bytes.null?

          # Read binary data
          bytes.read_bytes(length)
        rescue
          nil
        end

        # Read string content for text types
        def self.read_string(pasteboard, uti)
          # Try to get as string first
          objc_getClass("NSString")
          uti_str = create_nsstring(uti)
          return nil unless uti_str

          string_obj = objc_msgSend_id(pasteboard, sel_registerName("stringForType:"), uti_str)
          if string_obj && !string_obj.null?
            utf8_selector = sel_registerName("UTF8String")
            cstr = objc_msgSend(string_obj, utf8_selector)
            return cstr.read_string unless cstr.null?
          end

          # Fallback to reading as data
          data = read_type(pasteboard, uti)
          data&.force_encoding("UTF-8")
        rescue
          nil
        end

        # Read file URLs from pasteboard
        def self.read_file_urls(pasteboard)
          # Try NSFilenamesPboardType first (Finder uses this for copied files)
          file_paths = read_filenames_pboard_type(pasteboard)
          return file_paths if file_paths.any?

          # Fallback to public.file-url
          file_paths = read_public_file_url(pasteboard)
          return file_paths if file_paths.any?

          []
        rescue => e
          warn "Error reading file URLs: #{e.message}"
          []
        end

        # Read file paths from NSFilenamesPboardType (used by Finder)
        def self.read_filenames_pboard_type(pasteboard)
          uti_str = create_nsstring("NSFilenamesPboardType")
          return [] unless uti_str

          # Get property list (NSArray of file path strings)
          prop_list_sel = sel_registerName("propertyListForType:")
          array_obj = objc_msgSend_id(pasteboard, prop_list_sel, uti_str)
          return [] unless array_obj && !array_obj.null?

          # Get count of files
          count_sel = sel_registerName("count")
          count = objc_msgSend_uint(array_obj, count_sel)
          return [] if count.zero?

          # Extract file paths
          file_paths = []
          count.times do |i|
            obj_at_index_sel = sel_registerName("objectAtIndex:")
            path_obj = objc_msgSend_uint64(array_obj, obj_at_index_sel, i)
            next unless path_obj && !path_obj.null?

            utf8_sel = sel_registerName("UTF8String")
            cstr = objc_msgSend(path_obj, utf8_sel)
            next if cstr.null?

            path = cstr.read_string
            file_paths << path if File.exist?(path)
          end

          file_paths
        rescue => e
          warn "Error reading NSFilenamesPboardType: #{e.message}"
          []
        end

        # Read file URL from public.file-url
        def self.read_public_file_url(pasteboard)
          data = read_type(pasteboard, "public.file-url")
          return [] unless data

          # Parse URL from data
          url_str = data.force_encoding("UTF-8").strip

          # Remove "file://" prefix if present
          url_str = url_str.sub(%r{^file://}, "")

          # URL decode
          url_str = begin
            URI.decode_www_form_component(url_str)
          rescue
            url_str
          end

          File.exist?(url_str) ? [url_str] : []
        rescue
          []
        end

        # Helper to create NSString from Ruby string
        def self.create_nsstring(str)
          ns_string_class = objc_getClass("NSString")
          return nil unless ns_string_class

          utf8_selector = sel_registerName("stringWithUTF8String:")
          objc_msgSend_id(ns_string_class, utf8_selector, FFI::MemoryPointer.from_string(str))
        rescue
          nil
        end
      end
    end
  end
end

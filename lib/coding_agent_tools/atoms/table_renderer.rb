# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # Renders tabular data in a formatted text table
    class TableRenderer
      DEFAULT_COLUMN_SEPARATOR = ' | '
      DEFAULT_HEADER_SEPARATOR = '-'
      
      attr_reader :columns, :rows, :options
      
      # Initialize with column definitions
      # @param columns [Array<Hash>] Column definitions with :name, :width, :align
      # @param options [Hash] Rendering options
      def initialize(columns, options = {})
        @columns = columns
        @rows = []
        @options = {
          separator: DEFAULT_COLUMN_SEPARATOR,
          header_separator: DEFAULT_HEADER_SEPARATOR,
          max_width: options[:max_width] || terminal_width
        }.merge(options)
      end
      
      # Add a row of data
      # @param row [Array] Data values for each column
      def add_row(row)
        @rows << row
      end
      
      # Render the table as a string
      # @return [String] Formatted table
      def render
        calculate_column_widths
        
        lines = []
        lines << render_header
        lines << render_separator
        @rows.each { |row| lines << render_row(row) }
        
        lines.join("\n")
      end
      
      private
      
      def terminal_width
        # Try to get terminal width, default to 80
        ENV['COLUMNS']&.to_i || 80
      end
      
      def calculate_column_widths
        # Calculate actual widths based on content and constraints
        @columns.each_with_index do |col, i|
          if col[:width]
            # Use specified width
            col[:actual_width] = col[:width]
          else
            # Calculate width based on content
            max_content_width = col[:name].length
            
            # Check all row values
            @rows.each do |row|
              value = row[i]&.to_s || ''
              max_content_width = [max_content_width, value.length].max
            end
            
            col[:actual_width] = max_content_width
          end
        end
      end
      
      def render_header
        values = @columns.map.with_index do |col, i|
          align_text(col[:name], col[:actual_width], col[:align] || :left)
        end
        values.join(@options[:separator])
      end
      
      def render_separator
        parts = @columns.map do |col|
          @options[:header_separator] * col[:actual_width]
        end
        parts.join(@options[:separator].gsub(' ', @options[:header_separator]))
      end
      
      def render_row(row)
        values = @columns.map.with_index do |col, i|
          value = row[i]&.to_s || ''
          align_text(value, col[:actual_width], col[:align] || :left)
        end
        values.join(@options[:separator])
      end
      
      def align_text(text, width, alignment)
        truncated = text.length > width ? text[0...width-1] + '…' : text
        
        case alignment
        when :right
          truncated.rjust(width)
        when :center
          truncated.center(width)
        else
          truncated.ljust(width)
        end
      end
    end
  end
end
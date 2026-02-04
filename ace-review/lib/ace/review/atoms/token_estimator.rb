# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Pure function for estimating token counts from text
      #
      # Uses a simple chars/4 heuristic which provides reasonable accuracy
      # (typically within 20% of actual token counts) for most text types.
      # This is intentionally simple and fast - actual tokenization would
      # require model-specific tokenizers which adds complexity and latency.
      #
      # @example Basic usage
      #   TokenEstimator.estimate("hello world")
      #   #=> 2
      #
      # @example File estimation
      #   TokenEstimator.estimate_file("/path/to/code.rb")
      #   #=> 1500
      module TokenEstimator
        # Average characters per token for the heuristic
        # Most modern tokenizers average around 3-5 chars/token
        # 4 is a reasonable middle ground
        CHARS_PER_TOKEN = 4

        # Estimate token count from a string using chars/4 heuristic
        #
        # @param text [String, nil] The text to estimate tokens for
        # @return [Integer] Estimated token count (0 for nil/empty)
        #
        # @example
        #   TokenEstimator.estimate("Hello, world!")
        #   #=> 3
        def self.estimate(text)
          return 0 if text.nil? || text.empty?

          (text.length.to_f / CHARS_PER_TOKEN).ceil
        end

        # Estimate token count from a file
        #
        # @param path [String] Path to the file
        # @return [Integer] Estimated token count
        # @raise [Errno::ENOENT] if file does not exist
        # @raise [Errno::EACCES] if file is not readable
        #
        # @example
        #   TokenEstimator.estimate_file("/path/to/code.rb")
        #   #=> 1500
        def self.estimate_file(path)
          content = File.read(path)
          estimate(content)
        end

        # Estimate token count from multiple strings
        #
        # @param texts [Array<String>] Array of text strings
        # @return [Integer] Total estimated token count
        #
        # @example
        #   TokenEstimator.estimate_many(["hello", "world"])
        #   #=> 2
        def self.estimate_many(texts)
          return 0 if texts.nil? || texts.empty?

          texts.sum { |text| estimate(text) }
        end

        # Estimate token count from multiple files
        #
        # @param paths [Array<String>] Array of file paths
        # @return [Integer] Total estimated token count
        # @raise [Errno::ENOENT] if any file does not exist
        #
        # @example
        #   TokenEstimator.estimate_files(["/path/to/a.rb", "/path/to/b.rb"])
        #   #=> 3500
        def self.estimate_files(paths)
          return 0 if paths.nil? || paths.empty?

          paths.sum { |path| estimate_file(path) }
        end
      end
    end
  end
end

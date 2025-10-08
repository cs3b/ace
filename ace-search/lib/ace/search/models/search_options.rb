# frozen_string_literal: true

module Ace
  module Search
    module Models
      # SearchOptions encapsulates all search configuration parameters
      # This is a model - pure data structure
      class SearchOptions
        attr_accessor :pattern, :type, :case_insensitive, :whole_word, :multiline,
          :context, :before_context, :after_context,
          :glob, :exclude, :include,
          :max_results, :hidden, :files_with_matches,
          :scope, :since, :before,
          :format, :interactive, :preset

        def initialize(pattern, **options)
          @pattern = pattern
          @type = options[:type] || :auto
          @case_insensitive = options[:case_insensitive] || false
          @whole_word = options[:whole_word] || false
          @multiline = options[:multiline] || false
          @context = options[:context] || 0
          @before_context = options[:before_context]
          @after_context = options[:after_context]
          @glob = options[:glob]
          @exclude = options[:exclude] || []
          @include = options[:include] || []
          @max_results = options[:max_results]
          @hidden = options[:hidden] || false
          @files_with_matches = options[:files_with_matches] || false
          @scope = options[:scope]
          @since = options[:since]
          @before = options[:before]
          @format = options[:format] || :text
          @interactive = options[:interactive] || false
          @preset = options[:preset]
        end

        def to_h
          {
            pattern: @pattern,
            type: @type,
            case_insensitive: @case_insensitive,
            whole_word: @whole_word,
            multiline: @multiline,
            context: @context,
            before_context: @before_context,
            after_context: @after_context,
            glob: @glob,
            exclude: @exclude,
            include: @include,
            max_results: @max_results,
            hidden: @hidden,
            files_with_matches: @files_with_matches,
            scope: @scope,
            since: @since,
            before: @before,
            format: @format,
            interactive: @interactive,
            preset: @preset
          }
        end
      end
    end
  end
end

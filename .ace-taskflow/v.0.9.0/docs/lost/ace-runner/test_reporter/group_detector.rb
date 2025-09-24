# frozen_string_literal: true

module AceTools
  module TestReporter
    class GroupDetector
      ATOM_LAYERS = %w[atoms molecules organisms ecosystems].freeze
      RAILS_DIRS = %w[models controllers views helpers mailers jobs channels].freeze

      def initialize(group_by = 'auto')
        @group_by = group_by
        @project_type = detect_project_type
      end

      def detect_group(file_path)
        return 'UNKNOWN' if file_path.nil? || file_path.empty?

        case @group_by
        when 'auto'
          auto_detect_group(file_path)
        when 'directory'
          directory_based_group(file_path)
        when 'none'
          'TESTS'
        else
          custom_group(file_path)
        end
      end

      private

      def detect_project_type
        # Check for ATOM structure
        if Dir.exist?('lib/ace_tools') || Dir.exist?('lib/coding_agent_tools')
          :atom
        # Check for Rails structure
        elsif File.exist?('config/application.rb') || File.exist?('Gemfile.lock') && File.read('Gemfile.lock').include?('rails')
          :rails
        else
          :generic
        end
      end

      def auto_detect_group(file_path)
        case @project_type
        when :atom
          atom_group(file_path)
        when :rails
          rails_group(file_path)
        else
          directory_based_group(file_path)
        end
      end

      def atom_group(file_path)
        ATOM_LAYERS.each do |layer|
          return layer.upcase if file_path.include?("/#{layer}/")
        end

        # Check for CLI, models, or other special directories
        return 'CLI' if file_path.include?('/cli/')
        return 'MODELS' if file_path.include?('/models/')
        return 'INTEGRATION' if file_path.include?('/integration/')

        'OTHER'
      end

      def rails_group(file_path)
        RAILS_DIRS.each do |dir|
          return dir.upcase if file_path.include?("/#{dir}/")
        end

        return 'SYSTEM' if file_path.include?('/system/')
        return 'INTEGRATION' if file_path.include?('/integration/')
        return 'UNIT' if file_path.include?('/unit/')

        'OTHER'
      end

      def directory_based_group(file_path)
        # Extract the test directory name
        if file_path =~ %r{test/(\w+)/}
          Regexp.last_match(1).upcase
        elsif file_path =~ %r{spec/(\w+)/}
          Regexp.last_match(1).upcase
        else
          'TESTS'
        end
      end

      def custom_group(file_path)
        # Allow custom grouping logic via configuration
        # For now, just return the configured group name
        @group_by.upcase
      end
    end
  end
end
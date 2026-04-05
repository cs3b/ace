# frozen_string_literal: true

require "ace/support/items"
require_relative "../atoms/hitl_file_pattern"

module Ace
  module Hitl
    module Molecules
      class HitlScanner
        attr_reader :last_scan_total, :last_folder_counts

        def initialize(root_dir)
          @root_dir = root_dir
          @scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
            root_dir,
            file_pattern: Atoms::HitlFilePattern::FILE_GLOB
          )
        end

        def scan
          @scanner.scan
        end

        def scan_in_folder(folder)
          results = scan
          @last_scan_total = results.size
          @last_folder_counts = results.group_by(&:special_folder).transform_values(&:size)
          return results if folder.nil?

          virtual = Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?(folder)
          case virtual
          when :all then results
          when :next then results.select { |r| r.special_folder.nil? }
          else
            normalized = Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(folder)
            results.select { |r| r.special_folder == normalized }
          end
        end
      end
    end
  end
end

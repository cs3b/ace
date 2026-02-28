# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Models
        # Value object representing a scan result for an item directory
        # Holds path information, raw ID, and folder metadata
        ScanResult = Struct.new(
          :id,           # Raw 6-char b36ts ID (e.g., "8ppq7w")
          :slug,         # Folder slug without ID (e.g., "dark-mode-support")
          :folder_name,  # Full folder name (e.g., "8ppq7w-dark-mode-support")
          :dir_path,     # Full path to item directory
          :file_path,    # Full path to item spec file
          :special_folder, # Special folder name (e.g., "_maybe", nil if none)
          keyword_init: true
        ) do
          def to_h
            {
              id: id,
              slug: slug,
              folder_name: folder_name,
              dir_path: dir_path,
              file_path: file_path,
              special_folder: special_folder
            }
          end
        end
      end
    end
  end
end

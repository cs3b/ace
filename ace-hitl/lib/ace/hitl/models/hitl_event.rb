# frozen_string_literal: true

module Ace
  module Hitl
    module Models
      HitlEvent = Struct.new(
        :id,
        :status,
        :kind,
        :title,
        :tags,
        :questions,
        :answer,
        :content,
        :path,
        :file_path,
        :special_folder,
        :created_at,
        :metadata,
        keyword_init: true
      ) do
        def shortcut
          id[-3..]
        end

        def answered?
          status.to_s == "answered" || metadata["answered"] == true
        end
      end
    end
  end
end

# frozen_string_literal: true

module Ace
  module Hitl
    module Models
      HitlEvent = Struct.new(
        :id,
        :status,
        :kind,
        :type,
        :result,
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

        def report?
          type.to_s == "report"
        end

        def question?
          !report?
        end

        # Recipient address hash (machine + folder [+ id] or machine + panel)
        # for consumers/adapters; nil for legacy events without keys.
        def recipient
          address_from_metadata("recipient")
        end

        # Reply address (original sender + exact case); questions only.
        def reply_to
          address_from_metadata("reply_to")
        end

        private

        def address_from_metadata(prefix)
          base = {
            "machine" => metadata["#{prefix}_machine"],
            "folder" => metadata["#{prefix}_folder"],
            "panel" => metadata["#{prefix}_panel"],
            "id" => metadata["#{prefix}_id"]
          }
          return nil if base["machine"].to_s.empty?

          base.compact
        end
      end
    end
  end
end

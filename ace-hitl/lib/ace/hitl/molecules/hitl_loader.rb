# frozen_string_literal: true

require "time"
require "ace/support/items"
require_relative "../atoms/hitl_file_pattern"
require_relative "../models/hitl_event"

module Ace
  module Hitl
    module Molecules
      class HitlLoader
        def load(dir_path, id: nil, special_folder: nil)
          return nil unless Dir.exist?(dir_path)

          hitl_file = Dir.glob(File.join(dir_path, Atoms::HitlFilePattern::FILE_GLOB)).first
          return nil unless hitl_file

          folder_name = File.basename(dir_path)
          id ||= extract_id(folder_name)

          content = File.read(hitl_file)
          frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
          answer = extract_answer(body)

          title = frontmatter["title"] ||
            Ace::Support::Items::Atoms::TitleExtractor.extract(body) ||
            folder_name

          created_at = parse_created_at(frontmatter["created_at"])

          known_keys = %w[
            id status title kind tags questions assignment step step_name
            resume_instructions created_at answered answered_at
            requester_provider requester_model requester_session_id
            waiter_state waiter_session_id waiter_provider waiter_last_seen_at
            waiter_poll_every_sec waiter_timeout_at
            resume_dispatch_status resume_dispatch_attempted_at resumed_at resumed_by
            resume_dispatch_error
          ]
          extra_metadata = frontmatter.reject { |k, _| known_keys.include?(k) }

          Models::HitlEvent.new(
            id: id || frontmatter["id"],
            status: frontmatter["status"] || "pending",
            kind: frontmatter["kind"] || "clarification",
            title: title,
            tags: Array(frontmatter["tags"]),
            questions: Array(frontmatter["questions"]),
            answer: answer,
            content: body.to_s.strip,
            path: dir_path,
            file_path: hitl_file,
            special_folder: special_folder,
            created_at: created_at,
            metadata: extra_metadata.merge(
              "assignment" => frontmatter["assignment"],
              "step" => frontmatter["step"],
              "step_name" => frontmatter["step_name"],
              "resume_instructions" => frontmatter["resume_instructions"],
              "answered" => frontmatter["answered"],
              "answered_at" => frontmatter["answered_at"],
              "requester_provider" => frontmatter["requester_provider"],
              "requester_model" => frontmatter["requester_model"],
              "requester_session_id" => frontmatter["requester_session_id"],
              "waiter_state" => frontmatter["waiter_state"],
              "waiter_session_id" => frontmatter["waiter_session_id"],
              "waiter_provider" => frontmatter["waiter_provider"],
              "waiter_last_seen_at" => frontmatter["waiter_last_seen_at"],
              "waiter_poll_every_sec" => frontmatter["waiter_poll_every_sec"],
              "waiter_timeout_at" => frontmatter["waiter_timeout_at"],
              "resume_dispatch_status" => frontmatter["resume_dispatch_status"],
              "resume_dispatch_attempted_at" => frontmatter["resume_dispatch_attempted_at"],
              "resumed_at" => frontmatter["resumed_at"],
              "resumed_by" => frontmatter["resumed_by"],
              "resume_dispatch_error" => frontmatter["resume_dispatch_error"]
            ).compact
          )
        rescue SystemCallError, Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
          warn "Warning: Failed to load HITL event from #{dir_path}: #{e.class}: #{e.message}"
          nil
        end

        private

        def extract_id(folder_name)
          match = folder_name.match(/^([0-9a-z]{6})/)
          match ? match[1] : nil
        end

        def extract_answer(body)
          text = body.to_s
          match = text.match(/^## Answer[ \t]*(?:\n(.*))?\z/m)
          return nil unless match

          answer = match[1].to_s.strip
          answer.empty? ? nil : answer
        end

        def parse_created_at(value)
          return Time.now unless value

          case value
          when Time then value
          when String then Time.parse(value)
          else Time.now
          end
        rescue StandardError
          Time.now
        end
      end
    end
  end
end

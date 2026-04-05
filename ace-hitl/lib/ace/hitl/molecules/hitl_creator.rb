# frozen_string_literal: true

require "fileutils"
require "time"
require "yaml"
require "ace/support/items"
require_relative "../atoms/hitl_file_pattern"
require_relative "../atoms/hitl_id_formatter"
require_relative "hitl_loader"

module Ace
  module Hitl
    module Molecules
      class HitlCreator
        def initialize(root_dir:, config: {})
          @root_dir = root_dir
          @config = config
        end

        def create(title,
          kind: nil,
          questions: [],
          tags: [],
          assignment: nil,
          step: nil,
          step_name: nil,
          resume_instructions: nil,
          move_to: nil,
          time: Time.now.utc)
          raise ArgumentError, "Title is required" if title.nil? || title.strip.empty?

          effective_kind = kind || @config.dig("hitl", "default_kind") || "clarification"
          id = generate_unique_id(time)
          folder_slug = generate_folder_slug(title)
          file_slug = generate_file_slug(title)

          target_dir = determine_target_dir(move_to)
          FileUtils.mkdir_p(target_dir)

          folder_name, _ = unique_folder_name(id, folder_slug, target_dir)
          item_dir = File.join(target_dir, folder_name)
          FileUtils.mkdir_p(item_dir)

          frontmatter = {
            "id" => id,
            "title" => title,
            "kind" => effective_kind,
            "status" => "pending",
            "tags" => tags,
            "questions" => questions,
            "assignment" => assignment,
            "step" => step,
            "step_name" => step_name,
            "resume_instructions" => resume_instructions,
            "answered" => false,
            "created_at" => time
          }.merge(infer_requester_context(assignment: assignment, step: step)).compact

          body = build_body(title: title, questions: questions)
          content = Ace::Support::Items::Atoms::FrontmatterSerializer.rebuild(frontmatter, body)

          item_file = File.join(item_dir, Atoms::HitlFilePattern.filename(id, file_slug))
          File.write(item_file, content)

          loader = HitlLoader.new
          special_folder = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
            item_dir,
            root: @root_dir
          )
          loader.load(item_dir, id: id, special_folder: special_folder)
        end

        private

        def generate_unique_id(base_time)
          time = base_time
          1000.times do
            id = Atoms::HitlIdFormatter.generate(time)
            return id unless hitl_id_exists?(id)

            time += 2
          end

          raise "Failed to generate unique HITL ID after 1000 attempts"
        end

        def hitl_id_exists?(id)
          pattern = File.join(@root_dir, "**", "#{id}-*")
          !Dir.glob(pattern).empty?
        end

        def unique_folder_name(id, slug, target_dir)
          folder_name = Atoms::HitlFilePattern.folder_name(id, slug)
          candidate_dir = File.join(target_dir, folder_name)
          return [folder_name, slug] unless Dir.exist?(candidate_dir)

          counter = 2
          loop do
            unique_slug = "#{slug}-#{counter}"
            folder_name = Atoms::HitlFilePattern.folder_name(id, unique_slug)
            candidate_dir = File.join(target_dir, folder_name)
            break [folder_name, unique_slug] unless Dir.exist?(candidate_dir)

            counter += 1
          end
        end

        def generate_folder_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title.to_s)
          words = sanitized.split("-")
          words.take(6).join("-").then { |s| s.empty? ? "hitl" : s }
        end

        def generate_file_slug(title)
          sanitized = Ace::Support::Items::Atoms::SlugSanitizer.sanitize(title.to_s)
          words = sanitized.split("-")
          words.take(8).join("-").then { |s| s.empty? ? "hitl" : s }
        end

        def determine_target_dir(move_to)
          return @root_dir unless move_to

          normalized = Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(move_to)
          candidate = File.expand_path(File.join(@root_dir, normalized))
          root_real = File.expand_path(@root_dir)

          unless candidate.start_with?(root_real + File::SEPARATOR) || candidate == root_real
            raise ArgumentError, "Path traversal detected in --move-to option"
          end

          candidate
        end

        def build_body(title:, questions: [])
          question_lines = if questions.empty?
            "- (pending human input)"
          else
            questions.map { |q| "- #{q}" }.join("\n")
          end

          <<~BODY
            # #{title}

            ## Questions

            #{question_lines}

            ## Answer

          BODY
        end

        def infer_requester_context(assignment:, step:)
          assignment_id = assignment.to_s.split("@", 2).first.to_s.strip
          return {} if assignment_id.empty?

          sessions_dir = File.join(project_root, ".ace-local", "assign", assignment_id, "sessions")
          return {} unless Dir.exist?(sessions_dir)

          candidates = []
          ancestors_for_step(step).each do |number|
            path = File.join(sessions_dir, "#{number}-session.yml")
            candidates << path if File.exist?(path)
          end
          newest = Dir.glob(File.join(sessions_dir, "*-session.yml")).sort_by { |path| File.mtime(path) }.reverse
          candidates.concat(newest)

          candidates.uniq.each do |path|
            data = YAML.safe_load_file(path, permitted_classes: [Time], aliases: false) || {}
            next unless data.is_a?(Hash)

            provider = data["provider"].to_s.strip
            model = data["model"].to_s.strip
            session_id = data["session_id"].to_s.strip
            next if provider.empty? && model.empty? && session_id.empty?

            return {
              "requester_provider" => (provider.empty? ? nil : provider),
              "requester_model" => (model.empty? ? nil : model),
              "requester_session_id" => (session_id.empty? ? nil : session_id)
            }.compact
          end

          {}
        rescue StandardError
          {}
        end

        def ancestors_for_step(step)
          raw = step.to_s.strip
          return [] if raw.empty?

          parts = raw.split(".")
          (1..parts.length).map { |count| parts[0, count].join(".") }.reverse
        end

        def project_root
          expanded = File.expand_path(@root_dir)
          suffix = "#{File::SEPARATOR}.ace-local#{File::SEPARATOR}hitl"
          return expanded[0...-suffix.length] if expanded.end_with?(suffix)

          Dir.pwd
        end
      end
    end
  end
end

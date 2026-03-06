# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Encapsulates path generation for organized session directory structure.
      #
      # Organized layout:
      #   session_dir/
      #     metadata.yml
      #     _subject/
      #       user.context.md
      #       user.prompt.md
      #     _prompts/
      #       {reviewer-name}.context.md
      #       {reviewer-name}.prompt.md
      #     _reports/
      #       {reviewer-name}/
      #         {provider-slug}.md
      #       lint.md
      #     _synthesis/
      #       feedback-synthesis.json
      #
      class SessionLayout
        SUBJECT_DIR = "_subject"
        PROMPTS_DIR = "_prompts"
        REPORTS_DIR = "_reports"
        SYNTHESIS_DIR = "_synthesis"

        attr_reader :session_dir

        def initialize(session_dir)
          @session_dir = session_dir
        end

        # @return [String] path to _subject/ directory
        def subject_dir
          File.join(@session_dir, SUBJECT_DIR)
        end

        # @return [String] path to _prompts/ directory
        def prompts_dir
          File.join(@session_dir, PROMPTS_DIR)
        end

        # @param reviewer_name [String, nil] reviewer name for subdirectory
        # @return [String] path to _reports/ or _reports/{reviewer}/ directory
        def reports_dir(reviewer_name = nil)
          base = File.join(@session_dir, REPORTS_DIR)
          reviewer_name ? File.join(base, SlugGenerator.generate(reviewer_name)) : base
        end

        # @return [String] path to _synthesis/ directory
        def synthesis_dir
          File.join(@session_dir, SYNTHESIS_DIR)
        end

        # Path for user context file
        # @return [String]
        def user_context_path
          File.join(subject_dir, "user.context.md")
        end

        # Path for user prompt file
        # @return [String]
        def user_prompt_path
          File.join(subject_dir, "user.prompt.md")
        end

        # Path for a reviewer's system context file (deduplicated by reviewer name)
        # @param reviewer_name [String]
        # @return [String]
        def system_context_path(reviewer_name)
          slug = SlugGenerator.generate(reviewer_name)
          File.join(prompts_dir, "#{slug}.context.md")
        end

        # Path for a reviewer's system prompt file (deduplicated by reviewer name)
        # @param reviewer_name [String]
        # @return [String]
        def system_prompt_path(reviewer_name)
          slug = SlugGenerator.generate(reviewer_name)
          File.join(prompts_dir, "#{slug}.prompt.md")
        end

        # Path for a review report file
        # @param reviewer_name [String] reviewer name (creates subdirectory)
        # @param provider_slug [String] provider slug (filename)
        # @return [String]
        def report_path(reviewer_name, provider_slug)
          File.join(reports_dir(reviewer_name), "#{provider_slug}.md")
        end

        # Path for a flat report (e.g. lint, dev-feedback)
        # @param filename [String] report filename
        # @return [String]
        def flat_report_path(filename)
          File.join(reports_dir, filename)
        end

        # Path for feedback synthesis output
        # @return [String]
        def synthesis_output_path
          File.join(synthesis_dir, "feedback-synthesis.json")
        end

        # Ensure all layout directories exist
        def ensure_directories!
          [subject_dir, prompts_dir, reports_dir, synthesis_dir].each do |dir|
            FileUtils.mkdir_p(dir)
          end
        end

        # Detect if a session directory uses the organized layout
        # @param dir [String] session directory path
        # @return [Boolean]
        def self.organized?(dir)
          File.directory?(File.join(dir, SUBJECT_DIR))
        end
      end
    end
  end
end

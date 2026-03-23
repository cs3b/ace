# frozen_string_literal: true

require "json"

module Ace
  module Idea
    module Molecules
      # Enhances ideas with LLM to produce the 3-Question Brief structure.
      # System prompt is hardcoded for this iteration (as specified by task 291.01).
      #
      # 3-Question Brief structure:
      # - What I Hope to Accomplish
      # - What "Complete" Looks Like
      # - Success Criteria
      class IdeaLlmEnhancer
        # Hardcoded system prompt for 3-Question Brief generation
        SYSTEM_PROMPT = <<~PROMPT
          You are an assistant that helps structure raw software development ideas into clear, actionable briefs.

          Given a raw idea, produce a structured response as a JSON object with these fields:
          - "title": a concise, clear title for the idea (max 60 chars)
          - "enhanced_content": the full enhanced idea in markdown with exactly these 3 sections:
            ## What I Hope to Accomplish
            (The desired impact or outcome - why this matters)

            ## What "Complete" Looks Like
            (A concrete end state that would indicate this idea is fully realized)

            ## Success Criteria
            (Verifiable checks that confirm success - use bullet points)

          Keep it concise and actionable. Respond with valid JSON only.
        PROMPT

        # @param config [Hash] Configuration hash (may contain llm_model)
        def initialize(config: {})
          @config = config
          @model = config.dig("idea", "llm_model") ||
            config["llm_model"] ||
            "gflash"
        end

        # Enhance content using LLM
        # @param content [String] Raw idea content
        # @return [Hash] Result with :success, :content (on success), :error (on failure)
        def enhance(content)
          return fallback_enhancement(content) unless llm_available?

          result = call_llm(content)
          if result[:success]
            format_enhanced(result[:data], content)
          else
            fallback_enhancement(content)
          end
        rescue => e
          fallback_enhancement(content, error: e.message)
        end

        private

        def llm_available?
          # Check if ace-llm is loadable
          require "ace/llm/query_interface"
          true
        rescue LoadError
          false
        end

        def call_llm(content)
          require "ace/llm/query_interface"

          prompt = "Structure this idea into a 3-Question Brief:\n\n#{content}"

          response = Ace::LLM::QueryInterface.query(
            @model,
            prompt,
            system: SYSTEM_PROMPT,
            temperature: 0.3,
            max_tokens: 2000
          )

          if response[:text]
            text = response[:text].strip
            # Extract JSON from optional markdown code block (handles preamble text)
            if (m = text.match(/```(?:json)?\s*\n?(.*?)\n?```/m))
              text = m[1].strip
            end

            data = JSON.parse(text)
            {success: true, data: data}
          else
            {success: false, error: "No text in LLM response"}
          end
        rescue JSON::ParserError => e
          {success: false, error: "Invalid JSON from LLM: #{e.message}"}
        rescue => e
          {success: false, error: e.message}
        end

        def format_enhanced(data, _original_content)
          title = data["title"] || "Untitled Idea"
          enhanced = data["enhanced_content"] || generate_stub_content(_original_content)

          content = "# #{title}\n\n#{enhanced}"

          {success: true, content: content, title: title}
        end

        def fallback_enhancement(content, error: nil)
          title = extract_title(content)

          # Build stub structure
          body = []
          body << "# #{title}"
          body << ""
          body << "## What I Hope to Accomplish"
          body << ""
          body << "_[What impact should this have? Why does it matter?]_"
          body << ""
          body << "## What \"Complete\" Looks Like"
          body << ""
          body << "_[What concrete end state would indicate this idea is fully realized?]_"
          body << ""
          body << "## Success Criteria"
          body << ""
          body << "_[What verifiable checks would confirm success?]_"
          body << ""
          body << "---"
          body << ""
          body << "## Original Idea"
          body << ""
          body << content.strip

          enhanced_content = body.join("\n")

          if error
            {success: true, content: enhanced_content, fallback: true, error: error}
          else
            {success: true, content: enhanced_content, fallback: true}
          end
        end

        def generate_stub_content(content)
          <<~STUB
            ## What I Hope to Accomplish

            _[What impact should this have? Why does it matter?]_

            ## What "Complete" Looks Like

            _[What concrete end state would indicate this idea is fully realized?]_

            ## Success Criteria

            _[What verifiable checks would confirm success?]_

            ---

            ## Original Idea

            #{content.strip}
          STUB
        end

        def extract_title(content)
          return "Untitled Idea" if content.nil? || content.strip.empty?

          match = content.match(/^#\s+(.+)$/)
          return match[1].strip if match

          first_line = content.split("\n").first&.strip || ""
          first_line.empty? ? "Untitled Idea" : first_line[0..59]
        end
      end
    end
  end
end

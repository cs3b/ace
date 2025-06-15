We should move molecules/model to models/llm_modl_info

Following those house rules:

Class kind 	Directory / namespace	Why
Pure data carrierattributes + maybe trivial helpers, no outside IO	lib/coding_agent_tools/models/llm_model_info.rb CodingAgentTools::Models::LlmModelInfo	Matches Models = data structures definition; easy for all layers to require/use.
Small behaviour-oriented helper that does something(e.g., token-cost calculator that calls atoms)	lib/coding_agent_tools/molecules/	Molecules are “simple compositions of atoms that form a meaningful, reusable operation”.

Rule of thumb
	•	No IO, no orchestration ⇒ Models/
	•	Composes atoms to perform work ⇒ Molecules/
	•	Coordinates multiple molecules, maybe talks to adapters ⇒ Organisms/

Suggested file

# lib/coding_agent_tools/models/llm_model_info.rb
module CodingAgentTools
  module Models
    # Value object describing an LLM that CAT can talk to
    # This is intentionally immutable; create a new instance for changes.
    LlmModelInfo = Struct.new(
      :provider,        # :gemini, :openai, :local etc.
      :name,            # "gemini-1.5-pro", "gpt-4o-mini"…
      :context_window,  # tokens
      :max_tokens,      # tokens
      :temperature,     # default temp
      :cost_per_1k,     # optional billing info
      keyword_init: true
    ) do
      # Optional convenience helpers are fine
      def chat_capable?
        provider != :openai || name.start_with?("gpt")
      end
    end
  end
end

Migration steps
	1.	Move the file to lib/coding_agent_tools/models/.
	2.	Update any require paths (require 'coding_agent_tools/models/llm_model_info').
	3.	Adjust namespaces in callers (Models::LlmModelInfo.new(...)).
	4.	If Zeitwerk is autoloading, no extra config needed—folder name matches namespace.

Why this keeps the mental model clean
	•	Readers instantly know “anything under models/ is a dumb data object” without wondering if it hides logic.
	•	Molecules remain action-oriented, preventing them from becoming a catch-all.
	•	If one day you decide to persist LLM metadata to a YAML file or DB, you can either extend this object or introduce a repository/adapter layer without breaking API users.

So despite the “model” name collision with Rails, sticking to Models for lightweight POROs is perfectly idiomatic in your ATOM variant.

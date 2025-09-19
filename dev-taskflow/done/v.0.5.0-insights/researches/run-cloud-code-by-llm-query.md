Here’s how to run Claude Code (Anthropic’s CLI) from the command line in a non‑interactive (print) mode, passing both an input file as the prompt and an additional system prompt, while selecting a specific model:

⸻

Command-Line Invocation

claude -p "your user prompt" \
  --append-system-prompt "your system prompt" \
  --model <model-alias-or-full-name> \
  --output-format text \
  --input-format text \
  --output result.txt

Details you can adjust:
	•	-p: runs in non‑interactive (“print”) mode with the given prompt.
	•	--append-system-prompt: adds context or role prompt as a system prompt.  ￼
	•	--model: explicitly selects the model (e.g., claude-sonnet-4-20250514)  ￼
	•	--output-format: choose between text, json, or stream-json  ￼
	•	--input-format: specify input format (text or stream-json)  ￼
	•	--output: directs the output to a file instead of printing to stdout (based on the CLI man page)  ￼

⸻

Using an Input File as the Prompt

If your user prompt is stored in a file (e.g., input.txt), you can pipe it:

cat input.txt | claude -p "$(cat input.txt)" \
  --append-system-prompt "System prompt here" \
  --model claude-sonnet-4-20250514

Alternatively, if supported, you might be able to use a --file or -f flag to read directly, depending on your version of the CLI (this is a convention seen in other tools but not explicitly documented in the Claude Code CLI reference)  ￼.

⸻

Specifying the Model

To select a model for that session:

--model claude-sonnet-4-20250514

Supported model names include those like claude-opus-4-20250514, claude-sonnet-4-20250514, claude-3-7-sonnet-20250219, etc.  ￼

⸻

Complete Example (Assuming Input File)

cat prompt.txt | claude -p "$(cat prompt.txt)" \
  --append-system-prompt "You are an expert data analyst." \
  --model claude-sonnet-4-20250514 \
  --output-format json \
  --input-format text \
  --verbose \
  --output response.json

This command reads in prompt.txt, uses it as the prompt, appends a system prompt to guide Claude, chooses the claude-sonnet-4-20250514 model, formats the output in JSON, and writes the response to response.json.

---
---
:finish_reason: stop
:input_tokens: 13
:output_tokens: 1958
:total_tokens: 1971
:took: 22.753
:provider: google
:model: gemini-2.5-flash
:timestamp: '2025-06-24T10:46:57Z'
---

Compressing rules and prompts for Large Language Models (LLMs) is crucial for several reasons:
1.  **Token Limits:** LLMs have a finite context window. Shorter prompts mean more space for the actual content or longer conversations.
2.  **Cost:** Most LLM APIs charge per token. Compression directly reduces costs.
3.  **Speed:** Fewer tokens mean faster processing.
4.  **Clarity & Focus:** A concise prompt is often clearer and helps the LLM focus on the essential instructions, reducing the chance of misinterpretation or "hallucination."
5.  **Consistency:** Well-defined, compact rules can lead to more consistent outputs.

Here are strategies categorized for effective compression:

---

### I. Content-Level Compression (What you say)

These strategies focus on the language and phrasing within the prompt itself.

1.  **Be Direct and Concise:**
    *   **Eliminate filler words:** "Please kindly consider summarizing the following text" -> "Summarize the text."
    *   **Use active voice:** "The report should be written by you" -> "Write the report."
    *   **Avoid redundancy:** Don't repeat instructions unless absolutely necessary for emphasis.
    *   **Use strong verbs:** "Make a summary" -> "Summarize."

2.  **Prioritize Keywords and Core Concepts:**
    *   Instead of verbose explanations, use specific terms the LLM likely understands.
    *   Example: Instead of "Provide an overview of the main points from the document, focusing on the most important information," try "Summarize key takeaways from the document."

3.  **Use Lists and Bullet Points:**
    *   This is highly effective for rules and requirements. It's visually compressed and easy for the LLM to parse.
    *   **Bad:** "The response needs to include the product name, its price, and a brief description, and it should also mention availability."
    *   **Good:** "Include: 1. Product Name, 2. Price, 3. Brief Description, 4. Availability."

4.  **Leverage Implicit Understanding (if reliable):**
    *   If a rule is generally understood from the task, don't explicitly state it.
    *   Example: If you ask for a "poem," you don't need to add "be creative and use poetic language."

5.  **Use Conditionals (IF/THEN):**
    *   Compactly define behavior based on conditions.
    *   Example: "IF user asks about pricing, THEN provide the standard pricing table. ELSE, offer to connect them to sales."

6.  **Specify Output Format:**
    *   Clearly defining the desired output format (JSON, YAML, CSV, Markdown table) helps the LLM structure its response, often reducing verbosity.
    *   Example: "Output as JSON: { 'name': '', 'age': '' }"

7.  **Negative Constraints (Use with caution):**
    *   Sometimes, telling the LLM what *not* to do can be more concise than listing everything it *should* do. However, LLMs can sometimes struggle with negations.
    *   Example: "DO NOT include personal opinions."

---

### II. Structure-Level Compression (How you organize)

These strategies involve the overall architecture and presentation of your prompt.

1.  **Clear Sections and Headings:**
    *   Use Markdown headings (e.g., `# Instructions`, `## Context`, `### Output Format`) to logically separate parts of the prompt. This helps the LLM understand the hierarchy of information.
    *   `# Role:`
    *   `# Task:`
    *   `# Constraints:`

2.  **Few-Shot Examples:**
    *   This is one of the most powerful compression techniques. Instead of lengthy descriptions of desired behavior, *show* the LLM what you want.
    *   Example: Instead of "When summarizing, ensure you capture the main idea, key supporting points, and a concise conclusion, avoiding jargon and maintaining a neutral tone," just provide a few input/output examples of summaries.
    *   **Input:** "The quick brown fox jumps over the lazy dog."
    *   **Output:** "Fox jumps over dog."
    *   (Then provide the actual text to be summarized.)

3.  **System, User, Assistant Roles (API-specific):**
    *   Utilize the distinct roles provided by LLM APIs (e.g., OpenAI's Chat Completion API).
    *   **System Role:** Best for high-level instructions, persona, and core rules that apply throughout the conversation. This is "background" context.
    *   **User Role:** For the specific query or task at hand.
    *   **Assistant Role:** For few-shot examples or to guide the conversation.
    *   Putting general rules in the System message keeps the User message clean and focused on the immediate task.

4.  **Delimiters:**
    *   Use clear delimiters (e.g., `---`, `###`, `<<<TEXT>>>`) to separate different parts of the input, especially the actual content from the instructions. This helps the LLM distinguish between instructions and data.
    *   Example:
        ```
        Your task is to summarize the following text:
        ---
        [TEXT TO BE SUMMARIZED]
        ---
        ```

5.  **YAML/JSON for Complex Rules/Data:**
    *   For highly structured rules or data, present them in a format LLMs are good at parsing. This is incredibly compact and unambiguous.
    *   Example:
        ```yaml
        Rules:
          - ID: R1
            Condition: "IF user mentions 'refund'"
            Action: "THEN check order history and provide refund policy."
          - ID: R2
            Condition: "IF user asks about 'shipping'"
            Action: "THEN provide estimated delivery times based on location."
        ```

---

### III. External & Pre-processing Strategies

These involve actions taken *before* the prompt is even sent to the LLM.

1.  **Rule Engine/Knowledge Base Integration:**
    *   Don't embed *all* your business logic or extensive knowledge directly in the prompt.
    *   Use an external system (a database, a traditional rule engine) to apply complex rules or retrieve specific data, then inject only the *relevant* results into the prompt.
    *   Example: Instead of giving the LLM an entire product catalog, query your database for the specific product the user asked about, then pass only that product's details to the LLM.

2.  **Retrieval-Augmented Generation (RAG):**
    *   Store large rule sets, documentation, or knowledge in a vector database.
    *   When a user asks a question, retrieve the most semantically relevant snippets of information/rules and inject *only those snippets* into the prompt. This avoids sending the entire corpus.

3.  **Function Calling / Tool Use:**
    *   If your rules involve interacting with external systems or performing specific calculations, use LLM function calling capabilities.
    *   Instead of explaining *how* to calculate a price, tell the LLM it has a `calculate_price(item_id, quantity)` function. The LLM will then *call* that function, and your external code handles the complex rule, returning only the result. This offloads complex logic from the prompt.

4.  **Fine-tuning (for core, stable rules):**
    *   For extremely common, core behaviors or rules that rarely change, you can fine-tune a model. This embeds the rules directly into the model's weights, making them "innate" and requiring no prompt tokens for those specific behaviors. This is the most token-efficient but also the most expensive and time-consuming upfront.

5.  **Semantic Compression/Summarization (Pre-prompting):**
    *   If you have a very long set of instructions or a complex document you need the LLM to understand, you can use *another* LLM (or a simpler model) to first summarize or extract key points from that long text. Then, feed the compressed version to your main LLM.

---

### IV. Iterative Refinement

Compression is often an iterative process.

1.  **Test and Measure:**
    *   Experiment with different phrasing and structures.
    *   Measure token count and output quality for each iteration.
    *   A/B test different prompt versions.

2.  **Monitor and Adapt:**
    *   If the LLM frequently misinterprets a rule, it might be too compressed or unclear. Expand it slightly, or rephrase it.
    *   Conversely, if it consistently follows a rule, try to simplify the wording further.

---

By combining these strategies, you can significantly reduce prompt size while improving LLM performance, cost-efficiency, and consistency. The key is finding the right balance between conciseness and clarity for your specific use case and LLM.
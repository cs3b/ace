# AI Ruby Agent SDK Documentation

## Introduction

This documentation provides an overview of the AI Ruby Agent SDK, focusing on its core concepts, structure, and usage. The SDK allows you to define agents that interact with both an LLM (using `ruby-llm`) and various system tools through MCP.

## Inspiration

The goal is to keep agents simple, focusing on three core components: environment, tools, and prompt. Early complexity should be avoided to facilitate iteration.

Key principles inspired by Barry Zhang from Anthropic:
- **Use Agents Sparingly**: Use agents only for complex, valuable, and ambiguous tasks. For simpler, predictable problems, workflows are more cost-effective.
- **Keep Agents Simple**: Focus on the core components to avoid early complexity that hinders iteration.
- **Think Like Your Agent**: Evaluate how agents perceive tasks within limited context windows to reveal design improvements.
- **Anticipate the Future**: Prepare for agents with better budget awareness, self-evolving tools, and multi-agent collaboration capabilities.

Actionable takeaway: Use agents sparingly, structure them minimally, test from their limited perspective, and prepare for a future where agents build and coordinate among themselves.

The first two principles will form the foundation of this SDK for agents - still simple definition will help to think like your agent (so 3rd also somehow count)


## Core Concepts and Structure

1.	Not every problem needs an agent – use agents only when tasks are complex, valuable, and ambiguous. For simpler, predictable problems, workflows are more cost-effective and controllable.
2.	Keep agents simple – focus on three core components: environment, tools, and prompt. Early complexity hinders iteration.
3.	Think like your agent – evaluate how agents perceive tasks within limited context windows. Simulating this perspective reveals design improvements.
4.	Anticipate the future – agents need better budget awareness, self-evolving tools, and multi-agent collaboration capabilities.

Actionable takeaway: Use agents sparingly, structure them minimally, test them from their limited perspective, and prepare for a future where agents build and coordinate among themselves.

### Agent
Each agent has the following components:
- **Name**: A unique identifier for the agent.
- **Description**: A brief description of what the agent does.
- **Inputs and Outputs**: Defined inputs and outputs for the agent.
- **Prompt**: Written in ERB to allow interpolation of input variables.

### Tools
The DSL (Domain-Specific Language) allows specifying what “tools” the agent can use, such as a web browser, file operations, etc. In a full implementation, these tools might be wrapped as MCP clients.

### Steps
Some agents have multi-step workflows. The DSL provides a `steps` block along with individual step declarations where you can optionally specify a tool (e.g., `:youtube_downloader`) and write a Ruby block that updates a context hash.

### Loop and Review
Each agent can define:
- **Loop Block**: To keep checking that work is finished (e.g., polling for a file to exist).
- **Review Block**: To validate the output (this could be as simple as a checksum or even another LLM call).

## Ruby Way and ERB Templates

### Using ERB for the Prompt
Using ERB for the prompt lets you interpolate input variables in a natural, Ruby-friendly way.

### DSL Syntax
The DSL itself provides a clean, declarative syntax where each method call (like `input`, `output`, `tools`, etc.) declares part of the configuration.

## File-Based Communication
### Source and Output Directories

- **Source Directory**: Each agent can have a defined source directory where it reads the next jobs from. This directory acts as an input queue for the agent.
- **Output Directory**: Each agent has an output directory where all artifacts generated during its execution should be moved. This includes intermediate files and the final results.

The source directory can contain subdirectories for different types of jobs or priorities. Similarly, the output directory can be organized into subdirectories to categorize different types of artifacts.

### Example Configuration

```ruby
agent :web_extractor do
  source_directory 'web_extraction/202504081254-browsermcp.io'
  output_directory 'markdown_summarizer/202504081254-browsermcp.io'

  # Other agent configurations...
end
```

This configuration ensures that the `web_extractor` agent reads jobs from the `jobs/web_extraction` directory and deposits its results in the `results/web_extraction` directory.

Although not implemented in detail in the simulation code, each agent is intended to use its own “queue” folder (via file operations). The idea is that agents deposit work in files that other agents can pick up.

## Sample Agents

            ### Web Extractor
            Extracts main page content and comments from a webpage and saves it as markdown.

            ```ruby
            agent :web_extractor do
              source_directory 'jobs/web_extraction'
              output_directory 'results/web_extraction'

              # Other agent configurations...
            end
            ```

            ### Markdown Summarizer
            Reads a markdown file and produces a summary.

            ```ruby
            agent :markdown_summarizer do
              source_directory 'jobs/markdown_files'
              output_directory 'results/summaries'

              # Other agent configurations...
            end
            ```

            ### YouTube to Markdown
            Downloads audio from a YouTube URL, transcribes it, and converts it to markdown.

            ```ruby
            agent :youtube_to_markdown do
              source_directory 'jobs/youtube_urls'
              output_directory 'results/transcriptions'

              # Other agent configurations...
            end
            ```

            ### Link Processor
            Reads a document with links, selects an interesting one, and then processes it using the `web_extractor` agent.

            ```ruby
            agent :link_processor do
              source_directory 'jobs/link_documents'
              output_directory 'results/processed_links'

              # Other agent configurations...
            end
            ```

## Execution Simulation

At the bottom of the file, there is sample code to simulate running each agent. In production, you would replace the simulated outputs and loop/review blocks with real checks and operations (e.g., file existence, LLM calls, MCP client interactions).

This DSL design should give you a flexible and “Ruby-ish” way to define agents that interact with both an LLM (using, for example, `ruby-llm`) and various system tools through MCP. You can expand or modify the DSL to suit further needs and to integrate robust file-based communication.

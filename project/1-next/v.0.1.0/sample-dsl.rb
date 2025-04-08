# agent_dsl.rb

require 'erb'
require 'json'

# Registry to hold all defined agents
module AgentRegistry
  @agents = {}

  def self.register(agent)
    @agents[agent.name] = agent
  end

  def self.get(name)
    @agents[name]
  end

  def self.all
    @agents.values
  end
end

# Core Agent class representing a defined agent
class Agent
  attr_accessor :name, :description, :input, :output, :prompt, :tools, :steps, :loop_block, :review_block

  def initialize(name)
    @name = name
    @input = {}
    @output = {}
    @tools = []
    @steps = []
  end

  def to_h
    {
      name: name,
      description: description,
      input: input,
      output: output,
      prompt: prompt,
      tools: tools,
      steps: steps,
      loop_block: loop_block,
      review_block: review_block
    }
  end

  # Render the prompt using ERB. Data is passed as a hash.
  def render_prompt(data = {})
    ERB.new(prompt).result_with_hash(data)
  end

  # Simulate an agent "run" (in practice, you’d plug in your LLM & MCP client calls, file I/O, etc)
  def run(context = {})
    puts "Running agent #{name}..."
    puts "Prompt: #{render_prompt(context)}"
    # Here you’d normally call ruby-llm with the rendered prompt, use tools, etc.
    # For steps workflows, iterate over steps (see Step below).
    steps.each do |step|
      step.run(context)
    end

    # Simulate loop validation: you might, for instance, wait or check a file exists.
    loop(&context) if loop_block

    # Finally, run the review block if defined.
    review_block.call(context) if review_block
    context
  end

  # For optional loops.
  def loop(context = {})
    instance_exec(context, &loop_block)
  end
end

# A simple structure for agent steps
class Step
  attr_reader :name, :using, :block

  def initialize(name, using: nil, &block)
    @name = name
    @using = using
    @block = block
  end

  def run(context)
    # Here you could have specialized logic for tools if :using is provided.
    puts "Running step #{name}#{using ? " using #{using}" : ""}..."
    block.call(context) if block
  end
end

# DSL Builder to allow clean agent definitions.
module AgentDSL
  def agent(name, &block)
    builder = AgentBuilder.new(name)
    builder.instance_eval(&block)
    AgentRegistry.register(builder.build)
  end
end

# The builder object for an agent.
class AgentBuilder
  def initialize(name)
    @agent = Agent.new(name)
  end

  def description(text)
    @agent.description = text
  end

  def input(name, type: :string)
    @agent.input[name] = type
  end

  def output(name, type: :string)
    @agent.output[name] = type
  end

  def prompt(text = nil, &block)
    if block_given?
      @agent.prompt = block.call
    elsif text
      @agent.prompt = text
    end
  end

  def tools(*t)
    @agent.tools.concat(t)
  end

  # For a step-based agent.
  def steps(&block)
    instance_eval(&block)
  end

  def step(name, using: nil, &block)
    @agent.steps << Step.new(name, using: using, &block)
  end

  # Define a loop block to keep checking until work is done.
  def loop(&block)
    @agent.loop_block = block
  end

  # Define a review block to double-check or guide the loop.
  def review(&block)
    @agent.review_block = block
  end

  def build
    @agent
  end
end

# Make DSL methods available globally
include AgentDSL

#############################
# Example agent definitions
#############################

# 1. Web Extractor Agent:
agent :web_extractor do
  description "Extract main content and comments from a webpage and save as markdown."
  input :url
  output :markdown_file
  prompt <<-ERB
Given the URL <%= url %>, extract the main content and any user comments.
Return the result as a markdown document.
  ERB
  tools :web_browser, :html_parser, :markdown_converter

  # Loop until the file is created on disk (for example purposes, we just simulate a check)
  loop do |context|
    # In a real implementation, you might check something like:
    # until File.exist?(context[:markdown_file]) do sleep 1; end
    puts "Loop: verifying file exists for #{context[:url]}..."
  end

  # A review block to decide if the job is done.
  review do |context|
    puts "Reviewing output for #{context[:url]}..."
    # In a real implementation, add code to validate markdown content.
  end
end

# 2. Markdown Summarizer Agent:
agent :markdown_summarizer do
  description "Create a summary of the given markdown document."
  input :markdown_file
  output :summary
  prompt <<-ERB
Read the markdown document at <%= markdown_file %> and generate a concise summary focusing on the key points.
  ERB
  tools :file_ops, :text_analyzer

  loop do |context|
    puts "Loop: checking if summary is complete for #{context[:markdown_file]}..."
  end

  review do |context|
    puts "Reviewing summary for #{context[:markdown_file]}..."
  end
end

# 3. YouTube to Markdown Agent:
agent :youtube_to_md do
  description "Download audio from a YouTube URL, generate transcript, and convert it to a markdown document."
  input :youtube_url
  output :markdown_file
  # For complex workflows, we define a sequence of steps:
  steps do
    step :download_audio, using: :youtube_downloader do |context|
      puts "Downloading audio from #{context[:youtube_url]}..."
      # Simulated outcome; in practice, set context[:audio_file]
      context[:audio_file] = "audio.mp3"
    end

    step :transcribe_audio, using: :audio_transcriber do |context|
      puts "Transcribing audio file #{context[:audio_file]}..."
      # Simulate transcript generation
      context[:transcript] = "This is the transcript of the video..."
    end

    step :convert_to_markdown, using: :markdown_converter do |context|
      puts "Converting transcript to markdown..."
      # Simulated outcome; in practice, save markdown to disk and update context
      context[:markdown_file] = "video_transcript.md"
    end
  end

  loop do |context|
    puts "Loop: verifying markdown document creation for #{context[:youtube_url]}..."
  end

  review do |context|
    puts "Reviewing markdown output for #{context[:youtube_url]}..."
  end
end

# 4. Link Processor Agent:
agent :link_processor do
  description "Analyze a document with links, select interesting ones, and process them using the web_extractor."
  input :document_file
  output :processed_files
  prompt <<-ERB
Given the document at <%= document_file %>, extract all hyperlinks,
determine the most interesting one, and process it through the web_extractor agent.
  ERB
  tools :file_ops, :link_parser

  steps do
    step :extract_links, using: :link_extractor do |context|
      puts "Extracting links from #{context[:document_file]}..."
      # Simulate link extraction
      context[:links] = ["http://example.com/article1", "http://example.com/article2"]
    end

    step :select_interesting do |context|
      puts "Selecting the most interesting link..."
      # For example, simply pick the first one.
      context[:selected_link] = context[:links].first
    end

    step :process_selected_link, using: :web_extractor do |context|
      puts "Processing selected link #{context[:selected_link]} using web_extractor..."
      # In a real system, you might call: AgentRegistry.get(:web_extractor).run(url: context[:selected_link])
      # Here we simulate the result.
      context[:processed_file] = "extracted_article.md"
    end
  end

  loop do |context|
    puts "Loop: checking processed file for #{context[:document_file]}..."
  end

  review do |context|
    puts "Reviewing processed output for #{context[:document_file]}..."
  end
end

#############################
# Sample execution simulation
#############################

# To run an agent, you could retrieve it from the registry and pass a context hash.
if __FILE__ == $0
  # Example: running the web_extractor agent:
  agent = AgentRegistry.get(:web_extractor)
  # Simulate context with a URL and an expected output file
  context = { url: "http://example.com/article", markdown_file: "article.md" }
  agent.run(context)

  # Similarly, you can run other agents:
  summarizer = AgentRegistry.get(:markdown_summarizer)
  summarizer.run(markdown_file: "article.md", summary: "summary.txt")

  yt_agent = AgentRegistry.get(:youtube_to_md)
  yt_agent.run(youtube_url: "https://youtube.com/watch?v=XYZ", markdown_file: "yt.md")

  link_processor = AgentRegistry.get(:link_processor)
  link_processor.run(document_file: "links_document.md", processed_files: "final_output.md")
end

# unified_tool_registry.rb

module ToolRegistry
  @tools = {}

  def self.register(tool)
    @tools[tool.name] = tool
  end

  def self.get(name)
    @tools[name]
  end

  def self.all
    @tools.values
  end
end

# The base Tool class holds all properties needed by the registry.
class Tool
  attr_accessor :name, :type, :description, :schema_def, :safety_checks, :whitelist, :blacklist, :config, :call_proc

  def initialize(name)
    @name = name
    @schema_def = { input: {}, output: {} }
    @safety_checks = { input: nil, output: nil }
    @whitelist = []
    @blacklist = []
    @config = {}
    @call_proc = nil
  end

  # Executes the tool: validates input, runs the call proc, validates output.
  def call(input)
    # Validate input first.
    if @safety_checks[:input]
      @safety_checks[:input].call(input)
    end

    # Call the tool using the provided call_proc.
    output = @call_proc.call(input, @config)

    # Validate output.
    if @safety_checks[:output]
      @safety_checks[:output].call(output)
    end

    output
  end
end

# DSL Module to allow clean tool definitions.
module ToolDSL
  def tool(name, &block)
    builder = ToolBuilder.new(name)
    builder.instance_eval(&block)
    ToolRegistry.register(builder.tool)
  end
end

class ToolBuilder
  attr_reader :tool

  def initialize(name)
    @tool = Tool.new(name)
  end

  def type(tool_type)
    @tool.type = tool_type
  end

  def description(text)
    @tool.description = text
  end

  def schema(&block)
    SchemaBuilder.new(@tool.schema_def).instance_eval(&block)
  end

  def safety(&block)
    SafetyBuilder.new(@tool.safety_checks).instance_eval(&block)
  end

  def config(&block)
    ConfigBuilder.new(@tool.config).instance_eval(&block)
  end

  def call(&block)
    @tool.call_proc = block
  end

  def whitelist(capabilities)
    @tool.whitelist.concat(capabilities)
  end

  def blacklist(capabilities)
    @tool.blacklist.concat(capabilities)
  end
end

class SchemaBuilder
  def initialize(schema_def)
    @schema_def = schema_def
  end

  def input(key, opts = {})
    @schema_def[:input][key] = opts
  end

  def output(key, opts = {})
    @schema_def[:output][key] = opts
  end
end

class SafetyBuilder
  def initialize(safety_checks)
    @safety_checks = safety_checks
  end

  def validate_input(&block)
    @safety_checks[:input] = block
  end

  def validate_output(&block)
    @safety_checks[:output] = block
  end
end

class ConfigBuilder
  def initialize(config)
    @config = config
  end

  # Set the command to run the tool
  def command(cmd)
    @config[:command] = cmd
  end

  # Set environment variables (as a hash)
  def env(env_hash)
    @config[:env] = env_hash
  end

  # Set the working directory for the tool
  def working_directory(dir)
    @config[:working_directory] = dir
  end

  # Additional configuration parameters can be added here.
end

# Make DSL methods available globally
include ToolDSL

# -------------------------------------------------------------
# Sample DSL Definitions
# -------------------------------------------------------------

# 1. MCP server that controls browsers
tool "browser_controller" do
  type :mcp_server
  description "An MCP server that controls browsers (navigation, click, screenshot, etc.)."

  config do
    command "run_browser_mcp --mode=headless"
    env({ "BROWSER_MODE" => "headless", "LOG_LEVEL" => "debug" })
    working_directory "/opt/mcp/browser"
  end

  schema do
    input :url, type: :string, required: true, description: "The URL to load in the browser."
    output :status, type: :json, description: "Status output from the browser."
  end

  safety do
    validate_input do |input|
      raise "URL must be a valid string" unless input[:url].is_a?(String) && input[:url] =~ URI::DEFAULT_PARSER.make_regexp
    end

    validate_output do |output|
      raise "Status output is missing" unless output.key?(:status)
    end
  end

  whitelist [:navigate, :click, :screenshot]
  blacklist [:shutdown]

  call do |input, config|
    # Example implementation:
    # Open a subprocess to run the MCP server command using STDIO.
    # Send the input (as JSON) to the process and read the JSON output.
    # (This is a simplified pseudo-code representation.)
    require 'json'
    command = config[:command]
    env = config[:env] || {}
    working_directory = config[:working_directory] || Dir.pwd

    # For demonstration, we simulate the execution:
    puts "Executing command: #{command}"
    puts "Working directory: #{working_directory}"
    puts "With environment variables: #{env}"
    puts "Sending input: #{input.to_json}"

    # Simulated output:
    result = { status: { message: "Browser navigated to #{input[:url]}" } }
    result
  end
end

# 2. MCP server that works on the directory
tool "directory_manager" do
  type :mcp_server
  description "An MCP server for directory operations (listing files, moving, copying, etc.)."

  config do
    command "run_directory_mcp"
    env({ "FILE_OP_MODE" => "safe" })
    working_directory "/opt/mcp/directory"
  end

  schema do
    input :directory_path, type: :string, required: true, description: "The target directory path."
    output :result, type: :json, description: "Result of the directory operation."
  end

  safety do
    validate_input do |input|
      raise "Directory path must be a valid string" unless input[:directory_path].is_a?(String)
    end

    validate_output do |output|
      raise "Directory operation result missing" unless output.key?(:result)
    end
  end

  call do |input, config|
    # Simulated directory operation call:
    puts "Running directory command: #{config[:command]} in #{config[:working_directory]}"
    puts "Processing input: #{input.to_json}"
    result = { result: "Directory listed: [file1.txt, file2.txt]" }
    result
  end
end

# 3. Command line tool to convert HTML to beautiful markdown
tool "html_to_markdown" do
  type :cmd
  description "A command-line tool that converts HTML content into beautifully formatted Markdown."

  schema do
    input :html_content, type: :string, required: true, description: "HTML content to convert."
    output :markdown, type: :string, description: "Resulting Markdown text."
  end

  safety do
    validate_input do |input|
      raise "HTML content must be provided as a string" unless input[:html_content].is_a?(String)
    end

    validate_output do |output|
      raise "Markdown conversion failed" unless output[:markdown].is_a?(String) && !output[:markdown].empty?
    end
  end

  call do |input, config|
    # Simulated conversion: In a real scenario, this could be a system call.
    puts "Converting HTML to Markdown..."
    result = { markdown: "Converted Markdown text from provided HTML." }
    result
  end
end

# 4. Simple currency exchange API
tool "currency_exchange_api" do
  type :api
  description "An API endpoint that converts amounts between currencies."

  schema do
    input :amount, type: :float, required: true, description: "Amount to convert."
    input :from_currency, type: :string, required: true, description: "Source currency code."
    input :to_currency, type: :string, required: true, description: "Target currency code."
    output :converted_amount, type: :float, description: "Converted amount."
  end

  safety do
    validate_input do |input|
      raise "Amount must be a positive number" unless input[:amount].is_a?(Numeric) && input[:amount] > 0
      %i[from_currency to_currency].each do |key|
        raise "#{key} must be a 3-letter currency code" unless input[key].is_a?(String) && input[key].size == 3
      end
    end

    validate_output do |output|
      raise "Conversion failed: converted_amount missing" unless output.key?(:converted_amount)
    end
  end

  call do |input, config|
    # Simulated API call: In production, this could be a HTTP request.
    puts "Calling Currency Exchange API..."
    converted = input[:amount] * 1.1  # Dummy conversion rate
    { converted_amount: converted }
  end
end

# -------------------------------------------------------------
# To test:
#
# sample_input = { url: "http://example.com" }
# result = ToolRegistry.get("browser_controller").call(sample_input)
# puts result.inspect
# -------------------------------------------------------------

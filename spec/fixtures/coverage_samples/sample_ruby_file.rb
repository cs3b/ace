# frozen_string_literal: true

module TestProject
  class ExampleClass
    def initialize(name)
      @name = name
    end

    def greet
      puts "Hello, #{@name}!"
      do_something_else
    end

    def do_something_else
      return "done" if @name
      "not done"
    end

    def calculate(a, b)
      result = a + b
      process_result(result)
    end

    private

    def process_result(result)
      # This method is not covered
      result * 2
    end
  end
end
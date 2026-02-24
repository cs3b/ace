# frozen_string_literal: true

class Application
  def initialize(name)
    @name = name
  end

  def run
    puts "Running #{@name}"
  end
end

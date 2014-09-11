require 'message/filters/error_handling'
require 'message/filters/benchmarking'

module Message
  class Filters
    attr_accessor :error_handling, :benchmarking

    def initialize
      @data = {:process => [], :enq => []}
      @error_handling = ErrorHandling.new
      @benchmarking = Benchmarking.new
      load(defaults)
    end

    def [](type)
      @data[type]
    end

    def load(data)
      data.each do |t, m|
        @data[t] << [m, send(m)]
      end
    end

    def defaults
      [
        [:process, :error_handling],
        [:enq, :error_handling],
        [:process, :benchmarking]
      ]
    end
  end
end

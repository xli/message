require 'message/filters/error_handling'
require 'message/filters/benchmarking'
require 'message/filters/retry_on_error'

module Message
  class Filters
    include Enumerable

    attr_accessor :error_handling, :benchmarking, :retry_on_error

    def initialize
      @data = []
      @error_handling = ErrorHandling.new
      @benchmarking = Benchmarking.new
      @retry_on_error = RetryOnError.new
      load(defaults)
    end

    def <<(filter)
      @data << filter
    end

    def load(data)
      data.each do |m|
        @data << [m, send(m)]
      end
    end

    def defaults
      [:error_handling, :benchmarking, :retry_on_error]
    end

    def each(&block)
      @data.each(&block)
    end
  end
end

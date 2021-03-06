require 'message/filters'

module Message
  class Job
    class << self
      def filters
        @filters ||= Filters.new
      end

      def filter(name, &block)
        filters << [name, block]
      end

      def reset
        @filters = nil
      end
    end

    def initialize(queue, &processor)
      @queue = queue
      @processor = processor || lambda {|msg| msg}
    end

    def name
      @queue.name
    end

    def size
      @queue.size
    end

    def enq(msg)
      chain(:enq, lambda {|msg| @queue.enq(msg)}).call(msg)
    end
    alias :<< :enq

    def process(size=1)
      deq = lambda do |size|
        @queue.deq(size) do |msg|
          chain(:process, @processor).call(msg)
        end
      end
      chain(:deq, deq).call(size)
    end

    private
    def chain(action, base)
      Job.filters.to_a.reverse.inject(base) do |m, f|
        f[1].call(m, self, action)
      end
    end
  end
end
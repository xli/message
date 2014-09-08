module Message
  class Job
    class << self
      def filters
        @filters ||= Hash.new{|h,k|h[k]=[]}
      end

      def filter(type, name, &block)
        filters[type] << [name, block]
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
      chain(:enq, @queue.method(:enq)).call(msg)
    end
    alias :<< :enq

    def process(size=1)
      chain(:process, @queue.method(:deq)).call(size, &@processor)
    end

    private
    def chain(type, base)
      Job.filters[type].reverse.inject(base) do |m, f|
        f[1].call(m, self)
      end
    end
  end
end
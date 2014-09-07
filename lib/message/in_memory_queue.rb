require 'thread'

module Message
  class InMemoryQueue
    attr :name
    def initialize(name)
      @name = name
      @queue = ::Queue.new
    end

    def enq(msg)
      @queue << msg
    end
    alias :<< :enq

    def deq(size=1, &block)
      if size == 1
        __deq__(&block)
      else
        size.times { __deq__(&block) }
      end
    rescue ThreadError
      #no message in queue
    end

    def size
      @queue.size
    end

    private
    def __deq__(&block)
      if block_given?
        yield(@queue.deq(true))
      else
        @queue.deq(true)
      end
    end
  end
end
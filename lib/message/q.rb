require 'message/in_memory_queue'
module Message
  module Q
    module_function
    def init(name)
      adapters[adapter].new(name)
    end

    def adapters
      @adapters ||= { :in_memory => InMemoryQueue }
    end

    def adapter
      @adapter ||= :in_memory
    end

    def adapter=(name)
      @adapter = name
    end

    def reset
      @adapter = nil
      @adapters = nil
    end
  end
end
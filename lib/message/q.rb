require 'message/in_memory_queue'
module Message
  class AdapterNotFoundError < StandardError
  end

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
      if name.nil?
        @adapter = nil
        return
      end
      name = name.to_sym
      unless adapters.has_key?(name)
        raise AdapterNotFoundError, "Could not find adapter named #{name.inspect}"
      end
      @adapter = name
    end

    def reset
      @adapter = nil
      @adapters = nil
    end
  end
end
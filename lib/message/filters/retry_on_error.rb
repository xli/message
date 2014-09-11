module Message
  class Filters
    class RetryOnError
      attr_accessor :tries, :on, :sleep
      def initialize
        @tries = 3
        @on = StandardError
        @sleep = 0.1
      end

      def call(filter, _, _)
        lambda do |arg|
          @try = 0
          begin
            filter.call(arg)
          rescue self.on => e
            @try += 1
            if @try < self.tries
              Kernel.sleep self.sleep.to_f
              retry
            end
            raise
          end
        end
      end
    end
  end
end
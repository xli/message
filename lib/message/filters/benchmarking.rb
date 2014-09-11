require 'benchmark'
module Message
  class Filters
    class Benchmarking
      def call(filter, job)
        lambda do |size, &processor|
          filter.call(size) do |msg|
            ret = nil
            Message.logger.info { "#{job.name}: processing one message"}
            s = Benchmark.realtime do
              ret = processor.call(msg)
            end
            Message.logger.info { "#{job.name}: processed in #{(1000 * s).to_i}ms" }
            ret
          end
        end
      end
    end
  end
end
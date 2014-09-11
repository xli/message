require 'benchmark'
module Message
  class Filters
    class Benchmarking
      def call(filter, job, action)
        lambda do |msg|
          return filter.call(msg) unless action == :process

          ret = nil
          Message.logger.info { "#{job.name}: processing one message"}
          s = Benchmark.realtime do
            ret = filter.call(msg)
          end
          Message.logger.info { "#{job.name}: processed in #{(1000 * s).to_i}ms" }
          ret
        end
      end
    end
  end
end
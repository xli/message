require 'benchmark'

module Message
  module Filters
    module_function
    def defaults
      [
        [:process, :error_handling],
        [:process, :benchmarking]
      ]
    end

    def load
      defaults.each do |t, m|
        Job.filter(t, m, &method(m))
      end
    end

    def error_handling(filter)
      lambda do |size, &processor|
        filter.call(size) do |msg|
          begin
            processor.call(msg)
          rescue => e
            Message.logger.error {
              "Process message error #{e.message}:\n#{e.backtrace.join("\n")}"
            }
          end
        end
      end
    end

    def benchmarking(filter)
      lambda do |size, &processor|
        filter.call(size) do |msg|
          ret = nil
          ms = Benchmark.realtime do
            ret = processor.call(msg)
          end
          Message.logger.info { "Processed one message in #{ms.to_i}ms" }
          ret
        end
      end
    end
  end
end

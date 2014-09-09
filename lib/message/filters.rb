require 'benchmark'

module Message
  class Filters
    attr_reader :config

    def initialize
      @data = Hash.new{|h,k|h[k]=[]}
      @config = {
        :error_handling_callback => lambda {|type, job, msg, e| }
      }
      defaults.each do |t, m|
        self[t] << [m, method(m)]
      end
    end

    def [](type)
      @data[type]
    end

    def defaults
      [
        [:process, :error_handling],
        [:enq, :error_handling],
        [:process, :benchmarking]
      ]
    end

    def error_handling(filter, job)
      lambda do |arg, &processor|
        type = processor ? :process : :enq
        log_error(type, job, (type == :enq ? arg : nil)) do
          if processor
            filter.call(arg) do |msg|
              log_error(type, job, msg) { processor.call(msg) }
            end
          else
            filter.call(arg)
          end
        end
      end
    end

    def benchmarking(filter, job)
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

    private
    def log_error(type, job, msg, &block)
      block.call
    rescue => e
      Message.logger.error {"#{type} #{job.name} message failed, #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"}
      config[:error_handling_callback].call(type, job, msg, e)
    end
  end
end

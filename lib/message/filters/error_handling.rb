module Message
  class Filters
    class ErrorHandling
      attr_accessor :callback

      def call(filter, job)
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

      def log_error(type, job, msg, &block)
        block.call
      rescue => e
        Message.logger.error {"#{type} #{job.name} message failed, #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"}
        if self.callback
          self.callback.call(type, job, msg, e)
        end
      end
    end
  end
end
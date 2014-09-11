module Message
  class Filters
    class ErrorHandling
      attr_accessor :callback

      def call(filter, job, action)
        lambda do |msg|
          begin
            filter.call(msg)
          rescue => e
            job_name = job.name rescue 'unknown job(find job name failed)'
            Message.logger.error {"#{action} #{job_name} message failed, #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"}
            if self.callback
              self.callback.call(e, msg, job, action)
            end
          end
        end
      end
    end
  end
end
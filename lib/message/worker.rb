require 'yaml'

module Message
  class Worker
    DEFAULT_JOB_NAME = 'message-worker-default'

    module SyntaxSugar
      class Enq
        def initialize(obj)
          @obj = obj
        end

        def method_missing(m, *args, &block)
          if block_given?
            raise ArgumentError, "Can't enqueue with block call."
          end
          unless @obj.respond_to?(m)
            @obj.send(m, *args)
          end
          Message.worker.job << YAML.dump([@obj, m, args])
        end
      end

      def enq
        Enq.new(self)
      end
    end

    class << self
      def default_job
        @default_job ||= Message.job(DEFAULT_JOB_NAME) do |msg|
          obj, m, args = YAML.load(msg)
          obj.send(m, *args)
        end
      end
    end

    def job
      Worker.default_job
    end

    def process(*args)
      job.process(*args)
    end
  end
end
require 'yaml'

module Message
  class Worker
    DEFAULT_JOB_NAME = 'message-worker-default'

    module Enqueue
      class Enq
        def initialize(obj, job)
          @obj = obj
          @job = job
        end

        def method_missing(m, *args, &block)
          if block_given?
            raise ArgumentError, "Can't enqueue with block call."
          end
          unless @obj.respond_to?(m)
            raise NoMethodError, "undefined method `#{m}' for #{@obj.inspect}"
          end
          Worker.enq(@job, [@obj, m, args])
        end
      end

      def enq(job=DEFAULT_JOB_NAME)
        Enq.new(self, job)
      end
    end

    class << self
      def jobs
        @jobs ||= Hash.new{|h,k| h[k] = Message.job(k, &job_processor)}
      end

      def enq(name, work)
        jobs[name].enq(YAML.dump(work))
      end

      def job_processor
        lambda do |msg|
          obj, m, args = YAML.load(msg)
          obj.send(m, *args)
        end
      end
    end

    def initialize(job_name)
      @job_name = job_name || DEFAULT_JOB_NAME
    end

    def start(size=10, interval=1)
      Thread.start do
        begin
          log(:info) { "start" }
          loop do
            process(size)
            sleep interval
          end
          log(:info) { "stopped" }
        rescue => e
          log(:error) { "crashed: #{e.message}\n#{e.backtrace.join("\n")}"}
        end
      end
    end

    def process(size=1)
      Worker.jobs[@job_name].process(size)
    end

    private
    def log(level, &block)
      Message.logger.send(level) { "[Worker(#{Thread.current.object_id})] #{block.call}" }
    end
  end
end
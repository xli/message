require 'yaml'

module Message
  class Worker
    DEFAULT_JOB_NAME = 'message-worker-default'

    module Enqueue
      class Enq
        def initialize(obj, job)
          @obj = obj
          @job = job || Worker.default_job
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

      def enq(job=nil)
        Enq.new(self, job)
      end
    end

    class << self
      def default_job=(name)
        @default_job = name
      end

      def default_job
        @default_job ||= DEFAULT_JOB_NAME
      end

      def jobs
        @jobs ||= RUBY_PLATFORM =~ /java/ ? java.util.concurrent.ConcurrentHashMap.new : {}
      end

      def job(name)
        jobs[name] ||= Message.job(name, &job_processor)
      end

      def enq(name, work)
        job(name).enq(YAML.dump(work))
      end

      def reset
        @default_job = nil
        @jobs = nil
      end

      def job_processor
        lambda do |msg|
          obj, m, args = YAML.load(msg)
          obj.send(m, *args)
        end
      end
    end

    def initialize(job_name)
      @job_name = job_name
    end

    def default_job=(name)
      self.class.default_job = name
    end

    def default_job
      self.class.default_job
    end

    def reset
      self.class.reset
    end

    def job_name
      @job_name ||= default_job
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
      Worker.job(job_name).process(size)
    end

    private
    def log(level, &block)
      Message.logger.send(level) { "[Worker(#{Thread.current.object_id})] #{block.call}" }
    end
  end
end
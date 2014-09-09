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
          Message.worker(@job) << [@obj, m, args]
        end
      end

      def async(job=nil)
        Enq.new(self, job || Message.worker.default_job)
      end
    end

    class << self
      attr_accessor :default_job, :synch

      def default_job
        @default_job ||= DEFAULT_JOB_NAME
      end

      def default
        new(default_job)
      end

      def process(*args)
        default.process(*args)
      end

      def start(*args)
        default.start(*args)
      end

      def jobs
        @jobs ||= RUBY_PLATFORM =~ /java/ ? java.util.concurrent.ConcurrentHashMap.new : {}
      end

      def reset
        @default_job = nil
        @synch = nil
        @jobs = nil
      end
    end

    attr_reader :job_name

    def initialize(job_name)
      @job_name = job_name
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
      job.process(size)
    end

    def enq(work)
      job.enq(YAML.dump(work)).tap do
        process if self.class.synch
      end
    end
    alias :<< :enq

    private
    def job
      self.class.jobs[@job_name] ||= Message.job(@job_name, &job_processor)
    end

    def job_processor
      lambda do |msg|
        obj, m, args = YAML.load(msg)
        obj.send(m, *args)
      end
    end

    def log(level, &block)
      Message.logger.send(level) { "[Worker(#{Thread.current.object_id})] #{block.call}" }
    end
  end
end
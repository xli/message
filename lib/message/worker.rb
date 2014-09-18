require 'yaml'

module Message
  class Worker
    DEFAULT_JOB_NAME = 'message-worker-default'
    DEFAULT_PROCESS_SIZE = 10
    DEFAULT_PROCESS_INTERVAL = 5

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
      attr_accessor :default_job, :sync

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
        @sync = nil
        @jobs = nil
      end
    end

    attr_reader :job_name

    def initialize(job_name)
      @job_name = job_name
    end

    def start(options={})
      size = options[:size] || DEFAULT_PROCESS_SIZE
      interval = options[:interval] || DEFAULT_PROCESS_INTERVAL
      delay = options[:delay] || 10 + rand(20)
      Thread.start do
        begin
          Message.log(:info) { "[Worker] start in #{delay}" }
          sleep delay
          loop do
            process(size)
            sleep interval
          end
        rescue => e
          Message.log(:error) { "[Worker] crashed: #{e.message}\n#{e.backtrace.join("\n")}"}
        ensure
          Message.log(:info) { "[Worker] stopped" }
        end
      end
    end

    def process(size=1)
      job.process(size)
    end

    def enq(work)
      if self.class.sync
        process_work(work)
      else
        job.enq(YAML.dump(work))
      end
    end
    alias :<< :enq

    private
    def job
      self.class.jobs[@job_name] ||= Message.job(@job_name, &job_processor)
    end

    def job_processor
      lambda do |msg|
        process_work(YAML.load(msg))
      end
    end

    def process_work(work)
      obj, m, args = work
      obj.send(m, *args)
    end
  end
end
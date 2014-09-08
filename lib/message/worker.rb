require 'yaml'

module Message
  class Worker
    DEFAULT_JOB_NAME = 'message-worker-default'

    module Sugar
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
          Message.worker << [@job, [@obj, m, args]]
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
            log(:info) { "processing #{size} jobs" }
            s =  Benchmark.realtime do
              process(size)
            end
            log(:info) { "processed in #{(1000 * s).to_i}s" }
            sleep interval
          end
          log(:info) { "stopped" }
        rescue => e
          log(:error) { "crashed: #{e.message}\n#{e.backtrace.join("\n")}"}
        end
      end
    end

    def process(size=1)
      job(@job_name).process(size)
    end

    def <<(work)
      name, rest = work
      job(name).enq(YAML.dump(rest))
    end

    private
    def log(level, &block)
      Message.logger.send(level) { "[Worker(#{Thread.current.object_id})] #{block.call}" }
    end

    def job(name)
      Worker.jobs[name]
    end
  end
end
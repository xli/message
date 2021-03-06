require 'message/q'
require 'message/job'
require 'message/worker'
require 'logger'

module Message
  module_function
  def queue(name=nil)
    if name
      Q.init(name)
    else
      Q
    end
  end

  def job(name=nil, &block)
    if name
      Job.new(queue(name), &block)
    else
      Job
    end
  end

  def worker(job=nil)
    if job
      Worker.new(job)
    else
      Worker
    end
  end

  def log(level, &block)
    Message.logger.send(level) { "[Thread-#{Thread.current.object_id}] #{block.call}" }
  end

  def logger
    @logger ||= Logger.new(STDOUT)
  end

  def logger=(logger)
    @logger = logger
  end

  def reset
    Message.queue.reset
    Message.job.reset
    Message.worker.reset
  end

  reset
end

Object.send(:include, Message::Worker::Enqueue)
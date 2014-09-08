require 'message/q'
require 'message/job'
require 'message/filters'
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
    Worker.new(job)
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
    Message::Filters.load
  end

  reset
end

Object.send(:include, Message::Worker::Sugar)
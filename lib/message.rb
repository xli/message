require 'message/q'
require 'message/job'
require 'message/worker'

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

  def worker
    Worker.new
  end
end

Object.send(:include, Message::Worker::SyntaxSugar)
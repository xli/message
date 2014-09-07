require 'message/q'
require 'message/job'

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
end
require "test_helper"

class MessageTest < Test::Unit::TestCase
  class NewQueue
    def initialize(name)
      @name = name
    end
  end

  def teardown
    Message.reset
  end

  def test_in_memory_queue
    queue = Message.queue('name')
    assert_equal 'name', queue.name
    assert_equal 0, queue.size
    queue << 'msg1'
    assert_equal 1, queue.size
    queue.enq 'msg2'
    assert_equal 2, queue.size
    queue << 'msg3'
    assert_equal 3, queue.size
    assert_equal 'msg1', queue.deq
    assert_equal 2, queue.size
    assert_equal 'msg2', queue.deq
    assert_equal 1, queue.size

    log = []
    queue.deq do |msg|
      log << msg
    end
    assert_equal ['msg3'], log

    assert_equal 0, queue.size
  end

  def test_job
    log = []
    job = Message.job('name') { |msg| log << msg }
    job << 'msg1'
    job << 'msg2'

    job.process

    assert_equal 1, job.size
    assert_equal ['msg1'], log

    job.process
    assert_equal 0, job.size
    assert_equal ['msg1', 'msg2'], log

    job.process
    assert_equal 0, job.size
    assert_equal 2, log.size
  end

  def test_job_process_size
    log = []
    job = Message.job('name') { |msg| log << msg }
    job << 'msg1'
    job << 'msg2'
    job << 'msg3'
    job.process(3)
    assert_equal ['msg1', 'msg2', 'msg3'], log
  end

  def test_process_returns
    queue = Message.job('name') { |msg| 'process' }
    queue << 'msg1'
    assert_equal 'process', queue.process
    queue << 'msg2'
    queue << 'msg3'
    assert_equal 2, queue.process(2)
    assert_nil queue.process
    assert_nil queue.process(3)
  end

  def test_default_job_processor
    queue = Message.job('name')
    queue << 'msg1'
    assert_equal 'msg1', queue.process
  end

  def test_process_filter_when_processing_job
    Message.job.filter(:append_1, &process_filter(1))
    job = Message.job('name')
    job << 'msg'
    assert_equal 'process msg 1', job.process
  end

  def test_enq_filter
    Message.job.filter(:prepend_1, &enq_filter(1))
    job = Message.job('name')
    job << 'msg1'
    assert_equal 'enq 1 msg1', job.process
  end

  def test_enq_filters_order
    log = []
    Message.job.filter(:prepend_1, &enq_filter(1, log))
    Message.job.filter(:prepend_2, &enq_filter(2, log))

    job = Message.job('name')
    job << 'msg1'
    assert_equal [1, 2], log
    assert_equal 'enq 2 enq 1 msg1', job.process
  end

  def test_process_filters_order
    log = []
    Message.job.filter(:append_1, &process_filter(1, log))
    Message.job.filter(:append_2, &process_filter(2, log))

    job = Message.job('name')
    job << 'msg'
    assert_equal 'process process msg 1 2', job.process
    assert_equal [1, 2], log
  end

  def test_queue_adapter
    Message.queue.adapters[:new_adapter] = NewQueue
    Message.queue.adapter = :new_adapter
    q = Message.queue('name')
    assert_equal NewQueue, q.class
  end

  def test_adapter_not_exist
    assert_raise Message::AdapterNotFoundError do
      Message.queue.adapter = :nn
    end
  end

  def test_string_adapter_name
    Message.queue.adapter = 'in_memory'
    assert_equal :in_memory, Message.queue.adapter
  end
  
  def test_reset_adapter
    Message.queue.adapters[:new_adapter] = NewQueue
    Message.queue.adapter = :new_adapter
    Message.queue.adapter = nil
    assert_equal :in_memory, Message.queue.adapter
  end

  def enq_filter(prepend, log=[])
    lambda do |filter, job, action|
      lambda do |msg|
        msg = if action == :enq
          log << prepend
          "#{action} #{prepend} #{msg}"
        else
          msg
        end
        filter.call(msg)
      end
    end
  end

  def process_filter(append, log=[])
    lambda do |filter, job, action|
      lambda do |msg|
        msg = if action == :process
          log << append
          "#{action} #{msg} #{append}"
        else
          msg
        end
        filter.call(msg)
      end
    end
  end
end

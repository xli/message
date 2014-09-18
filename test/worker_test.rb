require 'test_helper'

class WorkerTest < Test::Unit::TestCase
  module Counter
    def count
      $count ||= 1
    end

    def count=(n)
      $count = n
    end

    def plus(n)
      self.count += n
    end

    def reset
      $count = 1
    end

    extend self
  end

  class Task
    include Counter
    extend Counter
  end

  def setup
    Counter.reset
  end

  def teardown
    Message.reset
  end

  def test_object_instance_syntax_sugar_and_worker_defaults
    t = Task.new
    t.async.plus(2)
    Message.worker.process
    assert_equal 3, t.count
  end

  def test_class_enq
    Task.async.plus(3)
    Message.worker.process
    assert_equal 4, Task.count
  end

  def test_module_enq
    Counter.async.plus(4)
    Task.async.plus(5)
    Message.worker.process(2)
    assert_equal 1 + 4 + 5, Task.count
  end

  def test_should_raise_error_when_enqueue_when_block_call
    assert_raises ArgumentError do
      Task.async.plus(3) { 4 }
    end
  end

  def test_should_raise_no_method_error_when_enqueue_with_unknown_method_call
    assert_raises NoMethodError do
      Task.async.multiply(3)
    end
  end

  def test_start_worker_thread
    t = Message.worker.start(size: 1, interval: 0.01, delay: 0)
    Task.async.plus(3)
    sleep 0.1
    assert_equal 4, Task.count
  ensure
    t.kill
  end

  def test_enq_and_process_different_job
    Task.async('job').plus(3)
    Message.worker.process
    assert_equal 1, Task.count
    Message.worker('job').process
    assert_equal 4, Task.count
  end

  def test_change_default_job_name
    Message.worker.default_job = 'new-default-job'
    Task.async.plus(3)
    Message.worker.process
    assert_equal 4, Task.count

    Task.async('new-default-job').plus(3)
    Message.worker.process
    assert_equal 4 + 3, Task.count

    Task.async.plus(3)
    Message.worker('new-default-job').process
    assert_equal 7 + 3, Task.count
  end

  def test_process_job_when_enq_for_test_environment
    Message.worker.sync = true
    Task.async.plus(3)
    assert_equal 4, Task.count
  end
end

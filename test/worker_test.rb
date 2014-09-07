require 'test_helper'

class WorkerTest < Minitest::Test
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

  def test_object_instance_syntax_sugar_and_worker_defaults
    t = Task.new
    t.enq.plus(2)
    Message.worker.process
    assert_equal 3, t.count
  end

  def test_class_enq
    Task.enq.plus(3)
    Message.worker.process
    assert_equal 4, Task.count
  end

  def test_module_enq
    Counter.enq.plus(4)
    Task.enq.plus(5)
    Message.worker.process(2)
    assert_equal 1 + 4 + 5, Task.count
  end

  def test_should_raise_error_when_enqueue_when_block_call
    assert_raises ArgumentError do
      Task.enq.plus(3) { 4 }
    end
  end
end

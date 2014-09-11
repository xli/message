require "test_helper"

class FiltersTest < Test::Unit::TestCase
  class LoggerStub
    attr_reader :log
    def initialize
      @log = []
    end

    def info(&block)
      @log << block.call
    end
    alias :error :info
  end

  def setup
    Message.logger = LoggerStub.new
  end

  def teardown
    Message.logger = nil
    Message.logger.level = Logger::ERROR
    Message.reset
  end

  def test_benchmarking_process_only
    job = Message.job('name') {|msg| msg}
    job << 1
    job.process(2)
    logs = Message.logger.log.select do |l|
      l =~ /processed in/
    end
    assert_equal 1, logs.size
  end

  def test_error_handling_on_processing
    count = 1
    job = Message.job('count') {|msg| count += msg}
    job << '1'
    job << 1
    job.process(2)
    assert_equal 0, job.size
    assert_equal 1+1, count
    assert_logged(/process count message failed/)
  end

  def test_error_handling_for_enq_error
    job = Message.job.new('queue')
    job << 'msg'
    assert_logged(/enq unknown job\(find job name failed\) message failed/)
  end

  def test_error_handling_for_deq_error
    job = Message.job.new('queue')
    job.process
    assert_logged(/deq unknown job\(find job name failed\) message failed/)
  end

  def test_error_handling_callback
    errors = []
    Message.job.filters.error_handling.callback = lambda do |error, msg, job, action|
      errors << [error, msg, job, action]
    end
    job = Message.job('count') {|msg| raise 'error'}
    job << 'msg'
    job.process

    assert_equal 1, errors.size

    assert_equal RuntimeError, errors[0][0].class
    assert_equal 'error', errors[0][0].message

    assert_equal 'msg', errors[0][1]
    assert_equal job, errors[0][2]
    assert_equal :process, errors[0][3]
  end

  def test_retry_on_error_default_configs
    assert_equal 3, Message.job.filters.retry_on_error.tries
    assert_equal StandardError, Message.job.filters.retry_on_error.on
    assert_equal 0.1, Message.job.filters.retry_on_error.sleep
  end

  def test_retry_on_enq_error
    q = []
    def q.enq(msg)
      self << 'error'
      raise "error"
    end

    job = Message.job.new(q)
    job << 'msg'

    assert_equal 3, q.size
  end

  def test_retry_on_processing_error
    count = 0
    job = Message.job('job') {|msg| count += 1; raise 'error'}
    job << 'msg'
    job.process
    assert_equal 3, count
  end

  def test_retry_on_deq_error
    q = []
    def q.deq(msg)
      self << 'error'
      raise "error"
    end

    job = Message.job.new(q)
    job.process

    assert_equal 3, q.size
  end

  def assert_logged(regex)
    m = Message.logger.log.find do |l|
      l =~ regex
    end
    assert m, "Could not find log match regex: #{regex.inspect}, log: \n#{Message.logger.log.join("\n")}"
  end
end

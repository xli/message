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

  def test_benchmarking
    job = Message.job('name') {|msg| msg}
    job << 1
    job.process(2)
    assert_logged("processed in")
  end

  def test_error_handling
    count = 1
    job = Message.job('count') {|msg| count += msg}
    job << '1'
    job << 1
    job.process(2)
    assert_equal 0, job.size
    assert_equal 1+1, count
    assert_logged("process count message failed")
  end

  def test_error_handling_for_processing_error
    job = OpenStruct.new(:name => 'count')
    filter = lambda do |msg|
      raise 'error'
    end
    Message.job.filters.error_handling.call(filter, job, :process).call('msg')
    assert_logged("process count message failed")
  end

  def test_error_handling_for_enq_error
    job = OpenStruct.new(:name => 'count')
    filter = lambda do |msg|
      raise 'error'
    end
    Message.job.filters.error_handling.call(filter, job, :enq).call('msg')
    assert_logged("enq count message failed")
  end

  def test_error_handling_callback_when_enq_failed
    log = []
    Message.job.filters.error_handling.callback = lambda do |error, msg, job, action|
      log << [error, msg, job, action]
    end
    job = OpenStruct.new(:name => 'count')
    Message.job.filters.error_handling.call(lambda{|_| raise "error"}, job, :enq).call('msg')
    assert_equal 1, log.size
    assert_equal ['msg', job, :enq], log[0][1..3]
    assert_equal RuntimeError, log[0][0].class
    assert_equal 'error', log[0][0].message
  end

  # def test_error_handling_callback_when_deq_failed
  #   log = []
  #   Message.job.filters.error_handling.callback = lambda do |error, msg, job, action|
  #     log << [error, msg, job, action]
  #   end
  #   job = OpenStruct.new(:name => 'count')
  #
  #   Message.job.filters.error_handling.call(lambda{|_| raise "error"}, job).call('msg')
  #
  #   assert_equal 1, log.size
  #   assert_equal [:process, job, nil], log[0][0..2]
  #   assert_equal RuntimeError, log[0][3].class
  #   assert_equal 'error', log[0][3].message
  # end

  def test_error_handling_callback_when_process_message_failed
    log = []
    Message.job.filters.error_handling.callback = lambda do |error, msg, job, action|
      log << [error, msg, job, action]
    end
    job = OpenStruct.new(:name => 'count')
    deq = lambda {|_| raise 'error'}

    Message.job.filters.error_handling.call(deq, job, :process).call('msg')

    assert_equal 1, log.size
    assert_equal ['msg', job, :process], log[0][1..3]
    assert_equal RuntimeError, log[0][0].class
    assert_equal 'error', log[0][0].message
  end

  def test_retry_on_error_default_configs
    assert_equal 3, Message.job.filters.retry_on_error.tries
    assert_equal StandardError, Message.job.filters.retry_on_error.on
    assert_equal 0.1, Message.job.filters.retry_on_error.sleep
  end

  def test_retry_on_error
    job = OpenStruct.new(:name => 'count')
    count = 0
    enq = lambda do |msg|
      count += 1
      raise 'error'
    end

    assert_raise RuntimeError do
      Message.job.filters.retry_on_error.call(enq, job, :enq).call('msg')
    end

    assert_equal 3, count
  end

  def test_retry_on_processing_error
    count = 0
    job = Message.job('name') do |msg|
      count += 1
      raise "error"
    end
    job << 1
    job.process
    assert_equal 3, count
  end

  def assert_logged(msg)
    m = Message.logger.log.find do |l|
      l =~ /#{msg}/i
    end
    assert m, "Could not find log has message: #{msg.inspect}"
  end
end

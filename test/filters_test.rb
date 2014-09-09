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
    job = Message.job('name') {|msg| count += msg}
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

  def test_error_handling_for_deq_error
    job = OpenStruct.new(:name => 'count')
    filter = lambda do |size|
      raise 'error'
    end
    Message.job.filters.error_handling(filter, job).call(1) {|_| }
    assert_logged("process count message failed")
  end

  def test_error_handling_for_enq_error
    job = OpenStruct.new(:name => 'count')
    filter = lambda do |msg|
      raise 'error'
    end
    Message.job.filters.error_handling(filter, job).call('msg')
    assert_logged("enq count message failed")
  end

  def test_error_handling_callback_when_enq_failed
    log = []
    Message.job.filters.config[:error_handling_callback] = lambda do |type, job, msg, error|
      log << [type, job, msg, error]
    end
    job = OpenStruct.new(:name => 'count')
    Message.job.filters.error_handling(lambda{|_| raise "error"}, job).call('msg')
    assert_equal 1, log.size
    assert_equal [:enq, job, 'msg'], log[0][0..2]
    assert_equal RuntimeError, log[0][3].class
    assert_equal 'error', log[0][3].message
  end

  def test_error_handling_callback_when_deq_failed
    log = []
    Message.job.filters.config[:error_handling_callback] = lambda do |type, job, msg, error|
      log << [type, job, msg, error]
    end
    job = OpenStruct.new(:name => 'count')

    Message.job.filters.error_handling(lambda{|_| raise "error"}, job).call(1) {|_|}

    assert_equal 1, log.size
    assert_equal [:process, job, nil], log[0][0..2]
    assert_equal RuntimeError, log[0][3].class
    assert_equal 'error', log[0][3].message
  end

  def test_error_handling_callback_when_process_message_failed
    log = []
    Message.job.filters.config[:error_handling_callback] = lambda do |type, job, msg, error|
      log << [type, job, msg, error]
    end
    job = OpenStruct.new(:name => 'count')
    deq = lambda{|_, &block| block.call('msg')}

    Message.job.filters.error_handling(deq, job).call(1) {|_| raise 'error'}

    assert_equal 1, log.size
    assert_equal [:process, job, 'msg'], log[0][0..2]
    assert_equal RuntimeError, log[0][3].class
    assert_equal 'error', log[0][3].message
  end

  def assert_logged(msg)
    m = Message.logger.log.find do |l|
      l =~ /#{msg}/i
    end
    assert m, "Could not find log has message: #{msg.inspect}"
  end
end

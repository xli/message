require "test_helper"

class FiltersTest < Minitest::Test
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
  end

  def test_benchmarking
    job = Message.job('name') {|msg| count += msg}
    job << 1
    job.process(2)
    assert_logged("one message in")
  end

  def test_error_handling
    count = 1
    job = Message.job('name') {|msg| count += msg}
    job << '1'
    job << 1
    job.process(2)
    assert_equal 0, job.size
    assert_equal 1+1, count
    assert_logged("Process message error")
  end

  def assert_logged(msg)
    m = Message.logger.log.find do |l|
      l =~ /#{msg}/
    end
    assert m, "Could not find log has message: #{msg.inspect}"
  end
end

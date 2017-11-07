require 'thread'

class Pool
  def initialize(size)
    @pool = []
    @pool_size = size
    @pool_mutex = Mutex.new
    @pool_cv = ConditionVariable.new
  end

  def run(*args)
    @pool_mutex.synchronize do
      while @pool.size >= @pool_size
        @pool_cv.wait @pool_mutex
      end
    end
    @pool << Thread.new(args) do
      yield *args
      @pool_mutex.synchronize do
        @pool.delete Thread.current
        @pool_cv.signal
      end
    end
  end

  def join
    @pool.each{|x| x.join}
  end
end

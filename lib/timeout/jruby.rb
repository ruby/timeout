require 'jruby'

module Timeout
  module_function def timeout(sec, klass = nil, message = nil, &block)
    #:yield: +sec+
    return yield(sec) if sec == nil or sec.zero?

    message ||= "execution expired".freeze

    if Fiber.respond_to?(:current_scheduler) && (scheduler = Fiber.current_scheduler)&.respond_to?(:timeout_after)
      return scheduler.timeout_after(sec, klass || Error, message, &block)
    end

    JRubyTimeout.timeout(sec, klass, message, &block)
  end

  # An efficient timeout implementation based on the JDK's ScheduledThreadPoolExecutor
  class JRubyTimeout
    java_import java.util.concurrent.ScheduledThreadPoolExecutor
    java_import java.lang.Runtime
    java_import org.jruby.threading.DaemonThreadFactory
    java_import java.util.concurrent.atomic.AtomicBoolean
    java_import org.jruby.RubyTime
    java_import java.util.concurrent.ExecutionException
    java_import java.lang.InterruptedException
    java_import java.lang.Runnable

    MICROSECONDS = java.util.concurrent.TimeUnit::MICROSECONDS

    # Executor for timeout jobs
    EXECUTOR = ScheduledThreadPoolExecutor.new(
      Runtime.runtime.available_processors,
      DaemonThreadFactory.new)
    EXECUTOR.remove_on_cancel_policy = true

    # Current JRuby runtime
    RUNTIME = JRuby.runtime

    include Runnable

    def self.timeout(seconds, exception_class, message)
      timeout_job = new(exception_class, message)
      timeout_job.start(seconds)
      begin
        yield seconds
      ensure
        timeout_job.finish
      end
    end

    def initialize(exception_class, message)
      @exception_class = exception_class
      @message = message

      @id = exception_class.nil? ? Object.new : nil
      @latch = AtomicBoolean.new
      @current_thread = Thread.current
    end

    def run
      # check latch to see if we have been canceled
      if @latch.compare_and_set(false, true)
        exception_class = @exception_class
        if exception_class.nil?
          timeout_exception = Timeout::Error.new(@message)
          timeout_exception.instance_variable_set(:@exception_id, @id)
          @current_thread.raise(timeout_exception)
        else
          @current_thread.raise(exception_class, @message);
        end
      end
    end

    def start(seconds)
      sec_float = RubyTime.convert_time_interval RUNTIME.current_context, seconds
      usec_float = sec_float * 1_000_000

      @timeout_future = EXECUTOR.schedule(self, usec_float, MICROSECONDS)
    end

    def finish
      timeout_future = @timeout_future
      if @latch.compare_and_set(false, true) && timeout_future.cancel(false)
        # ok, exception will not fire (also cancel caused task to be removed)
      else
        # future is not cancellable, wait for it to run and ignore results
        begin
          timeout_future.get
        rescue ExecutionException
        rescue InterruptedException
        end
      end
    end
  end
end

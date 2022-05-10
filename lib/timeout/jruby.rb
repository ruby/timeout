require 'jruby'

module Timeout
  # A module to hold the executor for timeout operations
  module JRuby
    java_import java.util.concurrent.ScheduledThreadPoolExecutor
    java_import java.lang.Runtime
    java_import org.jruby.threading.DaemonThreadFactory
    java_import java.util.concurrent.atomic.AtomicBoolean
    java_import org.jruby.RubyTime
    java_import java.util.concurrent.TimeUnit
    java_import java.util.concurrent.ExecutionException
    java_import java.lang.InterruptedException

    EXECUTOR = ScheduledThreadPoolExecutor.new(
      Runtime.runtime.available_processors,
      DaemonThreadFactory.new)
    EXECUTOR.remove_on_cancel_policy = true
  end

  # An efficient timeout implementation based on the JDK's ScheduledThreadPoolExecutor
  module_function def timeout(sec, klass = nil, message = nil, &block)
    #:yield: +sec+
    return yield(sec) if sec == nil or sec.zero?

    message ||= "execution expired".freeze

    if Fiber.respond_to?(:current_scheduler) && (scheduler = Fiber.current_scheduler)&.respond_to?(:timeout_after)
      return scheduler.timeout_after(sec, klass || Error, message, &block)
    end

    current_thread = Thread.current
    latch = JRuby::AtomicBoolean.new(false);

    id = klass.nil? ? Object.new : nil;

    sec_float = JRuby::RubyTime.convert_time_interval ::JRuby.runtime.current_context, sec

    timeout_runnable = -> {
      # check latch to see if we have been canceled
      if latch.compare_and_set(false, true)
        if klass.nil?
          timeout_exception = Timeout::Error.new(message)
          timeout_exception.instance_variable_set(:@exception_id, id)
          current_thread.raise(timeout_exception)
        else
          current_thread.raise(klass, message);
        end
      end
    }

    timeout_future = JRuby::EXECUTOR.schedule(timeout_runnable, sec_float * 1_000_000, JRuby::TimeUnit::MICROSECONDS)
    begin
      yield sec
    ensure
      if latch.compare_and_set(false, true) && timeout_future.cancel(false)
        # ok, exception will not fire (also cancel caused task to be removed)
      else
        # future is not cancellable, wait for it to run and ignore results
        begin
          timeout_future.get
        rescue JRuby::ExecutionException
        rescue JRuby::InterruptedException
        end
      end
    end
  end
end

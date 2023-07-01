require 'test/unit'
require 'timeout'
require 'thread'

class TestTimeout < Test::Unit::TestCase

  # Behavior marked "UNDESIRED?" is done so as John's opinion, these can/should be removed before the PR is merged

  require_relative 'error_lifecycle.rb'

  def core_assertions(s)
    assert s.inner_attempted
    assert !s.inner_else
    assert s.inner_ensure
    assert s.outer_ensure

    # This can result in user's expectation of total possible time
    # being very wrong
    # t = Time.now; Timeout.timeout(0.1){begin; sleep 1; ensure; sleep 2; end} rescue puts Time.now-t
    # => 2.106306
    assert s.inner_ensure_has_time_to_finish
    assert s.outer_ensure_has_time_to_finish
  end

  # when an exception to raise is not specified and the inner code does not catch Exception
  def test_1
    s = ErrorLifeCycleTester.new
    s.subject(nil, StandardError)
    core_assertions(s)

    assert !s.inner_rescue
    assert s.outer_rescue
  end

  # when an exception to raise is not specified and the inner code does catch Exception
  def test_2
    s = ErrorLifeCycleTester.new
    s.subject(nil, Exception)
    core_assertions(s)

    assert s.inner_rescue # true in 1.9, false in gem 0.2.0, true in gem 0.4.0

    # UNDESIRED?
    assert !s.outer_rescue # false in 1.9 stdlib, true in gem 0.2.0, false in gem 0.4.0
  end

  # when an exception to raise is StandardError and the inner code does not catch Exception
  def test_3
    s = ErrorLifeCycleTester.new
    s.subject(MyStandardError, StandardError)
    core_assertions(s)

    assert s.inner_rescue

    # UNDESIRED?
    assert !s.outer_rescue
  end

  # when an exception to raise is StandardError and the inner code does catch Exception
  def test_4
    s = ErrorLifeCycleTester.new
    s.subject(MyStandardError, Exception)
    core_assertions(s)

    assert s.inner_rescue

    # UNDESIRED?
    assert !s.outer_rescue
  end

  # when an exception to raise is Exception and the inner code does not catch Exception
  def test_5
    s = ErrorLifeCycleTester.new
    s.subject(MyException, StandardError)
    core_assertions(s)

    assert !s.inner_rescue
    assert s.outer_rescue
  end

  # when an exception to raise is Exception and the inner code does catch Exception
  def test_6
    s = ErrorLifeCycleTester.new
    s.subject(MyException, Exception)
    core_assertions(s)
  
    assert s.inner_rescue

    # UNDESIRED?
    assert !s.outer_rescue
  end

end

require 'test/unit'
require 'timeout'
require 'thread'

class TestTimeout < Test::Unit::TestCase

  ### Tests demonstrating problems with standard lib
  # NOTE: this demonstration was done such that all of the assertions pass,
  #       The ones marked weird, bad, and very bad should not, and their
  #       passing is demonstrating the brokenness.
  # ruby gem at 0f12a0ec11d4a860a56e74a2bb051a77fe70b006 also passes

  require_relative 'lib/error_lifecycle.rb'

  # when an exception to raise is not specified and the inner code does not catch Exception
  def test_1
    subject(nil, StandardError)

    # EXPECTED
    assert $inner_attempted
    assert !$inner_else
    assert !$inner_rescue
    assert $inner_ensure
    assert $outer_rescue
    assert $outer_ensure
    assert $inner_ensure_has_time_to_finish
    assert $outer_ensure_has_time_to_finish
  end

  # when an exception to raise is not specified and the inner code does catch Exception
  def test_2
    subject(nil, Exception)

    # EXPECTED
    assert $inner_attempted
    assert !$inner_else
    assert $inner_ensure
    assert $outer_ensure
    assert $inner_ensure_has_time_to_finish
    assert $outer_ensure_has_time_to_finish
    assert $inner_rescue # true in 1.9, false in gem 0.2.0, true in 0.4.0

    # BAD?
    assert !$outer_rescue # false in 1.9 stdlib, true in gem 0.2.0, false in 0.4.0
  end

  # when an exception to raise is StandardError and the inner code does not catch Exception
  def test_3
    subject(MyStandardError, StandardError)

    # EXPECTED
    assert $inner_attempted
    assert !$inner_else
    assert $inner_rescue
    assert $inner_ensure
    assert $outer_ensure
    assert $inner_ensure_has_time_to_finish
    assert $outer_ensure_has_time_to_finish

    # BAD?
    assert !$outer_rescue
  end

  # when an exception to raise is StandardError and the inner code does catch Exception
  def test_4
    subject(MyStandardError, Exception)

    # EXPECTED
    assert $inner_attempted
    assert !$inner_else
    assert $inner_rescue
    assert $inner_ensure
    assert $outer_ensure
    assert $inner_ensure_has_time_to_finish
    assert $outer_ensure_has_time_to_finish

    # BAD?
    assert !$outer_rescue
  end

  # when an exception to raise is Exception and the inner code does not catch Exception
  def test_5
    subject(MyException, StandardError)

    # EXPECTED
    assert $inner_attempted
    assert !$inner_else
    assert !$inner_rescue
    assert $inner_ensure
    assert $outer_ensure
    assert $outer_rescue
    assert $inner_ensure_has_time_to_finish
    assert $outer_ensure_has_time_to_finish
  end

  # when an exception to raise is Exception and the inner code does catch Exception
  def test_6
    subject(MyException, Exception)

    # EXPECTED
    assert $inner_attempted
    assert !$inner_else
    assert $inner_rescue
    assert $inner_ensure
    assert $outer_ensure
    assert $inner_ensure_has_time_to_finish
    assert $outer_ensure_has_time_to_finish

    # BAD?
    assert !$outer_rescue
  end

end

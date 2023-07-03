# frozen_string_literal: false
require 'test/unit'
require 'timeout'

class TestStressTest < Test::Unit::TestCase

  def test_timeout_queue_stress_test
    threads=[]
    10_000.times do
      print "."
      threads << Thread.new do
        assert_nothing_raised do
          print "+"
          assert_equal :ok, Timeout.timeout(1+rand){ :ok }
        end
      end

      threads << Thread.new do
        assert_raise(Timeout::Error) do
          print "-"
          Timeout.timeout(1+rand) {
            # nil while true # this causes the test to go much more slowly
            sleep 9000
          }
        end
      end
    end
    threads.each(&:join)
  end
end
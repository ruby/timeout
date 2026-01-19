require 'timeout'

begin
  Timeout.timeout(2) do
    Timeout.timeout(2) do
      sleep 3
    end
  end
rescue Exception => e
  p :HERE
  puts ">"+e.full_message
end
puts

begin
  Timeout.timeout(0.1) do
    p sleep 3
  end
rescue Exception => e
  p e.class
end

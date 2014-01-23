=begin
 This is a machine generated stub using stdlib-doc for <b>class ThreadError</b>
 Sources used:  Ruby 2.1.0-preview2
 Created on 2013-12-05 13:20:41 +0400 by IntelliJ Ruby Stubs Generator.
=end

# Raised when an invalid operation is attempted on a thread.
# 
# For example, when no other thread has been started:
# 
#    Thread.stop
# 
# This will raises the following exception:
# 
#    ThreadError: stopping only thread
#    note: use sleep to stop forever
class ThreadError < StandardError
end

=begin
 This is a machine generated stub using stdlib-doc for <b>class Interrupt</b>
 Sources used:  Ruby 1.9.3-p194
 Created on Mon Aug 13 21:17:55 +0400 2012 by IntelliJ Ruby Stubs Generator.
=end

# Raised with the interrupt signal is received, typically because the
# user pressed on Control-C (on most posix platforms). As such, it is a
# subclass of +SignalException+.
# 
#    begin
#      puts "Press ctrl-C when you get bored"
#      loop {}
#    rescue Interrupt => e
#      puts "Note: You will typically use Signal.trap instead."
#    end
# 
# <em>produces:</em>
# 
#    Press ctrl-C when you get bored
# 
# <em>then waits until it is interrupted with Control-C and then prints:</em>
# 
#    Note: You will typically use Signal.trap instead.
class Interrupt < SignalException
end

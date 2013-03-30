=begin
 This is a machine generated stub using stdlib-doc for <b>class FiberError</b>
 Sources used:  Ruby 1.9.3-p194
 Created on Mon Aug 13 21:17:55 +0400 2012 by IntelliJ Ruby Stubs Generator.
=end

# Raised when an invalid operation is attempted on a Fiber, in
# particular when attempting to call/resume a dead fiber,
# attempting to yield from the root fiber, or calling a fiber across
# threads.
# 
#    fiber = Fiber.new{}
#    fiber.resume #=> nil
#    fiber.resume #=> FiberError: dead fiber called
class FiberError < StandardError
end

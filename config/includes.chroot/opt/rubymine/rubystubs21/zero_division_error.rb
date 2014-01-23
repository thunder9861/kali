=begin
 This is a machine generated stub using stdlib-doc for <b>class ZeroDivisionError</b>
 Sources used:  Ruby 2.1.0-preview2
 Created on 2013-12-05 13:20:41 +0400 by IntelliJ Ruby Stubs Generator.
=end

# Raised when attempting to divide an integer by 0.
# 
#    42 / 0
#    #=> ZeroDivisionError: divided by 0
# 
# Note that only division by an exact 0 will raise the exception:
# 
#    42 /  0.0 #=> Float::INFINITY
#    42 / -0.0 #=> -Float::INFINITY
#    0  /  0.0 #=> NaN
class ZeroDivisionError < StandardError
end

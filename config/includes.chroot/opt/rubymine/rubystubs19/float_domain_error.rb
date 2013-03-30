=begin
 This is a machine generated stub using stdlib-doc for <b>class FloatDomainError</b>
 Sources used:  Ruby 1.9.2-p320
 Created on Mon Aug 13 21:19:05 +0400 2012 by IntelliJ Ruby Stubs Generator.
=end

# Raised when attempting to convert special float values
# (in particular infinite or NaN)
# to numerical classes which don't support them.
# 
#    Float::INFINITY.to_r
# 
# <em>raises the exception:</em>
# 
#    FloatDomainError: Infinity
class FloatDomainError < RangeError
end

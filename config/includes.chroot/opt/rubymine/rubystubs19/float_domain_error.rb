=begin
 This is a machine generated stub using stdlib-doc for <b>class FloatDomainError</b>
 Sources used:  Ruby 1.9.2-p320
 Created on 2013-07-25 12:24:14 +0400 by IntelliJ Ruby Stubs Generator.
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

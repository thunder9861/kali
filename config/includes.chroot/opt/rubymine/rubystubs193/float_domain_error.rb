=begin
 This is a machine generated stub using stdlib-doc for <b>class FloatDomainError</b>
 Sources used:  Ruby 1.9.3-p429
 Created on 2013-07-25 12:27:51 +0400 by IntelliJ Ruby Stubs Generator.
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

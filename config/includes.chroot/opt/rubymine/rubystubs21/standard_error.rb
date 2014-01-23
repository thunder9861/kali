=begin
 This is a machine generated stub using stdlib-doc for <b>class StandardError</b>
 Sources used:  Ruby 2.1.0-preview2
 Created on 2013-12-05 13:20:40 +0400 by IntelliJ Ruby Stubs Generator.
=end

# The most standard error types are subclasses of StandardError. A
# rescue clause without an explicit Exception class will rescue all
# StandardErrors (and only those).
# 
#    def foo
#      raise "Oups"
#    end
#    foo rescue "Hello"   #=> "Hello"
# 
# On the other hand:
# 
#    require 'does/not/exist' rescue "Hi"
# 
# <em>raises the exception:</em>
# 
#    LoadError: no such file to load -- does/not/exist
class StandardError < Exception
end

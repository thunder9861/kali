=begin
 This is a machine generated stub using stdlib-doc for <b>class IndexError</b>
 Sources used:  Ruby 2.1.0-preview2
 Created on 2013-12-05 13:20:40 +0400 by IntelliJ Ruby Stubs Generator.
=end

# Raised when the given index is invalid.
# 
#    a = [:foo, :bar]
#    a.fetch(0)   #=> :foo
#    a[4]         #=> nil
#    a.fetch(4)   #=> IndexError: index 4 outside of array bounds: -2...2
class IndexError < StandardError
end

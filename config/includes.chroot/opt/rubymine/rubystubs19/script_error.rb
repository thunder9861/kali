=begin
 This is a machine generated stub using stdlib-doc for <b>class ScriptError</b>
 Sources used:  Ruby 1.9.2-p320
 Created on 2013-07-25 12:24:14 +0400 by IntelliJ Ruby Stubs Generator.
=end

# ScriptError is the superclass for errors raised when a script
# can not be executed because of a +LoadError+,
# +NotImplementedError+ or a +SyntaxError+. Note these type of
# +ScriptErrors+ are not +StandardError+ and will not be
# rescued unless it is specified explicitly (or its ancestor
# +Exception+).
class ScriptError < Exception
end
